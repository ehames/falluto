class Treetop::Runtime::SyntaxNode
  alias text text_value

  def stripped
    text_value.strip
  end

  def compile generator
    generator.compile self
  end
end

module Falluto
  class ModuleDeclarationNode < Treetop::Runtime::SyntaxNode
    def name
      module_sign.name.stripped
    end

    def signature
      module_sign.stripped
    end

    def declarations
      decls
    end

  end

  class FaultDeclarationNode < Treetop::Runtime::SyntaxNode
    def name
      id.stripped
    end

    def precondition
      fault_pre.simple_expression.stripped
    end

    def restores
      fault_restores.next_expression.stripped
    end

    def effect
      result = Hash.new

      each_effect do |effect_expression|
        var = effect_expression.var_id.stripped
        effect = effect_expression.simple_expression.stripped
        result[var] = effect
      end

      result
    end

    def each_effect
      first =  fault_effect.list.first
      yield first unless first.text.empty?
      fault_effect.list.rest.elements.each {|e| yield e.fault_effect_expression}
    end
  end

  class FaultAssignmentNode < Treetop::Runtime::SyntaxNode
    def variable
      var_id.stripped
    end

    def value
      basic_expr
    end

    def faults
      [list.first.stripped] + list.rest.elements.map{|e| e.fault.stripped}
    end
  end

  class AssignmentNode < Treetop::Runtime::SyntaxNode
    def variable
      var_id.stripped
    end

    def value
      basic_expr
    end
  end

  class CaseNode < Treetop::Runtime::SyntaxNode
    def each_case &block
      cases.elements.each &block
    end
  end

  class CaseElementNode < Treetop::Runtime::SyntaxNode
    def condition
      left.stripped
    end

    def value
      right.stripped
    end

    def faults
      result = []

      if has_faults?
        list = disabled_by.list
        result << list.first.stripped
        list.rest.elements.inject(result) do |acc, node|
          acc << node.fault.stripped
        end
      end

      result
    end

    def has_faults?
      not disabled_by.elements.nil?
    end

  end

  class LtlSpecNode < Treetop::Runtime::SyntaxNode
    def specification
      spec.stripped
    end
  end

  class VarDeclNode < Treetop::Runtime::SyntaxNode
    def name
      decl_var_id.stripped
    end

    def vartype
      begin
        t = type.module_type.name.stripped
      rescue NoMethodError
        t = type.stripped
      end
    end

  end
end

