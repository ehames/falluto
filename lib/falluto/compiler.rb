require 'set'

require 'rubygems' # to load treetop
require 'treetop' # to build the parser

require 'falluto/grammar'
require 'falluto/nusmv'
require 'falluto/ruby_extensions'
require 'falluto/symboltable'

class UndeclaredFault < Exception ; end
class RedefinedFault < Exception ; end

class CompilerContext
  attr_reader :current_module, :modules
  attr_accessor :variable

  def initialize
    @modules = SymbolTable.new
  end

  def <<(m)
    @modules << m
    @current_module = m
  end

  def [](type)
    @modules[type]
  end

  def main_module
    @modules['main']
  end

end


class Compiler

  attr_reader :input_string, :compiled_string, :parsed_tree, :specs
  
  def initialize
    @parser = Falluto::GrammarParser.new
    #@parser.root = "Choose your favorite rule"
    @generator = Falluto::NuSMV::CodeGenerator.new
    @context = CompilerContext.new
    @specs = []
  end

  def run input
    @input_string = input
    @parsed_tree = @parser.parse @input_string
    if @parsed_tree
      @compiled_string = @parsed_tree.send :compile, self
    end
  end

  def auxiliar_variables
    variables = Set.new

    each_module do |m|
      m.each_fault do |f|
        f.each_auxiliar_variable do |v|
          variables << v.name
        end
        variables << f.precondition_variable
        variables << f.restore_variable
        variables << f.fairness_variable
      end
    end

    variables.sort
  end

  def each_module &block
    @context.modules.each{|m| yield m}
  end

  def compile node
    method = nil
    begin
      method = "compile_#{node.class.human_name}"
      #puts "compiling with #{method} '#{node.text}'"
      send method, node
    rescue => e
      puts e.message
      puts e.backtrace
      raise "[ERROR] Don't know how to compile #{node.class} (#{node.text})"
    end
  end

  # Recursively compile a syntax node descending into its elements.
  def compile_treetop_runtime_syntax_node node
    if node.elements
      node.elements.map{|element| 
#        puts "Invoking on #{element.class}"
        compile element}.to_s
    else
      node.text
    end 
  end

  def compile_falluto_module_declaration_node node
    m = Falluto::NuSMV::Module.new node.name
    @context << m

    result = "MODULE " + node.signature + "\n"
    result << compile(node.declarations)
    if @context.current_module.has_faults?
      result << dump_faulty_module_declarations 
      result << dump_system_effect_declaration
    end
    result
  end

  # Create a new fault object for this declaration.
  # No code is output for this construct.
  #
  def compile_falluto_fault_declaration_node node
    modname = @context.current_module.name
    name = node.name
    precondition = node.precondition
    restores = node.restores
    effect = node.effect

    f = Falluto::NuSMV::Fault.new modname, name, precondition, restores, effect
    raise RedefinedFault.new(f.name) if @context.current_module.is_defined? f
    @context.current_module.add_fault f
    ''
  end

  # Compile the following construct
  #
  # next(v) := val disabled_by {f,g};
  #
  # into
  #
  # next(v) :=
  #   case
  #     (1) & !f.active & !g.active : compile(val);
  #     1 : v;
  #   esac;
  #
  def compile_falluto_fault_assignment_node node
    variable = node.variable
    value = node.value
    faults = @context.current_module.get_faults *node.faults
    raise UndeclaredFault.new fname if faults.any?{ |f| f.nil? }
    @context.variable = variable

    new_condition = build_condition_with_faults "1", faults

    <<-END
  next(#{@context.variable}) :=
    case
      #{new_condition} : #{compile value};
      1 : #{@context.variable};
    esac;
    END

  end

  # Compile the following construct
  #
  # next(v) := val;
  #
  # into
  #
  # next(v) := compile(val);
  #
  # so that we can propagate fault compilation into the value.
  # (when val is a 'case' construct)
  #
  def compile_falluto_assignment_node node
    variable = node.variable
    value = node.value
    @context.variable = variable
    %Q|  next(#{@context.variable}) := #{compile value};\n|
  end

  # Compile the following construct
  #
  # next(v) := 
  #   case
  #     c_1 : v_1 disabled_by {f, g};
  #     ...
  #     c_n : v_n;
  #   esac;
  #
  #   into
  #
  # next(v) :=
  #   case
  #     (c_1) & !f.active & !g.active : compile(v1);
  #     ...
  #     c_n : v_n;
  #     1 : v;
  #   esac;
  #
  def compile_falluto_case_node node
    new_cases = []
    has_faults = false
    node.each_case do |c|
      has_faults ||= c.has_faults?
      new_cases << c.compile(self)
    end
    new_cases << "  1 : #{@context.variable};\n" if has_faults
    
    "case\n" + new_cases.join('') + "esac"
  end

  # Compile the folllowing construct
  #
  # c : v disabled_by {f,g};
  #
  # into
  #
  # (c) & !f.active & !g.active : v;
  #
  # if the construct is not disabled by faults,
  # then the input code is unchanged.
  #
  def compile_falluto_case_element_node node
    condition = node.condition
    value = node.value

    if node.has_faults?
      faults = @context.current_module.get_faults *node.faults
      raise UndeclaredFault.new fname if faults.any?{ |f| f.nil? }
      new_condition = build_condition_with_faults condition, faults
      add_condition_to_faults condition, faults
      "#{new_condition} : #{value};\n"
    else
      "#{condition} : #{value};\n"
    end
  end

  # Compile a variable will output the original code.
  # However, we also need to track variables and their types
  # to modify the model specifications.
  def compile_falluto_var_decl_node node
    v = Falluto::NuSMV::Variable.new node.name, node.vartype
    @context.current_module.add_variable v
    compile_treetop_runtime_syntax_node node
  end

  # Compile the following construct
  #
  # LTLSPEC s
  #
  # into
  #
  # LTLSPEC ((faults and processes are fair) -> (s))
  #
  def compile_falluto_ltl_spec_node node
    spec = node.specification
    sf_list = ['1']

    @context.main_module.each_variable do |variable|
      type = @context[variable.type]
      # NOTE nusmvmodule will be nil if type is undeclared
      sf = dump_module_strong_fairness(type, variable.name) unless type.nil?
      sf_list << sf if sf
    end
 
    @specs << spec

    "LTLSPEC (( #{sf_list.join(" & ")} ) -> #{spec})"
  end

  def no_fault_active faults
    faults.collect{|f| "! #{f.name}.#{f.active_variable}"}.join(' & ')
  end

  def build_condition_with_faults condition, faults
    "(#{condition}) & #{no_fault_active faults}"
  end

  def add_condition_to_faults condition, faults
    faults.each { |fault| fault.add_auxiliar_variable condition }
  end

  def dump_faulty_module_declarations 
    decls = ''

    @context.current_module.each_fault do |fault|
      decls << "-- Begin declarations for (#{fault.name})\n"
      decls << declare_fault_precondition(fault)
      decls << declare_fault_restore(fault)
      decls << declare_fault_instance(fault)
      decls << declare_auxiliar_variables(fault)
      decls << declare_fault_fairness(fault)
      decls << "-- End declarations for (#{fault.name})\n"
    end

    decls << "FAIRNESS running\n" if @context.current_module.has_faults?
    decls
  end

  def dump_system_effect_declaration
    decls = ''

    @context.current_module.each_fault do |fault|
      name = @context.current_module.name
      decls << "-- Begin system effect for (#{name}, #{fault.name})\n"
      decls << declare_sytem_effect(fault)
      decls << "-- End system effect for (#{name}, #{fault.name})\n"
    end

    decls
  end

  # NOTE: Can we return true when the module has no faults?
  def dump_module_strong_fairness m, inst
    sf = []
    m.each_fault{ |f| sf << f.strong_fairness(inst) }

    if sf.empty?
      nil
    else
      "(#{sf.join(" & ")})"
    end
  end

  def declare_fault_precondition fault
    %Q|DEFINE #{fault.precondition_variable} := (#{fault.precondition});\n|
  end

  def declare_fault_restore fault
    %Q|DEFINE #{fault.restore_variable} := (#{fault.restore});\n|
  end

  def declare_fault_instance fault
    %Q|VAR #{fault.name} : process #{fault.instance_signature};\n|
  end

  def declare_auxiliar_variables fault
    str = ''
    fault.each_auxiliar_variable do |v|
      str << %Q|DEFINE #{v.name} := (#{v.condition});\n|
    end
    str
  end

  def declare_fault_fairness fault
    fv = fault.fairness_variable
    result =<<-END_DECL
VAR #{fv} : boolean;
ASSIGN
  next(#{fv}) :=
    case
      #{fault.fairness_condition} & !#{fv} : 1;
      1 : 0;
    esac;
    END_DECL
  end

  def declare_sytem_effect fault
    # The system effect is a module which takes all variables affected by
    # faults as parameters and modifies them when the fault occurs.

    declare_fault_module(fault) +
      declare_affected_variables_modifications(fault) +
      "FAIRNESS running\n"
  end

  def declare_fault_module fault
    instance_signature = fault.instance_signature
    active = fault.active_variable
    pre = fault.precondition_variable
    restore = fault.restore_variable

    <<-END_DECL
MODULE #{instance_signature}
VAR #{active} : boolean;
ASSIGN
  next(#{active}) :=
    case
      #{pre} & !#{active} : {0, 1};
      #{active} & next(#{restore}) : 0;
      1 : #{active};
    esac;
    END_DECL
  end

  def declare_affected_variables_modifications fault
    decls = ''

    fault.each_affected_variable_with_effect do |v, effect|
      decls << declare_affected_variable_modification(fault, v, effect)
    end

    decls
  end

  def declare_affected_variable_modification fault, variable, effect
    active = fault.active_variable

    <<-END_DECL
  next(#{variable}) :=
    case
      !#{active} & next(#{active}) : #{effect};
      1 : #{variable};
    esac;
    END_DECL
  end


end

