---- Implementation of many of Python's builtin functions.
-- @module core

--Global variable patching
abs = math.abs
unpack = table.unpack


--convert table to string with special cases for custom objects
local function table2string(input)
  local m = getmetatable(input)
  local function idxstr(idx, val, custom_type) 
    if custom_type then return str(val) 
    elseif is.str(val) then val = '"'..val..'"'
    else val = str(val) end
    if is.str(idx) then idx = '"'..idx..'"'
    else idx = str(idx) end
    return string.format('%s: %s', idx, val)
  end
  
  local custom = m and m.__name and list{'list', 'set'}:contains(m.__name)
  local count, all_int = 0, true
  for i, v in pairs(input) do
    count = count + 1
    if not is.num(i) or i ~= count then 
      all_int = false
      break
    end
  end
  if count ~= #input then all_int = false end
  custom = custom or all_int   
  
  local pre, suf = '{', '}'
  if input == list(input) then  pre, suf = '[', ']' end
  local s = pre
  for i, v in pairs(input) do
    if s ~= pre then s = s .. ', ' end
    s = s .. idxstr(i, v, custom)
  end
  return s .. suf
end



--Index of class names
local classes = {} 
--Table in a class instance's __private variable are stored here
--They are only created upon being indexed for memory efficiency
local private_tables = {}
  
---- Create a new class instance
-- @param name 
-- @param ...
function class(name, ...)
  local c --a new class instance
  local getters, setters = {}, {}
  local bases = {}
  for i, v in pairs({...}) do
    if is.str(v) then v = classes[v] end
    table.insert(bases, v)
  end

  --returns unique table upon intialization
  --not seen to class instance unless indexed specifically with <instance>.__private
  getters.__private = function(self, value)
    local key = tostring(self)
    if not private_tables[key] then
      private_tables[key] = {}
    end
    return private_tables[key]
  end
  
  --protect the __private table
  setters.__private = function()
    error('Cannot set __private table')
  end
  
  --class constructor
  local function constructor(cls, ...)
    local self = {}
    setmetatable(self, c)
    
    if cls.__init then 
      cls.__init(self, ...) 
    else
      for _, base in pairs(bases) do
        if base.__init then 
          base.__init(self, ...)
          break
        end
      end
    end
    
    return self
  end
  
  --class object searches in object first, then in class for value
  local function class_meta_index(cls, value) 
    return rawget(cls, value) or rawget(c, value) 
  end
  
  --can only set values of class object
  local function class_meta_newindex(cls, key, value) 
    rawset(cls, key, value) 
  end
  
  --slight improvement of tostring(<table>)
  local function class_repr(cls)
    return '<'..string.gsub(tostring(cls), 'table:', name..' instance at')..'>'
  end
  
    --custom strings for dict, list and set
  local function class_str(cls)
    if list{'dict', 'list', 'set'}:contains(getmetatable(cls).__name) then
      return table2string(cls)
    else
      return class_repr(cls)
    end
  end
  
  c = {
    __name = name,
    __bases = bases,
    __getters = getters,
    __setters = setters,
    __index = getattr,
    __newindex = setattr,
    __repr = class_repr,
    -- convience methods
    copy = copy,
    isinstance = isinstance
  }

  -- copy any methods from base classes in order of inheritance (youngest first)
  for _, base in pairs(bases) do
    for k, v in pairs(base) do
      if not c[k] then c[k] = v end
    end
  end

  classes[name] = setmetatable(c, {
      __call = constructor,
      __index = class_meta_index,
      __newindex = class_meta_newindex,
      __tostring = class_str,
    })
  return classes[name]
end


---- indexing that supports Python-like property getters
-- @param cls 
-- @param value
function getattr(cls, value)  
  if cls and isType(cls, 'table') then
    local mt = getmetatable(cls)
    local primary = rawget(cls, value)
    if primary then
      return primary
    elseif mt then  
      local fallback = rawget(mt, value) 
      if mt.__getters and mt.__getters[value] then 
        return mt.__getters[value](cls, value)
      elseif mt.__getitem then
        return mt.__getitem(cls, value)
      elseif fallback then
        return fallback
      end
    end
  end
end

---- new indexing that supports Python-like property setters
-- @param cls 
-- @param key
-- @param value
function setattr(cls, key, value)
  local mt = getmetatable(cls)
  if mt.__setters[key] then 
    mt.__setters[key](cls, value)
  else
    if mt.__setitem then 
      mt.__setitem(cls, key, value) 
    else 
      rawset(cls, key, value)
    end
  end
end


---- Copy an object
-- @param object any table-like object
-- @param deep whether to copy recursively
-- @return copy of object at a new memory location
function copy(object, deep) 
  --copy object attributes
  local c = {}
  for k, v in pairs(object) do
    if deep and is.table(v) then c[k] = copy(v, true)
    else c[k] = v end
  end
  --copy metatable attributes
  local mt = {}
  local m = getmetatable(object)
  if m then setmetatable(c, m) end
  
  return c
end

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

---- Unique integer representation of input
-- @param input an integer, string or any object that has a __hash method
-- @return integer unique integer representation of object
function hash(input)
  local m = getmetatable(input)  
  if m and m.__hash then return input:__hash() end
  
  local hsh
  local mod = 2 ^ 64
  if is.num(input) then 
    if input > 0 then hsh = -input * 2 
    elseif input < 0 then hsh = input * 2 - 1
    else hsh = input end
  elseif not is.str(input) then error("Can only hash integers and strings")
  else
    hsh = string.byte(input[1]) * 2 ^ 7
    for i, v in pairs(input) do hsh = (1000003 * hsh + string.byte(v)) % mod end
  end
  return hsh
end


---- Check if sub is contained in main (like Python's "x in y" syntax)
-- @param sub
-- @param main
-- @return
function isin(sub, main) 
  local _is = false
  local length, subLength
  local mt = getmetatable(main)
  if not mt or not mt.contains then 
    if is.str(main) then return Not.Nil(main:find(sub))
    elseif is.table(main) then length = #main; subLength = 1
    else length = 1; subLength = 1 end
    for i=1, length do 
      if _is then break end
      for j=0, subLength do 
        if requal(main[i + j], sub) then 
          _is = true
          break 
        end 
      end 
    end
  else
    _is = main:contains(sub) 
  end
  return _is
end

---- Check if sub is NOT contained in main (like Python's "x not in y" syntax)
-- @param sub
-- @param main
-- @return
function isnotin(sub, main) return not isin(sub, main) end

---- Check if class is an instance of another class recursively
-- @param klass
-- @param other
-- @return boolean
function isinstance(klass, other)
  local m = getmetatable(klass)
  if not m or not m.__name then 
    if not is.str(other) then other = type(other) end
    return type(klass) == other
  else 
    if is.str(other) then other = {__name = other} end 
  end
  
  local i, v
  local to_check = {}
  while m do
    if m.__name == other.__name then
      return true
    else
      for i, v in pairs(m.__bases) do to_check[#to_check + 1] = v end
      i, m = next(to_check, i)
    end
  end
  return false
end

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

---- Numerical representation of input
-- @param input any object that can be converted into a number
-- @return numerical representation of input
function num(input) 
  if is.num(input) then return input else return tonumber(input) end 
end

--pretty printing code modified from
--https://github.com/Anaminus/lua-pretty-print/blob/master/PrettyPrint.lua
local isPrimitiveType = {string=true, number=true, boolean=true}
local typeSortOrder = {
  ['boolean']  = 1;
  ['number']   = 2;
  ['string']   = 3;
  ['function'] = 4;
  ['thread']   = 5;
  ['table']    = 6;
  ['userdata'] = 7;
  ['nil']      = 8;
}


local function isPrimitiveArray(array)
  local max,n = 0,0
  for k,v in pairs(array) do
    if not (type(k) == 'number' and k > 0 and math.floor(k) == k) or not isPrimitiveType[type(v)] then
      return false
    end
    max = k > max and k or max
    n = n + 1
  end
  return n == max
end


local function formatValue(value)
  if type(value) == 'string' then
    return string.format('%q',value)
  else
    return tostring(value)
  end
end


local function formatKey(key,seq)
  if seq then return "" end
  if type(key) == 'string' then
    if key:match('^[%a_][%w_]-$') == key then -- key is variable name
      return key .. " = "
    else
      return "[" .. string.format('%q',key) .. "] = "
    end
  else
    return "[" .. tostring(key) .. "] = "
  end
end


local function traverseTable(dataTable,tableRef,indent,delim)
  delim = delim or ','
  local output = ""
  local indentStr = string.rep("\t",indent)

  local keyList = {}
  for k,v in pairs(dataTable) do
    if isPrimitiveType[type(k)] then
      keyList[#keyList + 1] = k
    end
  end
  table.sort(keyList,function(a,b)
    local ta,tb = type(dataTable[a]),type(dataTable[b])
    if ta == tb then
      if type(a) == 'number' and type(b) == 'number' then
        return a < b
      else
        return tostring(a) < tostring(b)
      end
    else
      return typeSortOrder[ta] < typeSortOrder[tb]
    end
  end)

  local in_seq = false
  local prev_key = 0

  for i = 1,#keyList do
    local key = keyList[i]
    if type(key) == 'number' and key > 0 and key - 1 == prev_key then
      prev_key = key
      in_seq = true
    else
      in_seq = false
    end

    local value = dataTable[key]
    if type(value) == 'table' then
      if tableRef[value] == nil then -- prevent reference loops
        tableRef[value] = true

        local has_items = false
        for k,v in pairs(value) do
          if isPrimitiveType[type(k)] and (isPrimitiveType[type(v)] or type(v) == 'table') then
            has_items = true
            break
          end
        end

        if has_items then -- table contains values
          if isPrimitiveArray(value) then -- collapse primitive arrays
            output = output .. indentStr .. formatKey(key,in_seq) .. "{"
            local n = #value
            for i=1,n do
              output = output .. formatValue(value[i])
              if i < n then
                output = output .. ", "
              end
            end
            output = output .. "}"..delim.."\n"
          else -- table is not primitive array
            output = output
            .. indentStr .. formatKey(key,in_seq) .. "{\n"
            .. traverseTable(value,tableRef,indent+1, delim)
            .. indentStr .. "}"..delim.."\n"
          end
        else -- table is empty
          output = output .. indentStr .. formatKey(key,in_seq) .. "{}"..delim.."\n"
        end

        tableRef[value] = nil
      end
    elseif isPrimitiveType[type(value)] then
      output = output .. indentStr .. formatKey(key,in_seq) .. formatValue(value) .. ""..delim.."\n"
    end
  end
  return output
end


--defaults to log in AutoTouch, otherwise print in IDEs or terminal for developement
local _print = log or print
---- Improved print function
-- @param ... 
-- @return
function print(...) 
  local strings = {}
  for i, v in pairs({...}) do strings[#strings + 1] = str(v) end
  _print(table.concat(strings, '\t')) 
end

---- Pretty print a table
-- @tparam table tbl 
function pprint(tbl)
  print("\n{\n" .. traverseTable(tbl,{[tbl]=true},1, ',') .. "}")
end


---- Simple string representation of an object
-- @param input
-- @return 
function repr(input) 
  local m = getmetatable(input)
  if m and m.__repr then return input:__repr()
  else return tostring(input) end
end


---- Sleep for a certain amount of seconds.
-- The precision is +-0.1ms
-- @tparam number seconds number of seconds to sleep for
function sleep(seconds) 
  seconds = (seconds^2)^0.5
  local remainder = seconds
  if seconds > 0.01 then
    local rnd = round(seconds, 5)
    remainder = seconds - rnd
    io.popen('sleep ' .. rnd) :close()
  end
  local start = os.clock()
  while os.clock() - start < remainder do end
end


---- Convert an input into a string
-- @param input any object
-- @treturn string string representation of object
function str(input) 
  local m = getmetatable(input)
  if m then
    local _m = getmetatable(m)
    if m.__tostring then return tostring(input)
    elseif _m and _m.__tostring then return _m.__tostring(input) end
  elseif isType(input, 'number') or isType(input, 'bool') then return tostring(input)
  elseif isType(input, 'nil') then return 'nil'
  elseif isType(input, 'string') then return input 
  elseif isType(input, 'table') then return table2string(input) end
  return repr(input)
end



---- Reverse the order of the elements in a table or list
-- @param object object to reverse order of
-- @treturn table copy of object with elements in reverse order
function reversed(object)
  if is.str(object) then return object:reverse() end
  local result = list()
  for i, v in pairs(object) do result:insert(1, v) end
  return result
end

---- Sort an object
-- @param object
-- @param key
-- @return 
function sorted(object, key) 
  local sorter
  local cp = copy(object)
  if isType(key, 'function') then
    sorter = function(v1, v2)
      v1, v2 = key(v1), key(v2)
      return v1 < v2
    end
  end
  table.sort(cp, sorter)
  return cp
end
