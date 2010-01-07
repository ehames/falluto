require 'falluto/symboltable'

module Falluto
  module NuSMV
    class Module
      attr_reader :name

      def initialize name
        @name = name
        @faults = SymbolTable.new
        @variables = SymbolTable.new
      end

      def add_fault fault
        @faults.insert fault
      end

      def get_faults *fault_names
        fault_names.collect{ |fname| @faults.get fname }
#    @faults.get f
      end

      def is_defined? fault
        @faults.has? fault
      end

      def has_faults?
        not @faults.empty?
      end

      def each_fault &block
        @faults.each &block
      end

      def add_variable var
        @variables.insert var
      end

      def each_variable &block
        @variables.each &block
      end

    end
  end
end
