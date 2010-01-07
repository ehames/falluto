#!/usr/bin/ruby
#
# FT-NuSMV compiler front end

require 'optparse' # to build a nicer CLI

require 'falluto/compiler'
require 'falluto/version'

def parse_cmdline_args
  options = {:method => :compile, :rule => 'program', :file => nil, :output => nil, :auxfile => nil }
  op = OptionParser.new do |opts|
    opts.on('-f', '--file FILE', 'Specify input file') do |f|
      options[:file] = f
    end

    opts.on('-o', '--output FILE', 'Specify output file (compiled model)') do |f|
      options[:output] = f
    end

    opts.on('-a', '--auxfile FILE', 'Specify auxiliar file (auxiliar variables, etc)') do |f|
      options[:auxfile] = f
    end

    opts.on('-v', '--version', "Print the version number of #{Falluto::NAME} and exit.") do |x|
      puts Falluto::Version::STRING
      exit 0
    end
  end
  op.parse!
  options
end

def save_auxiliar_data compiler, filename
  File.open(filename, "w+") do |f|
    compiler.auxiliar_variables.each do |v|
      f.puts "VAR: #{v}"
    end
    compiler.specs.each do |s|
      f.puts "SPEC: #{s}"
    end
  end
end

def save_compiled_code compiler, filename
  File.open(filename, "w+") do |f|
    f.puts compiler.compiled_string
  end
end

def main
  begin
    options = parse_cmdline_args

    infile = options[:file]
    outfile = options[:output]
    auxfile = options[:auxfile]


    puts "Reading input model from: #{infile}"
    puts "Writing compiled model to: #{outfile}"
    puts "Writing support objects to: #{auxfile}"

    string = File.read infile
    compiler = Compiler.new
    compiler.run string

    # save compiled string into output file
    save_compiled_code compiler, outfile

    # save auxiliar data into separate file
    save_auxiliar_data compiler, auxfile

    puts "Done."

  rescue UndeclaredFault => e
    puts ""
    puts "ERROR: Fault #{e} undeclared in module "
    exit 1
  rescue RedefinedFault => e
    puts ""
    puts "ERROR: Fault #{e} already declared in module "
    exit 1
  rescue OptionParser::InvalidOption => e
    puts ""
    puts "ERROR: #{e}"
    exit 1
  rescue => e
    puts ""
    puts "ERROR: #{Falluto::NAME}: #{e}"
    exit 1
  end
end

main

