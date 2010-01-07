require 'rubygems'
require 'rake'

require 'lib/falluto/version'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "falluto"
    gem.version = Falluto::Version::STRING
    gem.summary = %Q{A model checker for verifying fault tolerant systems}
    gem.description = %Q{A model checker for verifying fault tolerant systems}
    gem.email = "ehames@gmail.com"
    gem.homepage = "http://github.com/ehames/falluto"
    gem.authors = ["Edgardo Hames"]
    gem.files = ["{lib,bin}/**/*"].map{|p| Dir[p]}.flatten


    # Development dependencies
    gem.add_development_dependency "bacon", ">= 1.1.0"

    # Runtime dependencies
    gem.add_dependency "treetop", ">= 1.2.3"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:spec) do |test|
  test.libs << 'spec'
  test.pattern = 'spec/**/*_spec.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'spec'
    test.pattern = 'spec/**/*_spec.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "falluto #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
