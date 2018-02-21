--- Argument checking and function overloading.
--Modified version of <a href=https://github.com/torch/argcheck>argcheck</a>.
--Documentation can be found
--<a href=https://github.com/torch/argcheck/blob/master/README.md#documentation>here</a>.
-- @module argcheck
-- @author Idiap Research Institute (Ronan Collobert)
-- @license <a href=https://github.com/torch/argcheck/blob/master/COPYRIGHT.txt>BSD-3</a>
-- @copyright Idiap Research Institute 2013-2014
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

-- user configurable function
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
   -- DEBUG: gros hack de misere
   return tostring(tbl):match('0x([^%s]+)')
end

local function func2id(func)
   -- DEBUG: gros hack de misere
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
   -- DEBUG: on peut aussi imaginer avoir d'abord mis
   -- les no-named, et ensuite les named!!

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
      -- check we are not overwriting something here
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

   -- special trick: mark self
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

   -- no need to go deeper if no rules found later
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

      -- 'M' case (method: first arg is self)
      if rulestype == 'M' then
         rules = utils.duptable(self.rules)
         table.remove(rules, 1) -- remove self
         rulesmask = rulesmask:sub(2)
      end

      -- func args
      local argcode = {}
      for ridx, rule in ipairs(rules) do
         if rules.pack then
            table.insert(argcode, string.format('%s=arg%d', rule.name, ridx))
         else
            table.insert(argcode, string.format('arg%d', ridx))
         end
      end

      -- passed arguments
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

      -- default arguments
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
   table.insert(code, '  local usage = require("src/argcheck").usage')
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

   -- note: we keep the original rules (id) for all path variants
   -- hence, the mask.
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

   -- basic checks
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

   -- dump doc if any
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
return {doc = doc, env = env, usage = usage, utils = utils}

