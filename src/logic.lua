---- Logic and math operations.
-- @module logic

--- Logic
-- @section logic


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




local type_index = {
  ['str'] = 'string',
  ['num'] = 'number',
  ['bool'] = 'boolean',
  ['tbl'] = 'table',
  ['file'] = 'userdata',
  ['func'] = 'function'
}

---- Check if an object is of one or more types
-- @param object object to check type of
-- @param ... types to check for
-- @treturn boolean is the object type in the given types
function isType(object, ...)
  local types = {...}
  if #types == 1 then return type(object) == types[1] end
  local is_type = false
  for i, v in pairs(types) do
    is_type = is_type or type(object) == (type_index[v] or v)
  end
  return is_type
end

---- Check if an object is not of one or more types
-- @param object object to check type of
-- @param ... types to check for
-- @treturn boolean is the object type not in the given types
function isNotType(object, ...)
  return not isType(object, ...)
end


--- Check if an object is truthy (like Python's "if x" syntax).
--- Truthy objects are any objects except for 0, false, nil and objects where len(object) == 0
-- @param object
is = setmetatable({}, {
  --check truthy
  __call = function(s, object)
    if object == nil or object == false or object == 0 then
      return false
    elseif isType(object, 'number', 'boolean', 'userdata', 'function') then
      return true
    elseif isType(object, 'string') then
      return #object > 0
    elseif isType(object, 'table') then
      local size = #object
      if size == 0 then
        for i, v in pairs(object) do
          size = size + 1
        end
      end
      return size > 0
    end
  end,
  --check type
  __index = function(s, value)
    return function(v) 
      local s = type_index[value] or value
      return isType(v, s:lower()) 
      end
  end
  })

--- Check if an object is falsy (like Python's "if not x" syntax)
-- @param object
Not = setmetatable({}, {
    --check falsy
    __call = function(s, object) return not is(object) end,
    --check type
    __index = function(s, value) 
      return function(v) return not is[value](v) end
    end
  })

---- Check if all values in two tables are equal (recursive-equal)
-- @tparam table value1 table for equality check
-- @tparam table value2 table for equality check
-- @treturn boolean all values in both tables are recursively equal
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

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

--- Math
-- @section math

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

---- Length of object (python style!)
-- @param input any object 
-- @treturn number length of the object
function len(input) 
  if is.Nil(input) then return 0
  elseif is.num(input) or is.Bool(input) then return 1
  else
    local total = 0
    for i, v in pairs(input) do total = total + 1 end
    return total 
  end
end

---- Round number to places (python style!)
-- @tparam number num number to round
-- @tparam number places number of decimal places to round to
-- @treturn number num rounded to places
function round(num, places) 
  local value = num * 10^places
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

---- Sum of an object (python style!)
-- @tparam table object containing numbers 
-- @treturn number result of adding all numbers in the object
function sum(object) 
  local total = 0
  for i, v in pairs(object) do total = total + v end
  return total
end
