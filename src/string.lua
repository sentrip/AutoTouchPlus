--- String operation extensions
-- @module string


---- Addable strings
-- @param s a thing
-- @param other athing
-- @usage "abc" + "cde" => "abccde"
function str_add(s, other) return s .. other end 

---- Callable string indexing
-- (see http://lua-users.org/wiki/StringIndexing)
-- @usage x = 'abcde'
--- x(2, 4) => 'bcd'
--- x{1, -2, 3} => 'adc'
function str_call(s,i,j)
  if isType(i, 'number') then 
    return string.sub(s, i, j or #s) 
  elseif isType(i, 'table') then
    local t = {}
    for k, v in ipairs(i) do t[k] = string.sub(s, v, v) end
    return table.concat(t)
  end
end

---- Improved string indexing (see http://lua-users.org/wiki/StringIndexing)
-- @usage x = 'abcde'
--- x[3] => 'c'
--- x.<command> => function or nil
function str_index(s, i) end

---- Multiply strings
-- @usage "ab" * 3 => "ababab"
function str_mul(s, other) 
  local t = {}
  for i=1, other do t[i] = s end
  return table.concat(t) 
end 

---- Iterable strings
-- @usage x = 'ab'
--- for i, v in pairs(x) do print(i, v) end
--- prints -> 
---     1, a
---     2, b
function str_pairs(s)
  local function _iter(s, idx)
    if idx < #s then return idx + 1, s[idx + 1] end
  end
  return _iter, s, 0
end

--- Additional methods for lua's 'string' object
-- @type string
_string = {
---- String ends with value
  endswith = function(s, value) return s(-#value, -1) == value end,

---- String formatting (Python style! ...kinda)
  format = function(s, ...)
    if isNotNil(string.find(s, '{[^}]*}')) then
      local args; local modified = ''; local stringified = ''; 
      local index = 1; local length = 0; local pad = 0
      if isTable(...) then args = ... else args = {...} end
      
      local function formatter(prev, match) 
        -- replace match
        if match == '' then 
          stringified = str(args[index])
        elseif match:startswith(':') then 
          length = tonumber(match(2))
          stringified = str(args[index])
        else
          for i, v in pairs(args) do if i == match then stringified = v end end 
        end
        -- apply padding if any
        pad = math.max(0, math.abs(length) - #stringified)
        if length < 0 then modified = modified + prev + stringified + ' ' * pad
        else modified = modified + prev + ' ' *  pad + stringified end
        index = index + 1
        length = 0
      end
      
      s:gsub('(.-){([^}]*)}', formatter)
      return modified
    else return string.format(s, ...) end
  end,

---- Placeholder
  join = function(s, other) return table.concat(other, s) end,

---- Replace occurrences of sub in main with rep
  replace = function(s, sub, rep, limit)  
    local _s, n = string.gsub(s, sub, rep, limit) return _s end,

---- String splitting (Python style!)
  split = function(s, delim)
    local i = 1
    local idx = 1
    local values = {}

    while i <= #s do
      if isNil(delim) then values[i] = s[i]; i = i + 1
      else
        if s(i, i + #delim - 1) == delim then idx = idx + 1; i = i + #delim - 1
      else 
          if isNil(values[idx]) then values[idx] = '' end
          values[idx] = values[idx] .. s[i] 
        end
        i = i + 1
      end
    end
    for i, v in pairs(values) do if isNil(v) then values[i] = '' end end
    return list(values)
  end,

---- String starts with value
  startswith = function(s, value) return s(1, #value) == value end,

---- String stripping (Python style!)
  strip = function(s, remove) 
    local start, _end
    for i=1, #s do if isnotin(s[i], remove) then start = i break end end
    for i=#s, start, -1 do if isnotin(s[i], remove) then _end = i break end end
    return s(start, _end)
    end
}


-- Metatable patching
getmetatable('').__add = str_add
getmetatable('').__call = str_call
getmetatable('').__ipairs = str_pairs
getmetatable('').__mul = str_mul
getmetatable('').__pairs = str_pairs
getmetatable('').__index = function(s, i) 
  if isNum(i) then 
    if i < 0 then i = #s + 1 + i end
    return string.sub(s, i, i) 
  else 
    return _string[i] or string[i] 
  end 
end
