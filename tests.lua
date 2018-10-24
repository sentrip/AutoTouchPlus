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





fixture('app', function(monkeypatch) 
  local calls = list()
  monkeypatch.setattr('appRun', function() calls:append('run') end)
  monkeypatch.setattr('appKill', function() calls:append('kill') end)
  return calls
end)

fixture('temp_dir', function(monkeypatch, request) 
  local dir_name = '_tmp_tst'
  io.popen('mkdir '..dir_name):close()
  request.addfinalizer(function() io.popen('rm -R '..dir_name):close() end)
  return dir_name .. '/'
end)


describe('contextlib',

  it('Exception', function()
    -- TODO: Exception test
    --local Ex = Exception('Ex')
    --local x, y = tostring(Ex), tostring(Ex())
    --local s = ''
    --for i, v in pairs(x) do 
    --  if y[i] ~= v then s = s..v end
    --end
    --print(x, y)
    --print(s)
    --assertEqual(tostring(Ex), tostring(Ex()),  
    --  'Exceptions return different messages')
    --local _, e1 = pcall(error, tostring(Ex))
    --local _, e2 = pcall(error, tostring(Ex()))
    --assertRequal(e1, e2, 'Exceptions return different messages')
  end),

  it('try', function()
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
  end),

  it('except', function()
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
  end),

  it('try_except', function()
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
  end),
  
  it('try_except_nested', function()
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
  end),

  it('ContextManager', function()
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
  end),

  it('contextmanager', function()
    local l = list()
    local q = contextmanager(function(a) 
        l:append(1)
        yield(a)
        l:append(3)
        end)
    with(q(2), function(v) l:append(v) end)
    assertEqual(l, list{1,2,3}, 'with contextmanager: incorrect execution order')
  end),

  it('contextmanager error', function() 
    local l = list()
    local fails = contextmanager(function(b) 
      l:append(1)
      yield(b)
      error('Damn')
      l:append(3)
      end)
    assertRaises('Damn', function() 
      with(fails('v'), function(v) 
        l:append(2)
      end)
    end, 'Contextmanager did not error')
    assertEqual(l, list{1, 2}, 'Did not run erroring contextmanager correctly')
  end),

  it('nested contextmanager', function() 
    local l = list()
    local inner = contextmanager(function(b) 
      l:append('inner enter')
      yield(b)
      l:append('inner exit')
      end)
    local outer = contextmanager(function(a) 
      l:append('outer enter')
      with(inner(a), function() 
        yield(a * 2)
      end)
      l:append('outer exit')
      end)

    with(outer(1), function(v)  
        l:append(v * 10)
      end)
    assertEqual(l, list{'outer enter', 'inner enter', 20, 'inner exit', 'outer exit'},
    'Did not execute nested contextmanagers in correct order')
  end),
  
  it('nested with', function() 
    local l = list()
    local outer = contextmanager(function(a) 
      l:append('outer enter')
      yield(a)
      l:append('outer exit')
      end)
    local inner = contextmanager(function(b) 
      l:append('inner enter')
      yield(b * 2)
      l:append('inner exit')
      end)

    with(outer(1), function(v) 
      with(inner(v), function(q) 
        l:append(q * 10)
      end)
    end)
    assertEqual(l, list{'outer enter', 'inner enter', 20, 'inner exit', 'outer exit'},
    'Did not execute nested with in correct order')
  end),

  it('open', function(temp_dir)
    local fle
    with(open(temp_dir..'t.txt', 'w'), function(f) fle = f; f:write('hello') end)
    assert(type(fle == 'userdata'), 'with open did not open a file')
    -- TODO: Fix this on mobile
    -- assertRaises(
    --   'attempt to use a closed file',  
    --   function() fle:read() end, 
    --   'with open did not close file after operation'
    -- )
    assert(isFile(temp_dir..'t.txt'), 'open did not create file')
    assertEqual(readLines(temp_dir..'t.txt'), list{'hello'}, 
      'with open did not write to file')
  end),

  it('suppress', function()
    assertEqual(with(suppress(), function() error(ValueError) end), nil,
      'Empty suppress raised error')
    assertEqual(with(suppress('.*'), function() error(ValueError) end), nil,
      'All suppress returned error')
    assertEqual(with(suppress(ValueError), function() error(ValueError) end), nil,
      'ValueError suppress returned error')
    assertRaises(ValueError, function()
        with(suppress(AssertionError), function() error(ValueError) end) 
      end, 'AssertionError suppress did not return error')
  end),

  it('run_and_close', function(monkeypatch, app) 
    monkeypatch.setattr('appState', function() return 'ACTIVE' end)
    with(run_and_close('app'), function() app:append('do') end)
    assert(requal(app, {'kill', 'run', 'do', 'kill'}), 'Did not run and kill in correct order')
    app:clear()
    monkeypatch.setattr('appState', function() return 'NOT RUNNING' end)
    with(run_and_close('app', false), function() app:append('do') end)
    assert(requal(app, {'run', 'do'}), 'Did not run and kill in correct order')
  end),

  it('run_if_closed', function(monkeypatch, app) 
    monkeypatch.setattr('appState', function() return 'ACTIVE' end)
    with(run_if_closed('app'), function() app:append('do') end)
    assert(requal(app, {'do'}), 'Did not run if closed in correct order')
    app:clear()
    monkeypatch.setattr('appState', function() return 'NOT RUNNING' end)
    with(run_if_closed('app'), function() app:append('do') end)
    assert(requal(app, {'run', 'do', 'kill'}), 'Did not run if closed in correct order')
  end),

  it('time_ensured', function() 
    local time_ns = num(exe('date +%s%N'))
    with(time_ensured(0.01), function() end)
    -- TODO: Fix time_ensured for mobile
    -- local diff = round((num(exe('date +%s%N')) - time_ns) / 1000000000, 2)
    -- assert(diff == 0.01, 'Ensure time did not take correct amount of time')
  end)
)









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









describe("itertools",
  it('map', function ()
    local input = { 1, 2, 3, 4, 5 }
    local l = itertools.collect(itertools.map(function (x) return x + 1 end,
                             itertools.each(input)))
    for i = 1, #l do
         assertEqual(i + 1, l[i])
    end
    end),
  it('cycle', function ()
    local nextvalue = itertools.cycle(itertools.values { "foo", "bar" })
    for i = 1, 10 do
         assertEqual("foo", nextvalue())
         assertEqual("bar", nextvalue())
    end
    end),
  it('takewhile', function ()
    local data = { 1, 1, 1, 1, -1, 1, -1, 1, 1 }
    local result = itertools.collect(itertools.takewhile(function (x) return x > 0 end, itertools.values(data)))
    assertEqual(4, #result)
    for _, v in ipairs(result) do
      assertEqual(1, v)
    end
    end),
  it('filter', function ()
    local data = { 6, 1, 2, 3, 4, 5, 6 }
    local result = itertools.collect(itertools.filter(function (x) return x < 4 end, itertools.values(data)))
    assertEqual(3, #result)
    for i, v in ipairs(result) do
         assertEqual(i, v)
    end
    end),
  it('count', function ()
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
    end),
  it('islice', function ()
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
    end),
  it('sorted', function ()
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
    end),
  it('can repeat values', function() 
    local finite = itertools.value(1, 3)
    local infinite = itertools.value(1)
    for i=1, 3 do
      assert(finite() == 1)
      assert(infinite() == 1)
    end
    assert(finite() == nil)
    assert(infinite() == 1)
    end)
)









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









describe('logic', 
  it('all', function()
    assert(all({true, true, true}), 'All - table of booleans')
    assert(all(list{true, true, true}), 'All - list of booleans')
    assert(all({true, false, true}) == false, 'All with false - table of booleans')
    assert(all(list{true, false, true}) == false, 'All with false - list of booleans')
    assert(all({1,2,3}), 'All - table of numbers')
    assert(all(list{1,2,3}), 'All - list of numbers')
    assert(all({1,0,3}) == false, 'All with false - table of numbers')
    assert(all(set{1,0,3}) == false, 'All with false - set of numbers')
    end),
  it('any', function()
    assert(any({true, false, true}), 'Any - table of booleans')
    assert(any(list{true, false, true}), 'Any - list of booleans')
    assert(any({false, false, false}) == false, 'Any with false - table of booleans')
    assert(any(list{false, false, false}) == false, 'Any with false - list of booleans')
    assert(any({1,2,3}), 'Any - table of numbers')
    assert(any(list{1,2,3}), 'Any - list of numbers')
    assert(any({0,0,0}) == false, 'Any with false - table of numbers')
    assert(any(list{0, 0, 0}) == false, 'Any with false - list of numbers')
    end),

  it('isType', function()
    assert(isType(true, 'boolean'), 'basic isType failed')
    assert(isType(true, 'string', 'bool'), 'multi arg isType failed')
    assert(not isType(true, 'string', 'table'), 'multi arg isType failed')
    end),
  it('is', function()
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
    end),
  it('Not', function()
    assert(Not(nil), 'nil Not failed')
    assert(Not(0), 'number Not failed')
    assert(Not(false), 'boolean Not failed')
    assert(Not(''), 'string(0) Not failed')
    assert(Not({}), 'table(0) Not failed')
    assert(is(true) == not is.Not(true), 
      'is and is.Not did not return opposite results')
    end),
  it('requal', function()
    assert(requal({'a'}, {'a'}), 'Basic tables not requal')
    assert(requal(
        {a = {b = {1, 2}, c = {3, 4}}}, 
        {a = {b = {1, 2}, c = {3, 4}}}),  'Nested tables not requal')
    assertEqual(requal(
        {a = {b = {1, 2}, c = {3, 4}, d = {5, 6}}}, 
        {a = {g = {1, 2}, c = {5, 4}}}), false, 'Different nested tables requal')
    end),
  it('count', function() 
    assertEqual(count(1, {1,1,2}), 2, 'Incorrect integer count')
    assertEqual(count('a', 'aab'), 2, 'Incorrect character count')    
    end),
  it('div', function()
    assertEqual(div(3, 4), 0, 'Bad floor division no remainder')
    assertEqual(div(4, 3), 1, 'Bad floor division remainder')
    end),
  it('len', function() 
    assertEqual(len({1,2,3}), 3, 'Incorrect table length') end),
  it('round', function()
    assertEqual(round(0.12, 1), 0.1, 'Decimal rounding incorrect')
    assertEqual(round(0.15, 1), 0.2, 'Decimal rounding incorrect')
    assertEqual(round(1.15, 0), 1, 'Number rounding incorrect')
    assertEqual(round(1.55, 0), 2, 'Number rounding incorrect')
    assertEqual(round(12.15, -1), 10, '10s rounding incorrect')
    assertEqual(round(15.15, -1), 20, '10s rounding incorrect')
    end),
  it('sign', function() 
    assertEqual(sign(10.2), 1, 'Positive sign incorrect')
    assertEqual(sign(-0.1), -1, 'Negative sign incorrect')
    assertEqual(sign(0), 1, 'Zero sign incorrect')
    end),
  it('sum', function() 
    assertEqual(sum({1,2,3}), 6, 'Number sum incorrect') 
    end)
)










describe('navigation', 
  it('tree_root_nagivation', function()
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
    end),
  it('tree_lca_nagivation', function()
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
    end)
)









fixture('dict_a', function() return dict() end)
fixture('dict_b', function() return dict{a=1, b=2} end)

fixture('list_a', function() return list() end)
fixture('list_b', function() return list{1,2,3} end)
fixture('list_c', function() return list{1, {2,3}} end)

fixture('set_a', function() return set() end)
fixture('set_b', function() return set{1,2,3} end)
fixture('set_c', function() return set{'a', 'b', 'c'} end)


describe('objects - dict',

  it('creation', function(dict_a, dict_b)
    assertNotRequal(dict_a, dict_b, 'Different dicts requal')
    assertRequal(dict_a, {}, 'Dict and table not requal')
    assertRequal(dict_b, {a=1, b=2}, 'Dict and table not requal')
    assertEqual(dict_a['thing'], nil, 'Unknown key does not return nil')
  end),

  it('addition', function(dict_a, dict_b)
    assertEqual(dict_a + dict_b, dict_b, 'Added dicts not equal')
    assertEqual(dict_b + {b=9}, dict{a=1, b=9}, 'Added dicts not equal')
  end),

  it('equality', function(dict_a, dict_b)
    dict_a:update(dict_b)
    assertEqual(dict_a, dict_b, 'Dicts not equal')
    assertRequal(dict_a, {a=1, b=2}, 'Dict and table not requal')
    assertNotEqual(dict_a, {a=1, b=2}, 'Dict and table equal')
  end),

  it('for', function(dict_a, dict_b)
    local expected
    local expected1 = {'a', 'b'}
    local expected2 = {'b', 'a'}
    local i = 1
    local st = false
    for k in dict_b() do 
      if not st then
        st = true
        if k == 'a' then expected = expected1
        else expected = expected2 end
      end
      assertEqual(k, expected[i], 'incorrect key returned in for loop')
      i = i + 1
    end
  end),

  it('pairs', function(dict_a, dict_b)
    local expected = {a=1, b=2}
    for i, v in pairs(dict_b) do
      assertEqual(v, expected[i], 'Pairs returns incorrect result')
    end
  end),

  it('pop', function(dict_a, dict_b)
    assertEqual(dict_b:pop('a'), 1, 'Incorrect value popped from dict')
    assertEqual(dict_b, dict{b=2}, 'Dict and new dict not equal')
    assert(dict_b:pop(), 'Did not pop value from dict')
    assertEqual(dict_b, dict(), 'Dict and new dict not equal')
  end),

  it('clear', function(dict_a, dict_b)
    dict_a:clear()
    dict_b:clear()
    assertEqual(dict_a, dict_b, 'Dict not empty after clear')
  end),

  it('contains', function(dict_a, dict_b)
    assert(not dict_b:contains('q'), 'Dict contains unknown key')
    assert(dict_b:contains('a'), 'Dict does not contain key')
  end),

  it('get', function(dict_a, dict_b)
    assertEqual(dict_b:get('a'), 1, 'Dict get incorrect for known key')
    assertEqual(dict_b:get('q'), nil, 'Dict get incorrect for unknown key')
    assertEqual(dict_b:get('a', 5), 1, 'Dict get incorrect for known key with default')
    assertEqual(dict_b:get('q', 5), 5, 'Dict get incorrect for unknown key with default')
  end),

  it('keys', function(dict_a, dict_b)
    assert(Not(dict_a:keys(), 'Incorrect dict keys'))
    for i, v in pairs({'a', 'b'}) do
      assert(isin(v, dict_b:keys()), 'Dict key not found')
    end
  end),

  it('set', function(dict_a, dict_b)
    dict_b:set('b', 5)
    assertEqual(dict_b['b'], 5, 'Incorrect value after set')
  end), 

  it('update', function(dict_a, dict_b)
    dict_a:update(dict_b)
    assertEqual(dict_a, dict_b, 'Dicts not equal after update')
  end),

  it('values', function(dict_a, dict_b)
    assert(Not(dict_a:values(), 'Incorrect dict values'))
    for i, v in pairs({1, 2}) do
      assert(isin(v, dict_b:values()), 'Dict value not found')
    end
  end)
)


describe('objects - list',

  it('creation', function(list_a, list_b, list_c)
    assertNotEqual(list_a, list_b, 'Different lists are equal')
    assertNotEqual(list_a, list_c, 'Different lists are equal')
    assertNotEqual(list_b, list_c, 'Different lists are equal')
    assertEqual(list_a, list(), 'List and new list not equal')
    assertEqual(list_b, list{1,2,3}, 'List and new list not equal')
    assertEqual(list_c, list{1,{2, 3}}, 'List and new list not equal')
    assertRequal(list_a, {}, 'List and table not requal')
    assertRequal(list_b, {1,2,3}, 'List and table not requal')
    assertRequal(list_c, {1,{2, 3}}, 'List and table not requal')
  end),

  it('addition', function(list_a, list_b, list_c)
    assertRequal(list_a + list_b, list_b, 'Added lists returned incorrect list')
    assertRequal(list_b + list{5}, {1,2,3,5}, 'Added lists returned incorrect list')
    assertRequal(list{5} + list_b, {5,1,2,3}, 'Added lists returned incorrect list')
  end),

  it('multiplication', function(list_a, list_b)
    assertRequal(list_a * 2, list_a, 'Multiplied lists returned incorrect list')
    assertRequal(list_b * 2, list{1, 2, 3, 1, 2, 3}, 'Multiplied lists returned incorrect list')
  end),

  it('equality', function(list_a, list_b, list_c)
    assertEqual(list_a, list(), 'Lists not equal')
    assertRequal(list_a, {}, 'List not requals table')
    assertNotEqual(list_a, {}, 'List equals table')
    assertRequal(list_b, {1,2,3}, 'List not requals table')
    assertEqual(list_b, list{1,2,3}, 'Lists not equal')
    assertNotEqual(list_b, {1,2,3}, 'List equals table')
  end),

  it('for', function(list_a, list_b, list_c)
    local count = 0
    local expected = {1, 2, 3}
    for v in list_b() do 
      count = count + 1
      assertEqual(v, expected[count], 'Unknown element returned')
    end
    assertEqual(count, len(list_b), 'Incorrect number of elements')
  end),

  it('indexing', function(list_a, list_b, list_c)
    assertEqual(list_b[2], 2, 'Positive index returned incorrect result')
    assertEqual(list_b[-2], 2, 'Negative index returned incorrect result')
  end),  

  it('pairs', function(list_a, list_b, list_c)
    local expected = {1,2,3}
    for i, v in pairs(list_b) do
      assertEqual(v, expected[i], 'Incorrect item returned in list pairs')
    end
  end),

  it('slicing', function(list_a, list_b, list_c)
    assertEqual(list_b(1), list_b, 'list slice failed')
    assertEqual(list_b(1, 2), list{1,2}, 'list slice failed')
    assertEqual(list_b(1, 3), list_b, 'list slice failed')
    assertEqual(list_b(1, -2), list{1,2}, 'list slice failed')
    assertEqual(list_b(3, 1, -1), reversed(list_b), 'list slice failed')
    assertEqual(list_b{2, -1, 1}, list{2, 3, 1}, 'list slice failed')
  end),

  it('append', function(list_a, list_b, list_c)
    list_a:append(5)
    assertEqual(list_a, list{5}, 'List and new list not equal')
    assertEqual(list_b, list{1,2,3}, 'Other lists changed after append')
    assertEqual(list_c, list{1,{2,3}}, 'Other lists changed after append')
    assertRequal(list_a, {5}, 'List and table not requal')
    assertRequal(list_b, {1,2,3}, 'Other lists changed after append')
    assertRequal(list_c, {1,{2,3}}, 'Other lists changed after append')
  end),

  it('clear', function(list_a, list_b, list_c) 
    list_a:clear()
    assertEqual(len(list_a), 0, 'Did not clear list')
    assertEqual(len(list_b), 3, 'Cleared more than one list')
    assertEqual(len(list_c), 2, 'Cleared more than one list')
    list_b:clear()
    assertEqual(len(list_b), 0, 'Did not clear list')
  end),

  it('contains', function(list_a, list_b, list_c)
    assert(list_b:contains(1), 'List does not contain number')
    assert(list_c:contains({2,3}), 'List does not contain table')
  end),

  it('extend', function(list_a, list_b, list_c)
    list_a:extend{1,2}
    assertEqual(list_a, list{1,2}, 'List and new list not equal')
    assertRequal(list_a, {1,2}, 'List and table not requal')
  end),

  it('index', function(list_a, list_b, list_c)
    assertEqual(list_b:index(1), 1, 'Incorrect list index')
  end),

  it('insert', function(list_a, list_b, list_c)
    list_b:insert(2, 5)
    assertEqual(list_b, list{1,5,2,3}, 'List and new list not equal')
    assertRequal(list_b, {1,5,2,3}, 'List and table not requal')
  end),

  it('pop', function(list_a, list_b, list_c)
    assertEqual(list_b:pop(2), 2, 'Incorrect value popped from list')
    assertEqual(list_b, list{1,3}, 'List and new list not equal')
    assertRequal(list_b, {1,3}, 'List and table not requal')
    assertEqual(list_b:pop(), 1, 'Incorrect value popped from list')
    assertEqual(list_b, list{3}, 'List and new list not equal')
  end)
)


describe('objects - set',

  it('creation', function(set_a, set_b, set_c)
    assertNotRequal(set_a, set_b, 'Different sets requal')
    assertRequal(set_a, {}, 'Set and table not requal')
    assertRequal(set_b, set{1,2,3}, 'Same sets not requal')
  end),

  it('equality', function(set_a, set_b, set_c)
    assertEqual(set_a, set(), 'Empty sets not equal')
    assertEqual(set_b, set{1, 2, 3}, 'Number sets not equal')
    assertEqual(set_c, set{'a', 'b', 'c'}, 'String sets not equal')
    assertNotEqual(set_b, {1, 2, 3}, 'Set and table equal')
    assertRequal(set_b, {1, 2, 3}, 'Set and table not requal')
  end),

  it('for', function(set_a, set_b, set_c)
    local count = 0
    for v in set_b() do 
      count = count + 1
      assert(isin(v, set_b), 'Unknown element returned')
    end
    assertEqual(count, len(set_b), 'Incorrect number of elements')
  end),

  it('pairs', function(set_a, set_b, set_c)
    for _, s in pairs({set_b, set_c}) do
      for k, v in pairs(s) do
        assertEqual(k, str(hash(v)), 'Set key is not hash of value')
      end
    end
  end),

  it('add', function(set_a, set_b, set_c)
    set_a:add(1)
    assertEqual(set_a, set{1}, 'Did not add element to set')
    assertEqual(len(set_a), 1, 'Incorrect number of elements after add')
    set_a:add(1)
    assertEqual(set_a, set{1}, 'Added already existing element to set')
    assertEqual(len(set_a), 1, 'Incorrect number of elements after add')
    set_a:add(2)
    set_a:add(3)
    assertEqual(set_a, set_b, 'Did not add elements to set')
  end),

  it('clear', function(set_a, set_b, set_c)
    set_b:clear()
    assertEqual(set_a, set_b, 'Did not clear set')
    set_c:clear()
    assertEqual(set_a, set_c, 'Did not clear set')
  end),

  it('contains', function(set_a, set_b, set_c)
    assert(set_b:contains(1), 'Set does not contain number element')
    assert(set_c:contains('b'), 'Set does not contain string element')
  end),

  it('difference', function(set_a, set_b, set_c)
    assertEqual(set_b - set{1}, set{2, 3}, 'Set subtraction with number items failed')
    assertEqual(set_c - set{'a', 'c'}, set{'b'}, 'Set subtraction with string items failed')
  end),

  it('pop', function(set_a, set_b, set_c)
    assertEqual(set_b:pop(1), 1, 'Did not return correct number value from pop')
    assertEqual(set_b, set{2, 3}, 'Did not return correct value from set after pop')
    assertEqual(set_c:pop('c'), 'c', 'Did not return correct value from pop')
    assertEqual(set_c, set{'a', 'b'}, 'Did not return correct value from set after pop')
    assert(set_b:pop(), 'Did not pop any value from set')
    assertEqual(len(set_b), 1, 'Did not pop any value from set')
  end),

  it('remove', function(set_a, set_b, set_c)
    set_b:remove(2)
    assertEqual(set_b, set{1, 3}, 'Did not remove number item from set')
    set_c:remove('b')
    assertEqual(set_c, set{'a', 'c'}, 'Did not remove number item from set')
  end),

  it('update', function(set_a, set_b, set_c)
    set_a:update(set_b)
    assertEqual(set_a, set_b, 'Update of empty set incorrect')
    assertEqual(set_b + set_c, set{'a', 'b', 'c', 1, 2, 3}, 'Addition of filled sets incorrect')
  end),

  it('values', function(set_a, set_b, set_c)
    for k, v in pairs(set_a:values()) do
      assert(set_a:contains(v), 'Set does not contain number element in values')
    end
    for k, v in pairs(set_b:values()) do
      assert(set_b:contains(v), 'Set does not contain string element in values')
    end
  end)
)










fixture('touches', function(monkeypatch)
  local touches = list()
  monkeypatch.setattr('usleep', function(...) end)
  monkeypatch.setattr('touchDown', function(i, x, y) touches:append({'down', i, x, y}) end)
  monkeypatch.setattr('touchUp', function(i, x, y) touches:append({'up', i, x, y}) end)
  monkeypatch.setattr('touchMove', function(i, x, y) touches:append({'move', i, x, y}) end)
  return touches
end)


describe('path', 

  it('can stringify Path and RelativePath', function() 
    local absolute = Path{{x=0, y=0}, {x=10, y=10}}
    local relative = RelativePath{{x=0, y=0}, {x=10, y=10}}
    assert(tostring(absolute) == string.format('<Path(points=%s, duration=%.2fs)>', len(absolute.locations), absolute.duration))
    assert(tostring(relative) == string.format('<RelativePath(points=%s, duration=%.2fs)>', len(relative.locations), relative.duration))
  end),

  it('can do Path + Path', function() 
    local path = Path{{x=0, y=0}, {x=10, y=10}}
    assert(path.point_count == 2, 'Did not create path with correct number of points')
    assert(path.absolute, 'Path is not absolute')
    assert(path.locations[-1].x == 10, 'Did not add correct points to path')
    path = path + Path{{x=10, y=10}, {x=20, y=20}}
    assert(path.point_count == 3, 'Did not create path with correct number of points')
    assert(path.locations[-1].x == 20, 'Did not add correct points to path')
    path = path + Path{{x=30, y=30}, {x=40, y=40}}
    assert(path.point_count == 5, 'Did not create path with correct number of points')
    assert(path.locations[-1].x == 40, 'Did not add correct points to path')
  end),

  it('can do Path + RelativePath', function() 
    local path = Path{{x=0, y=0}, {x=10, y=10}}
    assert(path.point_count == 2, 'Did not create path with correct number of points')
    assert(path.absolute, 'Path is not absolute')
    assert(path.locations[-1].x == 10, 'Did not add correct points to path')
    path = path + RelativePath{{x=0, y=0}, {x=10, y=10}}
    assert(path.point_count == 3, 'Did not create path with correct number of points')
    assert(path.absolute, 'Path is not absolute')
    assert(path.locations[-1].x == 20, 'Did not add correct points to path')
    path = path + RelativePath{{x=10, y=10}}
    assert(path.point_count == 4, 'Did not create path with correct number of points')
    assert(path.locations[-1].x == 30, 'Did not add correct points to path')
  end),

  it('can do RelativePath + RelativePath', function() 
    local path = RelativePath{{x=0, y=0}, {x=10, y=10}}
    assert(path.point_count == 2, 'Did not create path with correct number of points')
    assert(not path.absolute, 'Path is absolute')
    assert(path.locations[-1].x == 10, 'Did not add correct points to path')
    path = path + RelativePath{{x=0, y=0}, {x=10, y=10}}
    assert(path.point_count == 3, 'Did not create path with correct number of points')
    assert(not path.absolute, 'Path is absolute')
    assert(path.locations[-1].x == 20, 'Did not add correct points to path')
    path = path + RelativePath{{x=10, y=10}}
    assert(path.point_count == 4, 'Did not create path with correct number of points')
    assert(path.locations[-1].x == 30, 'Did not add correct points to path')
  end),

  it('cannot do RelativePath + Path', function() 
    assertRaises('Can only add RelativePath objects to other RelativePath objects', function() 
      local path = RelativePath{{x=0, y=0}, {x=10, y=10}} + Path{{x=0, y=0}, {x=10, y=10}}
    end, 'RelativePath + Path did not raise error')
  end),

  it('can step through path manually', function(touches) 
    local path = Path.linear(Pixel(10, 10), Pixel(100, 100))
    local calls = list()
    local actions = list()
    screen.before_action(function() actions:append('before') end)
    screen.after_action(function() actions:append('after') end)

    for speed in iter{1, 5, 10} do
      path:begin_swipe(2, speed)
      local done, l = false, 1
      while not done do
        done = path:step(2, function() calls:append(1) end)
        assert(len(calls) == math.min(l, 50 / speed - 1), 'Did not increment calls')
        l = l + 1
      end
      assert(len(touches) == 50 / speed + 1, 'Did not touch and move correctly')
      assert(len(calls) == 50 / speed - 1, 'Did not call on_move correct number of times')
      assert(touches[1][1] == 'down', 'Did not swipe in correct order')
      assert(touches[2][1] == 'move', 'Did not swipe in correct order')
      assert(touches[-1][1] == 'up', 'Did not swipe in correct order')
      assert(len(actions) == 0, 'Called action context functions in manual step')
      touches:clear()
      calls:clear()
    end

    screen.before_action_funcs:clear()
    screen.after_action_funcs:clear()
  end),
  
  it('can swipe path', function(touches) 
    local path = Path.linear(Pixel(10, 10), Pixel(100, 100))
    local calls = list()
    local actions = list()
    screen.before_action(function() actions:append('before') end)
    screen.after_action(function() actions:append('after') end)

    for speed in iter{1, 5, 10} do
      path:swipe{speed=speed, on_move=function() calls:append(1) end}
      assert(len(touches) == 50 / speed + 1, 'Did not touch and move correctly')
      assert(len(calls) == 50 / speed - 1, 'Did not call on_move correct number of times')
      assert(touches[1][1] == 'down', 'Did not swipe in correct order')
      assert(touches[2][1] == 'move', 'Did not swipe in correct order')
      assert(touches[-1][1] == 'up', 'Did not swipe in correct order')
      assert(requal(actions, {'before', 'after'}), 'Did not call action context functions')
      touches:clear()
      calls:clear()
      actions:clear()
    end

    screen.before_action_funcs:clear()
    screen.after_action_funcs:clear()
  end),

  it('can create arc', function() 
    local absolute = Path.arc(5, 45, 90, {x=10, y=10})
    local relative = Path.arc(5, 45, 90)
    local relative_origin = Path.arc(5, 45)
    -- TODO assertions about arcs
  end),
  
  it('can create line', function() 
    local absolute = Path.linear({x=50, y=50}, {x=100, y=100})
    local relative = Path.linear({x=50, y=50})
    local relative_neg = Path.linear({x=-50, y=-50})
    assert(absolute.absolute, 'Absolute linear path not absolute')
    assert(not relative.absolute, 'Relative linear path is absolute')
    assert(absolute[1].x == 50, 'Incorrect absolute location')
    assert(relative[1].x == 0, 'Incorrect relative location')
    assert(relative_neg[-1].x == -50, 'Incorrect relative location')
  end)
)










fixture('pixels', function(monkeypatch) 
  local pixels = list{
    Pixel(10, 10, 10),
    Pixel(20, 20, 20),
    Pixel(30, 30, 30),
    Pixel(40, 40, 40),
  }
  local function _getColor(x, y) 
    for p in iter(pixels) do if p.x == x and p.y == y then return p.expected_color end end
  end
  local function _getColors(pos) 
    local colors = list()
    for p in iter(pos) do colors:append(_getColor(p[1], p[2])) end
    return colors
  end

  monkeypatch.setattr('getColor', _getColor)
  monkeypatch.setattr('getColors', _getColors)
  return pixels
end)


describe('pixel - Pixel', 

  it('can create and hash pixel objects', function() 
    local pixels = set()
    local length = 0
    for i=1, 1000, 100 do
      for j=1, 1000, 100 do
        for color=1, 100000, 10000 do
          pixels:add(Pixel(i, j, color))
          assert(len(pixels) == length + 1, 'Did not create unique pixel')
          length = length + 1
        end
      end
    end
  end),

  it('can add and subtract pixel objects', function()
    local pix = Pixel(10, 10, 10) 
    local added = pix + Pixel(10, 10)
    local subbed = pix - Pixel(10, 10)
    assert(added:isinstance(Pixel), 'Adding pixel objects did not return pixel')
    assert(subbed:isinstance(Pixel), 'Subtracting pixel objects did not return pixel')
    assert(added.x == 20 and added.y == 20, 'Did not add pixel positions correctly')
    assert(subbed.x == 0 and subbed.y == 0, 'Did not add pixel positions correctly')
    assert(pix.expected_color == added.expected_color, 'Changed pixel color on add')
    assert(pix.expected_color == subbed.expected_color, 'Changed pixel color on sub')
    local added_table = pix + {10, 10}
    local subbed_table = pix - {10, 10}
    assert(added:isinstance(Pixel), 'Adding pixel and table did not return pixel')
    assert(subbed:isinstance(Pixel), 'Subtracting pixel and table did not return pixel')
    assert(added_table.x == 20 and added_table.y == 20, 'Did not add pixel positions correctly')
    assert(subbed_table.x == 0 and subbed_table.y == 0, 'Did not add pixel positions correctly')
    assert(pix.expected_color == added_table.expected_color, 'Changed pixel color on add with table')
    assert(pix.expected_color == subbed_table.expected_color, 'Changed pixel color on sub with table')
  end),

  it('can evaluate pixel equality', function(pixels) 
    assert(Pixel(10, 10, 10) == Pixel(10, 10, 10), 'Equal pixels not equal')
    assert(Pixel(0, 10, 10) ~= Pixel(10, 10, 10), 'Non-equal pixels equal')
    assert(Pixel(10, 0, 10) ~= Pixel(10, 10, 10), 'Non-equal pixels equal')
    assert(Pixel(10, 10, 0) ~= Pixel(10, 10, 10), 'Non-equal pixels equal')
  end),
  
  it('can stringify pixel', function() 
    assert(tostring(Pixel(10, 10, 10)) == string.format('<Pixel(%d, %d)>', 10, 10), 'Pixel tostring not correct')
  end),

  it('can get color of pixel', function(pixels)
    assert(Pixel(10, 10).color == 10, 'Did not get color of pixel') 
  end),

  it('can detect pixel color change', function(pixels) 
    local pix = Pixel(10, 10)
    local changed = pix:color_changed()
    assert(not changed(), 'Detected change in color when there was none')
    assert(not changed(), 'Detected change in color when there was none')
    pixels[1].expected_color = 10000
    assert(changed(), 'Did not detect change in pixel color')
    assert(not changed(), 'Detected change in color when there was none')
  end),

  it('can detect pixel visibility', function(pixels) 
    assert(Pixel(10, 10, 10):visible(), 'Visible pixel not visible') 
    assert(not Pixel(0, 10, 10):visible(), 'Non visible pixel visible') 
    assert(not Pixel(10, 0, 10):visible(), 'Non visible pixel visible') 
    assert(not Pixel(10, 10, 0):visible(), 'Non visible pixel visible') 
  end)
)


describe('pixel - Pixels',

  it('can add and subtract Pixels objects', function() 
    local pixels = Pixels{Pixel(0, 0), Pixel(10, 10), Pixel(10, 10)}
    local added = pixels + Pixels{Pixel(10, 10), Pixel(20, 20)}
    local subbed = pixels - Pixels{Pixel(10, 10), Pixel(20, 20)}
    assert(added:isinstance(Pixels), 'Add did not return Pixels object')
    assert(subbed:isinstance(Pixels), 'Subtract did not return Pixels object')
    assert(len(pixels.pixels) == 2, 'Did not create pixels correctly')
    assert(len(added.pixels) == 3, 'Did not add pixels correctly')
    assert(len(subbed.pixels) == 1, 'Did not sub pixels correctly')
  end),

  it('can evaluate Pixels equality', function() 
    assert(Pixels{Pixel(10, 10)} == Pixels{{10, 10}, {10, 10}}, 'Pixels are not equal')
    assert(Pixels{Pixel(10, 10)} == Pixels{Pixel(10, 10)}, 'Equal Pixels objects are not equal')
    assert(Pixels{Pixel(10, 10)} ~= Pixels{Pixel(10, 10), Pixel(10, 20)}, 'Not equal Pixels objects are equal')
    assert(Pixels{Pixel(0, 10)} ~= Pixels{Pixel(10, 10)}, 'Not equal Pixels objects are equal')
  end),

  it('can stringify Pixels', function() 
    local pixels = Pixels{Pixel(10, 10), Pixel(20, 20)}
    assert(tostring(pixels) == string.format('<Pixels(n=%d)>', len(pixels.pixels)))
  end),

  it('can get colors of Pixels', function(pixels) 
    local pix = Pixels{Pixel(10, 10, 10), Pixel(20, 20, 20)}
    local expected = {pixels[1].expected_color, pixels[2].expected_color}
    assert(requal(pix.colors, expected), 'Did not get all correct colors of Pixels')
  end),

  it('can detect Pixels visibility', function(pixels) 
    assert(Pixels{Pixel(10, 10, 10), Pixel(20, 20, 20)}:visible(), 'Visible pixel is not visible')
    assert(not Pixels{Pixel(10, 10, 0), Pixel(20, 20, 20)}:visible(), 'Non visible pixel is visible')
  end),

  it('can count number of different pixels', function(pixels) 
    local pix = Pixels{Pixel(10, 10, 10), Pixel(20, 20, 20), Pixel(100, 100, 10), Pixel(200, 200, 20)}
    assert(pix:count() == 2, 'Did not get correct pixel count')
  end),

  it('can detect specific Pixels color change configurations', function(pixels) 
    local pix = Pixels{
      Pixel(10, 10),
      Pixel(20, 20),
      Pixel(30, 30),
      Pixel(40, 40)
    }
    local any_change = pix:any_colors_changed()
    local all_change = pix:all_colors_changed()
    local two_change = pix:n_colors_changed(2)
    assert(not any_change(), 'Detected change when there was not one')
    assert(not all_change(), 'Detected change when there was not one')
    assert(not two_change(), 'Detected change when there was not one')
    pixels[1].expected_color = 0
    assert(any_change(), 'Did not detect change')
    assert(not all_change(), 'Detected change when there was not one')
    assert(not two_change(), 'Detected change when there was not one')
    pixels[1].expected_color = 1000
    pixels[2].expected_color = 1000
    assert(any_change(), 'Did not detect change')
    assert(not all_change(), 'Detected change when there was not one')
    assert(two_change(), 'Did not detect change')
    pixels[3].expected_color = 1000000
    pixels[4].expected_color = 1000000
    pixels[3].expected_color = 1000000
    pixels[4].expected_color = 1000000
    assert(any_change(), 'Did not detect change')
    assert(all_change(), 'Did not detect change')
    assert(two_change(), 'Did not detect change')
  end)
)

-- TODO: Ellipse and Triangle tests

describe('pixel - Region',

  it('can add and subtract Region objects', function() 
    local region = Region{Pixel(0, 0), Pixel(10, 10)}
    local added = region + Region{Pixel(10, 10), Pixel(20, 20)}
    local subbed = region - Region{Pixel(10, 10), Pixel(20, 20)}
    assert(added:isinstance(Region), 'Add did not return Region object')
    assert(subbed:isinstance(Region), 'Subtract did not return Region object')
    assertRaises('Can only', function() 
      local fail = Region{Pixel(0, 0)} + Pixels{Pixel(10, 10)}
    end, 'Adding Region to pixels did not fail')
    assertRaises('Can only', function() 
      local fail = Region{Pixel(0, 0)} - Pixels{Pixel(10, 10)}
    end, 'Subtracting Region to pixels did not fail')
  end),

  it('can stringify Region', function() 
    local region = Region{Pixel(0, 0), Pixel(10, 10)}
    assert(tostring(region) == string.format('<Region(pixels=%d, color=%d)>', len(region.pixels), region.color))
  end),

  it('can get center of Region', function() 
    local region = Region{Pixel(0, 0), Pixel(10, 10)}
    assert(region.center == Pixel(5, 5), 'Did not get correct center of region')
  end),
  
  it('can create Ellipse', function() 
  end),
  
  it('can create Rectangle', function() 
    local rect = Rectangle{
      x=10,
      y=10,
      width=100,
      height=100,
      spacing=10
    }
    assert(rect.x == 10, 'Rectangle has incorrect ')
    assert(rect.y == 10, 'Rectangle has incorrect y')
    assert(rect.width == 100, 'Rectangle has incorrect width')
    assert(rect.height == 100, 'Rectangle has incorrect height')
    assert(rect.spacing == 10, 'Rectangle has incorrect spacing')
    assert(len(rect.pixels) == 121, 'Incorrect number of pixels in Rectangle')
    assert(rect.pixels[1].x == rect.x and rect.pixels[1].y == rect.y, 'Incorrect first pixel location')
    assert(rect.pixels[-1].x == rect.x + rect.width and rect.pixels[-1].y == rect.y + rect.height, 'Incorrect last pixel location')
  end),
  
  it('can create Triangle', function() 
  end)
  
)










fixture('patched_wget', function(monkeypatch, request) 
  local old_exe = exe
  local output
  monkeypatch.setattr('exe', function(...) 
    if (...)[1] == 'wget' then
      local next_is_output = false
      local url
      for k, v in pairs(...) do 
        if v:startswith("'http") then url = v:strip("'") end
        if next_is_output then output = v; break end
        if v:startswith('--output-document') then next_is_output = true end
      end
      local path = url:replace('http://httpbin.org', ''):replace('https://httpbin.org', ''):split('?')[1]
      local stdout, response_data
      if path:startswith('/get') then
        stdout = '--2018-10-20 04:17:13--  http://httpbin.org/get?stuff=1\nResolving httpbin.org (httpbin.org)... 52.44.144.199, 52.2.175.150, 52.0.94.50, ...\nConnecting to httpbin.org (httpbin.org)|52.44.144.199|:80... connected.\nHTTP request sent, awaiting response... 200 OK\nLength: 297 [application/json]\nSaving to: ‘_response.txt’\n\n     0K                                                       100% 28,1M=0s\n\n2018-10-20 04:17:13 (28,1 MB/s) - ‘_response.txt’ saved [297/297]'
        response_data = '{\n  "args": {\n      "stuff": "1"\n    },\n    "headers": {\n      "Accept": "*/*",\n      "Accept-Encoding": "identity",\n      "Connection": "close",\n      "Host": "httpbin.org",\n      "User-Agent": "myAgent",\n      "X-Stuff": "abc"\n    },\n    "origin": "194.59.251.59",\n    "url": "http://httpbin.org/get?stuff=1"\n  }'
      elseif path:startswith('/post') then 
        stdout = '--2018-10-20 04:23:20--  http://httpbin.org/post\nResolving httpbin.org (httpbin.org)... 34.226.180.131, 34.231.150.116, 34.231.75.48, ...\nConnecting to httpbin.org (httpbin.org)|34.226.180.131|:80... connected.\nHTTP request sent, awaiting response... 200 OK\nLength: 434 [application/json]\nSaving to: ‘_response.txt’\n\n     0K                                                       100% 29,2M=0s\n\n2018-10-20 04:23:21 (29,2 MB/s) - ‘_response.txt’ saved [434/434]'
        response_data = '{\n  "args": {},\n  "data": "",\n  "files": {},\n  "form": {\n    "amount": "10"\n  },\n  "headers": {\n    "Accept": "*/*",\n    "Accept-Encoding": "identity",\n    "Connection": "close",\n    "Content-Length": "9",\n    "Content-Type": "application/x-www-form-urlencoded",\n    "Host": "httpbin.org",\n    "User-Agent": "Wget/1.17.1 (linux-gnu)"\n  },\n  "json": null,\n  "origin": "194.59.251.59",\n  "url": "http://httpbin.org/post"\n}'
      elseif path:startswith('/base64') then 
        stdout = '--2018-10-20 04:23:21--  https://httpbin.org/base64/SFRUUEJJTiBpcyBhd2Vzb21l\nResolving httpbin.org (httpbin.org)... 34.226.180.131, 34.231.150.116, 34.231.75.48, ...\nConnecting to httpbin.org (httpbin.org)|34.226.180.131|:443... connected.\nHTTP request sent, awaiting response... 200 OK\nLength: 18 [text/html]\nSaving to: ‘_response.txt’\n\n     0K                                                       100% 3,59M=0s\n\n2018-10-20 04:23:22 (3,59 MB/s) - ‘_response.txt’ saved [18/18]'
        response_data = 'HTTPBIN is awesome'
      elseif path:startswith('/basic-auth') then 
        stdout = '--2018-10-20 04:29:38--  https://httpbin.org/basic-auth/name/password\nResolving httpbin.org (httpbin.org)... 52.44.92.122, 52.4.75.11, 52.45.111.123, ...\nConnecting to httpbin.org (httpbin.org)|52.44.92.122|:443... connected.\nHTTP request sent, awaiting response... 401 UNAUTHORIZED\nAuthentication selected: Basic realm=\"Fake Realm\"\nReusing existing connection to httpbin.org:443.\nHTTP request sent, awaiting response... 200 OK\nLength: 47 [application/json]\nSaving to: ‘_response.txt’\n     0K                                                       100% 8,17M=0s\n2018-10-20 04:29:39 (8,17 MB/s) - ‘_response.txt’ saved [47/47]'
        response_data = '{\n          "authenticated": true,\n          "user": "name"\n        }'
      end
      local f = io.open(output, 'w')
      f:write(response_data)
      f:close()
      return stdout:split('\n')

      -- Use this to make requests over network
      -- local data = old_exe(...)
      -- pprint(data)
      -- local f = io.open(output)
      -- local stdout = f:read('*a')
      -- f:close()
      -- print('-' * 50)
      -- print(stdout)
      -- return data
    end
    return old_exe(...)
  end)  
end)


fixture('response', function() 
  local resp = Response({url='http://example.com', method='GET'})
  resp.status_code = 400
  resp.text = '{\n\t"a":"1",\n\t"b":"2"\n}'
  return resp
end)


describe('requests',

  it('gets json', function(patched_wget)
    local url = 'http://httpbin.org/get'
    local header_key = 'X-Stuff'
    local head, ua = {[header_key]='abc'}, 'myAgent'
    local resp = requests.get{url, params={stuff=1}, headers=head, user_agent=ua}
    assert(resp.status_code == 200, 'Did not return 200')
    assert(resp, 'Json request did not return response')
    local j = resp:json()
    assert(j.headers, 'Incorrect json returned')
    assert(j.origin, 'Incorrect json returned')
    assertEqual(j.url, url..'?stuff=1', 'Incorrect json returned')
    assertEqual(j.url, resp.url, 'Incorrect json returned')
    assert(j.headers['User-Agent'] == ua, 'Did not get correct user agent header')
    assert(j.headers[header_key] == head[header_key], 'Did not get correct custom header')
  end),
  
  it('posts json', function(patched_wget)
    local resp = requests.post{'http://httpbin.org/post', data={amount=10}}
    assert(resp.status_code == 200, 'Did not return 200')
    assertEqual(str(resp:json().form.amount), '10', 'Did not post correct data')
  end),
  
  it('gets text', function(patched_wget)
    local resp = requests.get('https://httpbin.org/base64/SFRUUEJJTiBpcyBhd2Vzb21l')
    assert(resp.status_code == 200, 'Did not return 200')
    assert(resp, 'Text request did not return response')
    assertEqual(resp.text, 'HTTPBIN is awesome', 'Incorrect text returned')
  end),

  it('makes request with auth', function(patched_wget) 
    local resp = requests.get{'https://httpbin.org/basic-auth/name/password', auth={user='name', password='password'}, verify_ssl=true}
    assert(resp.status_code == 200, 'Did not return 200')
    assert(resp:json().authenticated == true, 'Not authenticated with basic http auth')
    assert(resp:json().user == 'name', 'Did not get correct username')
  end),

  it('Response tostring', function(response) 
    assert(tostring(response) == string.format('<Response [%d]>', response.status_code), 
    'Response does not have correct tostring')
  end),
  
  it('Response iter_lines', function(response) 
    local expected = {'{', '\t"a":"1",', '\t"b":"2"', '}'}
    local count = 1
    for line in response:iter_lines() do
      assert(line == expected[count], 'Incorrect line in response')
      count = count + 1
    end
    assert(count, 'Did not iterate over response text')
  end),
  
  it('Response json', function(response) 
    assert(response:json().b == '2', 'Did not parse response json')
  end),
  
  it('Response raise_for_status', function(response) 
    assertRaises(response.method..' request: '..response.status_code, function() 
      response:raise_for_status()
    end, 'Did not raise error for response')
  end)
)









usleep = function(...) end

fixture('do_after', function() 
  return function(n, f, f_before)
    local count = 0
    return function()
      if f_before then f_before() end
      count = count + 1
      if count >= n then
        f()
      end
    end 
  end
end)


fixture('pixels', function(monkeypatch) 
  local pixels = list{
    Pixel(10, 10, 10),
    Pixel(20, 20, 20),
    Pixel(30, 30, 30),
    Pixel(40, 40, 40),
  }
  local function _getColor(x, y) 
    for p in iter(pixels) do if p.x == x and p.y == y then return p.expected_color end end
  end
  local function _getColors(pos) 
    local colors = list()
    for p in iter(pos) do colors:append(_getColor(p[1], p[2])) end
    return colors
  end
  
  monkeypatch.setattr('getColor', _getColor)
  monkeypatch.setattr('getColors', _getColors)
  return pixels
end)


fixture('taps', function(monkeypatch)
  screen.before_action_funcs = set()
  screen.after_action_funcs = set()
  screen.before_check_funcs = set()
  screen.after_check_funcs = set()
  screen.before_tap_funcs = set()
  screen.after_tap_funcs = set() 
  screen.nth_check_funcs = dict()
  screen.on_stall_funcs = set()
  screen.check_interval = 150
  local taps = list()
  monkeypatch.setattr('tap', function(x, y) taps:append(list{x, y}) end)
  return taps
end)


fixture('touches', function(monkeypatch)
  local touches = list()
  monkeypatch.setattr('usleep', function(...) end)
  monkeypatch.setattr('touchDown', function(i, x, y) touches:append({'down', i, x, y}) end)
  monkeypatch.setattr('touchUp', function(i, x, y) touches:append({'up', i, x, y}) end)
  monkeypatch.setattr('touchMove', function(i, x, y) touches:append({'move', i, x, y}) end)
  return touches
end)


describe('screen',
    
  it('can detect and recover from stall', function(monkeypatch, pixels, taps)
    monkeypatch.setattr(screen, 'stall_after_checks_interval', 0.001)
    screen.on_stall({function() end})
    
    local calls = list()
    screen.on_stall(function() 
      calls:append(true)
      pixels:clear()
    end)

    local pix = screen.stall_indicators:copy()
    pixels:extend(pix.pixels)
    screen.tap_while(pix, pix.pixels[1])
    assert(len(calls) == 1, 'Did not call on stall')
  end),
  
  it('can restart iterable stall procedure on successful stall recovery', function(monkeypatch, pixels, taps) 
    monkeypatch.setattr(screen, 'stall_after_checks_interval', 0.001)
    local calls = list()
    
    screen.on_stall{
      function() 
        calls:append(1)
      end,
      function() 
        calls:append(2)
        pixels:clear()
      end,
      function() 
        calls:append(3)
        pixels:clear()
      end
    }
    
    local pix = screen.stall_indicators:copy()
    pixels:extend(pix.pixels)
    local old_pix = pixels:copy()
    screen.tap_while(pix, pix.pixels[1])
    assert(len(calls) == 2, 'Did not call on stall correct number of times')
    assert(requal(calls, {1, 2}), 'Did not execute on stall procedure in correct order')
    calls:clear()
    -- Screen is no longer stalled, so color changes
    old_pix[5].expected_color = 50
    pixels:extend(old_pix)
    screen.tap_while(pix, pix.pixels[1])
    -- Now screen is stalled again, back to stall color
    old_pix[5].expected_color = colors.white
    pixels:extend(old_pix)
    screen.tap_while(pix, pix.pixels[1])
    local _ = 1  -- For some reason, without this line the test fails
    assert(len(calls) == 2, 'Did not call on stall correct number of times')
    assert(requal(calls, {1, 2}), 'Did not execute on stall procedure in correct order')
  end),

  it('can run functions after consecutive checks', function(monkeypatch, pixels, taps)
    monkeypatch.setattr(screen, 'stall_after_checks_interval', 0.001)
    
    local calls = list()
    local c = 0
    screen.before_check(function() c = c + 1 end)
    screen.on_nth_check(5, function() 
      calls:append(c)
    end)

    screen.on_nth_check(10, function() 
      calls:append(c)
      pixels:clear()
    end)

    local pix = screen.stall_indicators:copy()
    pixels:extend(pix.pixels)
    screen.tap_while(pix, pix.pixels[1])
    assert(len(calls) == 2, 'Did not call on stall')
    assert(requal(calls, {5, 10}), 'Did not execute nth check funcs in correct order')
  end),

  it('can swipe between pixels', function(touches) 
    local start_pix = Pixel(10, 10)
    local end_pix = Pixel(100, 100)
    for speed in iter{1, 5, 10} do
      screen.swipe(start_pix, end_pix, speed)
      assert(len(touches) == 50 / speed + 1, 'Did not touch and move correctly')
      assert(touches[1][1] == 'down', 'Did not swipe in correct order')
      assert(touches[2][1] == 'move', 'Did not swipe in correct order')
      assert(touches[-1][1] == 'up', 'Did not swipe in correct order')
      touches:clear()
    end
  end),

  it('can swipe in a direction', function(touches) 
    local positions = {'left', 'right', 'top', 'bottom', 'center', 'top_left', 'top_right', 'bottom_left', 'bottom_right'}
    for pos1 in iter(positions) do
      for pos2 in iter(positions) do
        if pos1 ~= pos2 then
          screen.swipe(pos1, pos2, 10)
          assert(len(touches) == 6, 'Did not touch and move correctly')
          assert(touches[1][1] == 'down', 'Did not swipe in correct order')
          assert(touches[2][1] == 'move', 'Did not swipe in correct order')
          assert(touches[-1][1] == 'up', 'Did not swipe in correct order')
          touches:clear()
        end
      end
    end
  end),

  it('can tap a position', function(taps) 
    local x, y, times = 10, 10, 5
    screen.tap(x, y, times)
    assert(len(taps) == times, 'Did not tap screen at position')
    assert(taps[1][1] == x, 'Did not tap screen at correct position')
  end),
  
  it('can tap a pixel', function(taps) 
    local pix, times = Pixel(10, 10), 5
    screen.tap(pix, times)
    assert(len(taps) == times, 'Did not tap screen at pixel')
    assert(taps[1][1] == pix.x, 'Did not tap screen at correct pixel position')
  end),
  
  it('can tap with context', function(taps, do_after) 
    local action_calls = list()
    local check_calls = list()
    local tap_calls = list()
    screen.before_action(function() action_calls:append('begin') end)
    screen.after_action(function() action_calls:append('end') end)
    screen.before_check(function() check_calls:append('begin') end)
    screen.after_check(function() check_calls:append('end') end)
    screen.before_tap(function() tap_calls:append('begin') end)
    screen.after_tap(function() tap_calls:append('end') end)
    
    local count = 0
    screen.tap_while(function() count = count + 1; return count < 3 end, Pixel(100, 100))
    
    assertRequal(action_calls, {'begin', 'end'}, 'action calls order incorrect')
    assertRequal(check_calls, {'begin', 'end', 'begin', 'end', 'begin', 'end'}, 'check calls order incorrect')
    assertRequal(tap_calls, {'begin', 'end', 'begin', 'end'}, 'tap calls order incorrect')
  end),
  
  it('can tap if a pixel is visible', function(taps, pixels) 
    local pix = Pixel(100, 100)
    screen.tap_if(pix)
    assert(len(taps) == 0, 'Tapped when pixel is not visible')
    pixels:append(pix)
    screen.tap_if(pix)
    assert(len(taps) == 1, 'Did not tap when pixel is visible')
    assert(taps[-1][1] == 100, 'Did not tap correct position')
    screen.tap_if(pix, Pixel(200, 200))
    assert(taps[-1][1] == 200, 'Did not tap correct position')
  end),
  
  it('can tap while a pixel is visible', function(taps, pixels, do_after) 
    local pix = Pixel(100, 100)
    pixels:append(pix)
    local required_taps = 3
    screen.before_tap(do_after(required_taps, 
      function() pixels:remove(pix) end
    ))
    screen.tap_while(pix)
    assert(len(taps) == required_taps, 'Tapped less than required amount')
  end),
  
  it('can tap until a pixel is visible', function(taps, pixels, do_after) 
    local pix = Pixel(100, 100)
    local required_taps = 3
    screen.before_tap(do_after(required_taps, 
      function() pixels:append(pix) end
    ))
    screen.tap_until(pix)
    assert(len(taps) == required_taps, 'Tapped less than required amount')
  end),
  
  it('can tap if a condition is met', function(taps) 
    screen.tap_if(function() return false end, Pixel(100, 100))
    assert(len(taps) == 0, 'Tapped when condition not met')
    screen.tap_if(function() return true end, Pixel(100, 100))
    assert(len(taps) == 1, 'Did not tap when condition is met')
    assert(taps[-1][1] == 100, 'Did not tap correct position')
  end),
  
  it('can tap while a condition is met', function(taps, do_after) 
    local cond = true
    local required_taps = 3
    screen.before_tap(do_after(required_taps, 
      function() cond = false end
    ))
    screen.tap_while(function() return cond end, Pixel(100, 100))
    assert(len(taps) == required_taps, 'Tapped less than required amount')
  end),
  
  it('can tap until a condition is met', function(taps, do_after) 
    local cond = false
    local required_taps = 3
    screen.before_tap(do_after(required_taps, 
      function() cond = true end
    ))
    screen.tap_until(function() return cond end, Pixel(100, 100))
    assert(len(taps) == required_taps, 'Tapped less than required amount')
  end),
  
  it('can wait for a pixel', function(taps, pixels, do_after) 
    local checks = 0
    local pix = Pixel(100, 100)
    local required_checks = 3
    screen.before_check(do_after(required_checks, 
      function() pixels:append(pix) end,
      function() checks = checks + 1 end
    ))
    screen.wait(pix)
    assert(checks == required_checks, 'Checked less than required amount')
  end),
  
  it('can wait for a condition', function(taps, do_after) 
    local checks = 0
    local cond = false
    local required_checks = 3
    screen.before_check(do_after(required_checks, 
      function() cond = true end,
      function() checks = checks + 1 end
    ))
    screen.wait(function() return cond end)
    assert(checks == required_checks, 'Checked less than required amount')
  end)

)










describe('string', 
  
  it('startswith', function() 
     assert(('\nabc'):startswith('\n'), 'Startswith \\n')
     assert(not ('abc'):startswith('\n'), 'Not Startswith \\n')
  end),

  it('endswith', function() 
    assert(('abc\n'):endswith('\n'), 'Endswith \\n')
    assert(not ('abc'):endswith('\n'), 'Not endswith \\n')
  end),

  it('format', function() 
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
  end),

  it('join', function() 
    assertEqual(('\n'):join({'a', 'b'}), 'a\nb', 
      'String join table failed')
    assertEqual(('\n'):join(list{'a', 'b'}), 'a\nb', 
      'String join list failed')
  end),

  it('replace', function()  
    assertEqual(('abcba'):replace('b', 'q'), 'aqcqa', 'String replacement incorrect') 
  end),

  it('split', function()
    local s1 = 'abc'
    local s2 = 'aabbcc'
    local s3 = 'a 20 300 dddd'
    assertRequal(s1:split(), {'a', 'b', 'c'}, 'Split with no args')
    assertRequal(s1:split('b'), {'a', 'c'}, 'Split with char arg')
    assertRequal(s2:split('bb'), {'aa', 'cc'}, 'Split with string arg')
    assertRequal(s3:split(' '), {'a', '20', '300', 'dddd'}, 'Split with spaces')
  end),

  it('strip', function()
    local x = 'abacbabacabab'
    local expected = 'cbabac'
    assertEqual(x:strip('ab'), expected, 'String not stripped correctly')
  end),

  it('str_add', function() 
    assertEqual('a' + 'b', 'ab', 'String add incorrect')
  end),

  it('str_mul', function() 
    assertEqual('ab' * 2, 'abab', 'String mul incorrect') 
  end),

  it('str_pairs', function() 
    local c = 1
    local _t = {'a', 'b', 'c'}
    for i, v in pairs('abc') do 
      assertEqual(i, c, 'String pairs index incorrect')
      assertEqual(v, _t[c], 'String pairs value incorrect')
      c = c + 1 
    end
  end),

  it('str_index', function() 
    local s = 'abc'
    for i, v in pairs(string) do
      assert(Not.Nil(s[i]), 'string missing function '..i)
    end
    assertEqual(s[1], 'a', 'Positive string index failed')
    assertEqual(s[-1], 'c', 'Negative string index failed')
    local x = 'abcde'
    assert(x(2, 4) == 'bcd', 'Did not slice string correctly')
    assert(x{1, -2, 3} == 'adc', 'Did not slice string correctly')
  end)
)










fixture('filesystem', function(request) 
  local cmd = ''
  if rootDir then cmd = 'cd '..rootDir()..' && ' end
  io.popen(cmd..'mkdir _tmp_tst'):close() 
  io.popen(cmd..'echo "line1\nline2\nline3" > _tmp_tst/t.txt'):close()
  io.popen(cmd..'echo "1\n2\n3" > _tmp_tst/t1.txt'):close()
  request.addfinalizer(function()
    local _cmd = ''
    if rootDir then _cmd = 'cd '..rootDir()..' && ' end
    if isDir('_tmp_tst') then io.popen(_cmd..'rm -r _tmp_tst'):close() end
    if isDir('_tmp_tst2') then io.popen(_cmd..'rm -R _tmp_tst2'):close() end
  end)
end)
  

describe('system', 

  it('exe', function(filesystem)
    local result = set(exe('ls _tmp_tst'))
    assertEqual(result, set{'t1.txt', 't.txt'}, 'ls returned incorrect files')
    assertRequal(exe('echo "1\n2"'), {'1', '2'}, 'Multi line output failed')
    assertEqual(exe('echo "1\n2"', false), '1\n2', 'Single output failed')
  end),

  it('fcopy', function(filesystem)
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
  end),

  it('find', function(filesystem)
    assertEqual(find('tests.lua'), './tests.lua', 
      'find returned incorrect file path')
    assertEqual(find{dir='_tmp_tst'}, './_tmp_tst', 
      'find returned incorrect directory path')
    assertRaises('Incorrect table arguments', function() 
      find{stuff='abc'}
    end, 'find with incorrect args did not raise error')
  end),

  it('get_cwd', function() 
    assert(isin('/', get_cwd()), 'get_cwd did not return directory')
  end),

  it('isDir', function(filesystem) 
    assert(isDir('_tmp_tst'), '_tmp_tst not a directory') 
  end),

  it('isFile', function(filesystem)
    assert(isFile('_tmp_tst/t.txt'), '_tmp_tst/t.txt not a file')
  end),

  it('listdir', function(filesystem)
    local result = listdir('_tmp_tst')
    local expected = {'t.txt', 't1.txt'}
    for i, v in pairs(result) do 
      assertEqual(v, expected[i], 'listdir has incorrect file name') 
    end
  end),

  it('pathExists', function(filesystem)
    assert(not pathExists('randompath_sdas'), 'Invalid path exists')
    assert(pathExists('/etc'), '/usr does not exist')
  end),

  it('pathJoin', function() 
    assert(pathJoin('dir', 'file') == 'dir/file', 'Did not join paths correctly')
    assert(pathJoin('dir', '/file') == 'dir/file', 'Did not join paths correctly')
    assert(pathJoin('dir/', 'file') == 'dir/file', 'Did not join paths correctly')
    assert(pathJoin('dir/', '/file') == 'dir/file', 'Did not join paths correctly')
  end),

  it('readLine', function(filesystem) 
    local line = readLine('_tmp_tst/t.txt', 2)
    assertEqual(line, 'line2', 'Second line read incorrectly')
  end),

  it('readLines', function(filesystem) 
    local expected = {'line1', 'line2', 'line3'}
    local lines = readLines('_tmp_tst/t.txt')
    for i, v in pairs(lines) do 
      assertEqual(v, expected[i], 'line read incorrectly') 
    end
  end),

  it('sizeof', function(filesystem)
    local size = sizeof('_tmp_tst/t.txt')
    --Don't know why text files are so drastically different 
    --in size accross linux and various IOS versions
    assert(size >= 4, 'Incorrect file size') 
  end),

  it('can sleep', function() 
    local time_ns = num(exe('date +%s%N'))
    sleep(0.01)
    local c_time_ns = num(exe('date +%s%N'))
    -- TODO: Fix sleep tests for mobile
    -- assert(round((c_time_ns - time_ns) / 1000000000, 2) == 0.01, 'Did not sleep for correct amount of time')
    time_ns = c_time_ns
    sleep(0.1)
    c_time_ns = num(exe('date +%s%N'))
    -- assert(round((c_time_ns - time_ns) / 1000000000, 1) == 0.1, 'Did not sleep for correct amount of time')
  end),

  it('writeLine', function(filesystem)
    writeLine('5', 2, '_tmp_tst/t1.txt')
    local lines = readLines('_tmp_tst/t1.txt')
    local expected = {'1', '5', '3'}
    for i, v in pairs(lines) do 
      assertEqual(v, expected[i], 'Incorrect line written') 
    end
  end),

  it('writeLines', function(filesystem) 
    local expected = {'2', '5', '6'}
    writeLines(expected, '_tmp_tst/t1.txt')
    local lines = readLines('_tmp_tst/t1.txt')
    for i, v in pairs(lines) do 
      assertEqual(v, expected[i], 'Incorrect lines written') 
    end
  end)
)





if run_tests() == 0 then alert("All tests passed!") end 




local stdout = ''
io.write = function(s) stdout = stdout..s end


function _reset_stdout_and_run_tests(func)
  stdout = ''
  func()
  run_tests()
end 

-- test definition
_reset_stdout_and_run_tests(function()
  describe('Basic', 
    it('can define test', function() 
      io.popen('sleep 0.01'):close()
    end)
  )
end)
assert(stdout:match('1 passed in 0%.[0-9][1-9]'), 'Basic tests did not pass')
assert(stdout:match('%.\n'), 'Incorrect test results')

-- No tests
_reset_stdout_and_run_tests(function() end)
assert(stdout:match('No tests found'), 'Empty tests did not pass')

-- fixture definition
_reset_stdout_and_run_tests(function() 
  local total_func = 0
  local total_group = 0
  local total_module = 0

  fixture('increment_func', function()
      total_func = total_func + 1
      return total_func
  end)
  
  fixture('increment_group', 'group', function()
    total_group = total_group + 1
    return total_group
  end)
  
  fixture('increment_module', 'module', function()
    total_module = total_module + 1
    return total_module
  end)

  describe('Fixtures', 
    it('can use fixture', function(increment_func)
      assert(increment_func == 1, 'Fixture value not correct')
    end
    ),
    it('creates new fixtures', function(increment_func)
      assert(increment_func == 2, 'Fixture value not correct')
    end
    ),
    it('can use multiple fixtures', function(increment_func, increment_group, increment_module)
      assert(increment_func == 3, 'Fixture value not correct')
      assert(increment_group == 1, 'Fixture value not correct')
      assert(increment_module == 1, 'Fixture value not correct')
    end
    )
  )
  describe('Fixture scope', 
    it('creates fixtures according to scope', function(increment_func, increment_group, increment_module)
      assert(increment_func == 4, 'Fixture value not correct')
      assert(increment_group == 2, 'Fixture value not correct')
      assert(increment_module == 1, 'Fixture value not correct')
    end
    )
  )

end)
assert(stdout:match('4 passed in'), 'Fixture tests did not pass')
assert(stdout:match('%....\n'), 'Incorrect test results')



--- fixture parametrization
_reset_stdout_and_run_tests(function()

  fixture('first', function()
    return 1
  end)

  fixture('second', function(first)
    return first + 1
  end)

  describe('Fixture parametrization', 
    it('can use fixtures that use other fixtures', function(second) 
      assert(second == 2)
    end)
  )
end)
assert(stdout:match('1 passed in'), 'Fixture parametrization tests did not pass')



--- teardown
local expected_stv = {'begin', 'test', 'end', 'begin', 'test', 'end', 'direct', 'test', 'direct', 'end_module'}
local setup_teardown_values = {}
_reset_stdout_and_run_tests(function()

  fixture('values', function(request)
    table.insert(setup_teardown_values, 'begin')
    request.addfinalizer(function() table.insert(setup_teardown_values, 'end') end)
    return setup_teardown_values
  end)

  fixture('values_module', 'module', function(request)
    request.addfinalizer(function() table.insert(setup_teardown_values, 'end_module') end)
    return setup_teardown_values
  end)

  describe('Fixture parametrization', 
    it('can use scoped fixtures with teardown', function(values_module) 
    end),  
    it('can use fixtures that use other fixtures', function(values) 
      table.insert(values, 'test')
    end),
    it('can add finalizers in test directly', function(values, request) 
      table.insert(setup_teardown_values, 'test')
      request.addfinalizer(function() table.insert(setup_teardown_values, 'direct') end)
    end),
    parametrize('val', {1},
    it('can add finalizers in parametrized test directly', function(val, request) 
      table.insert(setup_teardown_values, 'test')
      request.addfinalizer(function() table.insert(setup_teardown_values, 'direct') end)
    end)
    )
  )
end)
assert(stdout:match('4 passed in'), 'Fixture teardown tests did not pass')
assert(#setup_teardown_values == #expected_stv)
for k, v in pairs(setup_teardown_values) do assert(v == expected_stv[k], 'Fixture setup teardown order is incorrect') end



--- monkeypatch
local object_to_patch  = {value = 1}
function patchable_function(value)
  return value
end
function patchable_function_module(value)
  return value
end
_reset_stdout_and_run_tests(function()
  
  fixture('patched_object', function(monkeypatch) 
    monkeypatch.setattr(object_to_patch, 'value', 2)
  end)
  
  fixture('patched_global', function(monkeypatch) 
    monkeypatch.setattr('patchable_function', function(v) return v * 2 end)
  end)
  
  fixture('patched_global_module', 'module', function(monkeypatch) 
    monkeypatch.setattr('patchable_function_module', function(v) return v * 3 end)
  end)

  describe('Monkeypatch', 
    it('can patch global', function(patched_global, patched_global_module) 
      assert(patchable_function(1) == 2)
      assert(patchable_function_module(1) == 3)
    end),
    it('can patch object', function(patched_object) 
      assert(object_to_patch.value == 2)
    end),
    it('can patch according to scope', function() 
      assert(patchable_function_module(1) == 3)
    end)
  )
end)
assert(stdout:match('3 passed in'), 'Monkeypatch tests did not pass')
assert(object_to_patch.value == 1, 'Monkeypatch did not reset object value after tests')
assert(patchable_function(1) == 1, 'Monkeypatch did not reset global value after tests')
assert(patchable_function_module(1) == 1, 'Monkeypatch did not reset global value after tests')



--- parametrize
local total_value_parametrize = 1
local total_value_parametrize_multi = 1
_reset_stdout_and_run_tests(function()
  describe('Parametrize', 
    parametrize('value', {1, 2, 3}, 
    it('can parametrize test', function(value) 
      assert(value == total_value_parametrize)
      total_value_parametrize = total_value_parametrize + 1
    end)
    ),
    parametrize(
    'value1, value2', 
    {
      {1, 9},
      {2, 9},
      {3, 9},
    }, 
    it('can parametrize test with multiple arguments and nested parameters', function(value1, value2) 
      assert(value1 == total_value_parametrize_multi)
      assert(value2 == 9)
      total_value_parametrize_multi = total_value_parametrize_multi + 1
    end)
    )
  )
end)
assert(stdout:match('6 passed in'), 'Parametrize tests did not pass')



--error in test, parametrized test
_reset_stdout_and_run_tests(function()
  describe('Failing tests', 
    it('passes', function() end),
    it('fails', function() error('fail') end),
    parametrize('value', {1, 2},
    it('fails', function(value, request) error('fail') end)
    )
  )
end)
assert(stdout:match('3 failed, 1 passed in'), 'Failing tests did not have correct message')
assert(stdout:match('%.FFF\n'), 'Incorrect test results')



--error in fixture create, fixture teardown
_reset_stdout_and_run_tests(function()

  fixture('fail_before', function(request)
    error('before')
  end)

  fixture('fail_after', function(request)
    request.addfinalizer(function() error('after') end)
  end)
  
  fixture('fail_before_and_after', function(request)
    request.addfinalizer(function() error('after') end)
    error('before')
  end)

  describe('Failing fixture tests 1', 
    it('errors during fixture setup', function(fail_before) 
    end),
    it('errors during fixture setup with failing test', function(fail_before) 
      error('during')
    end)
  )
  describe('Failing fixture tests 2', 
    it('errors during fixture teardown', function(fail_after) 
    end),
    it('errors during fixture teardown with failing test', function(fail_after) 
      error('during')
    end)
  )
  describe('Failing fixture tests 3', 
    it('errors during fixture setup and teardown', function(fail_before_and_after) 
    end),
    it('errors during fixture setup and teardown with failing test', function(fail_before_and_after) 
      error('during')
    end)
  )
end)
assert(stdout:match('5 failed, 1 passed, 8 error in'), 'Failing fixture tests did not pass')
assert(stdout:match('Failing fixture tests 1: EFEF'), 'Incorrect success/fail/error status written to stdout')
assert(stdout:match('Failing fixture tests 2: %.EFE'), 'Incorrect success/fail/error status written to stdout')
assert(stdout:match('Failing fixture tests 3: EFEEFE'), 'Incorrect success/fail/error status written to stdout')


-- TODO: Skiped test tests


