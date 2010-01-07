module Falluto
  module NuSMV
    class Variable
      attr_reader :name, :type
      def initialize(name, type)
        raise 'name cannot be empty' if (name.nil? or name.empty?)
        raise 'type cannot be empty' if (type.nil? or type.empty?)
        @name, @type = name, type
      end
    end
  end
end

