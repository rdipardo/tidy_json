# frozen_string_literal: true

if ENV['COVERAGE']
  begin
    require 'simplecov'
    SimpleCov.start
    SimpleCov.command_name 'Unit Tests'

    if ENV['CI']
      require 'codecov'
      formatter = SimpleCov::Formatter::Codecov.new
      formatter.format(SimpleCov::ResultMerger.merged_result)
    end
  rescue LoadError
    warn 'Can''t locate coverage drivers! Try running: `gem install` first.'
  end
end
