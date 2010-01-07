module Falluto
  module NuSMV
    class AuxiliarVariable
      attr_reader :name, :condition
      def initialize name, condition
        @name, @condition = name, condition
      end
    end

    class Fault
      GUARD_VARIABLE_FORMAT = '%s_g%d'

      attr_reader :name, :process_name
      attr_reader :precondition, :restore
      attr_reader :precondition_variable, :restore_variable, :active_variable,
                  :fairness_variable

      def initialize modul, name, precondition, restore, effect
        @name = name
        @process_name = "#{modul}_#{name}"
        @precondition = precondition
        @restore = restore
        @system_effect = effect

        @fairness_variable = "#{@name}_vfair"
        @precondition_variable = "#{@name}_pre"
        @restore_variable = "#{@name}_restore"
        @active_variable = "active"

        @auxiliar_variables = []

      end

      def add_auxiliar_variable guard
        vname = next_auxiliar_variable
        @auxiliar_variables << AuxiliarVariable.new(vname, guard)
      end

      def next_auxiliar_variable
        i = @auxiliar_variables.length + 1
        GUARD_VARIABLE_FORMAT % [@name, i]
      end

      def strong_fairness inst
        "((G F (#{fairness_condition(inst)})) -> (G F (#{inst}.#{fairness_variable})))"
      end

      ##### Variables affected by system effect
      def each_affected_variable &block
        @system_effect.variables.each{ |v| yield v }
      end

      def each_affected_variable_with_effect &block
        @system_effect.each_pair{ |v, effect| yield v, effect }
      end
      
      def instance_signature
        parameters = "#{precondition_variable}, #{restore_variable}"
        each_affected_variable{|v| parameters << ", #{v}"}
        %Q|#{process_name}(#{parameters})|
      end

      def each_auxiliar_variable &block
        @auxiliar_variables.each {|v| yield v}
      end

      def fairness_condition inst = nil
        if inst.nil?
          not_effect = "! #{@name}.#{active_variable}"
    #      not_effect = "! #{active_variable}"
        else
          not_effect = "! #{inst}.#{@name}.#{active_variable}"
        end

        if @auxiliar_variables.empty?
          not_effect
        else
          vars = @auxiliar_variables.collect do |v|
            (inst.nil? ? '' : "#{inst}.") + v.name
          end
          '( ' + vars.join(' | ') + " ) & #{not_effect}"
        end
      end
    end
  end
end

