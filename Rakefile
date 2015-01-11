require 'bundler/gem_tasks'

require 'rake'
require 'rake/testtask'

task :default => [:specs]

desc "Run basic specs"
Rake::TestTask.new("specs") { |t|
  t.pattern = 'spec/*_spec.rb'
  t.verbose = true
  t.warning = true
}