# frozen_string_literal: false

module TidyJson
  ##
  # A purpose-built JSON formatter.
  #
  # @api private
  class Formatter
    # @return [Hash] the JSON format options specified by this +Formatter+
    #   instance.
    attr_reader :format

    ##
    # Returns a new instance of +Formatter+.
    #
    # @param opts [Hash] Formatting options.
    # @option opts [[2,4,6,8,10,12]] :indent (2) An even number of spaces to
    #   indent each object member.
    # @option opts [[2..8]] :space_before (0) The number of spaces to put
    #   before each +:+ delimiter.
    # @option opts [[2..8]] :space (1) The number of spaces to put after
    #   each +:+ delimiter.
    # @option opts [String] :object_nl ("\n") A string to put at the end of
    #   each object member.
    # @option opts [String] :array_nl ("\n") A string to put at the end of
    #   each array member.
    # @option opts [Numeric] :max_nesting (100) The maximum level of data
    #   structure nesting in the generated JSON. Disable depth checking by
    #   passing +max_nesting: 0+.
    # @option opts [Boolean] :escape_slash (false) Whether or not a forward
    #   slash (/) should be escaped.
    # @option opts [Boolean] :ascii_only (false) Whether or not only ASCII
    #   characters should be generated.
    # @option opts [Boolean] :allow_nan (false) Whether or not +NaN+,
    #   +Infinity+ and +-Infinity+ should be generated. If +false+, an
    #   exception is thrown if these values are encountered.
    # @option opts [Boolean] :sort (false) Whether or not object members should
    #   be sorted by key.
    # @see https://github.com/flori/json/blob/d49c5de49e54a5ad3f6fcf587f98d63266ef9439/lib/json/pure/generator.rb#L111 JSON::Pure::Generator
    def initialize(opts = {})
      # The number of times to reduce the left indent of a nested array's
      # opening bracket
      @left_bracket_offset = 0

      # True if printing a nested array
      @need_offset = false

      valid_indent = (2..12).step(2).include?(opts[:indent])
      valid_space_before = (2..8).include?(opts[:space_before])
      valid_space_after = (2..8).include?(opts[:space])
      # don't test for the more explicit :integer? method because it's defined
      # for floating point numbers also
      valid_depth = opts[:max_nesting] >= 0 \
                    if opts[:max_nesting].respond_to?(:times)
      @format = {
        indent: "\s" * (valid_indent ? opts[:indent] : 2),
        space_before: "\s" * (valid_space_before ? opts[:space_before] : 0),
        space: "\s" * (valid_space_after ? opts[:space] : 1),
        object_nl: opts[:object_nl] || "\n",
        array_nl: opts[:array_nl] || "\n",
        max_nesting: valid_depth ? opts[:max_nesting] : 100,
        escape_slash: opts[:escape_slash] || false,
        ascii_only: opts[:ascii_only] || false,
        allow_nan: opts[:allow_nan] || false,
        sorted: opts[:sort] || false
      }
    end
    # ~Formatter#initialize

    ##
    # Returns the given +node+ as pretty-printed JSON.
    #
    # @param node [#to_s] A visible attribute of +obj+.
    # @param obj [{Object => #to_s}, <#to_s>] The enumerable object
    #   containing +node+.
    # @return [String] A formatted string representation of +node+.
    def format_node(node, obj)
      str = ''
      indent = @format[:indent]

      is_last = (obj.length <= 1) ||
                (obj.length > 1 &&
                  (obj.instance_of?(Array) &&
                    !(node === obj.first) &&
                      (obj.size.pred == obj.rindex(node))))

      if node.instance_of?(Array)
        str << '['
        str << "\n" unless node.empty?

        # format array elements
        node.each do |elem|
          if elem.instance_of?(Hash)
            str << "#{indent * 2}{"
            str << "\n" unless elem.empty?

            elem.each_with_index do |inner_h, h_idx|
              str << "#{indent * 3}\"#{inner_h.first}\": "
              str << node_to_str(inner_h.last, 4)
              str << ',' unless h_idx == elem.to_a.length.pred
              str << "\n"
            end

            str << (indent * 2).to_s unless elem.empty?
            str << '}'

          # element a scalar, or a nested array
          else
            is_nested_array = elem.instance_of?(Array) &&
                              elem.any? { |e| e.instance_of?(Array) }
            if is_nested_array
              @left_bracket_offset = \
                elem.take_while { |e| e.instance_of?(Array) }.size
            end

            str << (indent * 2) << node_to_str(elem)
          end

          str << ",\n" unless node.index(elem) == node.length.pred
        end

        str << "\n#{indent}" unless node.empty?
        str << ']'
        str << ",\n" unless is_last

      elsif node.instance_of?(Hash)
        str << '{'
        str << "\n" unless node.empty?

        # format elements as key-value pairs
        node.each_with_index do |h, idx|
          # format values which are hashes themselves
          if h.last.instance_of?(Hash)
            key = if h.first.eql? ''
                    "#{indent * 2}\"<##{h.last.class.name.downcase}>\": "
                  else
                    "#{indent * 2}\"#{h.first}\": "
                  end

            str << key << '{'
            str << "\n" unless h.last.empty?

            h.last.each_with_index do |inner_h, inner_h_idx|
              str << "#{indent * 3}\"#{inner_h.first}\": "
              str << node_to_str(inner_h.last, 4)
              str << ",\n" unless inner_h_idx == h.last.to_a.length.pred
            end

            str << "\n#{indent * 2}" unless h.last.empty?
            str << '}'

          # format scalar values
          else
            str << "#{indent * 2}\"#{h.first}\": " << node_to_str(h.last)
          end

          str << ",\n" unless idx == node.to_a.length.pred
        end

        str << "\n#{indent}" unless node.empty?
        str << '}'
        str << ',' unless is_last
        str << "\n"

      # scalars
      else
        str << node_to_str(node)
        str << ',' unless is_last
        str << "\n"
      end

      trim str.gsub(/(#{indent})+[\n\r]+/, '')
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

      indent = @format[:indent] * (tabs / 2)

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
    # ~Formatter#node_to_str

    ##
    # Removes any trailing comma from serialized object members.
    #
    # @param node [String] A serialized object member.
    # @return [String] A copy of +node+ without a trailing comma.
    def trim(node)
      if (extra_comma = /(?<trail>,\s*[\]\}]\s*)$/.match(node))
        node.sub(extra_comma[:trail],
                 extra_comma[:trail]
                 .slice(1, node.length.pred)
                 .sub(/^\s/, "\n"))
      else node
      end
    end
    # ~Formatter#trim
  end

  private_constant :Formatter
end
