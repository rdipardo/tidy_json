# tidy_json

[![Build Status][travis_build_status_badge]][travis_build_status]  [![cci_build_status_badge]][cci_build_status]  [![Gem Version][gem_version_badge]][gem_version]

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
    @a = { a: 'uno', f: ['I', 'II', 'III', ['i.', 'ii.', 'iii.', { 'ichi': "\u{4e00}", 'ni': "\u{4e8c}", 'san': "\u{4e09}", 'yon': "\u{56db}" }]], b: 'dos' }
    @b = { z: { iv: 4, ii: 'duos', iii: 3, i: 'one' }, b: ['two', 3, '<abbr title="four">IV</abbr>'], a: 1, f: %w[x y z] }
  end
end

my_jsonable = Jsonable.new

JSON.parse my_jsonable.stringify
# => {"class"=>"Jsonable", "a"=>{"a"=>"uno", "f"=>["I", "II", "III", ["i.", "ii.", "iii.", {"ichi"=>"一", "ni"=>"二", "san"=>"三", "yon"=>"四"}]], "b"=>"dos"}, "b"=>{"z"=>{"iv"=>4, "ii"=>"duos", "iii"=>3, "i"=>"one"}, "b"=>["two", 3, "<abbr title=\"four\">IV</abbr>"], "a"=>1, "f"=>["x", "y", "z"]}}

puts my_jsonable.to_tidy_json(indent: 4, sort: true)
# {
#     "a": {
#         "a": "uno",
#         "b": "dos",
#         "f": [
#             "I",
#             "II",
#             "III",
#             [
#                 "i.",
#                 "ii.",
#                 "iii.",
#                 {
#                     "ichi": "一",
#                     "ni": "二",
#                     "san": "三",
#                     "yon": "四"
#                 }
#             ]
#         ]
#     },
#     "b": {
#         "a": 1,
#         "b": [
#             "two",
#             3,
#             "<abbr title=\"four\">IV</abbr>"
#         ],
#         "f": [
#             "x",
#             "y",
#             "z"
#         ],
#         "z": {
#             "i": "one",
#             "ii": "duos",
#             "iii": 3,
#             "iv": 4
#         }
#     },
#     "class": "Jsonable"
# }
# => nil
```

### Dependencies

#### Runtime
- [json](https://rubygems.org/gems/json) ~> 2.2

#### Building
- [test-unit](https://rubygems.org/gems/test-unit) ~> 3.3
- [yard](https://rubygems.org/gems/yard) ~> 0.9

### License
[MIT](https://github.com/rdipardo/tidy_json/blob/master/LICENSE)


[travis_build_status]: https://travis-ci.com/rdipardo/tidy_json
[cci_build_status]: https://circleci.com/gh/rdipardo/tidy_json/tree/master
[cci_build_status_badge]: https://circleci.com/gh/rdipardo/tidy_json.svg?style=svg
[travis_build_status_badge]: https://travis-ci.com/rdipardo/tidy_json.svg?branch=master
[gem_version]: https://badge.fury.io/rb/tidy_json
[gem_version_badge]: https://badge.fury.io/rb/tidy_json.svg
