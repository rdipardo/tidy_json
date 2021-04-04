# tidy_json

![Gem Version][gem_version_badge]  ![Downloads][gem_downloads]  [![Travis CI][travis_build_status_badge]][travis_build_status]  [![Circle CI][cci_build_status_badge]][cci_build_status]  [![codecov][codecov_badge]][codecov_status]

A mixin providing (recursive) JSON serialization and pretty printing.

### Installation

```bash
$ gem install tidy_json
```

Or, in your `Gemfile`:

```ruby
source 'https://rubygems.org'
# ...
gem 'tidy_json'
# ...
```

### Formatting Options

As of version [0.3.0][], most of the same options accepted by [`JSON.generate`][]
can be passed to `#write_json`, `#to_tidy_json`, or `TidyJson.tidy`.

See [the docs][] for a current list of options and their default values.

### Example

```ruby
require 'tidy_json'

class Jsonable
  attr_reader :a, :b
  def initialize
    @a = { a: 'uno', f: ['I', 'II', 'III', ['i.', 'ii.', 'iii.', { 'ichi': "\u{4e00}", 'ni': "\u{4e8c}", 'san': "\u{4e09}", 'yon': "\u{56db}" }]], c: {}, b: 'dos', e: [[]] }
    @b = { z: { iv: 4, ii: 'dos', iii: 3, i: 'uno' }, b: ['deux', 3, '<abbr title="four">IV</abbr>'], a: 1, g: [{ none: [] }], f: %w[x y z] }
  end
end

my_jsonable = Jsonable.new
# => #<Jsonable:0x000055790c93e768 @a={:a=>"uno", :f=>["I", "II", "III", ["i.", "ii.", "iii.", {:ichi=>"一", :ni=>"二", :san=>"三", :yon=>"四"}]], :c=>{}, :b=>"dos", :e=>[[]]}, @b={:z=>{:iv=>4, :ii=>"dos", :iii=>3, :i=>"uno"}, :b=>["deux", 3, "<abbr title=\"four\">IV</abbr>"], :a=>1, :g=>[{:none=>[]}], :f=>["x", "y", "z"]}>

JSON.parse my_jsonable.stringify
# => "{\"class\":\"Jsonable\",\"a\":{\"a\":\"uno\",\"f\":[\"I\",\"II\",\"III\",[\"i.\",\"ii.\",\"iii.\",{\"ichi\":\"一\",\"ni\":\"二\",\"san\":\"三\",\"yon\":\"四\"}]],\"c\":{},\"b\":\"dos\",\"e\":[[]]},\"b\":{\"z\":{\"iv\":4,\"ii\":\"dos\",\"iii\":3,\"i\":\"uno\"},\"b\":[\"deux\",3,\"<abbr title=\\\"four\\\">IV</abbr>\"],\"a\":1,\"g\":[{\"none\":[]}],\"f\":[\"x\",\"y\",\"z\"]}}"

puts my_jsonable.to_tidy_json(indent: 4, sort: true, space_before: 2, ascii_only: true)
# {
#     "a"  : {
#         "a"  : "uno",
#         "b"  : "dos",
#         "c"  : {},
#         "e"  : [
#             []
#         ],
#         "f"  : [
#             "I",
#             "II",
#             "III",
#             [
#                 "i.",
#                 "ii.",
#                 "iii.",
#                 {
#                     "ichi"  : "\u4e00",
#                     "ni"  : "\u4e8c",
#                     "san"  : "\u4e09",
#                     "yon"  : "\u56db"
#                 }
#             ]
#         ]
#     },
#     "b"  : {
#         "a"  : 1,
#         "b"  : [
#             "deux",
#             3,
#             "<abbr title=\"four\">IV</abbr>"
#         ],
#         "f"  : [
#             "x",
#             "y",
#             "z"
#         ],
#         "g"  : [
#             {
#                 "none"  : []
#             }
#         ],
#         "z"  : {
#             "i"  : "uno",
#             "ii"  : "dos",
#             "iii"  : 3,
#             "iv"  : 4
#         }
#     },
#     "class"  : "Jsonable"
# }
# => nil
```

### License
Distributed under the terms of the [MIT License][].


[travis_build_status]: https://travis-ci.com/rdipardo/tidy_json
[cci_build_status]: https://circleci.com/gh/rdipardo/tidy_json/tree/master
[cci_build_status_badge]: https://circleci.com/gh/rdipardo/tidy_json.svg?style=svg
[travis_build_status_badge]: https://travis-ci.com/rdipardo/tidy_json.svg?branch=master
[codecov_status]: https://codecov.io/gh/rdipardo/tidy_json/branch/master
[codecov_badge]: https://codecov.io/gh/rdipardo/tidy_json/branch/master/graph/badge.svg
[gem_version_badge]: https://img.shields.io/gem/v/tidy_json?color=%234ec820&label=gem%20version&logo=ruby&logoColor=%23e9573f
[gem_downloads]: https://img.shields.io/gem/dt/tidy_json?logo=ruby&logoColor=%23e9573f
[MIT License]: https://github.com/rdipardo/tidy_json/blob/master/LICENSE

<!-- API spec -->
[`JSON.generate`]: https://github.com/flori/json/blob/d49c5de49e54a5ad3f6fcf587f98d63266ef9439/lib/json/pure/generator.rb#L111
[the docs]: https://rubydoc.org/github/rdipardo/tidy_json/TidyJson/Formatter#initialize-instance_method
[0.3.0]: https://github.com/rdipardo/tidy_json/releases/tag/v0.3.0
