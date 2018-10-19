--- Python's basic objects: dict, list and set
-- @module objects

require("src/logic")

--Python-like typed equality checking
local function namedRequality(name)
  return function(me, other)
    local mt = getmetatable(other)
    if mt and mt.__name == name then
      return requal(me, other) 
    end
    return false
  end
end

--- Dict object - mirrors Python's 'dict' api as closely as possible
-- @type dict
dict = class('dict')

function dict:__init(dct) self:update(dct or {}) end

function dict:__add(other) 
  local result = dict(self)
  result:update(other)
  return result
end

function dict:__call(...) 
  assert(is.Nil(...), 'Dict can only be called in a for-loop')
  local key, value
  return function()
    key, value =  next(self, key, value)
    return key
  end
end

function dict:__eq(other) return namedRequality('dict')(self, other) end

function dict:__setitem(key, value) self:set(key, value) end

function dict:__ipairs() return self:__pairs() end

function dict:__len() return 0 end

function dict:__pairs() 
  local function iter(value, key)
    key, value =  next(self, key, value)
    return key, value
  end
  return iter, self, nil
end

--- Clear all the keys and values in the dictionary
function dict:clear() for k, v in pairs(self) do self:set(k, nil) end end

--- Check if the dict contains a key
-- @param key key to check for
-- @return (boolean) is the key in the dict
function dict:contains(key) return Not.Nil(rawget(self, key)) end

--- Get the value indexed by the given key in the dictionary
-- @param key key index of dictionary
-- @param default value to return if key is not in dictionary
-- @return value indexed by key if key is in dictionary, otherwise default (nil)
function dict:get(key, default) return rawget(self, key) or default end

--- List all the key, value pairs in the dictionary
-- @return pairs iterator
function dict:items() return pairs(self) end

--- List all the keys in the dictionary
-- @return 'list' of keys
function dict:keys() 
  local ks = list()
  for k in self() do ks:append(k) end
  return sorted(ks) 
end

--- Pop a value from the dictionary given by key, or return a default
-- @param key key index of dictionary
-- @param default default value to return
function dict:pop(key, default) 
  if key then
    result = rawget(self, key) or default
    rawset(self, key, nil) 
    return result
  else
    local k, v = pairs(self)(self)
    rawset(self, k, nil)
    return v
  end
end

--- Set the value indexed by given key to given value
-- @param key key index of dictionary
-- @param value value to set at given key
function dict:set(key, value) rawset(self, key, value) end

--- Update current dictionary's keys and values with given dictionary's keys and values
-- @param other dictionary (or string indexed table) to use for update
function dict:update(other) for k, v in pairs(other) do self:set(k, v) end end

--- List all the values in the dictionary
-- @return 'list' of values
function dict:values() 
  local vs = list()
  for k, v in pairs(self) do vs:append(v) end
  return vs 
end

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

---- List object - mirrors Python's 'list' api as closely as possible
-- @type list
list = class('list')


function list:__init(lst) 
  if is.table(lst) then self:extend(lst) end
end

function list:__add(other) local new = list(self); new:extend(other); return new end

function list:__call(start, _end, step) 
  local key, value
  local slice = list()
   
  if is.Nil(start or _end or step) then  -- no arguements -> for loop
    return function()
      key, value =  next(self, key, value)
      return value
    end
  else -- arguments -> slice
    _end = _end or #self
    if _end < 0 and not step then _end = #self + 1 + _end end
    if is.table(start) then for i, v in pairs(start) do slice:append(self[v]) end
    else for i=start, _end, step or 1 do slice:append(self[i]) end end
    return slice  
  end
end

function list:__eq(other) return namedRequality('list')(self, other) end

function list:__len() return len(self) end

function list:__getitem(value) 
  if is.str(value) then return rawget(list, value) 
  else 
    if sign(value) < 0 then value = #self + 1 + value end
    return rawget(self, value) end
end

function list:__mul(n)
  local result = list()
  for i=1, n do result:extend(self) end
  return result
end

---- Append a value to the list
-- @param value the value to append
function list:append(value) rawset(self, #self + 1, value) end

--- Clear the list of all values
function list:clear() for k, _ in pairs(self) do rawset(self, k, nil) end end

---- Check if the list contains a value
-- @param value value to check for
-- @return (boolean) is the value in the list
function list:contains(value)
  for i, v in pairs(self) do if requal(v, value) then return true end end
  return false
end

---- Extend the list with the given values
-- @param values values to add (can be a table or a list)
function list:extend(values) for i, v in pairs(values) do self:append(v) end end

---- Get index of the requested value in the list
-- @param value the value to index
-- @return index of requested value
function list:index(value) for i, v in pairs(self) do if requal(v, value) then return i end end end

---- Insert a value into the list at the given index
-- @param index the index at which to insert value
-- @param value value to insert
function list:insert(index, value) 
  for i=#self, index, -1 do rawset(self, i + 1, rawget(self, i)) end
  rawset(self, index, value)
end

---- Pop a value out of the list at given index. If index is nil then returns first value in list
-- @param index the index of the value in the list
-- @return value
function list:pop(index) 
  local value = rawget(self, index or 1)
  for i=index or 1, #self do rawset(self, i, rawget(self, i + 1)) end
  return value
end

---- Remove a value from list
-- @param value value to remove
function list:remove(value) local _ = self:pop(self:index(value)) end

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

--- Set object - mirrors Python's 'set' api as closely as possible
-- @type set
set = class('set')

function set:__init(s)
  self:update(s or {})
end

function set:__add(other) 
  local new = set(self)
  new:update(other)
  return new 
end

function set:__call(...)
  assert(is.Nil(...), 'Set can only be called in a for-loop')
  local key, value
  return function()
    key, value =  next(self, key, value)
    return value
  end
  end

function set:__eq(other) return namedRequality('set')(self, other) end

function set:__len() return 0 end

function set:__pairs()
  local function iter(value, key)
    return next(self, key, value)
  end
  return iter, self, nil
end

function set:__sub(other) return self:difference(other) end


--- Add a value to the set
-- @param value
function set:add(value) 
  if Not.Nil(value) then rawset(self, str(hash(value)), value) end end

--- Clear the set of all values
function set:clear() for v in self() do self:remove(v) end end

--- Check if the set contains a value
-- @param value
function set:contains(value) return Not.Nil(rawget(self, str(hash(value)))) end

--- Difference of two sets
-- @param other
function set:difference(other) 
  local vs = set()
  for v in self() do 
    if is.Nil(rawget(other, str(hash(v)))) then vs:add(v) end 
  end
  return vs
end

--- Pop a value out of the set
-- @param value
function set:pop(value) 
  if value then
    self:remove(value) 
    return value 
  else
    local k, v = pairs(self)(self)
    rawset(self, k, nil)
    return v
  end
end

--- Remove a value from the set
-- @param value
function set:remove(value) rawset(self, str(hash(value)), nil) end

--- Update the set with the values of an object
-- @param other
function set:update(other) for _, v in pairs(other) do self:add(v) end end

--- List of the values in the set
function set:values() 
  local result = {}
  for v in self() do result[#result + 1] = v end
  return result
end
