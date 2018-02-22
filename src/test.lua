--- Basic unit-testing framework
-- @module test
require("src/core")

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


--- Calls test functions in a table (indexed by name) and prints failures
-- @param description general description of tests
-- @param tests table of test functions (function that makes assertions)
-- @param setup function that sets up the test environment
-- @param teardown function that tears down/cleans up the test environment
-- @usage local failed = false
--- failed = failed or test('my test description', {
---          myTest1 = function() assert(true, "my error message1") end,
---          myTest2 = function() assert(true, "my error message2") end,
---        })
function test(description, tests, setup, teardown) 
  local failed = false
  local test_vars
  table.sort(tests)
  for test_name, tst in pairs(tests) do 
    test_vars = {}
    if isNotNil(setup) then setup(test_vars) end
    success, err = pcall(tst, test_vars)
    if isNotNil(teardown) then teardown(test_vars) end
    if not success then 
      if not failed then 
        print(description) 
        failed = true 
      end
      print(string.gsub(err, "(.*):([0-9]+): ", function(path, n) 
            return string.format('\n    FAILURE in %s -> %s @ %d\n    ==> ', test_name, path, n) 
            end) .. '\n') 
    end 
  end
  return failed
end