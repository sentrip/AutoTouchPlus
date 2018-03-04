---- AutoTouchPlus stuff and things.
-- @module AutoTouchPlus
-- @author Djordje Pepic
-- @license Apache 2.0
-- @copyright Djordje Pepic 2018
-- @usage require("AutoTouchPlus")
abs = math.abs
unpack = table.unpack
local _execute = os.execute
os.execute = function(s) 
  if rootDir then s = 'cd '..rootDir()..'; '..s end
  return _execute(s)
end
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
local classes = {} 
local private_tables = {}
function class(name, ...)
  local c --a new class instance
  local getters, setters = {}, {}
  local bases = {}
  for i, v in pairs({...}) do
    if is.str(v) then v = classes[v] end
    table.insert(bases, v)
  end
  getters.__private = function(self, value)
    local key = tostring(self)
    if not private_tables[key] then
      private_tables[key] = {}
    end
    return private_tables[key]
  end
  setters.__private = function()
    error('Cannot set __private table')
  end
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
  local function class_meta_index(cls, value) 
    return rawget(cls, value) or rawget(c, value) 
  end
  local function class_meta_newindex(cls, key, value) 
    rawset(cls, key, value) 
  end
  local function class_repr(cls)
    return '<'..string.gsub(tostring(cls), 'table:', name..' instance at')..'>'
  end
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
    copy = copy,
    isinstance = isinstance
  }
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
function copy(object, deep) 
  local c = {}
  for k, v in pairs(object) do
    if deep and is.table(v) then c[k] = copy(v, true)
    else c[k] = v end
  end
  local mt = {}
  local m = getmetatable(object)
  if m then setmetatable(c, m) end
  return c
end
function eval(input) 
  local f = load(input)
  if f then
    return f() 
  else
    error('Syntax error occurred while parsing input: '..input)
  end
end
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
function isnotin(sub, main) return not isin(sub, main) end
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
function max(...) 
  local args
  if is.table(...) then args = ... else args = {...} end
  local mt = getmetatable(args)
  if mt and mt.__name == 'set' then -- special case for set objects
    args = args:values() 
  end
  return math.max(unpack(args))
end
function min(...) 
  local args
  if is.table(...) then args = ... else args = {...} end
  local mt = getmetatable(args)
  if mt and mt.__name == 'set' then -- special case for set objects
    args = args:values() 
  end
  return math.min(unpack(args))
end
function num(input) 
  if is.num(input) then return input else return tonumber(input) end 
end
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
local _print = log or print
function print(...) 
  local strings = {}
  for i, v in pairs({...}) do strings[#strings + 1] = str(v) end
  _print(table.concat(strings, '\t')) 
end
function pprint(tbl)
  print("\n{\n" .. traverseTable(tbl,{[tbl]=true},1, ',') .. "}")
end
function repr(input) 
  local m = getmetatable(input)
  if m and m.__repr then return input:__repr()
  else return tostring(input) end
end
function sleep(seconds) 
  seconds = (seconds^2)^0.5
  local remainder = seconds
  if seconds > 0.01 then
    local rnd = round(seconds, 5)
    remainder = seconds - rnd
    os.execute('sleep ' .. rnd) 
  end
  local start = os.clock()
  while os.clock() - start < remainder do end
end
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
function reversed(object)
  if is.str(object) then return object:reverse() end
  local result = list()
  for i, v in pairs(object) do result:insert(1, v) end
  return result
end
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
local doc = {}
function doc.record()
   doc.__record = {}
end
function doc.stop()
   local md = table.concat(doc.__record)
   doc.__record = nil
   return md
end
function doc.doc(str)
   if doc.__record then
      table.insert(doc.__record, str)
   end
end
setmetatable(doc, {__call=
                      function(self, ...)
                         return self.doc(...)
                      end})
local utils = {}
function utils.setupvalue(func, name, newvalue, quiet)
   local uidx = 0
   repeat
      uidx = uidx + 1
      local uname, value = debug.getupvalue(func, uidx)
      if uname == name then
         debug.setupvalue(func, uidx, newvalue)
         return value -- previous one
      end
   until uname == nil
   if not quiet then
      error(string.format('unknown upvalue <%s>', name))
   end
end
function utils.getupvalue(func, name, quiet)
   local uidx = 0
   repeat
      uidx = uidx + 1
      local uname, value = debug.getupvalue(func, uidx)
      if uname == name then
         return value
      end
   until uname == nil
   if not quiet then
      error(string.format('unknown upvalue <%s>', name))
   end
end
function utils.duptable(tbl)
   local dup = {}
   for k,v in pairs(tbl) do
      dup[k] = v
   end
   return dup
end
local env = {}
function env.istype(obj, typename)
   local mt = getmetatable(obj)
   if type(mt) == 'table' then
      local objtype = rawget(mt, '__typename')
      if objtype then
         return objtype == typename
      end
   end
   return type(obj) == typename
end
function env.type(obj)
   local mt = getmetatable(obj)
   if type(mt) == 'table' then
      local objtype = rawget(mt, '__typename')
      if objtype then
         return objtype
      end
   end
   return type(obj)
end
local function argname2idx(rules, name)
   for idx, rule in ipairs(rules) do
      if rule.name == name then
         return idx
      end
   end
   error(string.format('invalid defaulta name <%s>', name))
end
local function table2id(tbl)
   return tostring(tbl):match('0x([^%s]+)')
end
local function func2id(func)
   return tostring(func):match('0x([^%s]+)')
end
local function rules2maskedrules(rules, rulesmask, rulestype, iscall)
   local maskedrules = {}
   for ridx=1,#rulesmask do
      local rule = utils.duptable(rules[ridx])
      rule.__ridx = ridx
      if not iscall then -- do not mess up the name for a call
         if rulestype == 'O' then
            rule.name = nil
         elseif rulestype == 'M' and ridx == 1 then -- self?
            rule.name = nil
         end
      end
      local rulemask = rulesmask:sub(ridx,ridx)
      if rulemask == '1' then
         table.insert(maskedrules, rule)
      elseif rulemask == '2' then
      elseif rulemask == '3' and rulestype == 'O' then
         rule.type = 'nil'
         rule.check = nil
         table.insert(maskedrules, rule)
      end
   end
   return maskedrules
end
local function rules2defaultrules(rules, rulesmask, rulestype)
   local defaultrules = {}
   for ridx=1,#rulesmask do
      local rule = utils.duptable(rules[ridx])
      rule.__ridx = ridx
      if rulestype == 'O' then
         rule.name = nil
      elseif rulestype == 'M' and ridx == 1 then -- self?
         rule.name = nil
      end
      local rulemask = rulesmask:sub(ridx,ridx)
      if rulemask == '1' then
      elseif rulemask == '2' then
         table.insert(defaultrules, rule)
      elseif rulemask == '3' then
         if rule.default or rule.defaulta or rule.defaultf then
            table.insert(defaultrules, rule)
         end
      end
   end
   return defaultrules
end
local usage = {}
local function generateargp(rules)
   local txt = {}
   for idx, rule in ipairs(rules) do
      local isopt = rule.opt or rule.default ~= nil or rules.defauta or rule.defaultf
      table.insert(txt,
                   (isopt and '[' or '')
                      .. ((idx == 1) and '' or ', ')
                      .. rule.name
                      .. (isopt and ']' or ''))
   end
   return table.concat(txt)
end
local function generateargt(rules)
   local txt = {}
   table.insert(txt, '```')
   table.insert(txt, string.format(
                   '%s%s',
                   rules.noordered and '' or '(',
                   rules.nonamed and '' or '{'))
   local size = 0
   for _,rule in ipairs(rules) do
      size = math.max(size, #rule.name)
   end
   local arg = {}
   local hlp = {}
   for _,rule in ipairs(rules) do
      table.insert(arg,
                   ((rule.opt or rule.default ~= nil or rule.defaulta or rule.defaultf) and '[' or ' ')
                   .. rule.name .. string.rep(' ', size-#rule.name)
                   .. (rule.type and (' = ' .. rule.type) or '')
                .. ((rule.opt or rule.default ~= nil or rule.defaulta or rule.defaultf) and ']' or '')
          )
      local default = ''
      if rule.defaulta then
         default = string.format(' [defaulta=%s]', rule.defaulta)
      elseif rule.defaultf then
         default = string.format(' [has default]')
      elseif type(rule.default) ~= 'nil' then
         if type(rule.default) == 'string' then
            default = string.format(' [default=%s]', rule.default)
         elseif type(rule.default) == 'number' then
            default = string.format(' [default=%s]', rule.default)
         elseif type(rule.default) == 'boolean' then
            default = string.format(' [default=%s]', rule.default and 'true' or 'false')
         else
            default = ' [has default value]'
         end
      end
      table.insert(hlp, (rule.help or '') .. (rule.doc or '') .. default)
   end
   local size = 0
   for i=1,#arg do
      size = math.max(size, #arg[i])
   end
   for i=1,#arg do
      table.insert(txt, string.format("  %s %s -- %s", arg[i], string.rep(' ', size-#arg[i]), hlp[i]))
   end
   table.insert(txt, string.format(
                   '%s%s',
                   rules.nonamed and '' or '}',
                   rules.noordered and '' or ')'))
   table.insert(txt, '```')
   txt = table.concat(txt, '\n')
   return txt
end
function usage.render(doc)
   return doc
end
function usage.usage(truth, rules, ...)
   if truth then
      local norender = select(1, ...)
      local doc = rules.help or rules.doc
      if doc then
         doc = doc:gsub('@ARGP',
                        function()
                           return generateargp(rules)
                        end)
         doc = doc:gsub('@ARGT',
                        function()
                           return generateargt(rules)
                        end)
      end
      if not doc then
         doc = '\n*Arguments:*\n' .. generateargt(rules)
      end
      return doc
   else
      local self = rules
      local args = {}
      for i=1,select('#', ...) do
         table.insert(args, string.format("**%s**", env.type(select(i, ...))))
      end
      local argtblidx
      if self:hasruletype('N') then
         if select("#", ...) == 1 and env.istype(select(1, ...), "table") then
            argtblidx = 1
         end
      elseif self:hasruletype('M') then
         if select("#", ...) == 2 and env.istype(select(2, ...), "table") then
            argtblidx = 2
         end
      end
      if argtblidx then
         local argtbl = {}
         local tbl = select(argtblidx, ...)
         local n = 0
         for k,v in pairs(tbl) do
            n = n + 1
            if n > 20 then
               table.insert(argtbl, '...')
               break
            end
            if type(k) == 'string' then
               table.insert(argtbl, string.format("**%s=%s**", k, env.type(v)))
            else
               table.insert(argtbl, string.format("**[%s]**=?", env.type(k)))
            end
         end
         args[argtblidx] = string.format("**table**={ %s }", table.concat(argtbl, ', '))
      end
      local doc = string.format("*Got:* %s", table.concat(args, ', '))
      return doc
   end
end
local ACN = {}
function ACN.new(typename, name, check, rules, rulesmask, rulestype)
   assert(typename)
   local self = {}
   setmetatable(self, {__index=ACN})
   self.type = typename
   self.name = name
   self.check = check
   self.rules = rules
   self.rulesmask = rulesmask
   self.rulestype = rulestype
   self.next = {}
   return self
end
function ACN:add(node)
   table.insert(self.next, node)
end
function ACN:match(rules)
   local head = self
   for idx=1,#rules do
      local rule = rules[idx]
      local matched = false
      for _,child in ipairs(head.next) do
         if child.type == rule.type
         and child.check == rule.check
         and child.name == rule.name then
            head = child
            matched = true
            break
         end
      end
      if not matched then
         return head, idx-1
      end
   end
   return head, #rules
end
function ACN:hasruletype(ruletype)
   local hasruletype
   self:apply(function(self)
                 if self.rulestype == ruletype then
                    hasruletype = true
                 end
              end)
   return hasruletype
end
function ACN:addpath(rules, rulesmask, rulestype) -- 'O', 'N', 'M'
   assert(rules)
   assert(rulesmask)
   assert(rulestype)
   local maskedrules = rules2maskedrules(rules, rulesmask, rulestype, false)
   if rulestype == 'N' then
      table.insert(maskedrules, 1, {type='table'})
   end
   if rulestype == 'M' then
      table.insert(maskedrules, 2, {type='table'})
   end
   local head, idx = self:match(maskedrules)
   if idx == #maskedrules then
      if not rules.force and head.rules and rules ~= head.rules then
         error('argcheck rules led to ambiguous situations')
      end
      head.rules = rules
      head.rulesmask = rulesmask
      head.rulestype = rulestype
   end
   for idx=idx+1,#maskedrules do
      local rule = maskedrules[idx]
      local node = ACN.new(rule.type,
                           rule.name,
                           rule.check,
                           idx == #maskedrules and rules or nil,
                           idx == #maskedrules and rulesmask or nil,
                           idx == #maskedrules and rulestype or nil)
      head:add(node)
      head = node
   end
   if rulestype == 'M' then
      local head, idx = self:match({maskedrules[1]}) -- find self
      assert(idx == 1, 'internal bug, please report')
      head.isself = true
   end
end
function ACN:id()
   return table2id(self)
end
function ACN:print(txt)
   local isroot = not txt
   txt = txt or {'digraph ACN {'}
   table.insert(txt, 'edge [penwidth=.3 arrowsize=0.8];')
   table.insert(txt, string.format('id%s [label="%s%s%s%s" penwidth=.1 fontsize=10 style=filled fillcolor="%s"];',
                                   self:id(),
                                   self.type,
                                   self.isself and '*' or '',
                                   self.check and ' <check>' or '',
                                   self.name and string.format(' (%s)', self.name) or '',
                                   self.rules and '#aaaaaa' or '#eeeeee'))
   for _,child in ipairs(self.next) do
      child:print(txt) -- make sure its id is defined
      table.insert(txt, string.format('id%s -> id%s;',
                                      self:id(),
                                      child:id()))
   end
   if isroot then
      table.insert(txt, '}')
      txt = table.concat(txt, '\n')
      return txt
   end
end
function ACN:generate_ordered_or_named(code, upvalues, rulestype, depth)
   depth = depth or 0
   if not self:hasruletype(rulestype) then
      return
   end
   if depth > 0 then
      local argname =
         (rulestype == 'N' or rulestype == 'M')
         and string.format('args.%s', self.name)
         or string.format('select(%d, ...)', depth)
      if self.check then
         upvalues[string.format('check%s', func2id(self.check))] = self.check
      end
      if self.type == 'nil' and (rulestype == 'N' or rulestype == 'M') then
         table.insert(code, string.format('%sif istype(%s, "%s")%s then',
                                          string.rep('  ', depth),
                                          argname,
                                          self.type,
                                          self.check and string.format(' and check%s(%s)', func2id(self.check), argname) or ''))
      else
         table.insert(code, string.format('%sif narg > 0 and istype(%s, "%s")%s then',
                                          string.rep('  ', depth),
                                          argname,
                                          self.type,
                                          self.check and string.format(' and check%s(%s)', func2id(self.check), argname) or ''))
         table.insert(code, string.format('%s  narg = narg - 1', string.rep('  ', depth)))
      end
   end
   if self.rules and self.rulestype == rulestype then
      local rules = self.rules
      local rulesmask = self.rulesmask
      local id = table2id(rules)
      table.insert(code, string.format('  %sif narg == 0 then', string.rep('  ', depth)))
      if rulestype == 'M' then
         rules = utils.duptable(self.rules)
         table.remove(rules, 1) -- remove self
         rulesmask = rulesmask:sub(2)
      end
      local argcode = {}
      for ridx, rule in ipairs(rules) do
         if rules.pack then
            table.insert(argcode, string.format('%s=arg%d', rule.name, ridx))
         else
            table.insert(argcode, string.format('arg%d', ridx))
         end
      end
      local maskedrules = rules2maskedrules(rules, rulesmask, rulestype, true)
      for argidx, rule in ipairs(maskedrules) do
         local argname =
            (rulestype == 'N' or rulestype == 'M')
            and string.format('args.%s', rule.name)
            or string.format('select(%d, ...)', argidx)
         table.insert(code, string.format('    %slocal arg%d = %s',
                                          string.rep('  ', depth),
                                          rule.__ridx,
                                          argname))
      end
      local defaultrules = rules2defaultrules(rules, rulesmask)
      local defacode = {}
      for _, rule in ipairs(defaultrules) do
         local defidx = rulestype == 'M' and rule.__ridx+1 or rule.__ridx
         if rule.default ~= nil then
            table.insert(code, string.format('    %slocal arg%d = arg%s_%dd', string.rep('  ', depth), rule.__ridx, id, defidx))
            upvalues[string.format('arg%s_%dd', id, defidx)] = rule.default
         elseif rule.defaultf then
            table.insert(code, string.format('    %slocal arg%d = arg%s_%df()', string.rep('  ', depth), rule.__ridx, id, defidx))
            upvalues[string.format('arg%s_%df', id, defidx)] = rule.defaultf
         elseif rule.opt then
            table.insert(code, string.format('    %slocal arg%d', string.rep('  ', depth), rule.__ridx))
         elseif rule.defaulta then
            table.insert(defacode, string.format('    %slocal arg%d = arg%d', string.rep('  ', depth), rule.__ridx, argname2idx(rules, rule.defaulta)))
         end
      end
      if #defacode > 0 then
         table.insert(code, table.concat(defacode, '\n'))
      end
      if rules.pack then
         argcode = table.concat(argcode, ', ')
         if rulestype == 'M' then
            argcode = string.format('self, {%s}', argcode)
         else
            argcode = string.format('{%s}', argcode)
         end
      else
         if rulestype == 'M' then
            table.insert(argcode, 1, 'self')
         end
         argcode = table.concat(argcode, ', ')
      end
      if rules.call and not rules.quiet then
         argcode = string.format('call%s(%s)', id, argcode)
         upvalues[string.format('call%s', id)] = rules.call
      end
      if rules.quiet and not rules.call then
         argcode = string.format('true%s%s', #argcode > 0 and ', ' or '', argcode)
      end
      if rules.quiet and rules.call then
         argcode = string.format('call%s%s%s', id, #argcode > 0 and ', ' or '', argcode)
         upvalues[string.format('call%s', id)] = rules.call
      end
      table.insert(code, string.format('    %sreturn %s', string.rep('  ', depth), argcode))
      table.insert(code, string.format('  %send', string.rep('  ', depth)))
   end
   for _,child in ipairs(self.next) do
      child:generate_ordered_or_named(code, upvalues, rulestype, depth+1)
   end
   if depth > 0 then
      if self.type ~= 'nil' or (rulestype ~= 'N' and rulestype ~= 'M') then
         table.insert(code, string.format('%s  narg = narg + 1', string.rep('  ', depth)))
      end
      table.insert(code, string.format('%send', string.rep('  ', depth)))
   end
end
function ACN:apply(func)
   func(self)
   for _,child in ipairs(self.next) do
      child:apply(func)
   end
end
function ACN:usage(...)
   local txt = {}
   local history = {}
   self:apply(
      function(self)
         if self.rules and not history[self.rules] then
            history[self.rules] = true
            table.insert(txt, usage.usage(true, self.rules))
         end
      end
   )
   return string.format(
      "%s\n%s\n",
      table.concat(txt, '\n\nor\n\n'),
      usage.usage(false, self, ...)
   )
end
function ACN:generate(upvalues)
   assert(upvalues, 'upvalues table missing')
   local code = {}
   table.insert(code, 'return function(...)')
   table.insert(code, '  local narg = select("#", ...)')
   self:generate_ordered_or_named(code, upvalues, 'O')
   if self:hasruletype('N') then -- is there any named?
      local selfnamed = self:match({{type='table'}})
      assert(selfnamed ~= self, 'internal bug, please report')
      table.insert(code, '  if select("#", ...) == 1 and istype(select(1, ...), "table") then')
      table.insert(code, '    local args = select(1, ...)')
      table.insert(code, '    local narg = 0')
      table.insert(code, '    for k,v in pairs(args) do')
      table.insert(code, '      narg = narg + 1')
      table.insert(code, '    end')
      selfnamed:generate_ordered_or_named(code, upvalues, 'N')
      table.insert(code, '  end')
   end
   for _,head in ipairs(self.next) do
      if head.isself then -- named self method
         local selfnamed = head:match({{type='table'}})
         assert(selfnamed ~= head, 'internal bug, please report')
         if head.check then
            upvalues[string.format('check%s', func2id(head.check))] = head.check
         end
         table.insert(code,
                      string.format('  if select("#", ...) == 2 and istype(select(2, ...), "table") and istype(select(1, ...), "%s")%s then',
                                    head.type,
                                    head.check and string.format(' and check%s(select(1, ...))', func2id(head.check)) or '')
         )
         table.insert(code, '    local self = select(1, ...)')
         table.insert(code, '    local args = select(2, ...)')
         table.insert(code, '    local narg = 0')
         table.insert(code, '    for k,v in pairs(args) do')
         table.insert(code, '      narg = narg + 1')
         table.insert(code, '    end')
         selfnamed:generate_ordered_or_named(code, upvalues, 'M')
         table.insert(code, '  end')
      end
   end
   for upvaluename, upvalue in pairs(upvalues) do
      table.insert(code, 1, string.format('local %s', upvaluename))
   end
   table.insert(code, '  assert(istype)') -- keep istype as an upvalue
   table.insert(code, '  assert(graph)') -- keep graph as an upvalue
   local quiet = true
   self:apply(
      function(self)
         if self.rules and not self.rules.quiet then
            quiet = false
         end
      end
   )
   if quiet then
      table.insert(code, '  return false, usage.render(graph:usage(...))')
   else
      table.insert(code, '  error(string.format("%s\\ninvalid arguments!", usage.render(graph:usage(...))))')
   end
   table.insert(code, 'end')
   return table.concat(code, '\n')
end
local setupvalue = utils.setupvalue
local getupvalue = utils.getupvalue
local loadstring = loadstring or load
local function generaterules(rules)
   local graph
   if rules.chain or rules.overload then
      local status
      status, graph = pcall(getupvalue, rules.chain or rules.overload, 'graph')
      if not status then
         error('trying to overload a non-argcheck function')
      end
   else
      graph = ACN.new('@')
   end
   local upvalues = {istype=env.istype, graph=graph}
   local optperrule = {}
   for ridx, rule in ipairs(rules) do
      if rule.default ~= nil or rule.defaulta or rule.defaultf then
         optperrule[ridx] = 3 -- here, nil or not here
      elseif rule.opt then
         optperrule[ridx] = 3 -- here, nil or not here
      else
         optperrule[ridx] = 1 -- here
      end
   end
   local optperrulestride = {}
   local nvariant = 1
   for ridx=#rules,1,-1 do
      optperrulestride[ridx] = nvariant
      nvariant = nvariant * optperrule[ridx]
   end
   for variant=nvariant,1,-1 do
      local r = variant
      local rulemask = {} -- 1/2/3 means present [ordered]/not present [ordered]/ nil [named or ordered]
      for ridx=1,#rules do
         table.insert(rulemask, math.floor((r-1)/optperrulestride[ridx]) + 1)
         r = (r-1) % optperrulestride[ridx] + 1
      end
      rulemask = table.concat(rulemask)
      if not rules.noordered then
         graph:addpath(rules, rulemask, 'O')
      end
      if not rules.nonamed then
         if rules[1] and rules[1].name == 'self' then
            graph:addpath(rules, rulemask, 'M')
         else
            graph:addpath(rules, rulemask, 'N')
         end
      end
   end
   local code = graph:generate(upvalues)
   return code, upvalues
end
function argcheck(rules)
   assert(not (rules.noordered and rules.nonamed), 'rules must be at least ordered or named')
   assert(rules.help == nil or type(rules.help) == 'string', 'rules help must be a string or nil')
   assert(rules.doc == nil or type(rules.doc) == 'string', 'rules doc must be a string or nil')
   assert(rules.chain == nil or type(rules.chain) == 'function', 'rules chain must be a function or nil')
   assert(rules.overload == nil or type(rules.overload) == 'function', 'rules overload must be a function or nil')
   assert(not (rules.chain and rules.overload), 'rules must have either overload [or chain (deprecated)]')
   assert(not (rules.doc and rules.help), 'choose between doc or help, not both')
   for _, rule in ipairs(rules) do
      assert(rule.name, 'rule must have a name field')
      assert(rule.type == nil or type(rule.type) == 'string', 'rule type must be a string or nil')
      assert(rule.help == nil or type(rule.help) == 'string', 'rule help must be a string or nil')
      assert(rule.doc == nil or type(rule.doc) == 'string', 'rule doc must be a string or nil')
      assert(rule.check == nil or type(rule.check) == 'function', 'rule check must be a function or nil')
      assert(rule.defaulta == nil or type(rule.defaulta) == 'string', 'rule defaulta must be a string or nil')
      assert(rule.defaultf == nil or type(rule.defaultf) == 'function', 'rule defaultf must be a function or nil')
   end
   if rules[1] and rules[1].name == 'self' then
      local rule = rules[1]
      assert(
            not rule.opt
            and not rule.default
            and not rule.defaulta
            and not rule.defaultf,
         'self cannot be optional, nor having a default value!')
   end
   if rules.doc or rules.help then
      doc(usage.render(usage.usage(true, rules, true)))
   end
   local code, upvalues = generaterules(rules)
   if rules.debug then
      print(code)
   end
   local func, err = loadstring(code, 'argcheck')
   if not func then
      error(string.format('could not generate argument checker: %s', err))
   end
   func = func()
   for upvaluename, upvalue in pairs(upvalues) do
      setupvalue(func, upvaluename, upvalue)
   end
   if rules.debug then
      return func, upvalues.graph:print()
   else
      return func
   end
end
env.argcheck = argcheck
local function format_ne(msg, v1, v2)
  msg = msg or ''
  return msg..string.format(' ==> %s != %s', str(v1 or ''), str(v2 or ''))
end
local function format_ge(msg, more, less)
  msg = msg or ''
  return msg..string.format(' ==> %s is not greater than %s', tostring(more), tostring(less))
end
function assertEqual(v1, v2, msg) assert(v1 == v2, format_ne(msg, v1, v2)) end
function assertNotEqual(v1, v2, msg) assert(v1 ~= v2, format_ne(msg, v1, v2)) end
function assertRequal(v1, v2, msg) assert(requal(v1, v2), format_ne(msg, v1, v2)) end
function assertNotRequal(v1, v2, msg) assert(not requal(v1, v2), format_ne(msg, v1, v2)) end
function assertLessThan(less, more, msg) assert(less < more, format_ge(msg, more, less)) end
function assertMoreThan(more, less, msg) assert(more > less, format_ge(msg, more, less)) end
function assertLessThanEqual(less, more, msg) assert(less <= more, format_ge(msg, more, less)) end
function assertMoreThanEqual(more, less, msg) assert(more >= less, format_ge(msg, more, less)) end
function assertRaises(exception, func, msg) 
  local success, result = pcall(func)
  if isNotType(exception, 'string') then
    exception = exception.type
  end
  assert(not success, 'No exception raised: '..msg)
  assert(string.find(result or '', tostring(exception)), 'Incorrect error raised: '..msg)
end
function test(description, tests, setup, teardown) 
  local failed = false
  local test_vars
  table.sort(tests)
  for test_name, tst in pairs(tests) do 
    test_vars = {}
    if Not.Nil(setup) then setup(test_vars) end
    success, err = pcall(tst, test_vars)
    if Not.Nil(teardown) then teardown(test_vars) end
    if not success then 
      if not failed then 
        print(description) 
        failed = true 
      end
      print(string.gsub(err or 'Error', "(.*):([0-9]+): ", function(path, n) 
            return string.format('\n    FAILURE in %s -> %s @ %d\n    ==> ', test_name, path, n) 
            end) .. '\n') 
    end 
  end
  return failed
end
Pixel = class('Pixel')
function Pixel:__init(x, y, color)
  self.x = x
  self.y = y
  if isType(color, 'table') then
    self.color = rgbToInt(unpack(color))
    self.rgb = color
  else
    self.color = color
    self.rgb = {intToRgb(color)}
  end
end
function Pixel:__add(position)
  self.x = self.x + (position.x or position[1] or 0)
  self.y = self.y + (position.y or position[1] or 0)
end
function Pixel:__sub(position)
  self.x = self.x - (position.x or position[1] or 0)
  self.y = self.y - (position.y or position[1] or 0)
end
function Pixel:__eq(pixel)
  return self.x == pixel.x and self.y == pixel.y and self.color == pixel.color
end
function Pixel:abs_position(screen)
  local x, y
  if self.x < 0 then x = screen.right + self.x
  else x = screen.x + self.x end
  if self.y < 0 then y = screen.bottom + self.y
  else y = screen.y + self.y end
  return x, y
end
function Pixel:in_(screen)
  return getColor(self:abs_position(screen)) == self.color
end
Pixels = class('Pixels')
function Pixels:__init(pixels)
  self.pixels = list()
  self.colors = list()
  if is(pixels) and getmetatable(pixels[1]) then
    self.pixels = pixels    
    for i, pixel in pairs(pixels) do
      self.colors:append(pixel.color)
    end
  else
    for i, t in pairs(pixels) do
      self.pixels:append(Pixel{t[1], t[2], t[3]})
      self.colors:append(t[3])
    end
  end
end
function Pixels:__add(pixels)
  for i, pixel in pairs(pixels) do
    self.pixels:append(pixel)
    self.colors:append(pixel.color)
  end
end
function Pixels:__eq(pixels)
  for i, pixel in pairs(pixels.pixels) do
    if pixel ~= self.pixels[i] then return false end
  end
  return true
end
function Pixels:in_(screen)
  local positions = {}
  for i, pixel in pairs(self.pixels) do 
    positions[#positions + 1] = {pixel:abs_position(screen)}
  end
  return requal(getColors(positions), self.colors)
end
function Pixels:count(screen)
  local positions = {}
  for i, pixel in pairs(self.pixels) do 
    positions[#positions + 1] = {pixel:abs_position(screen)}
  end
  local count = 0
  for i, v in pairs(getColors(positions)) do
    if v == self.colors[i] then count = count + 1 end
  end
  return count
end
Screen = class('Screen')
function Screen:__init(width, height, xOffSet, yOffSet)
  self.width = width
  self.height = height
  self.x = xOffSet or 0
  self.y = yOffSet or 0
  self.right = self.x + self.width
  self.bottom = self.y + self.height
  self.check_interval = 50000 --checks every 50ms (0.05s)
  self.mid = {
    left = {self.x, self.bottom / 2},
    right = {self.right, self.bottom / 2},
    top = {self.y, self.right / 2},
    bottom = {self.bottom, self.right / 2}
  }
end
function Screen:contains(pixel)
  return pixel:in_(self)
end
function Screen:tap(x, y, times, interval)
  local pixel
  if isType(x, 'number') then
    pixel = Pixel(x, y)
  else
    pixel, times, interval = x, y, times
  end
  for i=1, times or 1 do
    tap(pixel.x, pixel.y)
    if interval then usleep(interval * 10 ^ 6) end
  end
  return self
end
local function create_check(screen, condition)
  if is.func(condition) then
    return condition
  else
    return function() return screen:contains(condition) end
  end
end
function Screen:tap_if(condition, ...)
  local check = create_check(self, condition)
  if check() then
    self:tap(...)
  end
  return self
end
function Screen:tap_while(condition, ...)
  local check = create_check(self, condition)
  while check() do
    self:tap(...)
    usleep(self.check_interval)
  end
  return self
end
function Screen:tap_until(condition, ...)
  local check = create_check(self, condition)
  repeat  
    self:tap(...)
    usleep(self.check_interval)
  until check()
  return self
end
function Screen:swipe(start, _end, speed)
  if is.str(start) then
    assert(self.mid[start], 
      'Incorrect identifier: use one of (left, right, top, bottom)')
    start = self.mid[start]
  end
  if is.str(_end) then
    assert(self.mid[_end], 
      'Incorrect identifier: use one of (left, right, top, bottom)')
    _end = self.mid[_end]
  end
  local steps = 50 / speed
  local x, y = start[1], start[2]
  local deltaX = (_end[1] - start[1]) / steps
  local deltaY = (_end[2] - start[2]) / steps
  touchDown(2, x, y)
  usleep(16000)
  for i=1, steps do
    x = x + deltaX
    y = y + deltaY
    touchMove(2, x, y)
    usleep(16000)
  end
  touchUp(2, x, y)
  return self
end
TransitionTree = class('TransitionTree')
function TransitionTree:__init(name, parent, forward, backward)
  self.name = name or 'root'
  self.parent = parent
  if is.Nil(backward) then self.backward = forward
  else
    self.forward = forward
    self.backward = backward
  end
  self.nodes = {}
end
function TransitionTree:__index(value)
  return rawget(TransitionTree, value) or rawget(self, value) or self.nodes[value]
end
function TransitionTree:add(name, forward, backward)
  self.nodes[name] = TransitionTree(name, self, forward, backward)
end
function TransitionTree:path_to_root()
  local path = list{self}
  local parent = self.parent
  while Not.Nil(parent) do
    path:append(parent)
    parent = parent.parent
  end
  return path
end
function TransitionTree:path_to(name)
  local q = list()
  for i, v in pairs(self.nodes) do q:append({i, v}) end
  local item
  while len(q) > 0 do
    item = q:pop(1)
    for i, v in pairs(item[2].nodes) do q:append({i, v}) end
    if item[1] == name then return reversed(item[2]:path_to_root()) end
  end
end
function TransitionTree:lca(name1, name2)
  local lca = 'root'
  local v1, v2
  local path1, path2 = self:path_to(name1), self:path_to(name2)
  for i=2, math.min(len(path1), len(path2)) do
    v1, v2 = path1[i], path2[i]
    if v1.name == v2.name then lca = v1.name; break end
    if v1.parent ~= v2.parent then break else lca = v1.parent.name end
  end
  return lca 
end
function TransitionTree:navigate(start, _end)
  local counting = false
  local lca = self:lca(start, _end)
  local path1, path2 = reversed(self:path_to(start)), self:path_to(_end)
  for i, v in pairs(path1) do 
    if v.name == lca then break end
    v.backward()
  end
  for i, v in pairs(path2) do 
    if counting then v.forward() end
    if v.name == lca then counting = true end
  end
end
Navigator = class('Navigator')
json = {}
local encode
local escape_char_map = {
  [ "\\" ] = "\\\\",
  [ "\"" ] = "\\\"",
  [ "\b" ] = "\\b",
  [ "\f" ] = "\\f",
  [ "\n" ] = "\\n",
  [ "\r" ] = "\\r",
  [ "\t" ] = "\\t",
}
local escape_char_map_inv = { [ "\\/" ] = "/" }
for k, v in pairs(escape_char_map) do
  escape_char_map_inv[v] = k
end
local function escape_char(c)
  return escape_char_map[c] or string.format("\\u%04x", c:byte())
end
local function encode_nil(val)
  return "null"
end 
local function encode_table(val, stack)
  local res = {}
  stack = stack or {}
  if stack[val] then error("circular reference") end
  stack[val] = true
  if val[1] ~= nil or next(val) == nil then
    local n = 0
    for k in pairs(val) do
      if type(k) ~= "number" then
        error("invalid table: mixed or invalid key types")
      end
      n = n + 1
    end
    if n ~= #val then
      error("invalid table: sparse array")
    end
    for i, v in ipairs(val) do
      table.insert(res, encode(v, stack))
    end
    stack[val] = nil
    return "[" .. table.concat(res, ",") .. "]"
  else
    for k, v in pairs(val) do
      if type(k) ~= "string" then
        error("invalid table: mixed or invalid key types")
      end
      table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
    end
    stack[val] = nil
    return "{" .. table.concat(res, ",") .. "}"
  end
end
local function encode_string(val)
  return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end
local function encode_number(val)
  if val ~= val or val <= -math.huge or val >= math.huge then
    error("unexpected number value '" .. tostring(val) .. "'")
  end
  return string.format("%.14g", val)
end
local type_func_map = {
  [ "nil"     ] = encode_nil,
  [ "table"   ] = encode_table,
  [ "string"  ] = encode_string,
  [ "number"  ] = encode_number,
  [ "boolean" ] = tostring,
}
encode = function(val, stack)
  local t = type(val)
  local f = type_func_map[t]
  if f then
    return f(val, stack)
  end
  error("unexpected type '" .. t .. "'")
end
function json.encode(val)
  return ( encode(val) )
end
local parse
local function create_set(...) 
  local res = {}
  for i = 1, select("#", ...) do
    res[ select(i, ...) ] = true
  end
  return res
end
local space_chars   = create_set(" ", "\t", "\r", "\n")
local delim_chars   = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars  = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals      = create_set("true", "false", "null")
local literal_map = {
  [ "true"  ] = true,
  [ "false" ] = false,
  [ "null"  ] = nil,
}
local function next_char(str, idx, set, negate)
  for i = idx, #str do
    if set[str:sub(i, i)] ~= negate then
      return i
    end
  end
  return #str + 1
end
local function decode_error(str, idx, msg)
  local line_count = 1
  local col_count = 1
  for i = 1, idx - 1 do
    col_count = col_count + 1
    if str:sub(i, i) == "\n" then
      line_count = line_count + 1
      col_count = 1
    end
  end
  error( string.format("%s at line %d col %d", msg, line_count, col_count) )
end
local function codepoint_to_utf8(n)
  local f = math.floor
  if n <= 0x7f then
    return string.char(n)
  elseif n <= 0x7ff then
    return string.char(f(n / 64) + 192, n % 64 + 128)
  elseif n <= 0xffff then
    return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
  elseif n <= 0x10ffff then
    return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
                       f(n % 4096 / 64) + 128, n % 64 + 128)
  end
  error( string.format("invalid unicode codepoint '%x'", n) )
end
local function parse_unicode_escape(s)
  local n1 = tonumber( s:sub(3, 6),  16 )
  local n2 = tonumber( s:sub(9, 12), 16 )
  if n2 then
    return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
  else
    return codepoint_to_utf8(n1)
  end
end
local function parse_string(str, i)
  local has_unicode_escape = false
  local has_surrogate_escape = false
  local has_escape = false
  local last
  for j = i + 1, #str do
    local x = str:byte(j)
    if x < 32 then
      decode_error(str, j, "control character in string")
    end
    if last == 92 then -- "\\" (escape char)
      if x == 117 then -- "u" (unicode escape sequence)
        local hex = str:sub(j + 1, j + 5)
        if not hex:find("%x%x%x%x") then
          decode_error(str, j, "invalid unicode escape in string")
        end
        if hex:find("^[dD][89aAbB]") then
          has_surrogate_escape = true
        else
          has_unicode_escape = true
        end
      else
        local c = string.char(x)
        if not escape_chars[c] then
          decode_error(str, j, "invalid escape char '" .. c .. "' in string")
        end
        has_escape = true
      end
      last = nil
    elseif x == 34 then -- '"' (end of string)
      local s = str:sub(i + 1, j - 1)
      if has_surrogate_escape then 
        s = s:gsub("\\u[dD][89aAbB]..\\u....", parse_unicode_escape)
      end
      if has_unicode_escape then 
        s = s:gsub("\\u....", parse_unicode_escape)
      end
      if has_escape then
        s = s:gsub("\\.", escape_char_map_inv)
      end
      return s, j + 1
    else
      last = x
    end
  end
  decode_error(str, i, "expected closing quote for string")
end
local function parse_number(str, i)
  local x = next_char(str, i, delim_chars)
  local s = str:sub(i, x - 1)
  local n = tonumber(s)
  if not n then
    decode_error(str, i, "invalid number '" .. s .. "'")
  end
  return n, x
end
local function parse_literal(str, i)
  local x = next_char(str, i, delim_chars)
  local word = str:sub(i, x - 1)
  if not literals[word] then
    decode_error(str, i, "invalid literal '" .. word .. "'")
  end
  return literal_map[word], x
end
local function parse_array(str, i)
  local res = {}
  local n = 1
  i = i + 1
  while 1 do
    local x
    i = next_char(str, i, space_chars, true)
    if str:sub(i, i) == "]" then 
      i = i + 1
      break
    end
    x, i = parse(str, i)
    res[n] = x
    n = n + 1
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "]" then break end
    if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
  end
  return res, i
end
local function parse_object(str, i)
  local res = {}
  i = i + 1
  while 1 do
    local key, val
    i = next_char(str, i, space_chars, true)
    if str:sub(i, i) == "}" then 
      i = i + 1
      break
    end
    if str:sub(i, i) ~= '"' then
      decode_error(str, i, "expected string for key")
    end
    key, i = parse(str, i)
    i = next_char(str, i, space_chars, true)
    if str:sub(i, i) ~= ":" then
      decode_error(str, i, "expected ':' after key")
    end
    i = next_char(str, i + 1, space_chars, true)
    val, i = parse(str, i)
    res[key] = val
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "}" then break end
    if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
  end
  return res, i
end
local char_func_map = {
  [ '"' ] = parse_string,
  [ "0" ] = parse_number,
  [ "1" ] = parse_number,
  [ "2" ] = parse_number,
  [ "3" ] = parse_number,
  [ "4" ] = parse_number,
  [ "5" ] = parse_number,
  [ "6" ] = parse_number,
  [ "7" ] = parse_number,
  [ "8" ] = parse_number,
  [ "9" ] = parse_number,
  [ "-" ] = parse_number,
  [ "t" ] = parse_literal,
  [ "f" ] = parse_literal,
  [ "n" ] = parse_literal,
  [ "[" ] = parse_array,
  [ "{" ] = parse_object,
}
parse = function(str, idx)
  local chr = str:sub(idx, idx)
  local f = char_func_map[chr]
  if f then
    return f(str, idx)
  end
  decode_error(str, idx, "unexpected character '" .. chr .. "'")
end
function json.decode(str)
  if type(str) ~= "string" then
    error("expected argument of type string, got " .. type(str))
  end
  return ( parse(str, next_char(str, 1, space_chars, true)) )
end
local function namedRequality(name)
  return function(me, other)
    local mt = getmetatable(other)
    if mt and mt.__name == name then
      return requal(me, other) 
    else
      return false
    end
  end
end
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
function dict:clear() for k, v in pairs(self) do self:set(k, nil) end end
function dict:contains(key) return Not.Nil(rawget(self, key)) end
function dict:get(key, default) return rawget(self, key) or default end
function dict:items() return pairs(self) end
function dict:keys() 
  local ks = list()
  for k in self() do ks:append(k) end
  return sorted(ks) 
end
function dict:set(key, value) rawset(self, key, value) end
function dict:update(other) for k, v in pairs(other) do self:set(k, v) end end
function dict:values() 
  local vs = list()
  for k, v in pairs(self) do vs:append(v) end
  return vs 
end
list = class('list')
function list:__init(lst) 
  if is.table(lst) and lst[1] then self:extend(lst) end
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
function list:append(value) rawset(self, #self + 1, value) end
function list:contains(value)
  for i, v in pairs(self) do if requal(v, value) then return true end end
  return false
end
function list:extend(values) for i, v in pairs(values) do self:append(v) end end
function list:index(value) for i, v in pairs(self) do if requal(v, value) then return i end end end
function list:insert(index, value) 
  for i=#self, index, -1 do rawset(self, i + 1, rawget(self, i)) end
  rawset(self, index, value)
end
function list:pop(index) 
  local value = rawget(self, index or 1)
  for i=index or 1, #self do rawset(self, i, rawget(self, i + 1)) end
  return value
end
function list:remove(value) local _ = self:pop(self:index(value)) end
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
function set:add(value) 
  if Not.Nil(value) then rawset(self, str(hash(value)), value) end end
function set:clear() for v in self() do self:remove(v) end end
function set:contains(value) return Not.Nil(rawget(self, str(hash(value)))) end
function set:difference(other) 
  local vs = set()
  for v in self() do 
    if is.Nil(rawget(other, str(hash(v)))) then vs:add(v) end 
  end
  return vs
end
function set:pop(value) self:remove(value) return value end
function set:remove(value) rawset(self, str(hash(value)), nil) end
function set:update(other) for _, v in pairs(other) do self:add(v) end end
function set:values() 
  local result = {}
  for v in self() do result[#result + 1] = v end
  return result
end
function str_add(s, other) return s .. other end 
function str_call(s,i,j)
  if isType(i, 'number') then 
    return string.sub(s, i, j or #s) 
  elseif isType(i, 'table') then
    local t = {}
    for k, v in ipairs(i) do t[k] = string.sub(s, v, v) end
    return table.concat(t)
  end
end
function str_index(s, i) end
function str_mul(s, other) 
  local t = {}
  for i=1, other do t[i] = s end
  return table.concat(t) 
end 
function str_pairs(s)
  local function _iter(s, idx)
    if idx < #s then return idx + 1, s[idx + 1] end
  end
  return _iter, s, 0
end
_string = {
  endswith = function(s, value) return s(-#value, -1) == value end,
  format = function(s, ...)
    if Not.Nil(string.find(s, '{[^}]*}')) then
      local args; local modified = ''; local stringified = ''; 
      local index = 1; local length = 0; local pad = 0
      if is.table(...) then args = ... else args = {...} end
      local function formatter(prev, match) 
        if match == '' then 
          stringified = str(args[index])
        elseif match:startswith(':') then 
          length = tonumber(match(2))
          stringified = str(args[index])
        else
          for i, v in pairs(args) do if i == match then stringified = v end end 
        end
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
  join = function(s, other) return table.concat(other, s) end,
  replace = function(s, sub, rep, limit)  
    local _s, n = string.gsub(s, sub, rep, limit) return _s end,
  split = function(s, delim)
    local i = 1
    local idx = 1
    local values = {}
    while i <= #s do
      if is.Nil(delim) then values[i] = s[i]; i = i + 1
      else
        if s(i, i + #delim - 1) == delim then idx = idx + 1; i = i + #delim - 1
      else 
          if is.Nil(values[idx]) then values[idx] = '' end
          values[idx] = values[idx] .. s[i] 
        end
        i = i + 1
      end
    end
    for i, v in pairs(values) do if is.Nil(v) then values[i] = '' end end
    return list(values)
  end,
  startswith = function(s, value) return s(1, #value) == value end,
  strip = function(s, remove) 
    local start, _end
    for i=1, #s do if isnotin(s[i], remove) then start = i break end end
    for i=#s, start, -1 do if isnotin(s[i], remove) then _end = i break end end
    return s(start, _end)
    end
}
getmetatable('').__add = str_add
getmetatable('').__call = str_call
getmetatable('').__ipairs = str_pairs
getmetatable('').__mul = str_mul
getmetatable('').__pairs = str_pairs
getmetatable('').__index = function(s, i) 
  if isType(i, 'number') then 
    if i < 0 then i = #s + 1 + i end
    return string.sub(s, i, i) 
  else 
    return _string[i] or string[i] 
  end 
end
Exception = class('Exception')
function Exception:__init(_type, message)
  self.type = _type
  self.message = message or ''
end
function Exception:__tostring()
  return self.add_traceback('<'..self.type..'> '..self.message)
end
function Exception:__repr()
  return tostring(self)
end
function Exception:__call(message)
  return Exception(self.type, message)
end
function Exception.add_traceback(s)
  local start = list()
  local traceback = debug.traceback()
  if traceback then 
    local lines = traceback:split('\n')
    local count = 0
    for i, ln in pairs(lines) do
      if ln:startswith('\t[C]') then 
        count = count + 1 
        start:append(i)
      end 
    end
    if count > 3 then return s end
    lines = lines(start[-2])
    s = s..'\nstack traceback:\n'..('\n'):join(lines) 
  end
  return s
end
AssertionError = Exception('AssertionError')
IOError = Exception('IOError')
KeyError = Exception('KeyError')
OSError = Exception('OSError')
TypeError = Exception('TypeError')
ValueError = Exception('ValueError')
function try(f, except, finally)
  except = except or function() end
  local success, result = xpcall(f, except)
  if finally then finally() end
  if not success and result then error(tostring(result)) end
  return result
end
function except(types, f)
  if isType(types, 'table') then
    local mt = getmetatable(types)
    if mt and types.type then types = {types} end
  elseif isType(types, 'string') then
    types = {types}
  end
  if not types and not f then
    types, f = {'.*'}, function() end
  elseif not f then
    if isType(types, 'function') then
      types, f = {'.*'}, types
    end
  end
  types = types or {'.*'}
  return function(err)
    for i, _type in pairs(types) do
      if isType(_type, 'table') then 
        _type = _type.type or _type.__name or getmetatable(_type).__name 
      end
      if string.find(tostring(err), _type) then 
        local success, result = pcall(f or function() end, err)
        if not success then 
          return tostring(err)..
          '\n\nDuring handling of the above exception, another exception occurred:\n\n'
          ..result
        elseif result or (success and not result) then
          return result
        end
      end
    end
    return err
  end
end
ContextManager = class("ContextManager")
function ContextManager:__init(...)
  self.args = {...}
end
function ContextManager:__call()
  return coroutine.create(function()  
    local success, result
    success, result = pcall(self.__enter, self, unpack(self.args))
    if success then 
      coroutine.yield(result)
    else 
      error(result) 
    end
  end)
end
function ContextManager:__enter()
  return self 
end
function ContextManager:__exit(_type, value) 
  if _type or value then
    if _type then 
      value = Exception(_type, value) 
    else
      value = _type or value
    end
    error(err)
  end
end
function with(context, _do)
  local ctx = context()
  local success, result = coroutine.resume(ctx)
  if success then
    local _type, e
    try(
      function() _do(result) end,
      except(function(err) 
          e = err
          if err.type then _type, e = err.type, err.msg end
        end),
      function() context:__exit(_type, e) end
    )
  end
  coroutine.resume(ctx)
end
function contextmanager(f)
  return function(...)
    local Context = ContextManager(...)
    Context.__enter = function(self)
      return f(unpack(self.args))
    end
    return Context
  end
end
function yield(...) coroutine.yield(...) end
function open(name, mode)
  if rootDir then name = pathJoin(rootDir(), name) end
  local f = assert(io.open(name, mode or 'r'))
  yield(f)
  assert(f:close())
end
function closing(object)
  yield(object)
  object:close()
end
function suppress(...)
  local errors = {... or '.*'}
  local Context = ContextManager()
  Context.__exit = function(self, _type, value)
    local e = except(errors)(_type or value)
    if e then error(e) end
  end
  return Context
end
open = contextmanager(open)
closing = contextmanager(closing)
local type_index = {
  ['str'] = 'string',
  ['num'] = 'number',
  ['bool'] = 'boolean',
  ['tbl'] = 'table',
  ['file'] = 'userdata',
  ['func'] = 'function'
}
function isType(object, ...)
  local types = {...}
  if #types == 1 then return type(object) == types[1] end
  local is_type = false
  for i, v in pairs(types) do
    is_type = is_type or type(object) == (type_index[v] or v)
  end
  return is_type
end
function isNotType(object, ...)
  return not isType(object, ...)
end
is = setmetatable({}, {
  __call = function(s, object)
    if object == nil or object == false or object == 0 then
      return false
    elseif isType(object, 'number', 'boolean', 'userdata', 'function') then
      return true
    elseif isType(object, 'string') then
      return #object > 0
    elseif isType(object, 'table') then
      if object.__is then 
        return object:__is()
      else
        local size = #object
        if size == 0 then
          for i, v in pairs(object) do
            size = size + 1
          end
        end
        return size > 0
      end
    end
    return false
  end,
  __index = function(s, value)
    return function(v) 
      local s = type_index[value] or value
      return isType(v, s:lower()) 
      end
  end
  })
Not = setmetatable({}, {
    __call = function(s, object) return not is(object) end,
    __index = function(s, value) 
      return function(v) return not is[value](v) end
    end
  })
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
function count(value, input) 
  local total = 0 
  for i, v in pairs(input) do if v == value then total = total + 1 end end
  return total
  end
function div(x, y) return math.floor(x / y) end
function len(input) 
  if is.Nil(input) then return 0
  elseif is.num(input) or is.Bool(input) then return 1
  else
    local total = 0
    for i, v in pairs(input) do total = total + 1 end
    return total 
  end
end
function round(num, places) 
  local value = num * 10^places
  if value - math.floor(value) >= 0.5 then value = value + 1 end
  return math.floor(value) / 10 ^ places
end
function sign(n) 
  if n == 0 then return 1 
  else return math.floor(n / math.abs(n)) end 
end
function sum(object) 
  local total = 0
  for i, v in pairs(object) do total = total + v end
  return total
end
Response = class('Response')
function Response:__init(request)
  self.request = request or {}
  self.url = self.request.url
  self.status_code = -1
  self.text = ''
  self.encoding = ''
  self.reason = ''
  self.headers = dict()
  self.ok = false
end
function Response:__tostring()
  return string.format('<Response [%d]>', self.status_code)
end
function Response:iter_lines()
  local i, v
  local lines = self.text:split('\n')
  return function() i, v = next(lines, i) return v end
end
function Response:json()
  return json.decode(self.text)
end
function Response:raise_for_status()
  if self.status_code ~= 200 then error('error in '..self.method..' request: '..self.status_code) end
end
local function parse_log(f, request, response)
  local err_msg = 'error in '..request.method..' request: '
  local lines = readLines(f)
  assert(isnotin('failed', lines[6]), err_msg..'Url does not exist')
  local req = lines(lines:index('---request begin---') + 1, lines:index('---request end---') - 1)
  local resp = lines(lines:index('---response begin---') + 1, lines:index('---response end---') - 1)
  _, response.status_code, response.reason = unpack(resp[1]:split(' '))
  response.status_code = num(response.status_code)
  response.ok = response.status_code < 400
  local k, v
  for i, lns in pairs({request=req(2, nil), response=resp(2, nil)}) do
    for line in lns() do 
      k = line:split(':')[1]
      v = line:replace(k..': ', '')
      v = tonumber(v) or v
      if i == 'request' then 
        request.headers[k] = v 
      else 
        response.headers[k] = v 
        if k == 'Content-Type' then 
          if isin('charset=', v) then response.encoding = v:split('charset=')[2] end
        end
      end
    end
  end
end
local _requests = {
  tdata = '_response_data',
  tlog = '_response_log',
  tbody = '_request_body'
}
function _requests.check_data(request) 
  if not request.data then
    return
  elseif isType(request.data, 'table') and not request.data[1] then 
    assert(requal(request.data, json.decode(json.encode(request.data))),
      'Incorrect json formatting')
    request.data = json.encode(request.data)
  end
end
function _requests.check_url(request) 
  assert(request.url:startswith('http'), 'Only http(s) urls are supported')
end
function _requests.format_params(request) 
  if is(request.params) then
    request.url = request.url..'?'.._requests.urlencode(request.params)
  end
end
function _requests.urlencode(params)
  if is.str(params) then return params end
  local s = ''
  if not params or next(params) == nil then return s end
  for key, value in pairs(params) do
    if is(s) then s = s..'&' end
    if tostring(value) then s = s..tostring(key)..'='..tostring(value) end
  end
  return s
end
function _requests.make_request(request)
  local cmd = list{'wget', '--method', request.method:upper()}
  if request.verify == false then
    cmd:append('--no-check-certificate')
  end
  if is(request.data) then
    local fle = request.data[1] or _requests.tbody
    cmd:extend{'--body-file', fle}
  end
  if is(request.auth) then
    local usr = request.auth.user or request.auth[1]
    local pwd = request.auth.password or request.auth[2]
    assert(is.str(usr) and is.str(pwd), 'Incorrect authentication format')
    cmd:extend{'--http-user', usr, '--http-password', pwd}
  end
  if is(request.proxies) then
    assert(request.proxies.http or request.proxies.https, 'Incorrect proxy format')
    local usr, pwd
    for k, v in pairs(request.proxies) do
      if isin('@', v) then usr, pwd = unpack(v:split('//')[2]:split('@')[1]:split(':')) end
    end
  else cmd:append('--no-proxy') end
  if is(request.user_agent) then
    cmd:extend{'-U', request.headers.user_agent}
  end
  if is(request.headers) then
    for k, v in pairs(request.headers) do 
      cmd:append("--header='"..k..': '..str(v).."'")
    end
  else request.headers = {} end
  if isType(request.data, 'string') then 
    with(open(_requests.tbody, 'wb'), 
      function(f) f:write(_requests.urlencode(request.data)) end)
  end
  cmd:extend{"'"..request.url.."'", '-d'}
  cmd:extend{'--output-document', _requests.tdata}
  cmd:extend{'--output-file', _requests.tlog}
  exe(cmd)
  local response = Response(request)
  with(open(_requests.tdata, 'rb'), 
    function(f) response.text = f:read('*all') end)
  with(open(_requests.tlog), 
    function(f) parse_log(f, request, response) end)
  if isType(request.data, 'string') then
    exe{'rm', _requests.tbody}
  end
  exe{'rm', _requests.tdata, _requests.tlog} 
  return response
end
requests = {}
function requests.delete(url, args)
  return requests.request("DELETE", url, args)
end
function requests.get(url, args)
  return requests.request("GET", url, args)
end
function requests.post(url, args)
  return requests.request("POST", url, args)
end
function requests.put(url, args)
  return requests.request("PUT", url, args)
end
function requests.request(method, url, args)
  local request
  if is.table(url) then 
    if Not.Nil(url[1]) then 
      url.url = url[1] 
      url[1] = nil 
    end
    request = url
  else
    request = args or {}
    request.url = url
  end
  request.method = method
  _requests.check_url(request)
  _requests.check_data(request)
  _requests.format_params(request)
  return _requests.make_request(request)
end
local function _getType(name) 
  return exe(string.format(
    'if test -f "%s"; then echo "FILE"; elif test -d "%s"; then echo "DIR"; else echo "INVALID"; fi', 
    name, name))
end
function exe(cmd, split_output)
  if is.Nil(split_output) then split_output = true end
  if isNotType(cmd, 'string') then cmd = table.concat(cmd, ' ') end
  if rootDir then cmd = 'cd '..rootDir()..'; '..cmd end
  local f = assert(io.popen(cmd, 'r'))
  local data = readLines(f)
  local success, status, code = f:close()
  if split_output then
    if #data == 1 then data = data[1] end
  else
    data = table.concat(data, '\n')
  end
  if code ~= 0 then
    return data, status, code
  else
    return data
  end
end
function fcopy(src, dest, overwrite) 
  if is.Nil(overwrite) then overwrite = true end
  local cmd = list{'cp'}
  if isDir(src) then cmd:append('-R') end
  if not overwrite then cmd:append('-n') end
  cmd:extend{src, dest}
  exe(cmd)
end
function find(name, starting_directory) 
  local _type = 'f'
  if is.table(name) then
    starting_directory = name.start
    if name.file or name.f then 
      name = name.file or name.f
      _type = 'f'
    elseif name.dir or name.d then 
      name = name.dir or name.d
      _type = 'd'
    else 
      error('Incorrect table arguments ("file"/"f" or "dir"/"d" or "start")') 
    end 
  end
  return exe({'find', starting_directory or '.', '-type', _type, '-name', name})
  end
function isDir(name) return _getType(name) == 'DIR' end
function isFile(name) return _getType(name) == 'FILE' end
function listdir(dirname) return sorted(exe{'ls', dirname}) end
function pathExists(path) return _getType(path) ~= 'INVALID' end
function pathJoin(...) 
  local values
  if is.table(...) then values = ... else values = {...} end
  local s = string.gsub(table.concat(values, '/'), '/+', '/')
  return s
end
function readLine(f, lineNumber) 
  local lines = readLines(f)
  return lines[lineNumber] 
end 
function readLines(f) 
  local lines = list()
  local function read(fle) for line in fle:lines() do lines:append(line) end end
  if is.str(f) then with(open(f, 'r'), read) else read(f) end
  if lines[#lines] == '' then lines[#lines] = nil end
  return lines
end
function sizeof(name) 
  local result = exe(string.format('du %s', name))
  local size = 0
  for a in string.gmatch(result, "[0-9]*") do size = num(a); break end 
  return size
  end
function writeLine(line, lineNumber, filename) 
  local lines = readLines(filename)
  lines[lineNumber] = line
  writeLines(lines, filename, 'w')
end 
function writeLines(lines, filename, mode) 
  local function write(f) 
    for i, v in pairs(lines) do f:write(v .. '\n') end 
  end
  with(open(filename, mode or 'w'), write) 
end
