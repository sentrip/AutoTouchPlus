---- Some of Python's builtin functions
-- @module builtins

-- luacov: disable

---- Get absolute value of a number
-- @tparam number n any number
-- @treturn number absolute value of number
function abs(n) return math.abs(n) end

-- luacov: enable

---- All elements in an iterable evaluate to true
-- @param iterable any table-like object
-- @treturn boolean all elements are true
function all(iterable) 
  for k, v in pairs(iterable) do
    if Not(v) then return false end
  end
  return true
end

---- Any elements in an iterable evaluate to true
-- @param iterable any table-like object
-- @treturn boolean any elements are true
function any(iterable) 
  for k, v in pairs(iterable) do
    if is(v) then return true end
  end
  return false
end

---- Count occurrences of value in input
-- @param value any object
-- @param input any object that can contain value
-- @treturn number how many of value is in input
function count(value, input) 
  local total = 0 
  for i, v in pairs(input) do if v == value then total = total + 1 end end
  return total
end

---- Floor division of x by y
-- @tparam number x the numerator
-- @tparam number y the denominator
-- @treturn number integer result of x / y
function div(x, y) return math.floor(x / y) end

---- Evaluates a string as code and returns result (Python style!)
-- @param input 
-- @return stuff
function eval(input) 
  local f = load(input)
  if f then
    return f() 
  else
    error('Syntax error occurred while parsing input: '..input)
  end
end

-- luacov: disable

---- Filter elements of an iterable with a function
-- @param filt
-- @param iterable
-- @return 
function filter(filt, iterable) return itertools.filter(filt, iter(iterable)) end

-- luacov: enable

---- Unique integer representation of input
-- @param input an integer, string or any object that has a __hash method
-- @return integer unique integer representation of object
function hash(input)
  if is.func(input) then 
    input = tostring(input):match('function: (.*)') 
  else
    local m = getmetatable(input)  
    if m and m.__hash then return m.__hash(input) end
  end
  
  local hsh
  local mod = 2 ^ 64
  if is.num(input) then 
    if input > 0 then hsh = -input * 2 
    elseif input < 0 then hsh = input * 2 - 1
    else hsh = input end
  elseif not is.str(input) then error("Can only hash functions, integers and strings")
  else
    hsh = string.byte(input[1]) * 2 ^ 7
    for i, v in pairs(input) do hsh = (1000003 * hsh + string.byte(v)) % mod end
  end
  return hsh
end

-- luacov: disable

---- Convert input into an integer
-- @param input any object that can be converted into an integer
-- @treturn int of input
function int(input) return math.floor(input) end

-- luacov: enable

---- Iterate over the elements in an iterable
-- @param iterable
-- @return 
function iter(iterable) 
  if type(iterable) == 'function' then return iterable end
  return itertools.values(iterable) 
end

---- Length of iterable
-- @param input any iterable
-- @treturn number length of the iterable
function len(input) 
  if is.Nil(input) then return 0
  elseif is.num(input) or is.Bool(input) then return 1
  else
    local total = 0
    for i, v in pairs(input) do total = total + 1 end
    return total 
  end
end

-- luacov: disable

---- Call function on each element of an iterable
-- @param func
-- @param iterable
-- @return 
function map(func, iterable) return itertools.map(func, iter(iterable)) end

-- luacov: enable

---- Get the maximum value of two or more values
-- @param ... any objects that can be compared with <, >, and ==
-- @return maximum value of what was passed
function max(...) 
  local args
  if is.table(...) then args = ... else args = {...} end
  local mt = getmetatable(args)
  if mt and mt.__name == 'set' then -- special case for set objects
    args = args:values() 
  end
  return math.max(unpack(args))
end

---- Get the minimum value of two or more values
-- @param ... any objects that can be compared with <, >, and ==
-- @return minimum value of what was passed
function min(...) 
  local args
  if is.table(...) then args = ... else args = {...} end
  local mt = getmetatable(args)
  if mt and mt.__name == 'set' then -- special case for set objects
    args = args:values() 
  end
  return math.min(unpack(args))
end

-- luacov: disable

---- Convert input into a number
-- @param input any object that can be converted into a number
-- @treturn number input as a number
function num(input) return tonumber(input) end

-- luacov: enable

---- Simple string representation of an object
-- @param input
-- @return 
function repr(input) 
  local m = getmetatable(input)
  if m and m.__repr then return input:__repr()
  else return tostring(input) end
end

---- Check if all values in two iterables are equal (recursive-equal)
-- @param value1 iterable for equality check
-- @param value2 iterable for equality check
-- @treturn boolean all values in both iterables are recursively equal
function requal(value1, value2)
  local all_equal = type(value1) == type(value2)
  if all_equal and not is.table(value1) then 
    return value1 == value2 
  elseif all_equal then
    all_equal = len(value1) == len(value2)
  else
    return false
  end
  
  local l1, l2 = {}, {}
  for i, v in pairs(value1) do 
    if is.num(v) then v = str(v) end
    table.insert(l1, v)
  end
  for i, v in pairs(value2) do 
    if is.num(v) then v = str(v) end
    table.insert(l2, v)
  end
  
  local function sorter(first, second) 
    if is.table(first) or isType(first, 'function') then  return false end
    if type(first) ~= type(second) then return false end
    return first < second
  end
  table.sort(l1, sorter)
  table.sort(l2, sorter)
  for i, v in pairs(l1) do
    if not all_equal then return false end
    if is.table(v) then
      all_equal = requal(v, l2[i])
    else
      all_equal = type(v) == type(l2[i])
      if all_equal then all_equal = v == l2[i] end
    end
  end
  return all_equal
end

---- Reverse the order of the elements in an iterable
-- @param iterable object to reverse order of
-- @treturn table copy of object with elements in reverse order
function reversed(iterable)
  if is.str(iterable) then return iterable:reverse() end
  local result = list()
  for i, v in pairs(iterable) do result:insert(1, v) end
  return result
end

---- Round a number to places
-- @tparam number n number to round
-- @tparam number places number of decimal places to round to
-- @treturn number num rounded to places
function round(n, places) 
  places = places or 1
  local value = n * 10^places
  if value - math.floor(value) >= 0.5 then value = value + 1 end
  return math.floor(value) / 10 ^ places
end

---- Sign of a number
-- @tparam number n any number
-- @treturn 1|-1 sign of the number
function sign(n) 
  if n == 0 then return 1 
  else return math.floor(n / math.abs(n)) end 
end

---- Sort an object
-- @param object
-- @param key
-- @param reverse
-- @return 
function sorted(object, key, reverse) 
  local sorter
  local cp = copy(object)
  if type(key) == 'function' then
    sorter = function(v1, v2)
      v1, v2 = key(v1), key(v2)
      return v1 < v2
    end
  elseif type(key) == 'boolean' then 
    reverse = key
  end
  table.sort(cp, sorter)
  if reverse then cp = reversed(cp) end
  return cp
end


---- Sum of the values in an iterable
-- @tparam table iterable containing numbers 
-- @treturn number result of adding all numbers in the iterable
function sum(iterable) 
  local total = 0
  for i, v in pairs(iterable) do total = total + v end
  return total
end
