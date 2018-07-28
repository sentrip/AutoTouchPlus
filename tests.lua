-------------------------------AutoTouch mocking ---------------------------
alert = alert or print
tap = tap or function(x, y) print('tapping', x, y) end
usleep = usleep or function(t) sleep(t / 1000000) end
function intToRgb(i) return 0, 0, 0 end
function rgbToInt(r,g,b) return 0 end
----------------------------------------------------------------------------
require("AutoTouchPlus")
--check for wget
assert(is(exe('dpkg-query -W wget')),
  'wget not installed. Either install it or remove this check from test.lua (4-5)')
----------------------------------------------------------------------------
failed = test_all{
test('object tests', {
  dict_creation = function(self)
    assertNotRequal(self.dict_a, self.dict_b, 'Different dicts requal')
    assertRequal(self.dict_a, {}, 'Dict and table not requal')
    assertRequal(self.dict_b, {a=1, b=2}, 'Dict and table not requal')
    assertEqual(self.dict_a['thing'], nil, 'Unknown key does not return nil')
    end,
  dict_addition = function(self)
    assertEqual(self.dict_a + self.dict_b, self.dict_b, 'Added dicts not equal')
    assertEqual(self.dict_b + {b=9}, dict{a=1, b=9}, 'Added dicts not equal')
    end,
  dict_equality = function(self)
    self.dict_a:update(self.dict_b)
    assertEqual(self.dict_a, self.dict_b, 'Dicts not equal')
    assertRequal(self.dict_a, {a=1, b=2}, 'Dict and table not requal')
    assertNotEqual(self.dict_a, {a=1, b=2}, 'Dict and table equal')
    end,
  dict_for = function(self)
    local expected
    local expected1 = {'a', 'b'}
    local expected2 = {'b', 'a'}
    local i = 1
    local st = false
    for k in self.dict_b() do 
      if not st then
        st = true
        if k == 'a' then expected = expected1
        else expected = expected2 end
      end
      assertEqual(k, expected[i], 'incorrect key returned in for loop')
      i = i + 1
    end
    end,
  dict_pairs = function(self)
    local expected = {a=1, b=2}
    for i, v in pairs(self.dict_b) do
      assertEqual(v, expected[i], 'Pairs returns incorrect result')
    end
    end,
  dict_clear = function(self)
    self.dict_a:clear()
    self.dict_b:clear()
    assertEqual(self.dict_a, self.dict_b, 'Dict not empty after clear')
    end,
  dict_contains = function(self)
    assert(not self.dict_b:contains('q'), 'Dict contains unknown key')
    assert(self.dict_b:contains('a'), 'Dict does not contain key')
    end,
  dict_get = function(self)
    assertEqual(self.dict_b:get('a'), 1, 'Dict get incorrect for known key')
    assertEqual(self.dict_b:get('q'), nil, 'Dict get incorrect for unknown key')
    assertEqual(self.dict_b:get('a', 5), 1, 'Dict get incorrect for known key with default')
    assertEqual(self.dict_b:get('q', 5), 5, 'Dict get incorrect for unknown key with default')
    end,
  dict_keys = function(self)
    assert(Not(self.dict_a:keys(), 'Incorrect dict keys'))
    for i, v in pairs({'a', 'b'}) do
      assert(isin(v, self.dict_b:keys()), 'Dict key not found')
    end
    end,
  dict_set = function(self)
    self.dict_b:set('b', 5)
    assertEqual(self.dict_b['b'], 5, 'Incorrect value after set')
    end, 
  dict_update = function(self)
    self.dict_a:update(self.dict_b)
    assertEqual(self.dict_a, self.dict_b, 'Dicts not equal after update')
    end,
  dict_values = function(self)
    assert(Not(self.dict_a:values(), 'Incorrect dict values'))
    for i, v in pairs({1, 2}) do
      assert(isin(v, self.dict_b:values()), 'Dict value not found')
    end
    end,
  list_creation = function(self)
    assertNotEqual(self.list_a, self.list_b, 'Different lists are equal')
    assertNotEqual(self.list_a, self.list_c, 'Different lists are equal')
    assertNotEqual(self.list_b, self.list_c, 'Different lists are equal')
    assertEqual(self.list_a, list(), 'List and new list not equal')
    assertEqual(self.list_b, list{1,2,3}, 'List and new list not equal')
    assertEqual(self.list_c, list{1,{2, 3}}, 'List and new list not equal')
    assertRequal(self.list_a, {}, 'List and table not requal')
    assertRequal(self.list_b, {1,2,3}, 'List and table not requal')
    assertRequal(self.list_c, {1,{2, 3}}, 'List and table not requal')
    end,
  list_addition = function(self)
    assertRequal(self.list_a + self.list_b, self.list_b, 'Added lists returned incorrect list')
    assertRequal(self.list_b + list{5}, {1,2,3,5}, 'Added lists returned incorrect list')
    assertRequal(list{5} + self.list_b, {5,1,2,3}, 'Added lists returned incorrect list')
    end,
  list_equality = function(self)
    assertEqual(self.list_a, list(), 'Lists not equal')
    assertRequal(self.list_a, {}, 'List not requals table')
    assertNotEqual(self.list_a, {}, 'List equals table')
    assertRequal(self.list_b, {1,2,3}, 'List not requals table')
    assertEqual(self.list_b, list{1,2,3}, 'Lists not equal')
    assertNotEqual(self.list_b, {1,2,3}, 'List equals table')
    end,
  list_for = function(self)
    local count = 0
    local expected = {1, 2, 3}
    for v in self.list_b() do 
      count = count + 1
      assertEqual(v, expected[count], 'Unknown element returned')
    end
    assertEqual(count, len(self.list_b), 'Incorrect number of elements')
    end,
  list_indexing = function(self)
    assertEqual(self.list_b[2], 2, 'Positive index returned incorrect result')
    assertEqual(self.list_b[-2], 2, 'Negative index returned incorrect result')
    end,  
  list_pairs = function(self)
    local expected = {1,2,3}
    for i, v in pairs(self.list_b) do
      assertEqual(v, expected[i], 'Incorrect item returned in list pairs')
    end
    end,
  list_slicing = function(self)
    assertEqual(self.list_b(1), self.list_b, 'list slice failed')
    assertEqual(self.list_b(1, 2), list{1,2}, 'list slice failed')
    assertEqual(self.list_b(1, 3), self.list_b, 'list slice failed')
    assertEqual(self.list_b(1, -2), list{1,2}, 'list slice failed')
    assertEqual(self.list_b(3, 1, -1), reversed(self.list_b), 'list slice failed')
    assertEqual(self.list_b{2, -1, 1}, list{2, 3, 1}, 'list slice failed')
    end,
  list_append = function(self)
    self.list_a:append(5)
    assertEqual(self.list_a, list{5}, 'List and new list not equal')
    assertEqual(self.list_b, list{1,2,3}, 'Other lists changed after append')
    assertEqual(self.list_c, list{1,{2,3}}, 'Other lists changed after append')
    assertRequal(self.list_a, {5}, 'List and table not requal')
    assertRequal(self.list_b, {1,2,3}, 'Other lists changed after append')
    assertRequal(self.list_c, {1,{2,3}}, 'Other lists changed after append')
    end,
  list_contains = function(self)
    assert(self.list_b:contains(1), 'List does not contain number')
    assert(self.list_c:contains({2,3}), 'List does not contain table')
    end,
  list_extend = function(self)
    self.list_a:extend{1,2}
    assertEqual(self.list_a, list{1,2}, 'List and new list not equal')
    assertRequal(self.list_a, {1,2}, 'List and table not requal')
    end,
  list_index = function(self)
    assertEqual(self.list_b:index(1), 1, 'Incorrect list index')
    end,
  list_insert = function(self)
    self.list_b:insert(2, 5)
    assertEqual(self.list_b, list{1,5,2,3}, 'List and new list not equal')
    assertRequal(self.list_b, {1,5,2,3}, 'List and table not requal')
    end,
  list_pop = function(self)
    assertEqual(self.list_b:pop(2), 2, 'Incorrect value popped from list')
    assertEqual(self.list_b, list{1,3}, 'List and new list not equal')
    assertRequal(self.list_b, {1,3}, 'List and table not requal')
    end,
  
  
  set_creation = function(self)
    assertNotRequal(self.set_a, self.set_b, 'Different sets requal')
    assertRequal(self.set_a, {}, 'Set and table not requal')
    assertRequal(self.set_b, set{1,2,3}, 'Same sets not requal')
    end,
  set_equality = function(self)
    assertEqual(self.set_a, set(), 'Empty sets not equal')
    assertEqual(self.set_b, set{1, 2, 3}, 'Number sets not equal')
    assertEqual(self.set_c, set{'a', 'b', 'c'}, 'String sets not equal')
    assertNotEqual(self.set_b, {1, 2, 3}, 'Set and table equal')
    assertRequal(self.set_b, {1, 2, 3}, 'Set and table not requal')
    end,
  set_for = function(self)
    local count = 0
    for v in self.set_b() do 
      count = count + 1
      assert(isin(v, self.set_b), 'Unknown element returned')
    end
    assertEqual(count, len(self.set_b), 'Incorrect number of elements')
    end,
  set_pairs = function(self)
    for _, s in pairs({self.set_b, self.set_c}) do
      for k, v in pairs(s) do
        assertEqual(k, str(hash(v)), 'Set key is not hash of value')
      end
    end
    end,
  set_add = function(self)
    self.set_a:add(1)
    assertEqual(self.set_a, set{1}, 'Did not add element to set')
    assertEqual(len(self.set_a), 1, 'Incorrect number of elements after add')
    self.set_a:add(1)
    assertEqual(self.set_a, set{1}, 'Added already existing element to set')
    assertEqual(len(self.set_a), 1, 'Incorrect number of elements after add')
    self.set_a:add(2)
    self.set_a:add(3)
    assertEqual(self.set_a, self.set_b, 'Did not add elements to set')
    end,
  set_clear = function(self)
    self.set_b:clear()
    assertEqual(self.set_a, self.set_b, 'Did not clear set')
    self.set_c:clear()
    assertEqual(self.set_a, self.set_c, 'Did not clear set')
    end,
  set_contains = function(self)
    assert(self.set_b:contains(1), 'Set does not contain number element')
    assert(self.set_c:contains('b'), 'Set does not contain string element')
    end,
  set_difference = function(self)
    assertEqual(self.set_b - set{1}, set{2, 3}, 'Set subtraction with number items failed')
    assertEqual(self.set_c - set{'a', 'c'}, set{'b'}, 'Set subtraction with string items failed')
    end,
  set_pop = function(self)
    assertEqual(self.set_b:pop(1), 1, 'Did not return correct number value from pop')
    assertEqual(self.set_b, set{2, 3}, 'Did not number value from set after pop')
    assertEqual(self.set_c:pop('c'), 'c', 'Did not return correct number value from pop')
    assertEqual(self.set_c, set{'a', 'b'}, 'Did not number value from set after pop')
    end,
  set_remove = function(self)
    self.set_b:remove(2)
    assertEqual(self.set_b, set{1, 3}, 'Did not remove number item from set')
    self.set_c:remove('b')
    assertEqual(self.set_c, set{'a', 'c'}, 'Did not remove number item from set')
    end,
  set_update = function(self)
    self.set_a:update(self.set_b)
    assertEqual(self.set_a, self.set_b, 'Update of empty set incorrect')
    assertEqual(self.set_b + self.set_c, set{'a', 'b', 'c', 1, 2, 3}, 'Addition of filled sets incorrect')
    end,
  set_values = function(self)
    for k, v in pairs(self.set_a:values()) do
      assert(self.set_a:contains(v), 'Set does not contain number element in values')
    end
    for k, v in pairs(self.set_b:values()) do
      assert(self.set_b:contains(v), 'Set does not contain string element in values')
    end
    end,
  },
  function(self) 
    self.dict_a = dict()
    self.dict_b = dict{a=1, b=2}
    
    self.list_a =  list()
    self.list_b = list{1,2,3}
    self.list_c = list{1, {2,3}}
    
    
    self.set_a =  set()
    self.set_b = set{1,2,3}
    self.set_c = set{'a', 'b', 'c'}
  end),
--modified from https://github.com/rxi/json.lua/blob/master/test/test.lua
failed = failed or test('json tests', {
  json = function()
    local fmt = string.format

    local function test(name, func)
      local success, err = pcall(func)
      if not success then error(name..': '..err) end
    end


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


    test("numbers", function()
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
        assert( res == v, fmt("expected '%s', got '%s'", k, res) )
        local res = json.encode(v)
        assert( res == k, fmt("expected '%s', got '%s'", v, res) )
      end
      assert( json.decode("13e2") == 13e2 )
      assert( json.decode("13E+2") == 13e2 )
      assert( json.decode("13e-2") == 13e-2 )
    end)


    test("literals", function()
      assert( json.decode("true") == true )
      assert( json.encode(true) == "true" ) 
      assert( json.decode("false") == false )
      assert( json.encode(false) == "false" )
      assert( json.decode("null") == nil )
      assert( json.encode(nil) == "null")
    end)


    test("strings", function()
      local s = "Hello world"
      assert( s == json.decode( json.encode(s) ) )
      local s = "\0 \13 \27"
      assert( s == json.decode( json.encode(s) ) )
    end)


    test("unicode", function()
      local s = "こんにちは世界"
      assert( s == json.decode( json.encode(s) ) )
    end)


    test("arrays", function()
      local t = { "cat", "dog", "owl" }
      assert( equal( t, json.decode( json.encode(t) ) ) )
    end)


    test("objects", function()
      local t = { x = 10, y = 20, z = 30 }
      assert( equal( t, json.decode( json.encode(t) ) ) )
    end)


    test("decode invalid", function()
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
        assert( not status, fmt("'%s' was parsed without error", v) )
      end
    end)


    test("decode invalid string", function()
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
        assert( not status, fmt("'%s' was parsed without error", v) )
      end
    end)


    test("decode escape", function()
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
        assert( res == v, fmt("expected '%s', got '%s'", v, res) )
      end
    end)


    test("decode empty", function()
      local t = {
        [ '[]' ] = {},
        [ '{}' ] = {},
        [ '""' ] = "",
      }
      for k, v in pairs(t) do
        local res = json.decode(k)
        assert( equal(res, v), fmt("'%s' did not equal expected", k) )
      end
    end)


    test("decode collection", function()
      local t = {
        [ '[1, 2, 3, 4, 5, 6]'            ] = {1, 2, 3, 4, 5, 6},
        [ '[1, 2, 3, "hello"]'            ] = {1, 2, 3, "hello"},
        [ '{ "name": "test", "id": 231 }' ] = {name = "test", id = 231},
        [ '{"x":1,"y":2,"z":[1,2,3]}'     ] = {x = 1, y = 2, z = {1, 2, 3}},
      }
      for k, v in pairs(t) do
        local res = json.decode(k)
        assert( equal(res, v), fmt("'%s' did not equal expected", k) )
      end
    end)


    test("encode invalid", function()
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
        assert( not status, fmt("encoding idx %d did not result in an error", i) )
      end
    end)


    test("encode invalid number", function()
      local t = {
        math.huge,      -- inf
        -math.huge,     -- -inf
        math.huge * 0,  -- NaN
      }
      for i, v in ipairs(t) do
        local status, res = pcall(json.encode, v)
        assert( not status, fmt("encoding '%s' did not result in an error", v) )
      end
    end)


    test("encode escape", function()
      local t = {
        [ '"x"'       ] = [["\"x\""]],
        [ 'x\ny'      ] = [["x\ny"]],
        [ 'x\0y'      ] = [["x\u0000y"]],
        [ 'x\27y'     ] = [["x\u001by"]],
        [ '\r\n\t\\"' ] = [["\r\n\t\\\""]],
      }
      for k, v in pairs(t) do
        local res = json.encode(k)
        assert( res == v, fmt("'%s' was not escaped properly", k) )
      end
    end)
  end
}),
test('system tests', {  
  fcopy = function()
    local function check_lines(fname, expected)
      expected = expected or {'1', '2', '3'}
      for i, v in pairs(readLines(fname)) do 
        assertEqual(v, expected[i], 
          ('fcopy did not correctly copy contents of %s'):format(fname)) 
      end
    end
    
    fcopy('_tmp_tst/t1.txt', '_tmp_tst/t2.txt')
    check_lines('_tmp_tst/t2.txt')
    fcopy('_tmp_tst/t1.txt', '_tmp_tst/t.txt', false)
    check_lines('_tmp_tst/t.txt', {'line1', 'line2', 'line3'})
    fcopy('_tmp_tst/t1.txt', '_tmp_tst/t.txt')
    check_lines('_tmp_tst/t.txt')
    fcopy('_tmp_tst', '_tmp_tst2')
    assertEqual(listdir('_tmp_tst2'), listdir('_tmp_tst'), 
      'fcopy did not correctly copy directory contents')
    check_lines('_tmp_tst/tmp/t1.txt')
    end,
  find = function()
    assertEqual(find('tests.lua'), './tests.lua', 
      'find returned incorrect file path')
    assertEqual(find{dir='_tmp_tst'}, './_tmp_tst', 
      'find returned incorrect directory path')
    end,
  exe = function() 
    local result = set(exe('ls _tmp_tst'))
    assertEqual(result, set{'t1.txt', 't.txt'}, 'ls returned incorrect files')
    assertRequal(exe('echo "1\n2"'), {'1', '2'}, 'Multi line output failed')
    assertEqual(exe('echo "1\n"'), '1', 'Multi line output with single usable failed')
    assertEqual(exe('echo "1\n2"', false), '1\n2', 'Single output failed')
    end,
  isDir = function() 
    assert(isDir('_tmp_tst'), '_tmp_tst not a directory') 
    end,
  isFile = function()
    assert(isFile('_tmp_tst/t.txt'), '_tmp_tst/t.txt not a file')
    end,
  listdir = function()
    local result = listdir('_tmp_tst')
    local expected = {'t.txt', 't1.txt'}
    for i, v in pairs(result) do 
      assertEqual(v, expected[i], 'listdir has incorrect file name') 
    end
    end,
  pathExists = function()
    assert(not pathExists('randompath_sdas'), 'Invalid path exists')
    assert(pathExists('/etc'), '/usr does not exist')
    end,
  readLine = function() 
    local line = readLine('_tmp_tst/t.txt', 2)
    assertEqual(line, 'line2', 'Second line read incorrectly')
    end,
  readLines = function() 
    local expected = {'line1', 'line2', 'line3'}
    local lines = readLines('_tmp_tst/t.txt')
    for i, v in pairs(lines) do 
      assertEqual(v, expected[i], 'line read incorrectly') 
    end
    end,
  sizeof = function()
    local size = sizeof('_tmp_tst/t.txt')
    --Don't know why text files are so drastically different 
    --in size accross linux and various IOS versions
    assert(size >= 4, 'Incorrect file size') 
    end,
  writeLine = function()
    writeLine('5', 2, '_tmp_tst/t1.txt')
    local lines = readLines('_tmp_tst/t1.txt')
    local expected = {'1', '5', '3'}
    for i, v in pairs(lines) do 
      assertEqual(v, expected[i], 'Incorrect line written') 
    end
    end,
  writeLines = function() 
    local expected = {'2', '5', '6'}
    writeLines(expected, '_tmp_tst/t1.txt')
    local lines = readLines('_tmp_tst/t1.txt')
    for i, v in pairs(lines) do 
      assertEqual(v, expected[i], 'Incorrect lines written') 
    end
    end,
  },
  function() 
    local cmd = ''
    if rootDir then cmd = 'cd '..rootDir()..'; ' end
    io.popen(cmd..'mkdir _tmp_tst'):close() 
    io.popen(cmd..'echo "line1\nline2\nline3" > _tmp_tst/t.txt'):close()
    io.popen(cmd..'echo "1\n2\n3" > _tmp_tst/t1.txt'):close()
    end,
  function() 
    local cmd = ''
    if rootDir then cmd = 'cd '..rootDir()..'; ' end
    io.popen(cmd..'rm -r _tmp_tst'):close() 
    if isDir('_tmp_tst2') then io.popen(cmd..'rm -R _tmp_tst2'):close() end
    end),
test('core tests', {
  class_definition = function() -- todo add instance checking
    --definition
    local A = class("A")
    function A:__init(value)
      self.value = value
    end
    function A:run()
      return self.value
    end
    --attribute access
    local a = A(5)
    assert(a.value, 'Class instance does not have required attributes')
    assertEqual(a.value, 5, 
      'Class instance does not have correct attribute values')
    local a2 = A(1)
    assertEqual(a.value, 5, 
      'Different instance changed value after new instance was created')
    assertEqual(a2.value, 1, 
      'Class instance does not have correct attribute values')
    --method access
    assert(a.run, 'Class instance does not have required methods')
    assert(a2.run, 'Class instance does not have required methods')
    assertEqual(a:run(), 5, 'Class instance method returns incorrect result')
    assertEqual(a2:run(), 1, 'Class instance method returns incorrect result')
    --private tables
    local p1, p2 = a.__private, a2.__private
    assert(p1, 'Class instance does not have private table')
    assert(p1, 'Class instance does not have private table')
    assertNotEqual(p1, p2, 'Unique instance private tables are equal')
    end,
  class_single_inheritance = function()  -- todo add instance checking
    local A = class("A")
    function A:__init(value)
      self.value = value
    end
    function A:add(value)
      self.value = self.value + value
    end
    local B = class("B", A)
    local a, b = A(1), B(10)
    assertEqual(a.value, 1, 'Parent class has incorrect attribute value')
    assertEqual(b.value, 10, 'Child class has incorrect attribute value')
    assert(a.add, 'Parent class does not have required method')
    assert(b.add, 'Child class does not have required method')
    a:add(1)
    assertEqual(a.value, 2, 'Parent class method failure')
    assertEqual(b.value, 10, 'Difference class has incorrect attribute value')
    b:add(10)
    assertEqual(b.value, 20, 'Child class method failure')
    assertEqual(a.value, 2, 'Difference class has incorrect attribute value')
    end,
  class_multiple_inheritance = function() -- todo add instance checking
    local A = class("A")
    function A:__init(value)
      self.value = value
    end
    function A:run(value)
      return self.value + value
    end
    function A:run5(value)
      return self.value + value
    end
    local B = class("B", A)
    function B:run5(value)
      return self.value + value * 5
    end
    local C = class("C", B, A)
    function C:run(value)
      return self.value + value * 3
    end
    local a, b, c = A(1), B(2), C(1)
    assert(c.run, 'Class did not inherit method from base')
    assert(c.run5, 'Class did not inherit method from base 2')
    assertEqual(a:run(1), 2, 'Base class method changed')
    assertEqual(c:run(1), 4, 
      'Inherited method returned incorrect result')
    assertEqual(c:run5(1), 6, 
      'Did not inherit methods in correct order')
    assertEqual(c:run5(1), b:run5(1) - 1, 
      'Inherited method different from original method')
    end,
  class_get_set_properties = function()
    local A = class("A")
    function A:__init(value)
      self.value = max(0, min(10, value))
    end
    A.__getters['v'] = function(self)
      return self.value * 2
    end
    A.__setters['v'] = function(self, value)
      self.value = max(0, min(10, value))
    end
    a = A(1)
    assert(a.v, 'Getter proprty was not created on class')
    assertEqual(a.v, a.value * 2, 'Getter did not return custom value')
    a.v = -1
    assertEqual(a.v, 0, 'Setter did not set custom value')
    a.v = 10
    assertEqual(a.v, a.value * 2, 'Getter did not return custom value')
    end,
  copy = function()
    local t1, t2 = {1, 2}, {1, {1, 2}}
    local nt1 = copy(t1)
    assertRequal(t1, nt1, 'Did not copy all data')
    assertNotEqual(t1, nt1, 'Copy did not return new object')
    local nt2 = copy(t2)
    assertRequal(t2, nt2, 'Did not copy all data')
    assertNotEqual(t2, nt2, 'Copy did not return new object')
    assertEqual(t2[2], nt2[2], 'Shallow copy returned new object')
    nt2 = copy(t2, true)
    assertRequal(t2, nt2, 'Did not copy all data')
    assertNotEqual(t2, nt2, 'Copy did not return new object')
    assertNotEqual(t2[2], nt2[2], 'Deep copy returned new object')
    local l = list{1, {1, 2}}
    local nl = copy(l, true)
    assert(nl:isinstance(list), 'Did not copy object type')
    end,
  eval = function()
    assertEqual(eval('return 1 + 1'), 2, 'eval 1 + 1 failed')
    assertRaises('Syntax', function() eval('x =') end, 
      'eval of syntax error did not fail')
    end,
  hash = function()
    local h
    local values = {}
    for i=1, 128 do 
      h = hash(string.char(i))
      assert(isnotin(h, values), 'Hash collision in first 128 bits')
      values[#values + 1] = h
    end
    for i=0, 100 do
      h = hash(i - 50)
      assert(isnotin(h, values), 'Hash collision in first 50 +/- numbers')
      values[#values + 1] = h
    end
    end,
  isin = function()
    assert(isin('a', 'abc'), 'Character not in string when it should be')
    assert(not isin('t', 'abc'), "Character in string when it shouldn't be")
    assert(isin('failed', 'stuff and thingsandstuffthisfailedand other'), "Sub not in string when it should be")
    assert(isin(1, {1,2,3}), 'Number not in table when it should be')
    assert(not isin(5, {1,2,3}), "Number in table when it shouldn't be")
    assert(isin({1,2,3}, {{1,2,3}, {4,5,6}}), 'Table not in nested table when it should be')
    assert(not isin({5}, {{1,2,3}, {4,5,6}}), "Table in nested table when it shouldn't be")
    end,
  max = function()
    local l, s, t = list{2,1,3}, set{3,2,1}, {3,1,2}
    assertEqual(math.max(unpack(t)), max(t), 'table max not same as math.max')
    assertEqual(math.max(unpack(t)), max(l), 'list max not same as math.max')
    assertEqual(math.max(unpack(t)), max(s), 'set max not same as math.max')
    end,
  min = function()
    local l, s, t = list{2,1,3}, set{3,2,1}, {3,1,2}
    assertEqual(math.min(unpack(t)), min(t), 'table min not same as math.min')
    assertEqual(math.min(unpack(t)), min(l), 'list min not same as math.min')
    assertEqual(math.min(unpack(t)), min(s), 'set min not same as math.min')
    end,
  num = function()
    assert(is.num(num(1)), 'Converted int to non number')
    assert(is.num(num(1.0)), 'Converted float to non number')
    assert(is.num(num(-1)), 'Converted negative to non number')
    assertEqual(num('1'), 1, 'Converted string int to non number')
    assertEqual(num('-1.0'), -1.0, 'Converted negative string float to non number')
    end,
  str = function()
    assertEqual(str(1), '1', 'str number failed')
    assertEqual(str('1'), '1', 'str string failed')
    assertEqual(str({1,2}), '{1, 2}', 'table number failed')
    assertEqual(str(list{1,2}), '[1, 2]', 'str list failed')
    assertEqual(str(list{1,list{1,2}}), '[1, [1, 2]]', 'str recursive failed')
    end,
  getattr = function()
    local A = class('A')
    function A:__init()
      self.val = 5
    end
    local a = A()
    assertEqual(getattr(a, 'val'), 5, 'Did not get basic class attribute')
    assertEqual(getattr(a, 't'), nil, 'Did not get basic class attribute')
    assertEqual(getattr(a, 'isinstance'), A.isinstance, 'Getattr does not get inherited methods')
    end,
  setattr = function()
    local A = class('A')
    function A:__init()
      self.val = 5
    end
    local a = A()
    setattr(a, 'val', 3)
    assertEqual(getattr(a, 'val'), 3, 'Did not set basic class attribute')
    assertEqual(getattr(A, 'val'), nil, 'Did set class value on instance')
    end,
  reversed = function()
    local l, s = {1, 2, 3}, 'abc'
    local e1, e2 = {3, 2, 1}, {'c', 'b', 'a'}
    for i, v in pairs(reversed(l)) do 
      assertEqual(e1[i], v, 'Did not reverse table correctly')
    end
    for i, v in pairs(reversed(s)) do 
      assertEqual(e2[i], v, 'Did not reverse string correctly')
    end
    end,
  sorted = function()
    --basic sort
    local a, b = {3, 1, 2}, {'c', 'a', 'b'}
    local ea, eb = {1,2,3}, {'a','b','c'}
    for i, v in pairs(sorted(a)) do
      assertEqual(v, ea[i], 'Integer sorting failed')
    end
    for i, v in pairs(sorted(list(b))) do
      assertEqual(v, eb[i], 'String sorting failed')
    end
    --key based sort
    local a2, e2 = {list{'a', 2}, list{'b', 1}}, {list{'b', 1}, list{'a', 2}}
    for i, v in pairs(sorted(list(a2), function(m) return m[2] end)) do
      assertEqual(v, e2[i], 'String sorting failed')
    end
    end
}),
test('screen tests', {
  tree_root_nagivation = function()
    local l = list()
    local function f(v) return function() l:append({'fw', v}) end end
    local function b(v) return function() l:append({'bw', v}) end end
    local t = TransitionTree()
    t:add('left', f('left'), b('root'))
    t:add('mid', f('mid'), b('root'))
    t:add('right', f('right'), b('root'))

    t['left']:add('a', f('a'), b('left'))
    t['left']:add('b', f('b'), b('left'))

    t['mid']:add('c', f('c'), b('mid'))
    t['mid']:add('d', f('d'), b('mid'))

    t['right']:add('e', f('e'), b('right'))
    t['right']:add('f', f('f'), b('right'))
    t:navigate('a', 'f')
    local ea = {'bw', 'bw', 'fw', 'fw'}
    local en = {'left', 'root', 'right', 'f'}
    for i, v in pairs(ea) do
      assertEqual(l[i][1], ea[i], 'Did not navigate in correct direction')
      assertEqual(l[i][2], en[i], 'Did not navigate to correct node')
    end
  end,
  tree_lca_nagivation = function()
    local l = list()
    local function f(v) return function() l:append({'fw', v}) end end
    local function b(v) return function() l:append({'bw', v}) end end
    local t = TransitionTree()
    t:add('left', f('left'), b('root'))
    t:add('mid', f('mid'), b('root'))
    t:add('right', f('right'), b('root'))

    t['left']:add('a', f('a'), b('left'))
    t['left']:add('b', f('b'), b('left'))

    t['mid']:add('c', f('c'), b('mid'))
    t['mid']:add('d', f('d'), b('mid'))

    t['right']:add('e', f('e'), b('right'))
    t['right']:add('f', f('f'), b('right'))
    t:navigate('a', 'b')
    local ea = {'bw', 'fw'}
    local en = {'left', 'b'}
    for i, v in pairs(ea) do
      assertEqual(l[i][1], ea[i], 'Did not navigate in correct direction')
      assertEqual(l[i][2], en[i], 'Did not navigate to correct node')
    end
    end,
  },
  function(self) 
    end),
test('logic tests', {
  all = function()
    assert(all({true, true, true}), 'All - table of booleans')
    assert(all(list{true, true, true}), 'All - list of booleans')
    assert(all({true, false, true}) == false, 'All with false - table of booleans')
    assert(all(list{true, false, true}) == false, 'All with false - list of booleans')
    assert(all({1,2,3}), 'All - table of numbers')
    assert(all(list{1,2,3}), 'All - list of numbers')
    assert(all({1,0,3}) == false, 'All with false - table of numbers')
    assert(all(set{1,0,3}) == false, 'All with false - set of numbers')
    end,
  any = function()
    assert(any({true, false, true}), 'Any - table of booleans')
    assert(any(list{true, false, true}), 'Any - list of booleans')
    assert(any({false, false, false}) == false, 'Any with false - table of booleans')
    assert(any(list{false, false, false}) == false, 'Any with false - list of booleans')
    assert(any({1,2,3}), 'Any - table of numbers')
    assert(any(list{1,2,3}), 'Any - list of numbers')
    assert(any({0,0,0}) == false, 'Any with false - table of numbers')
    assert(any(list{0, 0, 0}) == false, 'Any with false - list of numbers')
    end,

  isType = function()
    assert(isType(true, 'boolean'), 'basic isType failed')
    assert(isType(true, 'string', 'bool'), 'multi arg isType failed')
    assert(not isType(true, 'string', 'table'), 'multi arg isType failed')
    end,
  is = function()
    local f = io.tmpfile()
    --truthy checks
    assert(is(true), 'boolean is failed')
    assert(is(1), 'number is failed')
    assert(is('thing'), 'string(5) is failed')
    assert(is({1,2,3}), 'table(3) is failed')
    assert(is(function() end), 'function is failed')
    assert(is(f), 'file is failed')
    --type checks
    assert(is.str(''), 'is.str failed')
    assert(is.num(0), 'is.num failed')
    assert(is.bool(true), 'is.bool failed')
    assert(is.tbl({}), 'is.tbl failed')
    assert(is.func(function() end), 'is.func failed')
    assert(is.file(f), 'is.file failed')
    assert(is.string(''), 'is.string failed')
    assert(is.number(0), 'is.number failed')
    assert(is.boolean(true), 'is.boolean failed')
    assert(is.table({}), 'is.table failed')
    assert(is.userdata(f), 'is.userdata failed')
    f:close()
    end,
  Not = function()
    assert(Not(nil), 'nil Not failed')
    assert(Not(0), 'number Not failed')
    assert(Not(false), 'boolean Not failed')
    assert(Not(''), 'string(0) Not failed')
    assert(Not({}), 'table(0) Not failed')
    assert(is(true) == not is.Not(true), 
      'is and is.Not did not return opposite results')
    end,
  requal = function()
    assert(requal({'a'}, {'a'}), 'Basic tables not requal')
    assert(requal(
        {a = {b = {1, 2}, c = {3, 4}}}, 
        {a = {b = {1, 2}, c = {3, 4}}}),  'Nested tables not requal')
    assertEqual(requal(
        {a = {b = {1, 2}, c = {3, 4}, d = {5, 6}}}, 
        {a = {g = {1, 2}, c = {5, 4}}}), false, 'Different nested tables requal')
  end,

  ------------------------------ Math Tests ---------------------------------
  count = function() 
    assertEqual(count(1, {1,1,2}), 2, 'Incorrect integer count')
    assertEqual(count('a', 'aab'), 2, 'Incorrect character count')    
  end,
  div = function()
    assertEqual(div(3, 4), 0, 'Bad floor division no remainder')
    assertEqual(div(4, 3), 1, 'Bad floor division remainder')
  end,
  len = function() 
    assertEqual(len({1,2,3}), 3, 'Incorrect table length') end,
  round = function()
    assertEqual(round(0.12, 1), 0.1, 'Decimal rounding incorrect')
    assertEqual(round(0.15, 1), 0.2, 'Decimal rounding incorrect')
    assertEqual(round(1.15, 0), 1, 'Number rounding incorrect')
    assertEqual(round(1.55, 0), 2, 'Number rounding incorrect')
    assertEqual(round(12.15, -1), 10, '10s rounding incorrect')
    assertEqual(round(15.15, -1), 20, '10s rounding incorrect')
    end,
  sign = function() 
    assertEqual(sign(10.2), 1, 'Positive sign incorrect')
    assertEqual(sign(-0.1), -1, 'Negative sign incorrect')
    assertEqual(sign(0), 1, 'Zero sign incorrect')
    end,
  sum = function() 
    assertEqual(sum({1,2,3}), 6, 'Number sum incorrect') end,
}),
test("itertools tests", {
   map = function ()
      local input = { 1, 2, 3, 4, 5 }
      local l = itertools.collect(itertools.map(function (x) return x + 1 end,
                             itertools.each(input)))
      for i = 1, #l do
         assertEqual(i + 1, l[i])
      end
   end,
   cycle = function ()
      local nextvalue = itertools.cycle(itertools.values { "foo", "bar" })
      for i = 1, 10 do
         assertEqual("foo", nextvalue())
         assertEqual("bar", nextvalue())
      end
   end,
  takewhile = function ()
      local data = { 1, 1, 1, 1, -1, 1, -1, 1, 1 }
      local result = itertools.collect(itertools.takewhile(function (x) return x > 0 end,
                                                 itertools.values(data)))
      assertEqual(4, #result)
      for _, v in ipairs(result) do
         assertEqual(1, v)
      end
   end,
   filter = function ()
      local data = { 6, 1, 2, 3, 4, 5, 6 }
      local result = itertools.collect(itertools.filter(function (x) return x < 4 end,
                                              itertools.values(data)))
      assertEqual(3, #result)
      for i, v in ipairs(result) do
         assertEqual(i, v)
      end
   end,
   count = function ()
      local nextvalue = itertools.count()
      for i = 1, 10 do
         assertEqual(i, nextvalue())
      end
      
      nextvalue = itertools.count(10)
      for i = 10, 20 do
         assertEqual(i, nextvalue())
      end
      
      nextvalue = itertools.count(nil, 2)
      for i = 1, 10, 2 do
         assertEqual(i, nextvalue())
      end
      
      nextvalue = itertools.count(10, 5)
      for i = 10, 30, 5 do
         assertEqual(i, nextvalue())
      end
      
      nextvalue = itertools.count(10, -1)
      for i = 10, 1, -1 do
         assertEqual(i, nextvalue())
      end
   end,
   islice = function ()
      local function check(result, nextvalue)
      local count = 0
      for _, v in ipairs(result) do
         assertEqual(v, nextvalue())
         count = count + 1
      end
      assertEqual(count, #result)
    end

    local input = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }

    check({ 5, 6, 7, 8, 9, 10 },
          itertools.islice(itertools.values(input), 5))
    check({ 1, 2, 3, 4 },
          itertools.islice(itertools.values(input), nil, 5))
    check({ 4, 5, 6, 7 },
          itertools.islice(itertools.values(input), 4, 7))
    check({ 5 }, itertools.islice(itertools.values(input), 5, 6))
    check({}, itertools.islice(itertools.values(input), 7, 3))
 end,
 sorted=function ()
      local data = { 1, 45, 9, 2, -2, 42, 0, 42 }
      local sorted = itertools.collect(itertools.sorted(itertools.values(data)))
      assertEqual(#data, #sorted)
      table.sort(data)
      for i = 1, #data do
         assertEqual(data[i], sorted[i])
      end
      
      data = { 1, 45, 9, 2, -2, 42, 0, 42 }
      sorted = itertools.collect(itertools.sorted(itertools.values(data), nil, true))
      assertEqual(#data, #sorted)
      table.sort(data, function (a, b) return a >= b end)
      for i = 1, #data do
         assertEqual(data[i], sorted[i])
      end
     
      data = { { z = 1 }, { z = 0 }, { z = 42 }, { z = -1 } }
      sorted = itertools.collect(itertools.sorted(itertools.values(data),
                                  function (v) return v.z end))
      assertEqual(#data, #sorted)
      table.sort(data, function (a, b) return a.z < b.z end)
      for i = 1, #data do
         assertEqual(data[i], sorted[i])
      end
   end
}),
test('requests tests', {
  get_json = function()
    local url = 'http://httpbin.org/get'
    local resp = requests.get(url)
    assert(resp, 'Json request did not return response')
    local j = resp:json()
    assert(j.headers, 'Incorrect json returned')
    assert(j.origin, 'Incorrect json returned')
    assertEqual(j.url, url, 'Incorrect json returned')
  end,
  post_json = function()
    local resp = requests.post{'http://httpbin.org/post', data={amount=10}}
    assertEqual(str(resp:json().form.amount), '10', 'Did not post correct data')
  end,
  get_text = function()
    local resp = requests.get('https://httpbin.org/base64/SFRUUEJJTiBpcyBhd2Vzb21l')
    assert(resp, 'Text request did not return response')
    assertEqual(resp.text, 'HTTPBIN is awesome', 'Incorrect text returned')
  end
  }),
test('string tests', {
  startswith = function() 
     assert(('\nabc'):startswith('\n'), 'Startswith \\n')
     assert(not ('abc'):startswith('\n'), 'Not Startswith \\n')
    end,
  endswith = function() 
    assert(('abc\n'):endswith('\n'), 'Endswith \\n')
    assert(not ('abc'):endswith('\n'), 'Not endswith \\n')
    end,
  format = function() 
    local o = 'Hello {}, {} and {}'
    local x = 'Hello {:-8}, {:2}, {:3}'
    local y = 'hello {j}, i am {d}'
    local eo = 'Hello jayjay, bob and 1000'
    local ex = 'Hello k       , bob, 1000'
    local ey = 'hello john, i am djordje'
    assertEqual(o:format('jayjay', 'bob', 1000), eo, 'Bad string format')
    assertEqual(x:format('k', 'bob', 1000), ex, 'Bad string format')
    assertEqual(y:format{j='john', d='djordje'}, ey, 'Bad string format')
    assertEqual(('%s, %d'):format('hello', 100), 'hello, 100', 'Bad string format')
    end,
  join = function() 
    assertEqual(('\n'):join({'a', 'b'}), 'a\nb', 
      'String join table failed')
    assertEqual(('\n'):join(list{'a', 'b'}), 'a\nb', 
      'String join list failed')
    end,
  replace = function()  
    assertEqual(('abcba'):replace('b', 'q'), 'aqcqa', 'String replacement incorrect') end,
  split = function()  
    local s1 = 'abc'
    local s2 = 'aabbcc'
    local s3 = 'a 20 300 dddd'
    assertRequal(s1:split(), {'a', 'b', 'c'}, 'Split with no args')
    assertRequal(s1:split('b'), {'a', 'c'}, 'Split with char arg')
    assertRequal(s2:split('bb'), {'aa', 'cc'}, 'Split with string arg')
    assertRequal(s3:split(' '), {'a', '20', '300', 'dddd'}, 'Split with spaces')
    end,
  strip = function()
    local x = 'abacbabacabab'
    local expected = 'cbabac'
    assertEqual(x:strip('ab'), expected, 'String not stripped correctly')
    end,
  str_add = function() 
    assertEqual('a' + 'b', 'ab', 'String add incorrect')    end,
  str_mul = function () 
    assertEqual('ab' * 2, 'abab', 'String mul incorrect') end,
  str_pairs = function() 
    local c = 1
    local _t = {'a', 'b', 'c'}
    for i, v in pairs('abc') do 
      assertEqual(i, c, 'String pairs index incorrect')
      assertEqual(v, _t[c], 'String pairs value incorrect')
      c = c + 1 
    end
  end,
  str_index = function() 
    local s = 'abc'
    for i, v in pairs(string) do
      assert(Not.Nil(s[i]), 'string missing function '..i)
    end
    assertEqual(s[1], 'a', 'Positive string index failed')
    assertEqual(s[-1], 'c', 'Negative string index failed')
  end,
}),
test('contextlib tests', {
  Exception = function()
    local Ex = Exception('Ex')
--    local x, y = tostring(Ex), tostring(Ex())
--    local s = ''
--    for i, v in pairs(x) do 
--      if y[i] ~= v then s = s..v end
--    end
--    print(x, y)
--    print(s)
    --assertEqual(tostring(Ex), tostring(Ex()),  
    --  'Exceptions return different messages')
    --local _, e1 = pcall(error, tostring(Ex))
    --local _, e2 = pcall(error, tostring(Ex()))
    --assertRequal(e1, e2, 'Exceptions return different messages')
    end,
  try = function()
    local result = try(function() return 1 end)
    assertEqual(result, 1, 'try did not return function result')
    result = try(function() error() end, function() end)
    assertEqual(result, nil, 'Failing try did not return nil')
    local l = list()
    result = try(
      function() l:append(1) error() end, 
      function() l:append(2) end, 
      function() l:append(3) end
      )
    assertEqual(result, nil, 'Failing try did not return nil')
    assertEqual(l, list{1,2,3}, 
      'Incorrect execution order for try, except, finally')
    end,
  except = function()
    local l = list()
    local x
    assertEqual(except()('err'), nil, 'Empty except returned exception')
    assertEqual(except(function(err) return err end)('err'), 'err', 
      'Return exception except did not return exception')
    x = except(
        '.*',
        function(err) l:append(err) end
        )('err')
    assertEqual(l[-1], 'err', 'Catch all except did not append error')
    assertEqual(x, nil, 'Caught exception returned error')
    x = except(
        'err',
        function(err) l:append(err) end
        )('err')
    assertEqual(l[-1], 'err', 'Catch err except did not return error')
    assertEqual(x, nil, 'Caught exception returned error')
    x = except(
        {'err'},
        function(err) l:append(err) end
        )('err')
    assertEqual(l[-1], 'err', 'Catch {err} except did not return error')
    assertEqual(x, nil, 'Caught exception returned error')
    x = except(
        'arbitrary',
        function(err) l:append(err) end
        )('errortastic')
    assertEqual(l[-1], 'err', 'Catch arbitrary except returned error')
    assertEqual(x, 'errortastic', 'Uncaught exception did not return error')
    local Ex = Exception('Ex')
    local e = Ex('err1')
    x = except(
        Ex,
        function(err) l:append(tostring(err):split('\n')[1]) end
        )(e)
    assertEqual(l[-1], '<Ex> err1', 'Did not catch Exception')
    assertEqual(x, nil, 'Caught Exception returned error')
    local e = Ex('err2')
    x = except(
        'arbitrary',
        function(err) l:append(tostring(err):split('\n')[1]) end
        )(e)
    assertEqual(l[-1], '<Ex> err1', 'Did not catch Exception')
    assertEqual(x, e, 'Caught Exception returned error')
    end,
  try_except = function()
    local Ex = Exception('Ex')
    local e = Ex('err1')
    local exFail = function() error(e) end
    local l = list()
    --successful try
    local result = try(
      exFail,
      except()
    )
    assertEqual(result, nil, 'TryExceptPass did not return nil')
    result = try(
      exFail,
      except(Ex)
    )
    assertEqual(result, nil, 'Caught exception did not return nil')
    result = try(
      exFail,
      except('.*', function(e) l:append(e) end)
    )
    assertEqual(result, nil, 'Caught exception did not return nil')
    assertEqual(l[-1], e, 'Catch function did not execute')
    result = try(
      exFail,
      except(Ex, function(e) l:append('a') end)
    )
    assertEqual(result, nil, 'Caught exception did not return nil')
    assertEqual(l[-1], 'a', 'Catch function did not execute')
    --failing try
    assertRaises(Ex, function() 
        try(
          exFail,
          except('sdfsdfsdf')
        )
      end, 'Uncaught exception did not raise')
    assertRaises(Ex, function() 
        try(
          exFail,
          except(Exception('other'))
        )
      end, 'Uncaught exception did not raise')
    assertRaises(Ex, function() 
        try(
          exFail,
          except({Exception('other'), Exception('other2')})
        )
      end, 'Uncaught exception did not raise')
    assertRaises(Ex, function() 
        try(
          exFail,
          except({'asdsdf', 'sfsdfsdf'})
        )
      end, 'Uncaught exception did not raise')
    assertRaises(Ex, function() 
        try(
          exFail,
          except({Exception('other'), Exception('other2')})
        )
      end, 'Uncaught exception did not raise')
   end,
  try_except_nested = function()
    local Ex = Exception('Ex')
    local Ex2 = Exception('Xe2')
    local e = Ex('err1')
    local e2 = Ex2('err1')
    local l = list()
    result = try(
      function() error(e) end,
      except(Ex, function() 
          try(
            function() error(e2) end,
            except(function(err) l:append(err) end)
            )
          end)
    )
    assertEqual(result, nil, 'Caught exception did not return nil')
    assertEqual(l[-1], e2, 'Caught exception returned incorrect error')
    assertRaises(Ex2, function() 
        try(
          function() error(e) end,
          except(Ex, function() 
              try(
                function() error(e2) end,
                except(Ex, function(err) l:append('a') end)
              )
            end)
          )
      end, 'Uncaught exception did not raise')
    assertEqual(l[-1], e2, 'Caught exception returned incorrect error')
    end,
  ContextManager = function()
    local l = list()
    local Q = class('Q', ContextManager)
    function Q:__enter()
      l:append(1)
      return 2
    end
    function Q:__exit(_type, value)
      ContextManager.__exit(self, _type, value)
      l:append(3)
    end
    with(Q(), function(v) l:append(v) end)
    assertEqual(l, list{1,2,3}, 'with ContextManager: incorrect execution order')
    end,
  contextmanager = function()
    local l = list()
    local q = contextmanager(function(a) 
        l:append(1)
        yield(a)
        l:append(3)
        end)
    with(q(2), function(v) l:append(v) end)
    assertEqual(l, list{1,2,3}, 'with contextmanager: incorrect execution order')
    end,
  open = function(self)
    with(open('_tmp_tst/t.txt', 'w'), function(f) f:write('hello') end)
    assert(type(self.l[1] == 'userdata'), 'with open did not open a file')
    assertRaises(
      'attempt to use a closed file',  
      function() self.l[1]:read() end, 
      'with open did not close file after operation'
    )
    assert(isFile('_tmp_tst/t.txt'), 'open did not create file')
    assertEqual(readLines('_tmp_tst/t.txt'), list{'hello'}, 
      'with open did not write to file')
    end,
  suppress = function()
    assertEqual(with(suppress(), function() error(ValueError) end), nil,
      'Empty suppress raised error')
    assertEqual(with(suppress('.*'), function() error(ValueError) end), nil,
      'All suppress returned error')
    assertEqual(with(suppress(ValueError), function() error(ValueError) end), nil,
      'ValueError suppress returned error')
    assertRaises(ValueError, function()
        with(suppress(AssertionError), function() error(ValueError) end)
      end, 'AssertionError suppress did not return error')
    
    end,
  },
  function(self) 
    self.l = list()
    self._open = io.open
    io.open = function(...) 
      local f = self._open(...)
      self.l:append(f) 
      return f 
    end
    exe('mkdir _tmp_tst')
  end,
  function(self)
    exe('rm -R _tmp_tst')
    io.open = self._open
  end
  ),

}
if is.Nil(rootDir) then os.exit(num(failed)) end
