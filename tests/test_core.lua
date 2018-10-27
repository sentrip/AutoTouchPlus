require('src/test')
require('src/core')
require('src/builtins')
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
    assert(isinstance(a, A), 'a not instance of A')
    assert(not isinstance({}, A), 'table is instance of A')
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

  it('getattr', function()
    local A = class('A')
    function A:__init()
      self.val = 5
    end
    local a = A()
    assertEqual(getattr(a, 'val'), 5, 'Did not get basic class attribute')
    assertEqual(getattr(a, 't'), nil, 'Did not get basic class attribute')
    assertEqual(getattr(a, 'isinstance'), A.isinstance, 'Getattr does not get inherited methods')
    -- TODO: __getters test
    -- TODO: __getitem test
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
    -- TODO: __setters test
    -- TODO: __setitem test
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

  it('isinstance', function() 
    -- TODO: isinstance test
  end),

  it('pprint', function(monkeypatch) 
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
  end),

  it('print', function() 
    -- TODO: print test
  end),

  it('property', function() 
    -- TODO: property test
  end),

  it('str', function()
    assertEqual(str(1), '1', 'str number failed')
    assertEqual(str('1'), '1', 'str string failed')
    assertEqual(str({1,2}), '{1, 2}', 'table number failed')
    assertEqual(str(list{1,2}), '[1, 2]', 'str list failed')
    assertEqual(str(list{1,list{1,2}}), '[1, [1, 2]]', 'str recursive failed')
  end)
)

run_tests()
