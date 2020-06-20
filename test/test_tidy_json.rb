# frozen_string_literal: true

require 'test/unit'
require 'tidy_json'

##
# Tests.
#
class JsonableObject
  attr_reader(:h, :a)

  def initialize
    @h = { one: 'uno', two: 'dos', three: %w[eine zwei drei], cuatro: ['I', 'II', 'III', ['i.', 'ii.', 'iii.', 'iv.']] }
    @a = ['k', 'l', %w[M N O P], 'q', 'r', 's', [10, 456, ['<abbr title="Reel 2, Dialog Track 2">R2D2</abbr>', 'R', 2, 'D', ['two']]], 'u', 'v', 'x', 'y', %w[Z AB]]
  end
end

class TidyJsonTest < Test::Unit::TestCase
  @@t = JsonableObject.new
  @@t2 = JsonableObject.new
  @@t3 = JsonableObject.new
  @@t.h[:cinque] = { 'ichi' => "\u{4e00}", 'ni' => "\u{4e8c}", 'san' => "\u{4e09}", 'yon' => "\u{56db}" }
  @@t.h[:sei] = @@t2
  @@t2.h[:five] = @@t3
  @@t.a.unshift([@@t2, 13, 14, 15, 5.6])

  def test_version_number
    refute_nil ::TidyJson::VERSION
  end

  def test_tidy_static
    assert_equal("{\n  \"a\": \"one\", \n  \"A\": \"ONE\", \n  \"b\": null\n}\n",
                 TidyJson.tidy(a: 'one', A: 'ONE', b: nil))
    assert_equal(4, TidyJson.tidy({}).length)
  end

  def test_sort_keys_static
    hash = { c: 3, d: { i: '34', ii: '35', f: 56, a: 9 }, a: 1, b: 2 }
    hash_array = [{ c: 3, d: { i: '34', ii: '35', f: 56, a: 9 } }, { a: 1 }, { b: 2 }]
    assert_equal({ a: 1, b: 2, c: 3, d: { a: 9, f: 56, i: '34', ii: '35' } },
                 TidyJson.sort_keys(hash))
    assert_equal([{ a: 1 }, { b: 2 }, { c: 3, d: { a: 9, f: 56, i: '34', ii: '35' } }],
                 TidyJson.sort_keys(hash_array))
    assert_equal({ a: 'one', b: 'two', c: 3 },
                 TidyJson.sort_keys('b': 'two', 'c': 3, 'a': 'one'))
    assert_equal([], TidyJson.sort_keys([]), 'return empty arrays unchanged')
    assert_equal({}, TidyJson.sort_keys({}), 'return empty hashes unchanged')
    assert_equal([3, 2, 1], TidyJson.sort_keys([3, 2, 1]),
                 'return arrays of keyless objects unchanged')
    assert_equal([{ b: 'two' }, 'one'],
                 TidyJson.sort_keys([{ 'b': 'two' }, 'one']),
                 'arrays with any keyless objects should be returned unchanged')
  end

  def test_sort_keys_instance
    flat_hash_array = [{ c: 3 }, { a: 1 }, { b: 2 }]
    nested_hash_array = [{ c: 3, d: { i: '34', ii: '35', f: 56, a: 9 } }, { a: 1 }, { b: 2 }]
    assert_equal("[\n  {\n    \"a\": 1\n  }, \n  {\n    \"b\": 2\n  }, \n  {\n    \"c\": 3\n  }\n]\n",
                 flat_hash_array.to_tidy_json(sort: true))
    assert_equal("[\n        {\n                \"a\": 1\n        }, \n        {\n                \"b\": 2\n        }, \n        {\n                \"c\": 3,\n                \"d\": {\n                        \"a\": 9,\n                        \"f\": 56,\n                        \"i\": \"34\",\n                        \"ii\": \"35\"\n                }\n        }\n]\n",
                 nested_hash_array.to_tidy_json(indent: 8, sort: true))
    assert_equal("{\n      \"a\": \"one\", \n      \"b\": \"two\", \n      \"c\": 3\n}\n",
                 { 'b': 'two', 'c': 3, 'a': 'one' }.to_tidy_json(indent: 6, sort: true))
    assert_equal("[\n]\n", [].to_tidy_json(sort: true))
    assert_equal("{\n}\n", {}.to_tidy_json(sort: true))
    assert_equal("[\n        3, \n        2, \n        1\n]\n",
                 [3, 2, 1].to_tidy_json(indent: 8, sort: true))
    assert_equal("[\n    {\n        \"b\": \"two\"\n    }, \n    \"one\"\n]\n",
                 [{ 'b': 'two' }, 'one'].to_tidy_json(indent: 4, sort: true))
  end

  def test_tidy_instance
    assert_equal({}.to_tidy_json, "{\n}\n")
    assert_equal([].to_tidy_json, "[\n]\n")
    assert_equal(Object.new.to_tidy_json, '')
    assert_equal(JsonableObject.new.to_tidy_json.length, 650)
  end

  def test_stringify_instance
    assert_equal(@@t.stringify, "{\"class\":\"JsonableObject\",\"h\":{\"one\":\"uno\",\"two\":\"dos\",\"three\":[\"eine\",\"zwei\",\"drei\"],\"cuatro\":[\"I\",\"II\",\"III\",[\"i.\",\"ii.\",\"iii.\",\"iv.\"]],\"cinque\":{\"ichi\":\"\u{4e00}\",\"ni\":\"\u{4e8c}\",\"san\":\"\u{4e09}\",\"yon\":\"\u{56db}\"},\"sei\":{\"class\":\"JsonableObject\",\"h\":{\"one\":\"uno\",\"two\":\"dos\",\"three\":[\"eine\",\"zwei\",\"drei\"],\"cuatro\":[\"I\",\"II\",\"III\",[\"i.\",\"ii.\",\"iii.\",\"iv.\"]],\"five\":{\"class\":\"JsonableObject\",\"h\":{\"one\":\"uno\",\"two\":\"dos\",\"three\":[\"eine\",\"zwei\",\"drei\"],\"cuatro\":[\"I\",\"II\",\"III\",[\"i.\",\"ii.\",\"iii.\",\"iv.\"]]},\"a\":[\"k\",\"l\",[\"M\",\"N\",\"O\",\"P\"],\"q\",\"r\",\"s\",[10,456,[\"<abbr title=\\\"Reel 2, Dialog Track 2\\\">R2D2</abbr>\",\"R\",2,\"D\",[\"two\"]]],\"u\",\"v\",\"x\",\"y\",[\"Z\",\"AB\"]]}},\"a\":[\"k\",\"l\",[\"M\",\"N\",\"O\",\"P\"],\"q\",\"r\",\"s\",[10,456,[\"<abbr title=\\\"Reel 2, Dialog Track 2\\\">R2D2</abbr>\",\"R\",2,\"D\",[\"two\"]]],\"u\",\"v\",\"x\",\"y\",[\"Z\",\"AB\"]]}},\"a\":[{\"class\":\"JsonableObject\",\"h\":{\"one\":\"uno\",\"two\":\"dos\",\"three\":[\"eine\",\"zwei\",\"drei\"],\"cuatro\":[\"I\",\"II\",\"III\",[\"i.\",\"ii.\",\"iii.\",\"iv.\"]],\"five\":{\"class\":\"JsonableObject\",\"h\":{\"one\":\"uno\",\"two\":\"dos\",\"three\":[\"eine\",\"zwei\",\"drei\"],\"cuatro\":[\"I\",\"II\",\"III\",[\"i.\",\"ii.\",\"iii.\",\"iv.\"]]},\"a\":[\"k\",\"l\",[\"M\",\"N\",\"O\",\"P\"],\"q\",\"r\",\"s\",[10,456,[\"<abbr title=\\\"Reel 2, Dialog Track 2\\\">R2D2</abbr>\",\"R\",2,\"D\",[\"two\"]]],\"u\",\"v\",\"x\",\"y\",[\"Z\",\"AB\"]]}},\"a\":[\"k\",\"l\",[\"M\",\"N\",\"O\",\"P\"],\"q\",\"r\",\"s\",[10,456,[\"<abbr title=\\\"Reel 2, Dialog Track 2\\\">R2D2</abbr>\",\"R\",2,\"D\",[\"two\"]]],\"u\",\"v\",\"x\",\"y\",[\"Z\",\"AB\"]]},[13,14,15,5.6],\"k\",\"l\",[\"M\",\"N\",\"O\",\"P\"],\"q\",\"r\",\"s\",[10,456,[\"<abbr title=\\\"Reel 2, Dialog Track 2\\\">R2D2</abbr>\",\"R\",2,\"D\",[\"two\"]]],\"u\",\"v\",\"x\",\"y\",[\"Z\",\"AB\"]]}")
  end

  def test_writers
    output = @@t.write_json
    assert(File.exist?(output))
    assert_nothing_thrown 'Raw JSON should be valid' do
      File.open(output, 'r') { |f| JSON.parse(f.read) }
    end
    pretty_output = @@t.write_json('prettified', tidy: true, indent: 4)
    assert(File.exist?(pretty_output))
    assert_nothing_thrown 'Formatted JSON should be valid' do
      File.open(pretty_output, 'r') { |f| JSON.parse(f.read) }
    end
  end

  def test_indent_bounds_checking
    assert_equal("{\n  \"a\": \"one\", \n  \"b\": \"two\", \n  \"c\": 3\n}\n",
                 { 'b': 'two', 'c': 3, 'a': 'one' }.to_tidy_json(indent: 5, sort: true),
                 'odd values should fall back to default of 2')
    assert_equal([].to_tidy_json(indent: '16'), "[\n]\n",
                 'values > 12 should fall back to default of 2')
    assert_equal('Object'.to_tidy_json(indent: []), '')
    assert_equal(0.to_tidy_json(indent: -89), '')
    assert_equal(3.1425.to_tidy_json(indent: 3.1425), '')
    assert_equal(''.to_tidy_json(indent: +0), '')
    assert_equal([].to_tidy_json(indent: -8.00009), "[\n]\n")
    assert_nothing_thrown '#stringify should return valid JSON even when ' \
      'format options are invalid' do
      assert_equal(JSON.parse(Object.new.stringify).to_tidy_json(indent: nil),
                   "{\n  \"class\": \"Object\"\n}\n")
      assert_equal(JSON.parse(''.stringify).to_tidy_json(indent: -16.009),
                   "{\n  \"class\": \"String\"\n}\n")
      assert_equal(JSON.parse({}.stringify).to_tidy_json(indent: '8'),
                   "{\n  \"class\": \"Hash\"\n}\n")
      assert_equal(JSON.parse(%w[k l m].stringify).to_tidy_json(indent: '<<'),
                   "{\n  \"class\": \"Array\"\n}\n")
    end
  end
end
