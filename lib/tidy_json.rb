# frozen_string_literal: false

require 'json'
require_relative 'tidy_json/serializer'
require_relative 'tidy_json/formatter'
require_relative 'tidy_json/version'

##
# A mixin providing (recursive) JSON serialization and pretty printing.
#
module TidyJson
  ##
  # Emits a pretty-printed JSON representation of the given +obj+.
  #
  # @param obj [Object] A Ruby object that can be parsed as JSON.
  # @param opts [Hash] Output format options.
  # @option (see Formatter#initialize)
  # @return [String] A pretty-printed JSON string.
  def self.tidy(obj = {}, opts = {})
    formatter = Formatter.new(opts)
    json = ''

    begin
      if obj.instance_variables.empty?
        obj = sort_keys(obj) if formatter.format[:sorted]
        json = JSON.generate(obj, formatter.format)
      else
        str = "{\n"
        obj = JSON.parse(obj.stringify)
        obj = sort_keys(obj) if formatter.format[:sorted]

        obj.each do |k, v|
          str << formatter.format[:indent] << "\"#{k}\": "
          str << formatter.format_node(v, obj)
        end

        str << "}\n"
        json = JSON.generate(JSON.parse(formatter.trim(str)), formatter.format)
      end

      json.gsub(/[\n\r]{2,}/, "\n")
          .gsub(/\[\s+\]/, '[]')
          .gsub(/{\s+}/, '{}') << "\n"
    rescue JSON::JSONError => e
      warn "#{__FILE__}.#{__LINE__}: #{e.message}"
    end
  end

  ##
  # Returns the given +obj+ with keys in ascending order to a maximum depth of
  # 2.
  #
  # @param obj [Hash, Array<Hash>] A dictionary-like object or collection
  #   thereof.
  # @return [Hash, Array<Hash>, Object] A copy of the given +obj+ with top- and
  #   second-level keys in ascending order, or else an identical copy of +obj+.
  # @note +obj+ is returned unchanged if: 1) it's not iterable; 2) it's an
  #   empty collection; 3) any one of its elements is not hashable (and +obj+
  #   is an array).
  def self.sort_keys(obj = {})
    return obj if !obj.respond_to?(:each) || obj.empty? ||
                  (obj.instance_of?(Array) &&
                   !obj.all? { |e| e.respond_to? :keys })

    sorted = {}
    sorter = lambda { |data, ret_val|
      data.keys.sort.each do |k|
        ret_val[k.to_sym] = if data[k].instance_of? Hash
                              sorter.call(data[k], {})
                            else
                              data[k]
                            end
      end

      return ret_val
    }

    if obj.instance_of? Array
      temp = {}
      sorted = []

      (obj.sort_by { |h| h.keys.first }).each_with_index do |h, idx|
        temp[idx] = sorter.call(h, {})
      end

      temp.each_key { |k| sorted << temp[k] }
    else
      sorted = sorter.call(obj, {})
    end

    sorted
  end

  ##
  # Like +TidyJson::tidy+, but callable by the sender object.
  #
  # @param opts [Hash] Output format options.
  # @option (see Formatter#initialize)
  # @return [String] A pretty-printed JSON string.
  def to_tidy_json(opts = {})
    TidyJson.tidy(self, opts)
  end

  ##
  # Emits a JSON representation of the sender object's visible attributes.
  #
  # @return [String] A raw JSON string.
  def stringify
    json_hash = {}

    begin
      json_hash = Serializer.serialize(self, class: self.class.name)
    rescue JSON::JSONError => e
      warn "#{__FILE__}.#{__LINE__}: #{e.message}"
    end

    json_hash.to_json
  end

  ##
  # Writes a JSON representation of the sender object to the file specified by
  # +out+.
  #
  # @param out [String] The destination filename.
  # @param opts [Hash] Output format options.
  # @option (see Formatter#initialize)
  # @option opts [Boolean] :tidy (false) Whether or not the output should be
  #   pretty-printed.
  # @return [String, nil] The path to the written output file, if successful.
  def write_json(out = "#{self.class.name}_#{Time.now.to_i}",
                 opts = { tidy: false })
    path = nil

    File.open("#{out}.json", 'w') do |f|
      path =
        f << if opts[:tidy] then to_tidy_json(opts)
             elsif instance_variables.empty? then to_json
             else stringify
             end
    end

    path&.path
  rescue Errno::ENOENT, Errno::EACCES, IOError, RuntimeError, NoMethodError => e
    warn "#{__FILE__}.#{__LINE__}: #{e.message}"
  end
end

##
# Includes +TidyJson+ in every Ruby class.
# ====
#  class Object
#    include TidyJson
#  end
class Object
  include TidyJson
end
