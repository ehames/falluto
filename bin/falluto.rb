#!/usr/bin/ruby

require 'optparse'

require 'falluto/ruby_extensions'
require 'falluto/version'

def parse_cmdline_args
  options = {:file => nil}
  optparser = OptionParser.new do |opts|
    opts.on('-f', '--file <input_file>', 'Verify the model and specs given in <input_file>.') do |file|
      options[:file] = file
    end

    opts.on('-n', '--nusmv <options>', 'Additional options for NuSMV (between quotes).') do |nusmvopts|
      options[:nusmvopts] = nusmvopts
    end

    opts.on('-g', '--graph', 'Generate graph of the counterexample automata.') do |x|
      options[:graph] = true
    end

    opts.on('-v', '--version', "Print the version number of #{Falluto::NAME} and exit.") do |x|
      puts Falluto::Version::STRING
      exit 0
    end
  end
  optparser.parse!
  options
end

def execute_command cmd
  puts cmd
  out = %x{#{cmd}}
  puts out if out !~ /^$/
end

def compile inputfile, modelfile, auxfile
  puts "# Compiling..."
  cmd = "ftnusmv.rb -f #{inputfile} -o #{modelfile} -a #{auxfile}"
  execute_command cmd
end

def check_model modelfile, tracefile, opts = nil
  puts "# Model checking..."
  cmd = "NuSMV #{opts} #{modelfile} > #{tracefile}"
  execute_command cmd
end

def clean_trace tracefile, auxfile, cleantracefile
  puts "# Cleaning trace..."
  cmd = "cleantrace.rb -f #{tracefile} -a #{auxfile} -o #{cleantracefile}"
  execute_command cmd
end

def generate_automata tracefile, dotfile, pdffile
  puts "# Graphing automata..."
  cmd = "viewtrace.rb -f #{tracefile} -d #{dotfile}  -o #{pdffile}"
  execute_command cmd
end

def main
  begin
    options = parse_cmdline_args

    inputfile = File.expand_path options[:file]
    modelfile = File.replace_extension inputfile, 'out'
    auxfile = File.replace_extension inputfile, 'aux'
    tracefile = File.replace_extension inputfile, 'trace'
    cleantracefile = File.replace_extension inputfile, "clean"
    dotfile = File.replace_extension inputfile, "dot"
    pdffile = File.replace_extension inputfile, "pdf"

    puts Falluto::Version::STRING
    puts ""

    compile inputfile, modelfile, auxfile
    check_model modelfile, tracefile, options[:nusmvopts]
    clean_trace tracefile, auxfile, cleantracefile

    if options[:graph]
      generate_automata cleantracefile, dotfile, pdffile 
    end

  rescue OptionParser::InvalidOption => e
    puts "Falluto: " + e
    exit 1
  end
end

main


