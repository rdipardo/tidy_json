require 'minitest/autorun'
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

class TidyJsonTest < Minitest::Test
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
    assert_equal(TidyJson.tidy(a: 'one', A: 'ONE', b: nil), "{\n  \"a\": \"one\", \n  \"A\": \"ONE\", \n  \"b\": null\n}\n")
    assert_equal(TidyJson.tidy({}).length, 4)
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
    pretty_output = @@t.write_json('prettified', tidy: true, indent: 4)
    assert(File.exist?(pretty_output))
  end

  def test_indent_bounds_checking
    assert_equal Object.new.to_tidy_json(indent: '8'), ''
    assert_equal 0.to_tidy_json(indent: -89), ''
    assert_equal 3.1425.to_tidy_json(indent: 3.1425), ''
    assert_equal ''.to_tidy_json(indent: 8.90999), ''
    assert_equal 'Object'.to_tidy_json(indent: []), ''
    assert_equal [].to_tidy_json(indent: -89), "[\n]\n"
    assert_equal(JSON.parse(Object.new.stringify).to_tidy_json(indent: nil),
                 "{\n  \"class\": \"Object\"\n}\n")
    assert_equal(JSON.parse(''.stringify).to_tidy_json(indent: -16.009),
                 "{\n  \"class\": \"String\"\n}\n")
    assert_equal(JSON.parse({}.stringify).to_tidy_json(indent: '8'),
                 "{\n  \"class\": \"Hash\"\n}\n")
    assert_equal(JSON.parse(1000.stringify).to_tidy_json(indent: '8'),
                 "{\n  \"class\": \"Fixnum\"\n}\n")
  end
end
