--- Screen interaction and observation helpers
-- @module screen.lua

screen = {
  
  before_action_funcs = set(),
  after_action_funcs = set(),
  before_check_funcs = set(),
  after_check_funcs = set(),
  before_tap_funcs = set(),
  after_tap_funcs = set(),
  on_stall_funcs = set(),

  check_interval = 150000,              -- every 150ms (0.15s)
  stall_after_checks = 5,               -- after 5 same screens
  stall_after_checks_interval = 3 * 60, -- every 180s

  wait_before_action = 0,
  wait_after_action = 0,
  wait_before_tap = 0,
  wait_after_tap = 0
  
}
---
local _stall = {count = 0, last_check=0, last_colors={}}
---

---
if Not.Nil(getScreenResolution) then
  screen.width, screen.height = getScreenResolution()
else
  screen.width, screen.height = 200, 400
end
---

---
screen.edge = {
  top_left = Pixel(0, 0),
  top_right = Pixel(screen.width, 0),
  bottom_left = Pixel(0, screen.height),
  bottom_right = Pixel(screen.width, screen.height)
}
---
screen.mid = {
  left = Pixel(0, screen.height / 2),
  right = Pixel(screen.width, screen.height / 2),
  top = Pixel(screen.width / 2, 0),
  bottom = Pixel(screen.width / 2, screen.height),
  center = Pixel(screen.width / 2, screen.height / 2)
}
---
screen.stall_indicators = Pixels{
  -- TODO: add more pixels for screen recovery check
  screen.mid.center
}
---

--@local
getColor = getColor or function(...) return 0 end
getColors = getColors or function(...) return {0} end
tap = tap or function(...) end
touchDown = touchDown or function(...) end
touchMove = touchDown or function(...) end
touchUp = touchDown or function(...) end
usleep = usleep or function(...) end
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
screen.tap_context = contextmanager(function()
  
  local ctx = create_context(
    screen.wait_before_tap, screen.wait_after_tap,
    screen.before_tap_funcs, screen.after_tap_funcs
  )
  
  with(ctx, function() yield() end)
  
end)
---

---- Register a function to be run before a screen action
-- @param func function to run before action (no arguments)
function screen.before_action(func)
  screen.before_action_funcs:add(func)
end
---

---- Register a function to be run after a screen action
-- @param func function to run after action (no arguments)
function screen.after_action(func)
  screen.after_action_funcs:add(func)
end
---

---- Register a function to be run before a screen check
-- @param func function to run before check (no arguments)
function screen.before_check(func)
  screen.before_check_funcs:add(func)
end
---

---- Register a function to be run after a screen check
-- @param func function to run after check (no arguments)
function screen.after_check(func)
  screen.after_check_funcs:add(func)
end
---

---- Register a function to be run before a screen tap
-- @param func function to run before tap (no arguments)
function screen.before_tap(func)
  screen.before_tap_funcs:add(func)
end
---

---- Register a function to be run after a screen tap
-- @param func function to run after tap (no arguments)
function screen.after_tap(func)
  screen.after_tap_funcs:add(func)
end
---

---- Register a function to be run when the screen is stalled
-- @param func function or list of functions to run when stalled (no arguments)
function screen.on_stall(func)
  local fs
  if is.func(func) then fs = list{func} else fs = list(func) end
  local cycler = itertools.cycle(iter(fs))
  local t = {}
  screen.on_stall_funcs:add(setmetatable(t, {
    __call=function() return cycler()() end,
    __hash=function() return tostring(t) end
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

--- Check if the screen has stalled on the same pixels for a while
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
      _stall.cyclers = list()
    end
    _stall.last_colors = current
    return result
  end

  return false
end
---

---- Improved tap function
-- @param x x-position to tap
-- @param y y-position to tap
-- @param times number of times to tap
-- @param interval interval (in secs) between taps
-- @treturn screen screen for method chaining
function screen.tap(x, y, times, interval)
  local pixel
  if isType(x, 'number') then
    pixel = Pixel(x, y)
  else
    pixel, times, interval = x, y, times
  end
  
  with(screen.tap_context(screen), function()
    for i=1, times or 1 do
      tap(pixel.x, pixel.y)
      usleep(10000)
      if interval then usleep(max(0, interval * 10 ^ 6 - 10000)) end
    end
    end)
    
  return screen
end
---

---- Tap the screen if a pixel/set of pixels is visible
-- @tparam Pixel|func condition pixel(s) to search for or an argumentless function that returns a boolean
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
---

---- Tap the screen while a pixel/set of pixels is visible
-- @tparam Pixel|func condition see @{screen.tap_if}
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
---

---- Tap the screen until a pixel/set of pixels is visible
-- @tparam Pixel|func condition see @{screen.tap_if}
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
---

---- Wait until a pixel/set of pixels is visible
-- @tparam Pixel|func condition see @{screen.tap_if}
-- @treturn screen screen for method chaining
function screen.wait(condition)
  with(screen.action_context(condition), function(check) 
    
    repeat
      usleep(screen.check_interval)
    until check()
    
    end)
  return screen
end
---

---- Swipe the screen
-- @tparam Pixel|string start pixel at which to start the swipe
-- @tparam Pixel|string _end pixel at which to end the swipe
-- Possible string arguments for start and _end:
--     left, right, top, bottom, center, 
--     top_left, top_right, bottom_left, bottom_right
-- @tparam number speed swipe speed (1-10)
-- @treturn screen screen for method chaining
function screen.swipe(start, _end, speed)
  if is.str(start) then
    assert(screen.mid[start] or screen.edge[start], 
      'Incorrect identifier: use one of (left, right, top, bottom, center, top_left, top_right, bottom_left, bottom_right)')
    start = screen.mid[start] or screen.edge[start]
  end
  
  if is.str(_end) then
    assert(screen.mid[_end] or screen.edge[_end], 
      'Incorrect identifier: use one of (left, right, top, bottom, center, top_left, top_right, bottom_left, bottom_right)')
    _end = screen.mid[_end] or screen.edge[_end]
  end
  
  return Path.linear(start, _end):swipe{speed=speed}
end
