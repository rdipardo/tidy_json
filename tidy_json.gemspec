require_relative 'lib/tidy_json/version'
require_relative 'lib/tidy_json/dedication'

Gem::Specification.new do |spec|
  spec.name        = 'tidy_json'
  spec.version     = TidyJson::VERSION
  spec.date        = Time.now.to_s[0..9]
  spec.summary     = 'Serialize any Ruby object as readable JSON'
  spec.description = 'A mixin providing (recursive) JSON serialization and pretty printing.'
  spec.authors     = ['Robert Di Pardo']
  spec.email       = 'rdipardo0520@conestogac.on.ca'
  spec.homepage    = 'https://github.com/rdipardo/tidy_json'
  spec.metadata    = { 'documentation_uri' => 'https://rubydoc.org/github/rdipardo/tidy_json' }
  spec.license     = 'MIT'
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    ['.yardopts'].concat(`git ls-files -z`.split("\x0").reject { |f| f.match(/^(\.[\w+\.]+|test|spec|features)/) })
  end
  spec.test_files = Dir['test/*']
  spec.require_paths = ['lib']
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3')
  spec.add_runtime_dependency 'json', '~> 2.2'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.rdoc_options = ['-x test/*']
  spec.post_install_message = TidyJson::DEDICATION
end
