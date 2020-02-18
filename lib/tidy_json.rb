require 'json'
require_relative 'tidy_json/version'

##
# A mixin providing (recursive) JSON serialization and pretty printing.
#
module TidyJson
  ##
  # Emits a pretty-printed JSON representation of the given +obj+.
  #
  # @param obj [Object] A Ruby object that can be parsed as JSON.
  # @param opts [Hash] Formatting options.
  #     [:indent] the number of white spaces to indent
  # @return [String] A pretty-printed JSON string.
  def self.tidy(obj = {}, opts = {})
    formatter = Formatter.new(opts)
    str = ''

    if obj.instance_of?(Hash)
      str << "{\n"

      obj.each do |k, v|
        str << formatter.indent << "\"#{k}\": "
        str << formatter.format_node(v, obj)
      end

      str << "}\n"

    elsif obj.instance_of?(Array)
      str << "[\n"

      obj.each do |v|
        str << formatter.indent
        str << formatter.format_node(v, obj)
      end

      str << "]\n"
    end

    str
  end

  ##
  # Like +TidyJson::tidy+, but callable by the sender object.
  #
  # @param opts [Hash] Formatting options.
  #     [:indent] the number of white spaces to indent
  # @return [String] A pretty-printed JSON string.
  def to_tidy_json(opts = {})
    if !instance_variables.empty?
      TidyJson.tidy(JSON.parse(stringify), opts)
    else
      TidyJson.tidy(self, opts)
    end
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
  # Writes a JSON representation of the sender object to the file specified by +out+.
  #
  # @param out [String] The destination filename.
  # @param opts [Hash] Formatting options for this object's +#to_tidy_json+ method.
  #     [:tidy] whether or not the output should be pretty-printed
  #     [:indent] the number of white spaces to indent
  # @return [String, nil] The path to the written output file, if successful.
  def write_json(out = "#{self.class.name}_#{Time.now.to_i}", opts = { tidy: false })
    path = nil

    File.open("#{out}.json", 'w') do |f|
      path = f << to_tidy_json(opts)
    end

    path.path
  rescue IOError, RuntimeError, NoMethodError => e
    warn "#{__FILE__}.#{__LINE__}: #{e.message}"
  end

  ##
  # A purpose-built JSON generator.
  #
  # @api private
  class Serializer
    ##
    # Searches +obj+ to a *maximum* depth of 2 for readable attributes,
    # storing them as key-value pairs in +json_hash+.
    #
    # @param obj [Object] A Ruby object that can be parsed as JSON.
    # @param json_hash [{String,Symbol => #to_s}] Accumulator.
    # @return [{String => #to_s}] A hash mapping of +obj+'s visible attributes.
    def self.serialize(obj, json_hash)
      obj.instance_variables.each do |m|
        key = m.to_s[/[^\@]\w*/].to_sym

        next unless key && !key.eql?('')

        begin
          val = obj.send(key) # assuming readable attributes . . .
        rescue NoMethodError # . . . which may not be always be the case !
          json_hash[key] = nil
        end

        begin
          # process class members of Hash type
          if val.instance_of?(Hash)
            nested_key = ''
            nested = nil

            val.each.any? do |k, v|
              if v.instance_variables.first
                nested_key = k
                nested = v
              end
            end

            json_hash[key] = val

            if nested
              pos = val.keys.select { |k| k === nested_key }.first.to_sym
              nested.instance_variables.each do
                json_hash[key][pos] = serialize(nested, class: nested.class.name)
              end
            end

          # process class members of Array type
          elsif val.instance_of?(Array)
            json_hash[key] = []

            val.each do |elem|
              i = val.index(elem)

              # multi-dimensional array
              if elem.instance_of?(Array)
                nested = []
                elem.each do |e|
                  j = elem.index(e)

                  # nested array element is a class object
                  if e.instance_variables.first
                    json_hash[key][j] = { class: e.class.name }

                    # recur over the contained object
                    serialize(e, json_hash[key][j])
                  else
                    # some kind of collection?
                    if e.respond_to? :each
                      temp = []
                      e.each { |el| temp << el }
                      nested << temp
                    else nested << e
                    end
                  end
                end
                # ~iteration of nested array elements

                json_hash[key] << nested

              else
                # 1-D array of class objects
                if elem.instance_variables.first
                  json_hash[key] << { class: elem.class.name }
                  serialize(elem, json_hash[key][i])
                else
                  # element of primitive type (or Array, or Hash):
                  # leverage 1:1 mapping of Hash:object
                  if elem.instance_of?(Hash) then json_hash[key] = val
                  else
                    # some kind of collection
                    if elem.respond_to? :each
                      temp = []
                      elem.each { |e| temp << e }
                      json_hash[key] << temp
                    else json_hash[key] << elem
                    end
                  end
                end
              end
            end
          # ~iteration of top-level array elements

          # process any nested class members, i.e., handle a recursive call
          # to Serializer.serialize
          elsif obj.index(val) || json_hash.key?(key)
            if val.instance_variables.first
              class_elem = { class: val.class.name }
              json_hash[key] << class_elem
              k = json_hash[key].index(class_elem)
              serialize(val, json_hash[key][k])
            else
              json_hash[key] << val
            end

          # process uncollected class members
          else
            # member a class object
            if val.instance_variables.first
              json_hash[key] = { class: val.class.name }
              serialize(val, json_hash[key])
            else
              # member a hash element
              if json_hash.key?(key) && \
                 !json_hash[key].has_val?(val) && \
                 json_hash[key].instance_of?(Hash)

                json_hash[key][key] = val
              else
                json_hash[key] = val
              end
            end
          end
        rescue NoMethodError
          # we expected an array to behave like a hash, or vice-versa
          json_hash.store(key, val) # a shallow copy is better than nothing
        end
      end
      # ~iteration of instance variables

      json_hash
    end
    # ~Serializer.serialize
  end
  # ~Serializer

  ##
  # A purpose-built JSON formatter.
  #
  # @api private
  class Formatter
    attr_reader :indent

    # @!attribute indent
    #   @return [String] the string of white space used by this +Formatter+ to indent object members.

    def initialize(format_options = {})
      ##
      # The number of times to reduce the left indent of a nested array's opening
      # bracket
      @left_bracket_offset = 0

      ##
      # True if printing a nested array
      @need_offset = false

      indent_width = format_options[:indent]

      # don't use the more explicit #integer? method because it's defined for
      # floating point numbers also
      good_width = indent_width.positive? if indent_width.respond_to? :times

      @indent = "\s" * (good_width ? indent_width : 2)
    end

    ##
    # Returns the given +node+ as pretty-printed JSON.
    #
    # @param node [#to_s] A visible attribute of +obj+.
    # @param obj [{Object => Object}, <Object>] The enumerable object containing +node+.
    # @return [String] A formatted string representation of +node+.
    def format_node(node, obj)
      str = ''
      indent = @indent

      if node.instance_of?(Array)
        str << "[\n"

        node.each do |elem|
          if elem.instance_of?(Hash)
            str << "#{(indent * 2)}{\n"

            elem.each_with_index do |inner_h, h_idx|
              str << "#{(indent * 3)}\"#{inner_h.first}\": "
              str << node_to_str(inner_h.last, 4)
              str << ', ' unless h_idx == (elem.to_a.length - 1)
              str << "\n"
            end

            str << "#{(indent * 2)}}"
            str << ',' unless node.index(elem) == (node.length - 1)
            str << "\n" unless node.index(elem) == (node.length - 1)

          else

            if elem.instance_of?(Array) && elem.any? { |e| e.instance_of?(Array) }
              @left_bracket_offset = elem.take_while { |e| e.instance_of?(Array) }.size
            end

            str << (indent * 2)
            str << node_to_str(elem)
            str << ",\n" unless node.index(elem) == (node.length - 1)
          end
        end

        str << "\n#{indent}]\n"

      elsif node.instance_of?(Hash)
        str << "{\n"

        node.each_with_index do |h, idx|
          if h.last.instance_of?(Hash)
            key = if h.first.eql? ''
                    "#{indent * 2}\"<##{h.last.class.name.downcase}>\": "
                  else
                    "#{indent * 2}\"#{h.first}\": "
                  end
            str << key
            str << "{\n"

            h.last.each_with_index do |inner_h, inner_h_idx|
              str << "#{indent * 3}\"#{inner_h.first}\": "
              str << node_to_str(inner_h.last, 4)
              str << ",\n" unless inner_h_idx == (h.last.to_a.length - 1)
            end

            str << "\n#{indent * 2}}"
          else
            str << "#{indent * 2}\"#{h.first}\": "
            str << node_to_str(h.last)
          end

          str << ",\n" unless idx == (node.to_a.length - 1)
        end

        str << "\n#{indent}}"
        str << ', ' unless (obj.length <= 1) || \
                           ((obj.length > 1) && \
                           (obj.instance_of?(Hash) && \
                             (obj.key(obj.values.last) === obj.key(node))) || \
                           (obj.instance_of?(Array) && (obj.last == node)))
        str << "\n"

      else
        str << node_to_str(node)
        str << ', ' unless (obj.length <= 1) || \
                           ((obj.length > 1) && \
                           (obj.instance_of?(Hash) && \
                             (obj.key(obj.values.last) === obj.key(node))) || \
                           (obj.instance_of?(Array) && (obj.last === node)))
        str << "\n"
      end

      str.gsub(/(#{indent})+[\n\r]+/, '').gsub(/\}\,+/, '},').gsub(/\]\,+/, '],')
    end
    # ~Formatter#format_node

    ##
    # Returns a JSON-appropriate string representation of +node+.
    #
    # @param node [#to_s] A visible attribute of a Ruby object.
    # @param tabs [Integer] Tab width at which to start printing this node.
    # @return [String] A formatted string representation of +node+.
    def node_to_str(node, tabs = 0)
      graft = ''
      tabs += 2 if tabs.zero?

      if @need_offset
        tabs -= 1
        @left_bracket_offset -= 1
      end

      indent = @indent * (tabs / 2)

      if node.nil? then graft << 'null'

      elsif node.instance_of?(Hash)
        format_node(node, node).scan(/.*$/) do |n|
          graft << "\n" << indent << n
        end

      elsif node.instance_of?(Array)
        @need_offset = @left_bracket_offset.positive?

        format_node(node, {}).scan(/.*$/) do |n|
          graft << "\n" << indent << n
        end

      elsif !node.instance_of?(String) then graft << node.to_s

      else graft << "\"#{node.gsub(/\"/, '\\"')}\""
      end

      graft.strip
    end
    # ~Formatter.node_to_str
  end
  # ~Formatter

  private_constant :Serializer
  private_constant :Formatter
end
# ~TidyJson

##
# Includes +TidyJson+ in every Ruby class.
# ====
#  class Object
#    include TidyJson
#  end
class Object
  include TidyJson
end
