--- Screen interaction and observation helpers
-- @module screen.lua

local _stall = {count = 0, last_check=0, last_colors={}, cyclers={}}
screen = {
  before_action_funcs = set(),
  after_action_funcs = set(),
  before_check_funcs = set(),
  after_check_funcs = set(),
  before_tap_funcs = set(),
  after_tap_funcs = set(),
  on_stall_funcs = set()
}
---
if Not.Nil(getScreenResolution) then
  screen.width, screen.height = getScreenResolution()
else
  screen.width, screen.height = 200, 400
end
---

---- Number milliseconds after which the screen is checked for updates
screen.check_interval = 150000
---- Number of successful checks before the screen is considered stalled
screen.stall_after_checks = 5               -- after 5 same screens
---- Number of seconds after which the screen is checked for stall
screen.stall_after_checks_interval = 3 * 60
---- Number of seconds to wait before each action (tap_if, tap_until, ...)
screen.wait_before_action = 0
---- Number of seconds to wait after each action (tap_if, tap_until, ...)
screen.wait_after_action = 0
---- Number of seconds to wait before each tap
screen.wait_before_tap = 0
---- Number of seconds to wait after each tap
screen.wait_after_tap = 0

---- Pixels on the corners of the screen
screen.edge = {
  top_left = Pixel(0, 0),                               -- x = 0, y = 0
  top_right = Pixel(screen.width, 0),                   -- x = screen.width, y = 0
  bottom_left = Pixel(0, screen.height),                -- x = 0, y = screen.height
  bottom_right = Pixel(screen.width, screen.height)     -- x = screen.width, y = screen.height
}
---- Pixels centered on various locations on the screen
screen.mid = {
  left = Pixel(0, screen.height / 2),                   -- x = 0, y = screen.height / 2
  right = Pixel(screen.width, screen.height / 2),       -- x = screen.width, y = screen.height / 2
  top = Pixel(screen.width / 2, 0),                     -- x = screen.width / 2, y = 0
  bottom = Pixel(screen.width / 2, screen.height),      -- x = screen.width / 2, y = screen.height
  center = Pixel(screen.width / 2, screen.height / 2)   -- x = screen.width / 2, y = screen.height / 2
}
--- Pixels to check that determine whether the screen is stalled
screen.stall_indicators = Pixels{
  -- TODO: add more pixels for screen recovery check
  screen.mid.center
}
---


-- @local
local create_context = contextmanager(function(before_wait, after_wait, before_funcs, after_funcs)
  
  sleep(before_wait)
    
  for func in iter(before_funcs) do
    func()
  end

  yield()

  for func in iter(after_funcs) do
    func()
  end

  sleep(after_wait)

end)
---


---- Context manager for screen actions and checking
-- @within Contexts
-- @param condition 
screen.action_context = contextmanager(function(condition)
  
  local ctx = create_context(
    screen.wait_before_action, screen.wait_after_action, 
    screen.before_action_funcs, screen.after_action_funcs
  )

  with(ctx, function()
      
      local check
      
      if is.func(condition) then
        check = condition
      else
        check = function() return screen.contains(condition) end
      end        
      
      yield(function()
          
          for func in iter(screen.before_check_funcs) do
            func()
          end

          -- Run stalling escape procedures if screen is stalled
          if screen.is_stalled() then
            for func in iter(screen.on_stall_funcs) do
              func()
            end
          end

          local result = check()
          
          for func in iter(screen.after_check_funcs) do
            func()
          end
          
          return result
        end)
      
      end)

end)
---

--- Context manager for tapping
-- @within Contexts
screen.tap_context = contextmanager(function()
  
  local ctx = create_context(
    screen.wait_before_tap, screen.wait_after_tap,
    screen.before_tap_funcs, screen.after_tap_funcs
  )
  
  with(ctx, function() yield() end)
  
end)
---

---- Register a function to be run before an action (tap_if, tap_until, ...)
-- @within Registration
-- @tparam function func function to run before action (no arguments)
function screen.before_action(func)
  screen.before_action_funcs:add(func)
end
---

---- Register a function to be run after an action (tap_if, tap_until, ...)
-- @within Registration
-- @tparam function func function to run after action (no arguments)
function screen.after_action(func)
  screen.after_action_funcs:add(func)
end
---

---- Register a function to be run before the screen is checked for updates
-- @within Registration
-- @tparam function func function to run before check (no arguments)
function screen.before_check(func)
  screen.before_check_funcs:add(func)
end
---

---- Register a function to be run after the screen is checked for updates
-- @within Registration
-- @tparam function func function to run after check (no arguments)
function screen.after_check(func)
  screen.after_check_funcs:add(func)
end
---

---- Register a function to be run before each tap
-- @within Registration
-- @tparam function func function to run before tap (no arguments)
function screen.before_tap(func)
  screen.before_tap_funcs:add(func)
end
---

---- Register a function to be run after each tap
-- @within Registration
-- @tparam function func function to run after tap (no arguments)
function screen.after_tap(func)
  screen.after_tap_funcs:add(func)
end
---

---- Register a function to be run when the screen is stalled.
-- This function should attempt stall recovery (e.g. restart current app)
-- @within Registration
-- @tparam function func function or list of functions to run when stalled (no arguments)
function screen.on_stall(func)
  _stall.count = 0
  _stall.last_check = 0
  _stall.last_colors = {}
  local fs
  if is.func(func) then fs = list{func} else fs = list(func) end
  local key = tostring(fs)
  _stall.cyclers[key] = {cycle=itertools.cycle(iter(fs)), fs=fs}
  screen.on_stall_funcs:add(setmetatable({}, {
    __hash=function() return key end,
    __call=function() 
      return _stall.cyclers[key].cycle()() 
    end
  }))
end
---

---- Check if the screen contains a pixel/set of pixels
-- @tparam Pixel|Pixels pixel Pixel(s) instance to check position(s) of
-- @treturn boolean does the screen contain the pixel(s)
function screen.contains(pixel)
  return pixel:visible()
end
---

--- Check if the screen has stalled on the same pixels
function screen.is_stalled()
  local current, previous
  local now = os.time()
  if now - _stall.last_check > screen.stall_after_checks_interval then
    _stall.last_check = now
    current = screen.stall_indicators.colors
    local result = false
    if requal(current, _stall.last_colors) then
      _stall.count = _stall.count + 1
      if _stall.count > screen.stall_after_checks then
        result = true
      end
    else
      _stall.count = 0
      for k, v in pairs(_stall.cyclers) do
        _stall.cyclers[k] = {cycle=itertools.cycle(iter(v.fs)), fs=v.fs}
      end
    end
    _stall.last_colors = current
    return result
  end

  return false
end
---

---- Tap the screen
-- @tparam int|Pixel x x-position or pixel to tap
-- @int y (optional) y-position to tap
-- @int times (optional) number of times to tap
-- @tparam number interval (optional) interval (in secs) between taps
-- @treturn screen screen for method chaining
function screen.tap(x, y, times, interval)
  local pixel
  if isType(x, 'number') then
    pixel = Pixel(x, y)
  else
    pixel, times, interval = x, y, times
  end
  
  with(screen.tap_context(), function()
    for i=1, times or 1 do
      tap(pixel.x, pixel.y)
      usleep(10000)
      if interval then usleep(max(0, interval * 10 ^ 6 - 10000)) end
    end
    end)
    
  return screen
end


---- Tap the screen if a pixel/set of pixels is visible
-- @tparam Pixel|function condition pixel(s) to search for or an argumentless function that returns a boolean
-- @param to_tap arguments for @{screen.tap}
-- @treturn screen screen for method chaining
function screen.tap_if(condition, to_tap)
  with(screen.action_context(condition), function(check) 
    
    if check() then
      screen.tap(to_tap or condition)
    end
    
    end)
  return screen
end


---- Tap the screen until a pixel/set of pixels is visible
-- @tparam Pixel|function condition see @{screen.tap_if}
-- @param to_tap arguments for @{screen.tap}
-- @treturn screen screen for method chaining
function screen.tap_until(condition, to_tap)
  with(screen.action_context(condition), function(check) 
    
    repeat  
      screen.tap(to_tap or condition)
      usleep(screen.check_interval)
    until check()
    
    end)
  return screen
end


---- Tap the screen while a pixel/set of pixels is visible
-- @tparam Pixel|function condition see @{screen.tap_if}
-- @param to_tap arguments for @{screen.tap}
-- @treturn screen screen for method chaining
function screen.tap_while(condition, to_tap)
  with(screen.action_context(condition), function(check) 
    
    while check() do
      screen.tap(to_tap or condition)
      usleep(screen.check_interval)
    end
    
    end)
  return screen
end


---- Swipe the screen
-- @tparam Pixel|string start_ pixel at which to start the swipe
-- @tparam Pixel|string end_ pixel at which to end the swipe
-- @int speed swipe speed (1-10)
-----------------
-- Possible string arguments for start_ and end_ are:
-----------------
--     left, right, top, bottom, center, 
-----------------
--     top_left, top_right, bottom_left, bottom_right
-----------------
-- @treturn screen screen for method chaining
function screen.swipe(start_, end_, speed)
  if is.str(start_) then
    assert(screen.mid[start_] or screen.edge[start_], 
      'Incorrect identifier: use one of (left, right, top, bottom, center, top_left, top_right, bottom_left, bottom_right)')
    start_ = screen.mid[start_] or screen.edge[start_]
  end
  
  if is.str(end_) then
    assert(screen.mid[end_] or screen.edge[end_], 
      'Incorrect identifier: use one of (left, right, top, bottom, center, top_left, top_right, bottom_left, bottom_right)')
    end_ = screen.mid[end_] or screen.edge[end_]
  end
  
  return Path.linear(start_, end_):swipe{speed=speed}
end


---- Wait until a pixel/set of pixels is visible
-- @tparam Pixel|function condition see @{screen.tap_if}
-- @treturn screen screen for method chaining
function screen.wait(condition)
  with(screen.action_context(condition), function(check) 
    
    repeat
      usleep(screen.check_interval)
    until check()
    
    end)
  return screen
end
