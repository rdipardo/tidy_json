# frozen_string_literal: false

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
  # @param opts [Hash] Output format options.
  # @option (see Formatter#initialize)
  # @return [String] A pretty-printed JSON string.
  def self.tidy(obj = {}, opts = {})
    formatter = Formatter.new(opts)
    obj = sort_keys(obj) if formatter.sorted
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

    if (extra_comma = /(?<trail>,\s*[\]\}])$/.match(str))
      str = str.sub(extra_comma[:trail],
                    extra_comma[:trail].slice(1, str.length.pred))
    end

    str
  end

  ##
  # Returns the given +obj+ with keys is ascending order, to a *maximum* depth
  # of 2.
  #
  # @param obj [Hash, Array<Hash>] A dictionary-like object or collection
  #   thereof.
  # @return [Hash, Array<Hash>] A copy of the given +obj+ with keys in
  #   ascending order, or else an exact copy.
  # @note When the +#keys+ method is not defined on +obj+ or (given a
  #   collection) every element in +obj+, it's returned unchanged.
  def self.sort_keys(obj = {})
    return obj if obj.nil? || obj.empty? ||
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

      temp.keys.each { |k| sorted << temp[k] }
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
        f << if !instance_variables.empty?
               if opts[:tidy] then to_tidy_json(opts)
               else stringify
               end
             else
               if opts[:tidy] then to_tidy_json(opts)
               else to_json
               end
             end
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
    # Searches +obj+ to a *maximum* depth of 2 for readable attributes, storing
    # them as key-value pairs in +json_hash+.
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
              unless v.instance_variables.empty?
                nested_key = k
                nested = v
              end
            end

            json_hash[key] = val

            if nested
              pos = val.keys.select { |k| k === nested_key }.first.to_sym
              nested.instance_variables.each do
                json_hash[key][pos] = serialize(nested,
                                                class: nested.class.name)
              end
            end

          # process class members of Array type
          elsif val.instance_of?(Array)
            json_hash[key] = []

            val.each do |elem|
              i = val.index(elem)

              # member is a multi-dimensional array
              if elem.instance_of?(Array)
                nested = []
                elem.each do |e|
                  j = elem.index(e)

                  # nested array element is a class object
                  if !e.instance_variables.empty?
                    json_hash[key][j] = { class: e.class.name }

                    # recur over the contained object
                    serialize(e, json_hash[key][j])

                  # some kind of collection?
                  elsif e.respond_to?(:each)
                    temp = []
                    e.each { |el| temp << el }
                    nested << temp

                  # primitive type
                  else nested << e
                  end
                end
                # ~iteration of nested array elements

                json_hash[key] << nested

              # member is a flat array
              else
                # class object?
                if !elem.instance_variables.empty?
                  json_hash[key] << { class: elem.class.name }
                  serialize(elem, json_hash[key][i])

                # leverage 1:1 mapping of Hash:object
                elsif elem.instance_of?(Hash)
                  json_hash[key] = val

                # some kind of collection
                elsif elem.respond_to?(:each)
                  temp = []
                  elem.each { |e| temp << e }
                  json_hash[key] << temp

                # primitive type
                else json_hash[key] << elem
                end
              end
            end
          # ~iteration of top-level array elements

          # process any nested class members, i.e., handle a recursive call
          # to Serializer.serialize
          elsif obj.index(val) || json_hash.key?(key)
            if !val.instance_variables.empty?
              class_elem = { class: val.class.name }
              json_hash[key] << class_elem
              k = json_hash[key].index(class_elem)
              serialize(val, json_hash[key][k])
            else
              json_hash[key] << val
            end

          # process uncollected class members
          else
            # member is a class object
            if !val.instance_variables.empty?
              json_hash[key] = { class: val.class.name }
              serialize(val, json_hash[key])

            # member belongs to a contained object
            elsif json_hash.key?(key) &&
                  !json_hash[key].has_val?(val) &&
                  json_hash[key].instance_of?(Hash)

              json_hash[key][key] = val

            # primitive member
            else json_hash[key] = val
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
    attr_reader :indent, :sorted
    # @!attribute indent
    # @return [String] the string of white space used by this +Formatter+ to
    #   indent object members.

    # @!attribute sorted
    # @return [Boolean] whether or not this +Formatter+ sorts object members by
    #   key name.

    ##
    # @param opts [Hash] Formatting options.
    # @option opts [[2,4,6,8,10,12]] :indent (2) An even number of white spaces
    #   to indent each object member.
    # @option opts [Boolean] :sort (false) Whether or not object members should
    #   be sorted by key.
    def initialize(opts = {})
      # The number of times to reduce the left indent of a nested array's
      # opening bracket
      @left_bracket_offset = 0

      # True if printing a nested array
      @need_offset = false

      # don't test for the more explicit :integer? method because it's defined
      # for floating point numbers also
      valid_width = opts[:indent].positive? \
                    if opts[:indent].respond_to?(:times) &&
                       (2..12).step(2).include?(opts[:indent])
      @indent = "\s" * (valid_width ? opts[:indent] : 2)
      @sorted = opts[:sort] || false
    end

    ##
    # Returns the given +node+ as pretty-printed JSON.
    #
    # @param node [#to_s] A visible attribute of +obj+.
    # @param obj [{Object => #to_s}, <#to_s>] The enumerable object
    #   containing +node+.
    # @return [String] A formatted string representation of +node+.
    def format_node(node, obj)
      str = ''
      indent = @indent

      # BUG: arrays of identical elements will have a trailing comma since
      # every element is the same as the last; a temporary hack in
      # TidyJson::tidy attempts to correct for this
      is_last = (obj.length <= 1) ||
                ((obj.length > 1) &&
                 (obj.instance_of?(Hash) &&
                  (obj.key(obj.values.last) === obj.key(node))) ||
                (obj.instance_of?(Array) && (obj.last === node)))

      if node.instance_of?(Array)
        str << "[\n"

        # format array elements
        node.each do |elem|
          if elem.instance_of?(Hash)
            str << "#{(indent * 2)}{\n"

            elem.each_with_index do |inner_h, h_idx|
              str << "#{(indent * 3)}\"#{inner_h.first}\": "
              str << node_to_str(inner_h.last, 4)
              # separate all but last element with a comma
              str << ', ' unless h_idx == elem.to_a.length.pred
              str << "\n"
            end

            str << "#{(indent * 2)}}"
            str << ',' unless node.index(elem) == node.length.pred
            str << "\n" unless node.index(elem) == node.length.pred

          # element a primitive, or a nested array
          else
            is_nested_array = elem.instance_of?(Array) &&
                              elem.any? { |e| e.instance_of?(Array) }
            if is_nested_array
              @left_bracket_offset = \
                elem.take_while { |e| e.instance_of?(Array) }.size
            end

            str << (indent * 2) << node_to_str(elem)
            str << ",\n" unless node.index(elem) == node.length.pred
          end
        end

        str << "\n#{indent}]\n"

      elsif node.instance_of?(Hash)
        str << "{\n"

        # format elements as key-value pairs
        node.each_with_index do |h, idx|
          # format values which are hashes themselves
          if h.last.instance_of?(Hash)
            key = if h.first.eql? ''
                    "#{indent * 2}\"<##{h.last.class.name.downcase}>\": "
                  else
                    "#{indent * 2}\"#{h.first}\": "
                  end
            str << key << "{\n"

            h.last.each_with_index do |inner_h, inner_h_idx|
              str << "#{indent * 3}\"#{inner_h.first}\": "
              str << node_to_str(inner_h.last, 4)
              # separate all but last pair with a comma
              str << ",\n" unless inner_h_idx == h.last.to_a.length.pred
            end

            str << "\n#{indent * 2}}"

          # format plain values
          else
            str << "#{indent * 2}\"#{h.first}\": " << node_to_str(h.last)
          end

          str << ",\n" unless idx == node.to_a.length.pred
        end

        str << "\n#{indent}}"
        str << ', ' unless is_last
        str << "\n"

      # format primitive types
      else
        str << node_to_str(node)
        str << ', ' unless is_last
        str << "\n"
      end

      str.gsub(/(#{indent})+[\n\r]+/, '')
         .gsub(/\}\,+/, '},')
         .gsub(/\]\,+/, '],')
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
