--- Basic unit-testing framework
-- @module test
require("src/core")

local popen = io.popen

local _count               = {success=0, failed=0, skipped=0, errors=0}
local _errors              = {}
local _fixtures            = {}
local _test_utils          = {}
local _tests               = {}
local _tests_duration      = 0

local _current_fixtures    = {}
_current_fixtures.func     = {}
_current_fixtures.group    = {}
_current_fixtures.module   = {}

local _finalizers    = {}
_finalizers.func     = {}
_finalizers.group    = {}
_finalizers.module   = {}


local _lines_of_this_file = {}
local _ansi_keys = {
  reset      = 0,
  bright     = 1,
  dim        = 2,
  red       = 31,
  green     = 32,
  yellow    = 33,
  blue      = 34,
  magenta   = 35,
  cyan      = 36,
  white     = 37,
}
local _concatenated = ''
if rootDir then 
  io.write = function(s) 
    _concatenated = _concatenated..s
     if _concatenated:match('\n') then print(_concatenated); _concatenated = '' end 
  end 
end


local function format_ne(msg, v1, v2)
  msg = msg or ''
  return msg..string.format(' ==> %s != %s', str(v1 or ''), str(v2 or ''))
end

local function format_ge(msg, more, less)
  msg = msg or ''
  return msg..string.format(' ==> %s is not greater than %s', tostring(more), tostring(less))
end


---- Assert two values are equal
-- @param v1
-- @param v2
-- @param msg
function assertEqual(v1, v2, msg) assert(v1 == v2, format_ne(msg, v1, v2)) end

---- Assert two values not are equal
-- @param v1
-- @param v2
-- @param msg
function assertNotEqual(v1, v2, msg) assert(v1 ~= v2, format_ne(msg, v1, v2)) end

---- Assert two values are recursively equal
-- @param v1
-- @param v2
-- @param msg
function assertRequal(v1, v2, msg) assert(requal(v1, v2), format_ne(msg, v1, v2)) end

---- Assert two values are not recursively equal
-- @param v1
-- @param v2
-- @param msg
function assertNotRequal(v1, v2, msg) assert(not requal(v1, v2), format_ne(msg, v1, v2)) end

---- Assert a value is less than another value
-- @param less
-- @param more
-- @param msg
function assertLessThan(less, more, msg) assert(less < more, format_ge(msg, more, less)) end

---- Assert a value is more than another value
-- @param more
-- @param less
-- @param msg
function assertMoreThan(more, less, msg) assert(more > less, format_ge(msg, more, less)) end

---- Assert a value is less than or equal to another value
-- @param less
-- @param more
-- @param msg
function assertLessThanEqual(less, more, msg) assert(less <= more, format_ge(msg, more, less)) end

---- Assert a value is more than or equal to another value
-- @param more
-- @param less
-- @param msg
function assertMoreThanEqual(more, less, msg) assert(more >= less, format_ge(msg, more, less)) end

---- Assert a function raises an error mathing a pattern
-- @param exception
-- @param func
-- @param msg
function assertRaises(exception, func, msg) 
  local success, result = pcall(func)
  if isNotType(exception, 'string') then
    exception = exception.type
  end
  assert(not success, 'No exception raised: '..msg)
  assert(string.find(result or '', tostring(exception)), 'Incorrect error raised: '..msg)
end


--- Define a group of tests
-- @tparam string description description of test group
-- @param ... tests defined with @{it}
-- @usage describe('Example tests',
---  it('makes an assertion', function() 
---    assert(true)  
---  end)
--- )
function describe(description, ...)
  local test_functions = {...}
  table.insert(_tests, {description=description, func=function()
    for i, test_funcs in pairs(test_functions) do
      if test_funcs.func ~= nil then test_funcs = {test_funcs} end
      for _, test_obj in pairs(test_funcs) do
        local _, err = pcall(test_obj.func, test_obj.f, description)
        _test_utils.write_test_result(err, description, test_obj.description)
        _test_utils.destroy_all_fixtures('func', description, test_obj.description)
      end
    end
  end})
end


--- Define a single test to be used in @{describe}
-- @tparam string description description of test
-- @tparam function f a test function (function that makes assertions)
function it(description, f)
  return {description=description, f=f, func=function(fn, group_description)
      local arg_table = _test_utils.setup_teardown_test(
        function(err) end, _test_utils.create_arg_table, fn, description
      )
      if type(arg_table) == 'string' then return {msg=arg_table, args={}} end
      local status, err = pcall(fn, unpack(arg_table))
      if not status then return {msg=err, args=arg_table} end
    end}
end


--- Define a fixture to be used in tests
-- @tparam string name name of the fixture
-- @param scope (optional) scope in which to create fixture ('func', 'group', 'module')
-- @param f function that creates the fixture (if the 'scope' argument is omitted then 'scope' is treated as 'f')
-- @usage fixture('myFixture', 'func', function() 
---   return 1
--- end)
--- describe('Example tests',
---  it('makes an assertion', function(myFixture) 
---    assert(myFixture == 1)  
---  end)
--- )
function fixture(name, scope, f)
  if f then
    _fixtures[name] = {func=f, scope=scope}
  else
    _fixtures[name] = {func=scope, scope='func'}
  end
end


--- Run a single test with multiple parameters
-- @tparam string names fixtures to parametrize (comma separated)
-- @param parameters table of parameters - if more than one parameter is specified this must be a table of tables
-- @tparam function f test function created with @{it}
-- @usage describe('Example tests',
---  parametrize('a,b,c', 
---  {
---    {1, 2, 3},
---    {4, 5, 9}
---  },
---  it('makes an assertion', function(a, b, c) 
---    assert(a + b == c)  
---  end))
--- )
function parametrize(names, parameters, f)
    local fields = {}
    names:gsub("([^,]+)", function(c) fields[#fields+1] = c end)
    local arg_names = _test_utils.get_arg_names(f.f)
    local _args = {}
    for _, k in pairs(arg_names) do
        local in_fields = false
        for _, n in pairs(fields) do
            if k:gsub(' *', '') == n:gsub(' *', '') then in_fields = true; break end
        end
        if not in_fields then table.insert(_args, k) end
    end
    local args_string = table.concat(_args, ',')
    local args_inner = args_string
    if args_inner ~= '' then args_inner = ', '..args_inner end
    local parametrized = {}
    for _, params in pairs(parameters) do
        if type(params) ~= 'table' then params = {params} end
        local code = 'function(%s) f(unpack(params)%s) end'
        local pfunc = load('return '..code:format(args_string, args_inner), nil, "t", {
          f=f.f, params=params, unpack=unpack
        })()
        table.insert(parametrized, {description=f.description, func=f.func, f=pfunc})
    end
    return parametrized
end


--- Run all described tests and write results to stdout
function run_tests()
  _test_utils.write_began_tests()
  
  local begin_time = _test_utils.get_system_time()
  for _, test_obj in pairs(_tests) do
    _test_utils.write_test_description(test_obj.description)
    
    test_obj.func()
    _test_utils.destroy_all_fixtures('group', test_obj.description)
    
    io.write('\n')
  end
  _test_utils.destroy_all_fixtures('module')
  _tests_duration = _test_utils.get_system_time() - begin_time

  local exit_code = math.min(1, _count.failed + _count.errors)
  _test_utils.write_completed_tests()
  _test_utils.write_errors()
  _test_utils.reset_internals()
  return exit_code
end



-- function skip() end
-- TODO: Skip tests
-- _test_utils.get_line_stripped(debug.getinfo(1).currentline - 1) == 'skip()'



---
function _test_utils.ansi(c)
  if rootDir then return end
  if type(c) == 'string' then c = _ansi_keys[c] end
  io.write(string.char(27)..'['..tostring(c)..'m')
  end

---
function _test_utils.create_arg_table(f, desc)
  local arg_table = {}
  local params = _test_utils.get_arg_names(f)
  for i, v in pairs(params) do 
    if v == 'request' then
      arg_table[i] = {addfinalizer=function(f) table.insert(_finalizers.func, {f=f, name=v}) end}
    elseif v == 'monkeypatch' then
      arg_table[i] = {setattr=function(o, k, v) _test_utils.setattr(_finalizers.func, desc, o, k, v) end}
    else
      arg_table[i] = _test_utils.create_fixture(v)
    end
  end
  return arg_table
end

---
function _test_utils.create_fixture(name)
  local fix = _fixtures[name]
  if not fix then error('Fixture "'..name..'" is not defined') end
  -- return fixture if exists
  for fixt_name, fixt in pairs(_current_fixtures[fix.scope]) do
    if name == fixt_name then
      return fixt.value
    end
  end
  -- create fixture
  local arg_table = _test_utils.get_fixture_args(fix.func, fix.scope, name)
  local status, result = pcall(fix.func, unpack(arg_table))
  if not status then 
    _current_fixtures[fix.scope][name] = {value=nil}
    error(string.format('Error setting up fixture %s: %s', name, result)) 
  end
  _current_fixtures[fix.scope][name] = {value=result}
  return result
end

---
function _test_utils.destroy_all_fixtures(scope, desc, func_name)
  _test_utils.setup_teardown_test(
  
    function(err) 
      _test_utils.insert_error({msg=err, args={}}, func_name or '', desc or 'Teardown')
    end,
      
    function()
      for name, fixtures in pairs(_current_fixtures[scope]) do
        _current_fixtures[scope][name] = nil
      end
      for _, final in pairs(_finalizers[scope]) do 
        local status, result = pcall(final.f)
        if not status then error(string.format('Error tearing down fixture %s: %s', final.name, result)) end
      end
      _finalizers[scope] = {}
    end
  )
end

---
function _test_utils.get_arg_names(f)
  local co = coroutine.create(f)
  local params = {}
  -- luacov: disable
  debug.sethook(co, function()
      local i, k = 1, debug.getlocal(co, 2, 1)
      while k do
        if k ~= "(*temporary)" then table.insert(params, k) end
        i = i+1
        k = debug.getlocal(co, 2, i)
      end
      error("~~end~~")
    end, "c")
  -- luacov: enable
  local res, err = coroutine.resume(co)
  if res then 
    error("The function provided defies the laws of the universe.", 2)
  elseif string.sub(tostring(err), -7) ~= "~~end~~" then 
    error("The function failed with the error: "..tostring(err), 2)
  end

  return params

end

---
function _test_utils.get_fixture_args(func, scope, fix_name)
  local arg_table = {}
  
  local params = _test_utils.get_arg_names(func)
  for i, name in pairs(params) do 
    if name == 'request' then
      arg_table[i] = {addfinalizer=function(f) table.insert(_finalizers[scope], {f=f, name=fix_name}) end}
    elseif name == 'monkeypatch' then
      arg_table[i] = {setattr=function(o, k, v) _test_utils.setattr(_finalizers[scope], fix_name, o, k, v) end}
    else
      arg_table[i] = _test_utils.create_fixture(name)
    end
  end
  return arg_table
end

---
-- function _test_utils.get_line_stripped(lineno)  
--   if #_lines_of_this_file == 0 then 
--     for l in io.lines(debug.getinfo(1, 'S').short_src) do 
--       _lines_of_this_file[#_lines_of_this_file + 1] = l 
--     end
--   end
--   return _lines_of_this_file[lineno]:gsub('[ \t]*', '')
-- end

---
function _test_utils.get_system_time()
  local _time = os.time()
  pcall(function() 
    local _f = assert(io.popen('date +%s%N'))
    _time = tonumber(_f:read()) / 1000000000
    assert(_f:close())
  end)
  return _time  
end

---
function _test_utils.get_terminal_width(default_width)
  local width = default_width
  pcall(function() 
    local _f = assert(io.popen('tput cols'))
    width = tonumber(_f:read()) or default_width
    assert(_f:close())
  end)
  return width  
end

---
function _test_utils.insert_error(err, test_desc, group_desc)
  local file_location = err.msg:match('(.*:%d+):.*')
  local line_no = err.msg:match('.*:(%d+):.*')
  local message = err.msg:match('.*:%d+: (.*)')
  table.insert(_errors, {
    fixtures   = err.args,
    group_name = group_desc, 
    test_name  = test_desc, 
    message    = message, 
    location   = file_location,
    line_no    = line_no
  })
end

---
function _test_utils.reset_internals()
  _count                     = {success=0, failed=0, skipped=0, errors=0}
  _current_fixtures.func     = {}
  _current_fixtures.group    = {}
  _current_fixtures.module   = {}
  _errors                    = {}
  _fixtures                  = {}
  _tests                     = {}
  _tests_duration            = 0
  
end

---
function _test_utils.setattr(finalizers, name, obj, key, value)
  local current_value, finalize
  if value == nil then 
    current_value = _G[obj]
    finalize = function() _G[obj] = current_value end
    _G[obj] = key
  else
    current_value = obj[key]
    finalize = function() obj[key] = current_value end
    obj[key] = value
  end
  table.insert(finalizers, {f=finalize, name=name})
end

---
function _test_utils.setup_teardown_test(on_complete, f, ...)
  local status, result = pcall(f, ...)
  if not status then 
    io.write('E') 
    _count.errors = _count.errors + 1
    if result then 
      on_complete(result) 
    end
  end
  return result
end

local _terminal_width = _test_utils.get_terminal_width(50)

---
function _test_utils.write_equals_padded(msg)
  local width = _terminal_width - string.len(msg) - 8
  for i=1, width/2 do io.write('=') end
  io.write('    '..msg..'    ')
  for i=1, width/2  do io.write('=') end
  io.write('\n')
end

---
function _test_utils.write_began_tests()
  _test_utils.ansi('bright')
  _test_utils.write_equals_padded('test session starts')
  io.write('testing: ')
  _test_utils.ansi('reset')
  _test_utils.ansi('white')
  io.write(debug.getinfo(1, 'S').short_src..'\n')
  _test_utils.ansi('reset')
  io.write('\n')
end

---
function _test_utils.write_completed_tests()
  io.write('\n')
  local message = ''
  if _count.failed == 0 then 
    if _count.success > 0 then
      _test_utils.ansi('bright')
      _test_utils.ansi('green')
    else
      _test_utils.ansi('yellow')
    end
  else
    _test_utils.ansi('bright')
    _test_utils.ansi('red')
    message = message.._count.failed..' failed'
    if _count.success > 0 then message = message..', ' end
  end
  if _count.success > 0 then message = message.._count.success..' passed' end
  if _count.skipped > 0 then message = message..', '.._count.skipped..' skipped' end
  if _count.errors > 0 then message = message..', '.._count.errors..' error' end
  if _count.success + _count.skipped + _count.errors == 0 then
    message = 'No tests found'
  else
    message = message..string.format(' in %.2f seconds', _tests_duration)
  end
  _test_utils.write_equals_padded(message)
  _test_utils.ansi('reset')
  _test_utils.ansi('reset')
  io.write('\n')
end

---
function _test_utils.write_test_description(description)
  io.write('\t'..description..': ')
end

---
function _test_utils.write_errors()
  if #_errors > 0 then
    io.write('Collected errors:\n\n')
    for _, err in pairs(_errors) do
      _test_utils.ansi('bright')
      _test_utils.ansi('red')
      io.write(string.format('%s - %s ', err.group_name, err.test_name))
      _test_utils.ansi('reset')
      
      _test_utils.ansi('yellow')
      io.write(string.format('@ %s', err.line_no))
      _test_utils.ansi('reset')

      local tab_count = 1
      local function _tab(n) tab_count = tab_count + (n or 0); return string.rep('\t', tab_count-1) end
      io.write('\n'.._tab(1)..'|--> ')

      _test_utils.ansi('cyan')
      io.write(string.format('%s\n', err.location))
      _test_utils.ansi('reset')
    
      io.write(string.format(_tab(1)..'%s\n', err.message))
      
      io.write('\n')
    end
  end
end

---
function _test_utils.write_test_result(err, group_desc, test_desc)
  if err == nil then
    io.write('.')
    _count.success = _count.success + 1
  elseif err.msg ~= nil then
    io.write('F')
    _count.failed = _count.failed + 1
    _test_utils.insert_error(err, test_desc, group_desc)
  end
end
