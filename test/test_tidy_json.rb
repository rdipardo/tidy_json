# frozen_string_literal: true

require_relative 'codecov_runner'
require 'test/unit'
require 'tidy_json'

##
# Tests.
#
class Nested
  attr_accessor :a, :b, :c, :d, :e

  def initialize
    @a = [[], [[5, 6, 7]], [1, 2, { 'three': 3, 'four': [5, 6] }, [4]], { 'inner': 1 }]
    @b = { 'a': [5], 'b': [1, 2, 3, [4]], 'c': [5], 'd': { 'inner': 1 }, 'e': [6] }
    @c = [[1, 2, 3, [4]], { 'inner': 1 }, {}]
    @d = [{}, [], [1, 2, 3, [4]], { 'inner': 1 }, []]
    @e = [[1, 2, 3, [4]], { 'inner': 1 }, {}]
  end
end

class JsonableObject
  attr_reader :a, :b, :c, :d, :e, :f, :h

  def initialize
    @h = { one: 'uno', two: 'dos', three: %w[eine zwei drei], cuatro: ['I', 'II', 'III', ['i.', 'ii.', 'iii.', 'iv.']] }
    @a = ['k', 'l', %w[M N O P], 'q', 'r', 's', [10, 456, ['<abbr title="Reel 2, Dialog Track 2">R2D2</abbr>', 'R', 2, 'D', ['two']]], 'u', 'v', 'x', 'y', %w[Z AB]]
    @b = [{ 'uno': Nested.new }, [Nested.new, [Nested.new, Nested.new], [Nested.new]]]
    @c = [[Nested.new, [Nested.new], [Nested.new]]]
    @d = []
    @f = {}
  end
end

class TidyJsonTest < Test::Unit::TestCase
  def setup
    @t = JsonableObject.new
    t2 = JsonableObject.new
    t3 = JsonableObject.new

    30.times { |_| t3.d << JsonableObject.new }
    t2.h[:five] = t3

    @t.h[:cinque] = { 'ichi' => "\u{4e00}", 'ni' => "\u{4e8c}", 'san' => "\u{4e09}", 'yon' => "\u{56db}" }
    @t.h[:sei] = t2
    @t.a.unshift([t2, 13, 14, 15, 5.6])
  end

  def test_version_number
    refute_nil ::TidyJson::VERSION
  end

  def test_tidy_static
    assert_equal("{\n  \"a\": \"one\",\n  \"A\": \"ONE\",\n  \"b\": null\n}\n",
                 TidyJson.tidy(a: 'one', A: 'ONE', b: nil))
    assert_equal(3, TidyJson.tidy({}).length)
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
    assert_equal("[\n  {\n    \"a\": 1\n  },\n  {\n    \"b\": 2\n  },\n  {\n    \"c\": 3\n  }\n]\n",
                 flat_hash_array.to_tidy_json(sort: true))
    assert_equal("[\n        {\n                \"a\": 1\n        },\n        {\n                \"b\": 2\n        },\n        {\n                \"c\": 3,\n                \"d\": {\n                        \"a\": 9,\n                        \"f\": 56,\n                        \"i\": \"34\",\n                        \"ii\": \"35\"\n                }\n        }\n]\n",
                 nested_hash_array.to_tidy_json(indent: 8, sort: true))
    assert_equal("{\n      \"a\": \"one\",\n      \"b\": \"two\",\n      \"c\": 3\n}\n",
                 { 'b': 'two', 'c': 3, 'a': 'one' }.to_tidy_json(indent: 6, sort: true))
    assert_equal("[]\n", [].to_tidy_json(sort: true))
    assert_equal("{}\n", {}.to_tidy_json(sort: true))
    assert_equal("[\n        3,\n        2,\n        1\n]\n",
                 [3, 2, 1].to_tidy_json(indent: 8, sort: true))
    assert_equal("[\n    {\n        \"b\": \"two\"\n    },\n    \"one\"\n]\n",
                 [{ 'b': 'two' }, 'one'].to_tidy_json(indent: 4, sort: true))
  end

  def test_tidy_instance
    assert_equal({}.to_tidy_json, "{}\n")
    assert_equal([].to_tidy_json, "[]\n")
    assert_equal(String.new.to_tidy_json, "\"\"\n")
    assert_equal(JsonableObject.new.to_tidy_json.length, 13_410)
  end

  def test_stringify_instance
    File.open("#{__dir__}/JsonableObject.json", 'r') do |json|
      assert_equal(@t.stringify, json.read.strip)
    end
  rescue Errno::ENOENT, Errno::EACCES, IOError => e
    flunk "#{__FILE__}.#{__LINE__}: #{e.message}"
  end

  def test_writers
    json_array = []
    assert_nothing_thrown '#stringify returns valid JSON' do
      3.times { |_| json_array << JSON.parse(@t.stringify) }
    end

    output = json_array.write_json
    assert(File.exist?(output))
    assert_nothing_thrown 'Raw JSON should be valid' do
      File.open(output, 'r') { |f| JSON.parse(f.read) }
    end

    pretty_output = \
      json_array.write_json('prettified', tidy: true, sort: true, indent: 4)

    assert(File.exist?(pretty_output))

    assert_nothing_thrown 'Formatted JSON should be valid' do
      File.open(pretty_output, 'r') { |f| JSON.parse(f.read) }
    end

    assert_nil json_array.write_json('/invalid/file/name/')
  end

  def test_indent_bounds_checking
    assert_equal("{\n  \"a\": \"one\",\n  \"b\": \"two\",\n  \"c\": 3\n}\n",
                 { 'b': 'two', 'c': 3, 'a': 'one' }.to_tidy_json(indent: 5, sort: true),
                 'odd values should fall back to default of 2')
    assert_equal([].to_tidy_json(indent: '16'), "[]\n",
                 'values > 12 should fall back to default of 2')
    assert_equal('Object'.to_tidy_json(indent: []), "\"Object\"\n")
    assert_equal(0.to_tidy_json(indent: -89), "0\n")
    assert_equal(3.1425.to_tidy_json(indent: 3.1425), "3.1425\n")
    assert_equal(''.to_tidy_json(indent: +0), "\"\"\n")
    assert_equal([].to_tidy_json(indent: -8.00009), "[]\n")
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
