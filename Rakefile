require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "persist"
    gem.summary = %Q{Ruby object persistance with a CouchDB storage backend}
    gem.description = %Q{Ruby object persistance with a CouchDB storage backend}
    gem.email = "baccigalupi@gmail.com"
    gem.homepage = "http://github.com/baccigalupi/persist"
    gem.authors = ["Kane Baccigalupi"]
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
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
  rdoc.title = "Persist #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end   

STATS_DIRECTORIES = [
  %w(Persist            lib/persist),
  %w(Specs              spec)
].collect { |name, dir| [ name, "#{File.dirname(__FILE__)}/#{dir}" ] }.select { |name, dir| File.directory?(dir) }

desc "Report code statistics (KLOCs, etc) on the gem"
task :stats do
  require File.dirname(__FILE__) + '/extras/code_statistics'
  CodeStatistics.new(*STATS_DIRECTORIES).to_s
end

