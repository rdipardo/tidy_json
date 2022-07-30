# frozen_string_literal: true

module TidyJson
  ##
  # A purpose-built JSON generator.
  #
  # @api private
  class Serializer
    ##
    # Searches +obj+ for readable attributes, storing them as key-value pairs in
    # +json_hash+.
    #
    # @param obj [Object] A Ruby object that can be parsed as JSON.
    # @param json_hash [{String,Symbol => #to_s}] Accumulator.
    # @return [{String => #to_s}] A hash mapping of +obj+'s visible attributes.
    # @note Hashes will be searched for nested objects to a maximum depth of 2;
    #   arrays to a maximum depth of 3.
    # @example
    #   class Obj
    #     class Child
    #       def initialize; @a = { a: 1 } end
    #        attr_reader :a
    #     end
    #     def initialize; @a = { b: Child.new } end
    #     attr_accessor :a
    #   end
    #
    #   o = Obj.new
    #   puts o.to_tidy_json
    #   <<JSON
    #   {
    #      "class": "Obj",
    #      "a": {
    #         "b": {
    #           "class": "Obj::Child",
    #            "a": {
    #              "a": 1
    #          }
    #        }
    #      }
    #   }
    #   JSON
    #
    #   # depth > 2: unreachable objects are not serialized
    #   o.a = { b: { c: { d: Obj::Child.new } } }
    #   puts o.to_tidy_json
    #   <<JSON
    #   {
    #      "class": "Obj",
    #      "a": {
    #         "b": {
    #           "c": {
    #             "d": "#<Obj::Child:0x0000559d4da865c0>"
    #          }
    #        }
    #      }
    #   }
    #   JSON
    #
    #   # object arrays can be nested up to 3 levels deep
    #   o.a = [ [ Obj::Child.new, [ Obj::Child.new, [ Obj::Child.new ] ] ] ]
    #   puts o.to_tidy_json
    #   <<JSON
    #   {
    #     "class": "Obj",
    #     "a": [
    #       {
    #         "class": "Obj::Child",
    #         "a": {
    #           "a": 1
    #         }
    #       },
    #       [
    #         [
    #           {
    #             "class": "Obj::Child",
    #             "a": {
    #               "a": 1
    #             }
    #           },
    #           [
    #             {
    #               "class": "Obj::Child",
    #               "a": {
    #                 "a": 1
    #               }
    #             }
    #           ]
    #         ]
    #       ]
    #     ]
    #   }
    #   JSON
    def self.serialize(obj, json_hash)
      obj.instance_variables.each do |m|
        key = m.to_s[/[^@]\w*/].to_sym

        next unless key && !key.eql?('')

        begin
          val = obj.send(key) # assuming readable attributes . . .
        rescue NoMethodError # . . . which may not be always be the case !
          json_hash[key] = nil
        end

        begin
          # process class members of Hash type
          if val.instance_of?(Hash)
            json_hash[key] = val

            val.each.any? do |k, v|
              json_hash[key][k.to_sym] = serialize(v, class: v.class.name) unless v.instance_variables.empty?
            end

          # process class members of Array type
          elsif val.instance_of?(Array)
            json_hash[key] = []

            val.each do |elem|
              i = val.index(elem)

              # member is a multi-dimensional collection
              if elem.respond_to?(:each)
                nested = []
                elem.each do |e|
                  j = if elem.respond_to?(:key)
                        elem.key(e)
                      else elem.index(e)
                      end

                  # nested element is a class object
                  if !e.instance_variables.empty?
                    json_hash[key][j] = { class: e.class.name }

                    # recur over the contained object
                    serialize(e, json_hash[key][j])

                  # some kind of collection?
                  elsif e.respond_to?(:each)
                    temp = []
                    e.each do |el|
                      if el.respond_to?(:each)
                        el.each_with_index do |ell, idx|
                          el[idx] = serialize(ell, class: ell.class.name) unless ell.instance_variables.empty?
                        end
                      end
                      temp << if el.instance_variables.empty? then el
                              else JSON.parse(el.stringify)
                              end
                    end

                    nested << temp

                  # scalar type
                  else nested << e
                  end
                end
                # ~iteration of nested array elements

                json_hash[key] << nested

              # member is a flat array
              elsif !elem.instance_variables.empty? # class object?
                json_hash[key] << { class: elem.class.name }
                serialize(elem, json_hash[key][i])

              # scalar type
              else json_hash[key] << elem
              end
            end
            # ~iteration of top-level array elements

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

  private_constant :Serializer
end
