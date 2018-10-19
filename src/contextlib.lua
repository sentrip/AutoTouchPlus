--- Context manager implementation
-- @module contextlib

require("src/logic")

---- Safely execute a function
-- @param f 
-- @param _except 
-- @param finally
function try(f, _except, finally)
  _except = _except or function() end
  local success, result = xpcall(f, _except)
  if finally then finally() end
  if not success and result then error(tostring(result)) end
  return result
end


---- Handle exceptions of specific types
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


---- Execute a function within a context
-- @param context
-- @param _do
function with(context, _do)
  local ctx = context()
  local success, result = coroutine.resume(ctx)
  if success then
    local error_type, error_message
    try(
      function() _do(result) end,
      except(function(err) 
          if err.type then 
            error_type = err.type 
            error_message = err.message 
          else 
            error_type = 'Exception'
            error_message = err 
          end
        end),
      function() context:__exit(error_type, error_message) end
    )
  end
  coroutine.resume(ctx)
end


---- Yield control back to function inside the current context
-- @param ...
function yield(...) coroutine.yield(...) end


---- Create a ContextManager from a function
-- @param f any function that yields
function contextmanager(f)
  return function(...)
    local Context = ContextManager(...)
    Context.__enter = function(self)
      return f(unpack(self.args))
    end
    return Context
  end
end


---- Open a file with a given mode, ensuring to close it after
-- @param name
-- @param mode
function open(name, mode)
  if rootDir then name = pathJoin(rootDir(), name) end
  local f = assert(io.open(name, mode or 'r'))
  yield(f)
  f:close()
end



---- Run a clean copy of an app and close it after
-- @param name 
-- @param close_after
function run_and_close(name, close_after)
  if close_after ~= false then close_after = true end
  if appState(name) ~= "NOT RUNNING" then appKill(name) end
  appRun(name)
  yield()
  if close_after then appKill(name) end
end
---- Run an app and close it after if it is not already running
-- @param name 
function run_if_closed(name)
  local run_kill = false
  if appState(name) ~= "ACTIVE" then 
    run_kill = true 
  end

  if run_kill then appRun(name) end
  yield()
  if run_kill then appKill(name) end

end



---- Suppress exceptions of a given type
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


---- Ensure code execution takes a certain amount of time
-- @param t
function time_ensured(t)
  local start = os.time()
  yield()
  sleep(max(0, t - (os.time() - start)))
end


---- Wait before and after executing code
-- @param t_before
-- @param t_after
function time_padded(t_before, t_after)
  sleep(t_before)
  yield()
  sleep(t_after or t_before)
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

---- Enter (setup) the context
-- @param ...
function ContextManager:__enter()
  return self 
end

---- Exit (teardown) the context
-- @param _type
-- @param value
function ContextManager:__exit(_type, value) 
  if _type then 
    value = Exception(_type, value).message 
  else
    value = _type or value
  end
  if value then error(value) end
end
  

--- Exception object
-- @type Exception
Exception = class('Exception')

--- Create an Exception object
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

---- Recent traceback for error tracking
-- @param s
-- @param force
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

--Context manager function wrapping, see contextmanager function for details
open = contextmanager(open)
run_and_close = contextmanager(run_and_close)
run_if_closed = contextmanager(run_if_closed)
time_ensured = contextmanager(time_ensured)
time_padded = contextmanager(time_padded)
