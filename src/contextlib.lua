--- Context manager implementation
-- @module contextlib

require("src/logic")

--- Exception object
-- @type Exception
Exception = class('Exception')

--- PlaceHolder
-- @param _type
-- @param message
function Exception:__init(_type, message)
  self.type = _type
  self.message = message or ''
end

function Exception:__tostring()
  return Exception.add_traceback('<'..self.type..'> '..self.message)
end

function Exception:__repr()
  return tostring(self)
end


function Exception:__call(message)
  return Exception(self.type, message)
end

---- Placeholder
-- @param s
function Exception.add_traceback(s, force)
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
    if not lines:contains("\t[C]: in function 'error'") and not force then return s end
    if not force then lines = lines(start[-2]) else lines = lines(2) end
    s = s..'\nstack traceback:\n'..table.concat(lines, '\n') 
  end
  return s
end

--Some useful exceptions
AssertionError = Exception('AssertionError')
IOError = Exception('IOError')
KeyError = Exception('KeyError')
OSError = Exception('OSError')
TypeError = Exception('TypeError')
ValueError = Exception('ValueError')


---- Placeholder
-- @param f 
-- @param except 
-- @param finally
function try(f, except, finally)
  except = except or function() end
  local success, result = xpcall(f, except)
  if finally then finally() end
  if not success and result then error(tostring(result)) end
  return result
end

---- Placeholder
-- @param types
-- @param f
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

------ Context manager object
---- @type ContextManager
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

---- Placeholder
-- @param ...
function ContextManager:__enter()
  return self 
end

---- Placeholder
-- @param _type
-- @param value
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

---- Placeholder
-- @param context
-- @param _do
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


---- Placeholder
-- @param f
function contextmanager(f)
  return function(...)
    local Context = ContextManager(...)
    Context.__enter = function(self)
      return f(unpack(self.args))
    end
    return Context
  end
end

---- Placeholder
-- @param ...
function yield(...) coroutine.yield(...) end



---- Placeholder
-- @param name
-- @param mode
function open(name, mode)
  if rootDir then name = pathJoin(rootDir(), name) end
  local f = assert(io.open(name, mode or 'r'))
  yield(f)
  assert(f:close())
end

---- Placeholder
-- @param object
function closing(object)
  yield(object)
  object:close()
end


---- Placeholder
-- @param ...
function suppress(...)
  local errors = {... or '.*'}
  local Context = ContextManager()
  
  Context.__exit = function(self, _type, value)
    local e = except(errors)(_type or value)
    if e then error(e) end
  end
  
  return Context
end
  
--Context manager function wrapping, see contextmanager function for details
open = contextmanager(open)
closing = contextmanager(closing)