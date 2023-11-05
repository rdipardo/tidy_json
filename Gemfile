# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :test do
  gem 'rake'
  gem 'test-unit', '~> 3.4'
  gem 'yard', '~> 0.9'
end

group :development do
  install_if -> { ENV['COVERAGE'] } do
    gem 'simplecov'
    gem 'simplecov-cobertura'
  end
end
