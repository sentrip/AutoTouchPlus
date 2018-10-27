--- Screen interaction and observation helpers
-- @module screen.lua

screen = {
  before_action_funcs = set(),
  after_action_funcs = set(),
  before_check_funcs = set(),
  after_check_funcs = set(),
  before_tap_funcs = set(),
  after_tap_funcs = set(),
  nth_check_funcs = dict()
}
-- luacov: disable
local _width, _height
if Not.Nil(getScreenResolution) then
  _width, _height = getScreenResolution()
else
  _width, _height = 200, 400
end
-- luacov: enable

---- Number milliseconds after which the screen is checked for updates
screen.check_interval = 150000
---- Number of seconds to wait before each action (tap_if, tap_until, ...)
screen.wait_before_action = 0
---- Number of seconds to wait after each action (tap_if, tap_until, ...)
screen.wait_after_action = 0
---- Number of seconds to wait before each tap
screen.wait_before_tap = 0
---- Number of seconds to wait after each tap
screen.wait_after_tap = 0
---- Print detailed information about taps, swipes and checks
screen.debug = false
---- Width of screen from getScreenResolution() (not writable)
screen.width = _width
---- Height of screen from getScreenResolution() (not writable)
screen.height = _height


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


local function _log(msg, ...) 
  if screen.debug then print(string.format(msg, ...)) end 
end

local function _log_action(condition, name, value)
  _log('%-32s: %s', 'Creating check for', condition)
  _log('%-10s - %-19s: %s', name, 'wait for', value)
end


local create_context = contextmanager(function(before_wait, after_wait, before_funcs, after_funcs)
  
  os.sleep(before_wait)
    
  for func in iter(before_funcs) do
    func()
  end

  yield()

  for func in iter(after_funcs) do
    func()
  end

  os.sleep(after_wait)

end)
---


---- Context manager for screen actions and checking
-- @within Contexts
-- @param condition 
screen.action_context = contextmanager(function(check)
  local _pixel
  local check_count = 0
  
  if not is.func(check) then 
    _pixel, check = check, function() return screen.contains(_pixel) end 
  end
  
  local ctx = create_context(
    screen.wait_before_action, screen.wait_after_action, 
    screen.before_action_funcs, screen.after_action_funcs
  )
  
  with(ctx, function()
    yield(function()
      -- Before check
      for func in iter(screen.before_check_funcs) do func() end
      -- Check
      local result = check()
      check_count = check_count + 1
      _log('%-32s: %s', 'Check '..check_count..' for condition', result)
      -- After check
      for func in iter(screen.after_check_funcs) do func() end
      -- Functions registered to current check count
      local nth_check_funcs = screen.nth_check_funcs[check_count] or list()
      if is(nth_check_funcs) then _log('Running nth_check functions after check %s', check_count) end
      for func in iter(nth_check_funcs) do func() end
      -- Return check result
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
-- @within Listeners
-- @tparam function func function to run before action (no arguments)
function screen.before_action(func)
  screen.before_action_funcs:add(func)
end


---- Register a function to be run after an action (tap_if, tap_until, ...)
-- @within Listeners
-- @tparam function func function to run after action (no arguments)
function screen.after_action(func)
  screen.after_action_funcs:add(func)
end


---- Register a function to be run before the screen is checked for updates
-- @within Listeners
-- @tparam function func function to run before check (no arguments)
function screen.before_check(func)
  screen.before_check_funcs:add(func)
end


---- Register a function to be run after the screen is checked for updates
-- @within Listeners
-- @tparam function func function to run after check (no arguments)
function screen.after_check(func)
  screen.after_check_funcs:add(func)
end


---- Register a function to be run before each tap
-- @within Listeners
-- @tparam function func function to run before tap (no arguments)
function screen.before_tap(func)
  screen.before_tap_funcs:add(func)
end


---- Register a function to be run after each tap
-- @within Listeners
-- @tparam function func function to run after tap (no arguments)
function screen.after_tap(func)
  screen.after_tap_funcs:add(func)
end


---- Register a function to be run after a number of consecutive screen checks
-- @within Listeners
-- @tparam int|table n number of checks to execute before calling function
-- @tparam function func function to run after n consecutive checks
function screen.on_nth_check(n, func)
  if type(n) == 'number' then n = {n} end
  if is.func(func) then func = {func} end
  for _, v in pairs(n) do
    screen.nth_check_funcs[v] = screen.nth_check_funcs[v] or list()
    for f in iter(func) do 
      screen.nth_check_funcs[v]:append(f) 
    end
  end
end


---- Check if the screen contains a pixel/set of pixels
-- @tparam Pixel|Pixels pixel Pixel(s) instance to check position(s) of
-- @treturn boolean does the screen contain the pixel(s)
function screen.contains(pixel)
  return pixel:visible()
end


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
      _log('Tap \t%5s, %5s', pixel.x, pixel.y)
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
  _log_action(condition, 'Tap if', 'true')
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
  _log_action(condition, 'Tap until', 'true')
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
  _log_action(condition, 'Tap while', 'false')
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
  _log('Swipe with speed %s from %s to %s', speed, start_, end_)
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
  _log_action(condition, 'Wait', 'true')
  with(screen.action_context(condition), function(check) 
    
    repeat
      usleep(screen.check_interval)
    until check()
    
    end)
  return screen
end
