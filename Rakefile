require 'bundler/gem_tasks'
require 'rake/testtask'
require 'yard'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/test_*.rb']
end

YARD::Rake::YardocTask.new

desc 'Run tests'
task default: :test
