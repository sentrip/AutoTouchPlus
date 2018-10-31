--- String operation extensions
-- @module string.lua


local metafuncs = {}

---- Add strings together with `+` operator
-- @within Metatable functions
-- @string s a thing
-- @string other athing
-- @usage "abc" + "cde" => "abccde"
function metafuncs.add(s, other) return s .. other end 

---- Slice a string into a smaller string.
-- (see http://lua-users.org/wiki/StringIndexing)
-- @within Metatable functions
-- @usage x = 'abcde'
--- x(2, 4) => 'bcd'
--- x{1, -2, 3} => 'adc'
function metafuncs.call(s,i,j)
  if isType(i, 'number') then 
    return string.sub(s, i, j or rawlen(s)) 
  elseif isType(i, 'table') then
    local t = {}
    for k, v in ipairs(i) do t[k] = string.sub(s, v, v) end
    return table.concat(t)
  end
end

---- Index a single character in a string.
-- (see http://lua-users.org/wiki/StringIndexing)
-- @within Metatable functions
-- @usage x = 'abcde'
--- x[3] == x[-3] == 'c'
--- x.<command> == function or nil
function metafuncs.index(s, i) 
  if isType(i, 'number') then 
    if i < 0 then i = rawlen(s) + 1 + i end
    return string.sub(s, i, i) 
  end 
  return string[i] 
end

---- Multiply a string to repeat it
-- @within Metatable functions
-- @usage "ab" * 3 => "ababab"
function metafuncs.mul(s, other) 
  local t = {}
  for i=1, other do t[i] = s end
  return table.concat(t) 
end 

---- Iterate over the characters in a string
-- @within Metatable functions
-- @usage x = 'ab'
--- for i, v in pairs(x) do print(i, v) end
--- prints -> 
---     1, a
---     2, b
function metafuncs.pairs(s)
  local function _iter(s, idx)
    if idx < rawlen(s) then return idx + 1, s[idx + 1] end
  end
  return _iter, s, 0
end

---- Check if a string ends with a value
-- @string s
-- @string value
-- @treturn boolean
function string.endswith(s, value) return s(-rawlen(value), -1) == value end

---- Concatenate a list/table of strings with another string as the delimiter
-- @string s
-- @param other
-- @treturn string
function string.join(s, other) return table.concat(other, s) end

---- Replace occurrences of a substring in a string
-- @string s
-- @string sub
-- @param rep
-- @int limit
-- @treturn string
function string.replace(s, sub, rep, limit)  
  -- local _s, n = string.gsub(s, sub, rep, limit) 
  -- return _s 
  return string.gsub(s, sub, rep, limit)
end

---- Split a string by a delimiter into a table of strings
-- @string s
-- @string delim
-- @treturn list
function string.split(s, delim)
  local i = 1
  local idx = 1
  local values = {}

  while i <= rawlen(s) do
    if is.Nil(delim) then values[i] = s[i]; i = i + 1
    else
      if s(i, i + rawlen(delim) - 1) == delim then idx = idx + 1; i = i + rawlen(delim) - 1
    else 
        if is.Nil(values[idx]) then values[idx] = '' end
        values[idx] = values[idx] .. s[i] 
      end
      i = i + 1
    end
  end
  for i, v in pairs(values) do if is.Nil(v) then values[i] = '' end end
  return list(values)
end

---- Check if a string starts with a value
-- @string s
-- @string value
-- @treturn boolean
function string.startswith(s, value) return s(1, rawlen(value)) == value end

---- Strip characters from the beginning and end of a string
-- @string s
-- @string remove
-- @treturn string
function string.strip(s, remove) 
  local start=1
  local _end = rawlen(s)
  for i=1, rawlen(s) do if isnotin(s[i], remove) then start = i break end end
  for i=rawlen(s), start, -1 do if isnotin(s[i], remove) then _end = i break end end
  return s(start, _end)
end

-- Metatable patching
getmetatable('').__add = metafuncs.add
getmetatable('').__call = metafuncs.call
getmetatable('').__ipairs = metafuncs.pairs
getmetatable('').__mul = metafuncs.mul
getmetatable('').__pairs = metafuncs.pairs
getmetatable('').__index = metafuncs.index
