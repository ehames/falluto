#!/usr/bin/env ruby

require 'optparse'

require 'falluto/ruby_extensions'
require 'falluto/version'

class Edge
  def initialize source, dest
    @source = source
    @dest = dest
    @label = ''
  end
  def << str
    @label << str.chomp.strip + '\\n'
  end
  def to_dot
    "#{@source.quote} -> #{@dest.quote} [label=#{@label.quote}];"
  end
end

class LoopEdge < Edge
  def to_dot
    "#{@source.quote} -> #{@dest.quote} [style=dotted,bold label=#{'LOOP'.quote}];"
  end
end

class Node
  attr_reader :name, :has_loop
  def initialize name, has_loop
    @name = name
    @label = 'State: ' + name + '\\n'
    @has_loop = has_loop
  end
  def << str
    @label << str.chomp.strip + '\\n'
  end
  def to_dot
    "#{@name.quote} [label=#{@label.quote}];"
  end
end

class TraceParser
  def initialize file
    @nodes = []
    @edges = []
    parse file
  end

  def to_dot
    "digraph G {\n" +
    @nodes.collect{|n| n.to_dot + "\n" }.join +
    @edges.collect{|e| e.to_dot + "\n" }.join +
    "}\n"
  end

  private
  def parse file
    @elems = []
    node = nil
    edge = nil
    has_loop = false
    IO.foreach(file) do |line|
      case line
      when /\*\*\*/
        # do nothing
      when /^Trace Description: (.*)/
        # do nothing
      when /^Trace Type: (.*)/
        # do nothing
      when /-- Loop/
        has_loop = true
      when /-> State: (\S+)/
        node = Node.new $1, has_loop
        has_loop = false
        @nodes << node
        edge = nil
      when /-> Input: (\S+) /
        edge = Edge.new node.name, $1
        @edges << edge
        node = nil
      else
        node <<(line) if node
        edge <<(line) if edge
      end
    end
    build_loops
    nil
  end

  def build_loops
    source = @nodes.last
    loop_nodes = @nodes.select {|n| n.has_loop}
    loop_nodes.each { |dest| @edges << LoopEdge.new(source.name, dest.name) }
  end
end


def parse_cmdline_args
  options = {:file => nil}
  op = OptionParser.new do |opts|
    opts.on('-f', '--file <trace_file>', 'Generate the automata for the trace in <trace_file>.') do |file|
      options[:file] = file
    end

    opts.on('-d', '--dotfile <dot_file>', 'Save the output dot file to <dot_file>.') do |file|
      options[:dotfile] = file
    end

    opts.on('-o', '--output <pdf_file>', 'Save the output PDF to file <pdf_file>.') do |output|
      options[:pdffile] = output
    end

    opts.on('-v', '--version', "Print the version number of #{Falluto::NAME} and exit.") do |x|
      puts Falluto::Version::STRING
      exit 0
    end
  end
  op.parse!
  options
end


def dump_dot tracefile, dotfile
    tp = TraceParser.new tracefile

    File.open(dotfile, "w+") do |f|
      f.puts tp.to_dot
    end
end

def generate_pdf dotfile, pdffile
  %x{dot -Tpdf #{dotfile} -o #{pdffile}}
end


def main
  begin
    options = parse_cmdline_args

    tracefile = options[:file]
    dotfile = options[:dotfile]
    pdffile = options[:pdffile]

    puts "Reading clean trace from: #{tracefile}"
    puts "Writing dot file to: #{dotfile}"
    puts "Writing automata to: #{pdffile}"

    dump_dot tracefile, dotfile
    generate_pdf dotfile, pdffile

    puts "Done."

  rescue => e
    puts ""
    puts "ERROR: #{Falluto::NAME}: #{e} "
    puts e.backtrace.join("\n")
    exit 1
  end
end

main
