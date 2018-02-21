---- Logic and math operations.
-- @module logic

--- Logic
-- @section logic

---- Check if input IS of given type.
-- @param input object to check type of
-- @param _type type to check for
-- @return boolean
function isType(input, _type) return type(input) == _type end

---- Check if input IS NOT of given type.
-- @param input object to check type of
-- @param _type type to check for
-- @return boolean
function isNotType(input, _type) return not isType(input, _type) end

---- Check if input is boolean
-- @param input object to check type
-- @return boolean
function isBool(input) return isType(input, 'boolean') end

---- Check if input is nil
-- @param input object to check type
-- @return boolean
function isNil(input) return isType(input, 'nil') end

---- Check if input is not nil
-- @param input object to check type
-- @return boolean
function isNotNil(input) return not isNil(input) end

---- Check if input is number
-- @param input object to check type
-- @return boolean
function isNum(input) return isType(input, 'number') end

---- Check if input is string
-- @param input object to check type
-- @return boolean
function isStr(input) return isType(input, 'string') end

---- Check if input is table
-- @param input object to check type
-- @return boolean
function isTable(input) return isType(input, 'table') end

---- Check if all values in two tables are equal (recursive-equal)
-- @param value1 table for equality check
-- @param value2 table for equality check
-- @return boolean
function requal(value1, value2)
  local all_equal = type(value1) == type(value2)
  if all_equal and not isTable(value1) then 
    return value1 == value2 
  elseif all_equal then
    all_equal = len(value1) == len(value2)
  else
    return false
  end
  
  local l1, l2 = {}, {}
  for i, v in pairs(value1) do 
    if isNum(v) then v = str(v) end
    table.insert(l1, v)
  end
  for i, v in pairs(value2) do 
    if isNum(v) then v = str(v) end
    table.insert(l2, v)
  end
  
  local function sorter(first, second) 
    if isTable(first) or isType(first, 'function')then  return false end
    if type(first) ~= type(second) then return false end
    return first < second
  end
  table.sort(l1, sorter)
  table.sort(l2, sorter)
  for i, v in pairs(l1) do
    if not all_equal then return false end
    if isTable(v) then
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
-- @param value
-- @param input
-- @return
function count(value, input) 
  local total = 0 
  for i, v in pairs(input) do if v == value then total = total + 1 end end
  return total
  end

---- Floor division of x by y
-- @param x
-- @param y
-- @return
function div(x, y) return math.floor(x / y) end

---- Length of object (python style!)
-- @param input 
-- @return
function len(input) 
  if isNil(input) then return 0
  elseif isNum(input) or isBool(input) then return 1
  else
    local total = 0
    for i, v in pairs(input) do total = total + 1 end
    return total 
  end
end

---- Round number to places (python style!)
-- @param num
-- @param places
-- @return
function round(num, places) 
  local value = num * 10^places
  if value - math.floor(value) >= 0.5 then value = value + 1 end
  return math.floor(value) / 10 ^ places
end

---- Sign of a number 
-- @param n 
-- @return
function sign(n) 
  if n == 0 then return 1 
  else return math.floor(n / math.abs(n)) end 
end

---- Sum of an object (python style!)
-- @param object 
-- @return
function sum(object) 
  local total = 0
  for i, v in pairs(object) do total = total + v end
  return total
end
