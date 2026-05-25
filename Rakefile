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

desc "Run specs with line coverage (uses stdlib Coverage, no extra deps)"
task :coverage do
  ruby '-W0', File.expand_path('script/coverage.rb', __dir__)
end