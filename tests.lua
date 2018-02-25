require("AutoTouchPlus")

-------------------------------AutoTouch mocking --------------------------- 
alert = alert or print
rootDir = rootDir or function() return '.' end
tap = tap or function(x, y) print('tapping', x, y) end
usleep = usleep or function(t) sleep(t / 1000000) end
----------------------------------------------------------------------------

local failed
failed = failed or test('class tests', {
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
    end
})

failed = failed or test('core, math and string tests', {
  ------------------------------ Core Tests ---------------------------------  
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
    assertEqual(math.max(unpack_(t)), max(t), 'table max not same as math.max')
    assertEqual(math.max(unpack_(t)), max(l), 'list max not same as math.max')
    assertEqual(math.max(unpack_(t)), max(s), 'set max not same as math.max')
    end,
  min = function()
    local l, s, t = list{2,1,3}, set{3,2,1}, {3,1,2}
    assertEqual(math.min(unpack_(t)), min(t), 'table min not same as math.min')
    assertEqual(math.min(unpack_(t)), min(l), 'list min not same as math.min')
    assertEqual(math.min(unpack_(t)), min(s), 'set min not same as math.min')
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
    end,
  ------------------------------ Logic Tests --------------------------------
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
  ------------------------------ String Tests -------------------------------
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
})

failed = failed or test('dict tests', {
  dict_creation = function(self)
    assertNotRequal(self.a, self.b, 'Different dicts requal')
    assertRequal(self.a, {}, 'Dict and table not requal')
    assertRequal(self.b, {a=1, b=2}, 'Dict and table not requal')
    assertEqual(self.a['thing'], nil, 'Unknown key does not return nil')
    end,
  dict_addition = function(self)
    assertEqual(self.a + self.b, self.b, 'Added dicts not equal')
    assertEqual(self.b + {b=9}, dict{a=1, b=9}, 'Added dicts not equal')
    end,
  dict_equality = function(self)
    self.a:update(self.b)
    assertEqual(self.a, self.b, 'Dicts not equal')
    assertRequal(self.a, {a=1, b=2}, 'Dict and table not requal')
    assertNotEqual(self.a, {a=1, b=2}, 'Dict and table equal')
    end,
  dict_for = function(self)
    local expected
    local expected1 = {'a', 'b'}
    local expected2 = {'b', 'a'}
    local i = 1
    local st = false
    for k in self.b() do 
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
    for i, v in pairs(self.b) do
      assertEqual(v, expected[i], 'Pairs returns incorrect result')
    end
    end,
  clear = function(self)
    self.a:clear()
    self.b:clear()
    assertEqual(self.a, self.b, 'Dict not empty after clear')
    end,
  contains = function(self)
    assert(not self.b:contains('q'), 'Dict contains unknown key')
    assert(self.b:contains('a'), 'Dict does not contain key')
    end,
  get = function(self)
    assertEqual(self.b:get('a'), 1, 'Dict get incorrect for known key')
    assertEqual(self.b:get('q'), nil, 'Dict get incorrect for unknown key')
    assertEqual(self.b:get('a', 5), 1, 'Dict get incorrect for known key with default')
    assertEqual(self.b:get('q', 5), 5, 'Dict get incorrect for unknown key with default')
    end,
  keys = function(self)
    assert(Not(self.a:keys(), 'Incorrect dict keys'))
    for i, v in pairs({'a', 'b'}) do
      assert(isin(v, self.b:keys()), 'Dict key not found')
    end
    end,
  set = function(self)
    self.b:set('b', 5)
    assertEqual(self.b['b'], 5, 'Incorrect value after set')
    end, 
  update = function(self)
    self.a:update(self.b)
    assertEqual(self.a, self.b, 'Dicts not equal after update')
    end,
  values = function(self)
    assert(Not(self.a:values(), 'Incorrect dict values'))
    for i, v in pairs({1, 2}) do
      assert(isin(v, self.b:values()), 'Dict value not found')
    end
    end,
  },
  function(self) 
    self.a = dict()
    self.b = dict{a=1, b=2}
    end)

failed = failed or test('list tests', {
  list_creation = function(self)
    assertNotEqual(self.a, self.b, 'Different lists are equal')
    assertNotEqual(self.a, self.c, 'Different lists are equal')
    assertNotEqual(self.b, self.c, 'Different lists are equal')
    assertEqual(self.a, list(), 'List and new list not equal')
    assertEqual(self.b, list{1,2,3}, 'List and new list not equal')
    assertEqual(self.c, list{1,{2, 3}}, 'List and new list not equal')
    assertRequal(self.a, {}, 'List and table not requal')
    assertRequal(self.b, {1,2,3}, 'List and table not requal')
    assertRequal(self.c, {1,{2, 3}}, 'List and table not requal')
    end,
  list_addition = function(self)
    assertRequal(self.a + self.b, self.b, 'Added lists returned incorrect list')
    assertRequal(self.b + list{5}, {1,2,3,5}, 'Added lists returned incorrect list')
    assertRequal(list{5} + self.b, {5,1,2,3}, 'Added lists returned incorrect list')
    end,
  list_equality = function(self)
    assertEqual(self.a, list(), 'Lists not equal')
    assertRequal(self.a, {}, 'List not requals table')
    assertNotEqual(self.a, {}, 'List equals table')
    assertRequal(self.b, {1,2,3}, 'List not requals table')
    assertEqual(self.b, list{1,2,3}, 'Lists not equal')
    assertNotEqual(self.b, {1,2,3}, 'List equals table')
    end,
  list_for = function(self)
    local count = 0
    local expected = {1, 2, 3}
    for v in self.b() do 
      count = count + 1
      assertEqual(v, expected[count], 'Unknown element returned')
    end
    assertEqual(count, len(self.b), 'Incorrect number of elements')
    end,
  list_indexing = function(self)
    assertEqual(self.b[2], 2, 'Positive index returned incorrect result')
    assertEqual(self.b[-2], 2, 'Negative index returned incorrect result')
    end,  
  list_pairs = function(self)
    local expected = {1,2,3}
    for i, v in pairs(self.b) do
      assertEqual(v, expected[i], 'Incorrect item returned in list pairs')
    end
    end,
  list_slicing = function(self)
    assertEqual(self.b(1), self.b, 'list slice failed')
    assertEqual(self.b(1, 2), list{1,2}, 'list slice failed')
    assertEqual(self.b(1, 3), self.b, 'list slice failed')
    assertEqual(self.b(1, -2), list{1,2}, 'list slice failed')
    assertEqual(self.b(3, 1, -1), reversed(self.b), 'list slice failed')
    assertEqual(self.b{2, -1, 1}, list{2, 3, 1}, 'list slice failed')
    end,
  append = function(self)
    self.a:append(5)
    assertEqual(self.a, list{5}, 'List and new list not equal')
    assertEqual(self.b, list{1,2,3}, 'Other lists changed after append')
    assertEqual(self.c, list{1,{2,3}}, 'Other lists changed after append')
    assertRequal(self.a, {5}, 'List and table not requal')
    assertRequal(self.b, {1,2,3}, 'Other lists changed after append')
    assertRequal(self.c, {1,{2,3}}, 'Other lists changed after append')
    end,
  contains = function(self)
    assert(self.b:contains(1), 'List does not contain number')
    assert(self.c:contains({2,3}), 'List does not contain table')
    end,
  extend = function(self)
    self.a:extend{1,2}
    assertEqual(self.a, list{1,2}, 'List and new list not equal')
    assertRequal(self.a, {1,2}, 'List and table not requal')
    end,
  index = function(self)
    assertEqual(self.b:index(1), 1, 'Incorrect list index')
    end,
  insert = function(self)
    self.b:insert(2, 5)
    assertEqual(self.b, list{1,5,2,3}, 'List and new list not equal')
    assertRequal(self.b, {1,5,2,3}, 'List and table not requal')
    end,
  pop = function(self)
    assertEqual(self.b:pop(2), 2, 'Incorrect value popped from list')
    assertEqual(self.b, list{1,3}, 'List and new list not equal')
    assertRequal(self.b, {1,3}, 'List and table not requal')
    end,
  
  },
  function(self) 
    self.a =  list()
    self.b = list{1,2,3}
    self.c = list{1, {2,3}}
    end)

failed = failed or test('set tests', {
  set_creation = function(self)
    assertNotRequal(self.a, self.b, 'Different sets requal')
    assertRequal(self.a, {}, 'Set and table not requal')
    assertRequal(self.b, set{1,2,3}, 'Same sets not requal')
    end,
  set_equality = function(self)
    assertEqual(self.a, set(), 'Empty sets not equal')
    assertEqual(self.b, set{1, 2, 3}, 'Number sets not equal')
    assertEqual(self.c, set{'a', 'b', 'c'}, 'String sets not equal')
    assertNotEqual(self.b, {1, 2, 3}, 'Set and table equal')
    assertRequal(self.b, {1, 2, 3}, 'Set and table not requal')
    end,
  set_for = function(self)
    local count = 0
    for v in self.b() do 
      count = count + 1
      assert(isin(v, self.b), 'Unknown element returned')
    end
    assertEqual(count, len(self.b), 'Incorrect number of elements')
    end,
  set_pairs = function(self)
    for _, s in pairs({self.b, self.c}) do
      for k, v in pairs(s) do
        assertEqual(k, str(hash(v)), 'Set key is not hash of value')
      end
    end
    end,
  add = function(self)
    self.a:add(1)
    assertEqual(self.a, set{1}, 'Did not add element to set')
    assertEqual(len(self.a), 1, 'Incorrect number of elements after add')
    self.a:add(1)
    assertEqual(self.a, set{1}, 'Added already existing element to set')
    assertEqual(len(self.a), 1, 'Incorrect number of elements after add')
    self.a:add(2)
    self.a:add(3)
    assertEqual(self.a, self.b, 'Did not add elements to set')
    end,
  clear = function(self)
    self.b:clear()
    assertEqual(self.a, self.b, 'Did not clear set')
    self.c:clear()
    assertEqual(self.a, self.c, 'Did not clear set')
    end,
  contains = function(self)
    assert(self.b:contains(1), 'Set does not contain number element')
    assert(self.c:contains('b'), 'Set does not contain string element')
    end,
  difference = function(self)
    assertEqual(self.b - set{1}, set{2, 3}, 'Set subtraction with number items failed')
    assertEqual(self.c - set{'a', 'c'}, set{'b'}, 'Set subtraction with string items failed')
    end,
  pop = function(self)
    assertEqual(self.b:pop(1), 1, 'Did not return correct number value from pop')
    assertEqual(self.b, set{2, 3}, 'Did not number value from set after pop')
    assertEqual(self.c:pop('c'), 'c', 'Did not return correct number value from pop')
    assertEqual(self.c, set{'a', 'b'}, 'Did not number value from set after pop')
    end,
  remove = function(self)
    self.b:remove(2)
    assertEqual(self.b, set{1, 3}, 'Did not remove number item from set')
    self.c:remove('b')
    assertEqual(self.c, set{'a', 'c'}, 'Did not remove number item from set')
    end,
  update = function(self)
    self.a:update(self.b)
    assertEqual(self.a, self.b, 'Update of empty set incorrect')
    assertEqual(self.b + self.c, set{'a', 'b', 'c', 1, 2, 3}, 'Addition of filled sets incorrect')
    end,
  values = function(self)
    for k, v in pairs(self.a:values()) do
      assert(self.a:contains(v), 'Set does not contain number element in values')
    end
    for k, v in pairs(self.b:values()) do
      assert(self.b:contains(v), 'Set does not contain string element in values')
    end
    end,
  },
  function(self)
    self.a =  set()
    self.b = set{1,2,3}
    self.c = set{'a', 'b', 'c'}
    end)


failed = failed or test('error tests', {
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
    end
})
failed = failed or test('contextlib tests', {
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
      function() self.l[1]:close() end, 
      'with open did not close file after operation'
      )
    assert(isFile('_tmp_tst/t.txt'), 'open did not create file')
    assertEqual(readLines('_tmp_tst/t.txt'), list{'hello'}, 
      'with open did not write to file')
    end,
  closing = function(self)
    local fl = io.open('_tmp_tst/t.txt', 'w')
    with(closing(fl), function(f) f:write('hello') end)
    assert(type(self.l[1] == 'userdata'), 'with open did not open a file')
    assertRaises(
      'attempt to use a closed file',  
      function() self.l[1]:close() end, 
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
  )

failed = failed or test('requests tests', {
--  get_json = function()
--    local resp = requests.get('http://httpbin.org/ip')
--    assert(resp, 'Json request did not return response')
--    local j = resp:json()
--    assert(j.origin, 'Incorrect json returned')
--  end,
--  get_text = function()
--    local txt
--    local base = 'https:/github.com/sentrip/AutoTouchPlus'
--    local url = base..'/blob/master/AutoTouchPlus/AutoTouchPlus.lua'
--    local resp = requests.get{url, params={raw=1}, verify=false}
--    assert(resp, 'Text request did not return response')
--    with(open('AutoTouchPlus.lua'), function(f) txt = f:read('*a') end)
--    assertEqual(txt, resp.text, 'Incorrect text returned')
--  end
  },
  function(self) 
    end)

failed = failed or test('screen tests', {
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
    end)

failed = failed or test('system tests', {  
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
    assertEqual(find{dir='src'}, './src', 
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
    assert(pathExists('/usr'), '/usr does not exist')
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
    --Don't know why text files are so drastically different in size
    --Accross linux and IOS (respectively)
    assert(size == 12 or size == 4, 'Incorrect file size') 
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
    os.execute('mkdir _tmp_tst') 
    os.execute('echo "line1\nline2\nline3" > _tmp_tst/t.txt')
    os.execute('echo "1\n2\n3" > _tmp_tst/t1.txt')
    end,
  function() 
    os.execute('rm -r _tmp_tst') 
    if isDir('_tmp_tst2') then os.execute('rm -R _tmp_tst2') end
    end)

--modified from https://github.com/torch/argcheck/blob/master/test/test.lua
local env = require('src/argcheck').env
failed = failed or test('argcheck tests', {
    all = function()
      function addfive(x)
         return string.format('%f + 5 = %f', x, x+5)
      end

      check = argcheck{
         {name="x", type="number"}
      }

      function addfive(...)
         local x = check(...)
         return string.format('%f + 5 = %f', x, x+5)
      end

      assert(addfive(5) == '5.000000 + 5 = 10.000000')
      assert(not pcall(addfive))

      check = argcheck{
         {name="x", type="number", default=0}
      }

      assert(addfive() == '0.000000 + 5 = 5.000000')


      check = argcheck{
         help=[[
      This function is going to do a simple addition.
      Give a number, it adds 5. Amazing.
      ]],
         {name="x", type="number", default=0, help="the age of the captain"},
         {name="msg", type="string", help="a message"}
      }

      function addfive(...)
        local x, msg = check(...)
        return string.format('%f + 5 = %f [msg=%s]', x, x+5, msg)
      end

      assert(addfive(4, 'hello world') == '4.000000 + 5 = 9.000000 [msg=hello world]')
      assert(addfive('hello world') == '0.000000 + 5 = 5.000000 [msg=hello world]')

      check = argcheck{
        {name="x", type="number"},
        {name="y", type="number", defaulta="x"}
      }

      function mul(...)
         local x, y = check(...)
         return string.format('%f x %f = %f', x, y, x*y)
      end

      assert(mul(3,4) == '3.000000 x 4.000000 = 12.000000')
      assert(mul(3) == '3.000000 x 3.000000 = 9.000000')

      idx = 0
      check = argcheck{
         {name="x", type="number"},
         {name="y", type="number", defaultf=function() idx = idx + 1 return idx end}
      }

      function mul(...)
         local x, y = check(...)
         return string.format('%f x %f = %f', x, y, x*y)
      end

      assert(mul(3) == '3.000000 x 1.000000 = 3.000000')
      assert(mul(3) == '3.000000 x 2.000000 = 6.000000')
      assert(mul(3) == '3.000000 x 3.000000 = 9.000000')

      check = argcheck{
        {name="x", type="number", default=0, help="the age of the captain"},
        {name="msg", type="string", help="a message", opt=true}
      }

      function addfive(...)
         local x, msg = check(...)
         return string.format('%f + 5 = %f [msg=%s]', x, x+5, msg)
      end

      assert(addfive('hello world') == '0.000000 + 5 = 5.000000 [msg=hello world]')
      assert(addfive() == '0.000000 + 5 = 5.000000 [msg=nil]')

      check = argcheck{
        {name="x", type="number", help="a number between one and ten",
          check=function(x)
                  return x >= 1 and x <= 10
                end}
      }

      function addfive(...)
         local x = check(...)
         return string.format('%f + 5 = %f', x, x+5)
      end

      assert(addfive(3) == '3.000000 + 5 = 8.000000')
      assert( not pcall(addfive, 11))

      check = argcheck{
        {name="x", type="number", default=0, help="the age of the captain"},
        {name="msg", type="string", help="a message", opt=true}
      }

      function addfive(...)
         local x, msg = check(...)
         return string.format('%f + 5 = %f [msg=%s]', x, x+5, msg)
      end

      assert(addfive(1, "hello world") == '1.000000 + 5 = 6.000000 [msg=hello world]')
      assert(addfive{x=1, msg="hello world"} == '1.000000 + 5 = 6.000000 [msg=hello world]')

      check = argcheck{
         pack=true,
         {name="x", type="number", default=0, help="the age of the captain"},
         {name="msg", type="string", help="a message"}
      }

      function addfive(...)
         local args = check(...) -- now arguments are stored in this table
         return(string.format('%f + 5 = %f [msg=%s]', args.x, args.x+5, args.msg))
      end

      assert(addfive(5, 'hello world') == '5.000000 + 5 = 10.000000 [msg=hello world]')

      check = argcheck{
         nonamed=true,
         {name="x", type="number", default=0, help="the age of the captain"},
         {name="msg", type="string", help="a message"}
      }

      function addfive(...)
         local x, msg = check(...)
         return string.format('%f + 5 = %f [msg=%s]', x, x+5, msg)
      end

      assert(addfive('blah') == '0.000000 + 5 = 5.000000 [msg=blah]')
      assert(not pcall(addfive, {msg='blah'}))

      check = argcheck{
         quiet=true,
         {name="x", type="number", default=0, help="the age of the captain"},
         {name="msg", type="string", help="a message"}
      }

      assert(check(5, 'hello world'))
      assert(not check(5))

      addfive = argcheck{
         {name="x", type="number"},
         call = 
            function(x)
               return string.format('%f + 5 = %f', x, x+5)
            end
      }

      assert(addfive(5) == '5.000000 + 5 = 10.000000')
      assert(not pcall(addfive))

      checknum = argcheck{
         quiet=true,
         {name="x", type="number"}
      }

      checkstr = argcheck{
         quiet=true,
         {name="str", type="string"}
      }

      function addfive(...)

        -- first case
        local status, x = checknum(...)
        if status then
           return string.format('%f + 5 = %f', x, x+5)
        end

        -- second case
        local status, str = checkstr(...)
        if status then
          return string.format('%s .. 5 = %s', str, str .. '5')
        end

        -- note that in case of failure with quiet, the error is returned after the status
        error('invalid arguments')
      end

      assert(addfive(123) == '123.000000 + 5 = 128.000000')
      assert(addfive('hi') == 'hi .. 5 = hi5')

      addfive = argcheck{
        {name="x", type="number"},
        call =
           function(x) -- called in case of success
              return string.format('%f + 5 = %f', x, x+5)
           end
      }

      addfive = argcheck{
        {name="str", type="string"},
        overload = addfive, -- overload previous one
        call =
           function(str) -- called in case of success
              return string.format('%s .. 5 = %s', str, str .. '5')
           end
      }

      assert(addfive(5) == '5.000000 + 5 = 10.000000')
      assert(addfive('hi') == 'hi .. 5 = hi5')

      addfive = argcheck{
        {name="x", type="number"},
        call =
           function(x) -- called in case of success
              return string.format('%f + 7 = %f', x, x+7)
           end
      }

      assert(not pcall(argcheck,
                       {
                          {name="x", type="number"},
                          {name="msg", type="string", default="i know what i am doing"},
                          overload = addfive,
                          call =
                             function(x, msg) -- called in case of success
                                return string.format('%f + 5 = %f [msg = %s]', x, x+5, msg)
                             end
                       })
      )

      addfive = argcheck{
        {name="x", type="number"},
        {name="msg", type="string", default="i know what i am doing"},
        overload = addfive,
        force = true,
        call =
           function(x, msg) -- called in case of success
              return string.format('%f + 5 = %f [msg = %s]', x, x+5, msg)
           end
      }

      assert(addfive(5, 'hello') == '5.000000 + 5 = 10.000000 [msg = hello]')
      assert(addfive(5) == '5.000000 + 5 = 10.000000 [msg = i know what i am doing]')

      local foobar
      if pcall(require, 'torch') then
         local ctors = {}
         torch.class('foobar', ctors)
         foobar = ctors.foobar()
      else
         foobar = {}
         setmetatable(foobar, {__typename="foobar"})
      end
      foobar.checksum = 1234567

      foobar.addnothing = argcheck{
         {name="self", type="foobar"},
         debug=false,
         call =
            function(self)
               return self.checksum
            end
      }

      assert(foobar:addnothing() == 1234567)

      foobar.addfive = argcheck{
         {name="self", type="foobar"},
         {name="x", type="number"},
         {name="msg", type="string", default="i know what i am doing"},
         call =
            function(self, x, msg) -- called in case of success
               return string.format('%f + 5 = %f [msg = %s] [self.checksum=%s]', x, x+5, msg, self.checksum)
            end
      }

      assert(foobar:addfive(5, 'paf') == '5.000000 + 5 = 10.000000 [msg = paf] [self.checksum=1234567]')
      assert(foobar:addfive{x=5, msg='paf'} == '5.000000 + 5 = 10.000000 [msg = paf] [self.checksum=1234567]')

      assert(foobar:addfive(5) == '5.000000 + 5 = 10.000000 [msg = i know what i am doing] [self.checksum=1234567]')
      assert(foobar:addfive{x=5} == '5.000000 + 5 = 10.000000 [msg = i know what i am doing] [self.checksum=1234567]')

      foobar.addfive = argcheck{
         {name="self", type="foobar"},
         {name="x", type="number", default=5},
         {name="msg", type="string", default="wassup"},
         call =
            function(self, x, msg) -- called in case of success
               return string.format('%f + 5 = %f [msg = %s] [self.checksum=%s]', x, x+5, msg, self.checksum)
            end
      }

      assert(foobar:addfive() == '5.000000 + 5 = 10.000000 [msg = wassup] [self.checksum=1234567]')
      assert(foobar:addfive('paf') == '5.000000 + 5 = 10.000000 [msg = paf] [self.checksum=1234567]')
      assert(foobar:addfive(nil, 'paf') == '5.000000 + 5 = 10.000000 [msg = paf] [self.checksum=1234567]')
      assert(foobar:addfive(6, 'paf') == '6.000000 + 5 = 11.000000 [msg = paf] [self.checksum=1234567]')
      assert(foobar:addfive(6) == '6.000000 + 5 = 11.000000 [msg = wassup] [self.checksum=1234567]')
      assert(foobar:addfive(6, nil) == '6.000000 + 5 = 11.000000 [msg = wassup] [self.checksum=1234567]')

      assert(foobar:addfive{} == '5.000000 + 5 = 10.000000 [msg = wassup] [self.checksum=1234567]')
      assert(foobar:addfive{msg='paf'} == '5.000000 + 5 = 10.000000 [msg = paf] [self.checksum=1234567]')
      assert(foobar:addfive{x=6, msg='paf'} == '6.000000 + 5 = 11.000000 [msg = paf] [self.checksum=1234567]')
      assert(foobar:addfive{x=6} == '6.000000 + 5 = 11.000000 [msg = wassup] [self.checksum=1234567]')

      addstuff = argcheck{
         {name="x", type="number"},
         {name="y", type="number", default=7},
         {name="msg", type="string", opt=true},
         call =
            function(x, y, msg)
               return string.format('%f + %f = %f [msg=%s]', x, y, x+y, msg or 'NULL')
            end
      }

      assert(addstuff(3) == '3.000000 + 7.000000 = 10.000000 [msg=NULL]')
      assert(addstuff{x=3} == '3.000000 + 7.000000 = 10.000000 [msg=NULL]')
      assert(addstuff(3, 'paf') == '3.000000 + 7.000000 = 10.000000 [msg=paf]')
      assert(addstuff{x=3, msg='paf'} == '3.000000 + 7.000000 = 10.000000 [msg=paf]')

      assert(addstuff(3, 4) == '3.000000 + 4.000000 = 7.000000 [msg=NULL]')
      assert(addstuff{x=3, y=4} == '3.000000 + 4.000000 = 7.000000 [msg=NULL]')
      assert(addstuff(3, 4, 'paf') == '3.000000 + 4.000000 = 7.000000 [msg=paf]')
      assert(addstuff{x=3, y=4, msg='paf'} == '3.000000 + 4.000000 = 7.000000 [msg=paf]')

      assert(env.type('string') == 'string')
      assert(env.type(foobar) == 'foobar')
    end
  })
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
})
--alert is set to print for IDEs
if not failed then alert('All tests passed!') end