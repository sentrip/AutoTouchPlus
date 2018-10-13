

fixture('equal', function() 
  local function equal(a, b)
    -- Handle table
    if type(a) == "table" and type(b) == "table" then
      for k in pairs(a) do
        if not equal(a[k], b[k]) then
          return false
        end
      end
      for k in pairs(b) do
        if not equal(b[k], a[k]) then
          return false
        end
      end
      return true
    end
    -- Handle scalar
    return a == b
  end
  return equal
end)

--modified from https://github.com/rxi/json.lua/blob/master/test/test.lua
describe('json',
  it("numbers", function()
    local t = {
      [ "123.456"       ] = 123.456,
      [ "-123"          ] = -123,
      [ "-567.765"      ] = -567.765,
      [ "12.3"          ] = 12.3,
      [ "0"             ] = 0,
      [ "0.10000000012" ] = 0.10000000012,
    }
    for k, v in pairs(t) do
      local res = json.decode(k)
      assert( res == v, string.format("expected '%s', got '%s'", k, res) )
      local res = json.encode(v)
      assert( res == k, string.format("expected '%s', got '%s'", v, res) )
    end
    assert( json.decode("13e2") == 13e2 )
    assert( json.decode("13E+2") == 13e2 )
    assert( json.decode("13e-2") == 13e-2 )
    end),
  it("literals", function()
    assert( json.decode("true") == true )
    assert( json.encode(true) == "true" ) 
    assert( json.decode("false") == false )
    assert( json.encode(false) == "false" )
    assert( json.decode("null") == nil )
    assert( json.encode(nil) == "null")
    end),
  it("strings", function()
    local s = "Hello world"
    assert( s == json.decode( json.encode(s) ) )
    local s = "\0 \13 \27"
    assert( s == json.decode( json.encode(s) ) )
    end),
  it("unicode", function()
    local s = "こんにちは世界"
    assert( s == json.decode( json.encode(s) ) )
    end),
  it("arrays", function(equal)
    local t = { "cat", "dog", "owl" }
    assert( equal( t, json.decode( json.encode(t) ) ) )
    end),
  it("objects", function(equal)
    local t = { x = 10, y = 20, z = 30 }
    assert( equal( t, json.decode( json.encode(t) ) ) )
    end),
  it("decode invalid", function()
    local t = {
      '',
      ' ',
      '{',
      '[',
      '{"x" : ',
      '{"x" : 1',
      '{"x" : z }',
      '{"x" : 123z }',
      '{x : 123 }',
      '{10 : 123 }',
      '{]',
      '[}',
      '"a',
    }
    for i, v in ipairs(t) do
      local status = pcall(json.decode, v)
      assert( not status, string.format("'%s' was parsed without error", v) )
    end
    end),
  it("decode invalid string", function()
    local t = {
      [["\z"]],
      [["\1"]],
      [["\u000z"]],
      [["\ud83d\ude0q"]],
      '"x\ny"',
      '"x\0y"',
    }
    for i, v in ipairs(t) do
      local status, err = pcall(json.decode, v)
      assert( not status, string.format("'%s' was parsed without error", v) )
    end
    end),
  it("decode escape", function()
    local t = {
      [ [["\u263a"]]        ] = '☺',
      [ [["\ud83d\ude02"]]  ] = '😂',
      [ [["\r\n\t\\\""]]    ] = '\r\n\t\\"',
      [ [["\\"]]            ] = '\\',
      [ [["\\\\"]]          ] = '\\\\',
      [ [["\/"]]            ] = '/',
    }
    for k, v in pairs(t) do
      local res = json.decode(k)
      assert( res == v, string.format("expected '%s', got '%s'", v, res) )
    end
    end),
  it("decode empty", function(equal)
    local t = {
      [ '[]' ] = {},
      [ '{}' ] = {},
      [ '""' ] = "",
    }
    for k, v in pairs(t) do
      local res = json.decode(k)
      assert( equal(res, v), string.format("'%s' did not equal expected", k) )
    end
    end),
  it("decode collection", function(equal)
    local t = {
      [ '[1, 2, 3, 4, 5, 6]'            ] = {1, 2, 3, 4, 5, 6},
      [ '[1, 2, 3, "hello"]'            ] = {1, 2, 3, "hello"},
      [ '{ "name": "test", "id": 231 }' ] = {name = "test", id = 231},
      [ '{"x":1,"y":2,"z":[1,2,3]}'     ] = {x = 1, y = 2, z = {1, 2, 3}},
    }
    for k, v in pairs(t) do
      local res = json.decode(k)
      assert( equal(res, v), string.format("'%s' did not equal expected", k) )
    end
    end),
  it("encode invalid", function()
    local t = {
      { [1000] = "b" },
      { [ function() end ] = 12 },
      { nil, 2, 3, 4 },
      { x = 10, [1] = 2 },
      { [1] = "a", [3] = "b" },
      { x = 10, [4] = 5 },
    }
    for i, v in ipairs(t) do
      local status, res = pcall(json.encode, v)
      assert( not status, string.format("encoding idx %d did not result in an error", i) )
    end
    end),
  it("encode invalid number", function()
    local t = {
      math.huge,      -- inf
      -math.huge,     -- -inf
      math.huge * 0,  -- NaN
    }
    for i, v in ipairs(t) do
      local status, res = pcall(json.encode, v)
      assert( not status, string.format("encoding '%s' did not result in an error", v) )
    end
    end),
  it("encode escape", function()
    local t = {
      [ '"x"'       ] = [["\"x\""]],
      [ 'x\ny'      ] = [["x\ny"]],
      [ 'x\0y'      ] = [["x\u0000y"]],
      [ 'x\27y'     ] = [["x\u001by"]],
      [ '\r\n\t\\"' ] = [["\r\n\t\\\""]],
    }
    for k, v in pairs(t) do
      local res = json.encode(k)
      assert( res == v, string.format("'%s' was not escaped properly", k) )
    end
    end)
)