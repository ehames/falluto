class SymbolTable
  include Enumerable

  def initialize attribute = :name
    @table = Hash.new
    @attribute = attribute
  end

  def has? object
    key = object.send(@attribute)
    @table.include? key
  end

  def insert(object)
    key = object.send(@attribute)
    @table[key] = object
  end
  alias << insert

  def get key
    @table[key]
  end
  alias [] get

  def empty?
    @table.empty?
  end

  def each &block
    @table.values.each &block
  end
end


