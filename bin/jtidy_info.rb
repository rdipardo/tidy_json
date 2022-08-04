# frozen_string_literal: true

module TidyJson
  class JtidyInfo # :nodoc:
    NOTICE = [
      '#',
      '# jtidy is in no way affiliated with, nor based on, ',
      '# the HTML parser and pretty printer of the same name.',
      '#',
      '# More information is available here:',
      '# https://github.com/rdipardo/tidy_json#command-line-usage',
      '#'
    ].join("\n").freeze

    attr_reader :meta

    def initialize
      gem = Gem::Specification.find_by_name('tidy_json')
      @meta = {
        name: "# jtidy #{gem.version}",
        license: "# License: #{gem.license}",
        bugs: "# Bugs: #{gem.metadata['bug_tracker_uri']}",
        notice: NOTICE
      }
    end

    def to_s
      (@meta.values.join "\n").freeze
    end
  end
end
