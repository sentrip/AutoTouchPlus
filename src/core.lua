---- Core functions and object orientation
-- @module core

unpack = table.unpack
-- Index of string converting functions (at end of file)
local _string_converters = {}
-- List of overwritable metamethods
local _metamethods = {
  '__add', '__sub', '__mul', '__div', '__idiv', '__pow', 
  '__mod', '__concat', '__index', '__newindex', '__call',
  '__pairs', '__ipairs', '__tostring', '__len', '__unm',
  '__mode', '__metatable', '__gc', '__eq', '__lt', '__gt',
  '__band', '__bor', '__bxor', '__bnot', '__shl', '__shr'
}

--Index of class names
local classes = {} 
--Table in a class instance's __private variable are stored here
--They are only created upon being indexed for memory efficiency
local private_tables = {}
  
---- Create a new class type
-- @string name name of the class
-- @param ... base classes to inherit from
-- @usage -- create class A
-- A = class('A')
-- function A:__init(value)
--  self.value = value
-- end
-- -- Create class B that inherits from A
-- B = class('B', 'A')
-- -- Create and use instances
-- a = A(5)
-- assert(a.value == 5)
-- b = B(5)
-- assert(b.value == 5)
function class(name, ...)
  local c --a new class type
  local bases, getters, setters = {}, {}, {}
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
    local table_string = tostring(self)
    setmetatable(self, c)
    
    if cls.__init then 
      cls.__init(self, ...) 
    end
    
    self.__getters.__base_repr = function(s) return table_string end
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
  
  c = {
    __name = name,
    __bases = bases,
    __getters = getters,
    __setters = setters,
    __index = getattr,
    __newindex = setattr,
    __repr = _string_converters.class_repr,
    __tostring = _string_converters.class_str,
    -- convience methods
    copy = copy,
    isinstance = isinstance
  }

  -- copy any methods/properties from base classes in order of inheritance (youngest first)
  for _, base in pairs(bases) do
    for k, v in pairs(base) do
      if not c[k] then c[k] = v end
      for _, meth in pairs(_metamethods) do
        if base[meth] and (meth == '__index' or meth == '__newindex' or meth == '__tostring' or not c[meth]) then 
          c[meth] = base[meth] 
        end
      end
    end
    for k, v in pairs(base.__getters) do
      if not c.__getters[k] then c.__getters[k] = v end
    end
    for k, v in pairs(base.__setters) do
      if not c.__setters[k] then c.__setters[k] = v end
    end
  end

  classes[name] = setmetatable(c, {
      __class = c,
      __call = constructor,
      __index = class_meta_index,
      __newindex = class_meta_newindex,
      __repr = _string_converters.class_repr,
    })
  return classes[name]
end

---- Indexing that supports Python-like property getters
-- @param cls 
-- @param value
function getattr(cls, value)  
  if cls and type(cls) == 'table' then
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

---- Index setting that supports Python-like property setters
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

---- Check if class is an instance of another class recursively
-- @param klass
-- @param other
-- @return boolean
function isinstance(klass, other)
  local m = getmetatable(klass)
  if not m or not m.__name then 
    if other and other.__name then
      other = ''
    elseif not is.str(other) then 
      other = type(other) 
    end
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

--defaults to log in AutoTouch, otherwise print in IDEs or terminal for developement
____print = log or print
---- Write a string to stdout (or to log.txt in AutoTouch)
-- @param ... 
-- @return
function print(...) 
  local strings = {}
  for i, v in pairs({...}) do strings[#strings + 1] = str(v) end
  return ____print(table.concat(strings, '\t')) 
end

---- Pretty print a table
-- @tparam table tbl 
function pprint(tbl)
  return print("\n{\n" .. _string_converters.traverseTable(tbl,{[tbl]=true},1, ',') .. "}")
end

---- Create a property on a class
-- @param klass class type to add the property to
-- @string name name of the property
-- @func getter function to get the value of the property
-- @func setter function to set the value of the property
-- @usage A = class('A')
-- function A:__init(value) 
--   self._private = value
-- end
--
-- property(A, 'value', 
--   function(self) return self._private * 2 end,
--   function(self, value) self._private = value * 2 end
-- )
-- a = A(1)
-- assert(a.value == 2)
-- a.value = 2
-- assert(a.value == 8)
function property(klass, name, getter, setter) 
  assert(klass and name and getter, 'Must provide a class, name and getter function')
  klass.__getters[name] = getter
  klass.__setters[name] = setter
end

---- Convert any object into a string
-- @param input any object
-- @treturn string string representation of object
function str(input) 
  local m = getmetatable(input)
  if m then
    local _m = getmetatable(m)
    if m.__tostring then return tostring(input)
    elseif _m and _m.__tostring then return _m.__tostring(input) end
  elseif type(input) == 'number' or type(input) == 'bool' then return tostring(input)
  elseif type(input) == 'nil' then return 'nil'
  elseif type(input) == 'string' then return input 
  elseif type(input) == 'table' then return _string_converters.table2string(input) end
  return repr(input)
end


--@local
--slight improvement of tostring(<table>)
function _string_converters.class_repr(cls)
  local obj_name, value
  if getmetatable(cls) and getmetatable(cls).__name then 
    obj_name = 'instance'
    value = cls.__base_repr or tostring(getmetatable(cls))
  else
    obj_name, value = 'class', tostring(cls)
  end
  return '<'..string.gsub(value, 'table:', cls.__name..' '..obj_name..' at')..'>'
end

--@local
--custom strings for dict, list and set
function _string_converters.class_str(cls)
  if set{'dict', 'list', 'set'}:contains(getmetatable(cls).__name) then
    return _string_converters.table2string(cls)
  end
  return _string_converters.class_repr(cls)
end


--@local
--convert table to string with special cases for custom objects
function _string_converters.table2string(input)
  local m = getmetatable(input)
  local function idxstr(idx, val, custom_type) 
    if custom_type then return str(val) end
    if is.str(val) then  val = '"'..val..'"'  end
    if is.str(idx) then idx = '"'..idx..'"' end
    return string.format('%s: %s', str(idx), str(val))
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
  if custom and m and m.__name == 'list' then  pre, suf = '[', ']' end
  local s = pre
  for i, v in pairs(input) do
    if s ~= pre then s = s .. ', ' end
    s = s .. idxstr(i, v, custom)
  end
  return s .. suf
end


--@local
--pretty printing code modified from https://github.com/Anaminus/lua-pretty-print/blob/master/PrettyPrint.lua
--TODO: write my own pprint function that is short and well tested
-- luacov: disable
function _string_converters.traverseTable(dataTable,tableRef,indent,delim)  
  delim = delim or ','
  local output = ""
  local indentStr = string.rep("\t",indent)

  local isPrimitiveType = {string=true, number=true, boolean=true, ['function']=true, thread=true, userdata=true, ['nil']=true}
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
    if array.isinstance and (array:isinstance(list) or array:isinstance(set)) then return true end
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
            local i = 1
            for _, v in pairs(value) do
              output = output .. formatValue(v)
              if i < len(value) then
                output = output .. ", "
              end
              i = i + 1
            end
            output = output .. "}"..delim.."\n"
          else -- table is not primitive array
            output = output
            .. indentStr .. formatKey(key,in_seq) .. "{\n"
            .. _string_converters.traverseTable(value,tableRef,indent+1, delim)
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
-- luacov: enable
