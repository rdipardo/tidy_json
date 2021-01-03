# tidy_json

![Gem Version][gem_version_badge]  ![gem_downloads]  [![Travis CI][travis_build_status_badge]][travis_build_status]  [![Circle CI][cci_build_status_badge]][cci_build_status]  [![codecov][codecov_badge]][codecov_status]

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
[cci_build_status]: https://circleci.com/gh/rdipardo/tidy_json/tree/testing
[cci_build_status_badge]: https://circleci.com/gh/rdipardo/tidy_json.svg?style=svg
[travis_build_status_badge]: https://travis-ci.com/rdipardo/tidy_json.svg?branch=testing
[codecov_status]: https://codecov.io/gh/rdipardo/tidy_json
[codecov_badge]: https://codecov.io/gh/rdipardo/tidy_json/branch/testing/graph/badge.svg
[gem_version_badge]: https://img.shields.io/gem/v/tidy_json?color=%234ec820&label=gem%20version&logo=ruby&logoColor=%23e9573f
[gem_downloads]: https://img.shields.io/gem/dt/tidy_json?logo=ruby&logoColor=%23e9573f
[MIT License]: https://github.com/rdipardo/tidy_json/blob/master/LICENSE
