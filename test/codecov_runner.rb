# frozen_string_literal: true

if ENV['COVERAGE']
  begin
    require 'simplecov'
    SimpleCov.start
    SimpleCov.command_name 'Unit Tests'

    if ENV['CI']
      require 'simplecov-cobertura'
      SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
    end
  rescue LoadError
    warn "Can't locate coverage drivers! Try running: `bundle install` first."
  end
end
