require 'rubygems'
require 'rake'
require 'yard'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "Aqua"
    gem.summary = %Q{Aqua: A Ruby Object Database ... just add water (and CouchDB)}
    gem.description = %Q{Even with ORMs like ActiveRecord, DataMapper which ease the pain of relational data storage, considerable developer effort goes into wrangling Ruby objects into their databases. Document-oriented databases have made it possible to store nested data structures that easily map to Ruby objects. Aqua (http://github.com/baccigalupi/aqua) is a new Ruby library that aims to painlessly persists objects, allowing developers to focus more on object oriented code and less on storage. Currently Aqua is in pre-alpha testing, with the following big things left to implement: A data query DSL and implementation; Support of all objects in the Standard Library; Class and code storage to allow the sharing and persistence of classes with their data. }
    gem.email = "baccigalupi@gmail.com"
    gem.homepage = "http://github.com/baccigalupi/aqua"
    gem.authors = ["Kane Baccigalupi"]
  end

rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end


task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Aqua #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

 
# Statistics ====================================
AQUA_DIRECTORIES = [
  %w(Aqua::Store         lib/aqua/store), 
  %w(Aqua::Object        lib/aqua/object),
  %w(Aqua/Support        lib/aqua/support),
  %w(Aqua::Store/Specs   spec/store),
  %w(Aqua::Object/Specs  spec/object)
].collect { |name, dir| [ name, "#{File.dirname(__FILE__)}/#{dir}" ] }.select { |name, dir| File.directory?(dir) }

COUCHREST_DIRECTORIES = [
  %w(CouchRest          utils/couchrest/lib),
  %w(Specs              utils/couchrest/spec/couchrest)
].collect { |name, dir| [ name, "#{File.dirname(__FILE__)}/#{dir}" ] }.select { |name, dir| File.directory?(dir) }

desc "Report code statistics (KLOCs, etc) on the gem"
task :stats do
  require File.dirname(__FILE__) + '/utils/code_statistics'
  CodeStatistics.new(*AQUA_DIRECTORIES).to_s
  CodeStatistics.new(*COUCHREST_DIRECTORIES).to_s if File.exists?( File.dirname(__FILE__) + '/utils/couchrest/lib')
end

# YARDing up some documentation
# YARD::Tags::Library.define_tag("API", :api) 
# YARD::Tags::Library.defind_tag("Inteface Specifications", :interface_level)
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/aqua/**/*.rb']
end

