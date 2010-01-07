#!/usr/bin/env ruby

require 'optparse'

require 'falluto/ruby_extensions'
require 'falluto/version'

class TraceCleaner
  def clean tracefile, auxfile, output
    load_auxdata auxfile
    do_clean tracefile, output
  end

  private

  def load_auxdata filename
    @auxvars, @specs = [], []

    IO.foreach(filename) do |line|
      if line =~ /^VAR: (.*)$/
        @auxvars << $1.chomp
      elsif line =~ /^SPEC: (.*)$/
        @specs << $1.chomp
      end
    end
  end

  def do_clean filename, output
    varsregexp = @auxvars.join('|')
    i = 0

    IO.foreach(filename) do |line|
      if line =~ /^-- specification (.*) is (true|false)/
        output.puts "Spec: #{@specs[i]} is #{$2}"
        output.puts "Counterexample:" if $2 == "false"
        i += 1
      elsif ((!varsregexp.empty?) && (line =~ /#{varsregexp}/))
        # skip it
      elsif (line =~ /-- Loop/) or (line !~ /^(\*\*\*|WARNING|--|Trace|$)/)
        output.print line
      end
    end
  end
end

def parse_cmdline_args
  options = {:file => nil, :auxfile => nil, :output => nil}
  optparser = OptionParser.new do |opts|
    opts.on('-f', '--file <trace_file>', 'Indicate the <trace_file> to be cleaned.') do |file|
      options[:file] = file
    end

    opts.on('-a', '--auxfile <aux_file>', 'Indicate the <aux_file> which contains compiler objects.') do |file|
      options[:auxfile] = file
    end

    opts.on('-o', '--output <clean_trace>', 'Indicate the output file which will have the clean trace.') do |file|
      options[:output] = file
    end

    opts.on('-v', '--version', "Print the version number of #{Falluto::NAME} and exit.") do |x|
      puts Falluto::Version::STRING
      exit 0
    end
  end
  optparser.parse!
  options
end


def main
  begin
    options = parse_cmdline_args

    tracefile = options[:file]
    auxfile = options[:auxfile]
    cleantrace = options[:output]

    puts "Reading NuSMV trace from: #{tracefile}"
    puts "Reading support objects from: #{auxfile}"
    puts "Writing clean trace to: #{cleantrace}"

    cleaner = TraceCleaner.new
    File.open(cleantrace, "w+") do |output|
      cleaner.clean tracefile, auxfile, output
    end

    puts "Done."

  rescue => e
    puts ""
    puts "ERROR: #{Falluto::NAME}: #{e} "
    exit 1
  end
end

main
