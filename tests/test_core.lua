require('src/test')
require('src/core')
require('src/contextlib')
require('src/objects')
require('src/string')
require('src/system')


describe('core',

  it('class_definition', function()
    --definition
    local A = class("A")
    function A:__init(value)
      self.value = value
    end
    function A:__tostring()
      return '['..self.value..']'
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
    
    local class_loc = repr(A):match('<%w+ class at (.*)')
    assert(str(A):startswith('<A class at'), 'str(class) is incorrect '..str(A))
    assert(repr(A):startswith('<A class at'), 'repr(class) is incorrect '..repr(A))
    assert(str(a):startswith('['), 'str(instance) is incorrect '..str(a))
    local instance_loc = repr(a):match('<%w+ instance at (.*)')
    assert(repr(a):startswith('<A instance at'), 'repr(instance) is incorrect '..repr(a))
    assert(class_loc ~= instance_loc, 'class and instance memory locations are the same')
  end),

  it('class_single_inheritance', function()
    local A = class("A")
    function A:__init(value)
      self.value = value
    end
    function A:add(value)
      self.value = self.value + value
    end
    local B = class("B", A)
    function B:__init(value)
      self.value2 = value
      A.__init(self, value)
    end
    local C = class("C", A)
    local a, b, c = A(1), B(10), C(1)
    assert(a.value == c.value, 'Child class with no init did not inherit and call init')
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
    assert(not a.value2, 'Parent class inherited properties of child')
    assert(b.value and b.value2, 'Did not inherit and add properties on child')
    assert(a:isinstance(A), 'Class not instance of itself')
    assert(b:isinstance(A), 'Child not instance of parent')
  end),

  it('class_multiple_inheritance', function()
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
    local B = class("B")
    function B:__init(value)
      self.value2 = value
    end
    function B:run5(value)
      return self.value2 + value * 5
    end
    local C = class("C", B, A)
    function C:__init(value)
      self.value3 = value
      A.__init(self, value)
      B.__init(self, value)
    end
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
    assert(c.value and c.value2 and c.value3, 'Did not set attributes of sub classes')
    assert(not b:isinstance(a), 'Unrelated classes are instances of eachother')
    assert(c:isinstance(A), 'Child not instance of oldest parent')
    assert(c:isinstance(B), 'Child not instance of youngest parent')
  end),

  it('class_get_set_properties', function()
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
    local B = class("B", A)
    
    a = A(1)
    assert(a.v, 'Getter property was not created on class')
    assertEqual(a.v, a.value * 2, 'Getter did not return custom value')
    a.v = -1
    assertEqual(a.v, 0, 'Setter did not set custom value')
    a.v = 10
    assertEqual(a.v, a.value * 2, 'Getter did not return custom value')
    b = B(1)
    assert(b.v, 'Getter property was not created on child class')
    assertEqual(b.v, b.value * 2, 'Getter did not return custom value with child class')
    b.v = -1
    assertEqual(b.v, 0, 'Setter did not set custom value with child class')
    b.v = 10
    assertEqual(b.v, b.value * 2, 'Getter did not return custom value with child class')
  end),

  it('copy', function()
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
  end),

  it('eval', function()
    assertEqual(eval('return 1 + 1'), 2, 'eval 1 + 1 failed')
    assertRaises('Syntax', function() eval('x =') end, 'eval of syntax error did not fail')
  end),

  it('hash', function()
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
  end),

  it('isin', function()
    assert(isin('a', 'abc'), 'Character not in string when it should be')
    assert(not isin('t', 'abc'), "Character in string when it shouldn't be")
    assert(isin('failed', 'stuff and thingsandstuffthisfailedand other'), "Sub not in string when it should be")
    assert(isin(1, {1,2,3}), 'Number not in table when it should be')
    assert(not isin(5, {1,2,3}), "Number in table when it shouldn't be")
    assert(isin({1,2,3}, {{1,2,3}, {4,5,6}}), 'Table not in nested table when it should be')
    assert(not isin({5}, {{1,2,3}, {4,5,6}}), "Table in nested table when it shouldn't be")
  end),

  it('max', function()
    local l, s, t = list{2,1,3}, set{3,2,1}, {3,1,2}
    assertEqual(math.max(unpack(t)), max(t), 'table max not same as math.max')
    assertEqual(math.max(unpack(t)), max(l), 'list max not same as math.max')
    assertEqual(math.max(unpack(t)), max(s), 'set max not same as math.max')
  end),

  it('min', function()
    local l, s, t = list{2,1,3}, set{3,2,1}, {3,1,2}
    assertEqual(math.min(unpack(t)), min(t), 'table min not same as math.min')
    assertEqual(math.min(unpack(t)), min(l), 'list min not same as math.min')
    assertEqual(math.min(unpack(t)), min(s), 'set min not same as math.min')
  end),

  it('num', function()
    assert(is.num(num(1)), 'Converted int to non number')
    assert(is.num(num(1.0)), 'Converted float to non number')
    assert(is.num(num(-1)), 'Converted negative to non number')
    assertEqual(num('1'), 1, 'Converted string int to non number')
    assertEqual(num('-1.0'), -1.0, 'Converted negative string float to non number')
  end),

  it('str', function()
    assertEqual(str(1), '1', 'str number failed')
    assertEqual(str('1'), '1', 'str string failed')
    assertEqual(str({1,2}), '{1, 2}', 'table number failed')
    assertEqual(str(list{1,2}), '[1, 2]', 'str list failed')
    assertEqual(str(list{1,list{1,2}}), '[1, [1, 2]]', 'str recursive failed')
  end),

  it('getattr', function()
    local A = class('A')
    function A:__init()
      self.val = 5
    end
    local a = A()
    assertEqual(getattr(a, 'val'), 5, 'Did not get basic class attribute')
    assertEqual(getattr(a, 't'), nil, 'Did not get basic class attribute')
    assertEqual(getattr(a, 'isinstance'), A.isinstance, 'Getattr does not get inherited methods')
  end),

  it('setattr', function()
    local A = class('A')
    function A:__init()
      self.val = 5
    end
    local a = A()
    setattr(a, 'val', 3)
    assertEqual(getattr(a, 'val'), 3, 'Did not set basic class attribute')
    assertEqual(getattr(A, 'val'), nil, 'Did set class value on instance')
  end),

  it('reversed', function()
    local l, s = {1, 2, 3}, 'abc'
    local e1, e2 = {3, 2, 1}, {'c', 'b', 'a'}
    for i, v in pairs(reversed(l)) do 
      assertEqual(e1[i], v, 'Did not reverse table correctly')
    end
    for i, v in pairs(reversed(s)) do 
      assertEqual(e2[i], v, 'Did not reverse string correctly')
    end
  end),

  it('sorted', function()
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
  end),

  it('pretty prints nested table', function(monkeypatch) 
    monkeypatch.setattr('print', function(...) return ... end)
    local text = pprint{
      n=1,
      s='a',
      t={
        n=1,
        s='a',
        t={
          d=dict{a=1, b=2},
          l=list{1, 2},
          st=set{1, 2},

        }
      },
      c=coroutine.create(function() coroutine.yield() end),
      f=io.tmpfile()
    }
    local expected = '{\n\tn = %d,\n\ts = "%w",\n\tc = thread: [%w%d]+,\n\tt = {\n\t\t'..
    'n = %d,\n\t\ts = "%w",\n\t\tt = {\n\t\t\td = {\n\t\t\t\ta = %d,\n\t\t\t\tb = %d,\n\t\t\t},'..
    '\n\t\t\tl = {%d, %d},\n\t\t\tst = {%d, %d},\n\t\t},\n\t},\n\tf = file %([%w%d]+%),\n}'
    assert(text:match(expected), 'pprint did not print correctly')
  end)
)

run_tests()
