# frozen_string_literal: true

require_relative 'lib/tidy_json/version'

Gem::Specification.new do |spec|
  spec.name        = 'tidy_json'
  spec.version     = TidyJson::VERSION
  spec.summary     = 'Serialize any Ruby object as readable JSON'
  spec.description = 'A mixin providing (recursive) JSON serialization and pretty printing.'
  spec.authors     = ['Robert Di Pardo']
  spec.email       = 'dipardo.r@gmail.com'
  spec.homepage    = 'https://github.com/rdipardo/tidy_json'
  spec.license     = 'MIT'
  spec.metadata    = {
    'documentation_uri' => 'https://rubydoc.info/github/rdipardo/tidy_json',
    'bug_tracker_uri' => 'https://github.com/rdipardo/tidy_json/issues'
  }
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    ['.yardopts'].concat(`git ls-files -z`.split("\x0").reject { |f| f.match(/^(\.[\w+.]+|test|spec|features|codecov)/) })
  end
  spec.test_files = Dir['test/*']
  spec.require_paths = ['lib']
  spec.executables = ['jtidy']
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3')
  spec.add_runtime_dependency 'json', '~> 2.6'
  spec.rdoc_options = ['-x test/*']
end
