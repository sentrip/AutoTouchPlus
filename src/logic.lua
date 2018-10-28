---- Logical operation utilites
-- @module logic


local type_index = {
  ['str'] = 'string',
  ['num'] = 'number',
  ['bool'] = 'boolean',
  ['tbl'] = 'table',
  ['file'] = 'userdata',
  ['func'] = 'function'
}

---- Check if sub is contained in main (like Python's "x in y" syntax)
-- @param sub
-- @param main
-- @return
function isin(sub, main) 
  local mt = getmetatable(main)
  
  if mt and mt.contains then 
    return main:contains(sub) 

  else
    if is.str(main) then 
      return Not.Nil(main:find(sub))

    elseif is.table(main) then 
      for i=1, rawlen(main) do 
        if requal(sub, main[i]) then 
          return true 
        end 
      end
    end
  end
  
  return false
end

---- Check if sub is NOT contained in main (like Python's "x not in y" syntax)
-- @param sub
-- @param main
-- @return
function isnotin(sub, main) return not isin(sub, main) end

---- Check if an object is of one or more types
-- @param object object to check type of
-- @param ... types to check for
-- @treturn boolean is the object type in the given types
function isType(object, ...)
  local types = {...}
  if rawlen(types) == 1 then return type(object) == types[1] end
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
is = {}

--- Check if an object is falsy (like Python's "if not x" syntax)
-- @param object
Not = {}

is = setmetatable(is, {
  --check truthy
  __call = function(s, object)
    if object == nil or object == false or object == 0 then
      return false
    elseif isType(object, 'number', 'boolean', 'userdata', 'function') then
      return true
    elseif isType(object, 'string') then
      return rawlen(object) > 0
    elseif isType(object, 'table') then
      local size = rawlen(object)
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
      return isType(v, (type_index[value] or value):lower()) 
    end
  end
})

Not = setmetatable(Not, {
  --check falsy
  __call = function(s, object) return not is(object) end,
  --check type
  __index = function(s, value) 
    return function(v) return not is[value](v) end
  end
})
