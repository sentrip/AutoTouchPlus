--- Screen interaction and observation helpers
-- @module screen.lua

screen = {
  
  before_action_funcs = list(),
  after_action_funcs = list(),
  before_check_funcs = list(),
  after_check_funcs = list(),
  before_tap_funcs = list(),
  after_tap_funcs = list(),
  
  check_interval = 150000, --checks every 150ms (0.15s)
  wait_before_action = 0,
  wait_after_action = 0,
  wait_before_tap = 0,
  wait_after_tap = 0
  
}
---

---
if Not.Nil(getScreenResolution) then
  screen.width, screen.height = getScreenResolution()
else
  screen.width, screen.height = 0, 0
end
---

---
screen.mid = {
  left = Pixel(0, screen.height / 2),
  right = Pixel(screen.width, screen.height / 2),
  top = Pixel(screen.width / 2, 0),
  bottom = Pixel(screen.height, screen.width / 2),
  center = Pixel(screen.width / 2, screen.height / 2)
}
---

---
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

---
local action_context = contextmanager(function(condition)
  
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
          
          local result = check()
          
          for func in iter(screen.after_check_funcs) do
            func()
          end
          
          return result
        end)
      
      end)

end)
---

---
local tap_context = contextmanager(function()
  
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
  screen.before_action_funcs:append(func)
end
---

---- Register a function to be run after a screen action
-- @param func function to run after action (no arguments)
function screen.after_action(func)
  screen.after_action_funcs:append(func)
end
---

---- Register a function to be run before a screen check
-- @param func function to run before check (no arguments)
function screen.before_check(func)
  screen.before_check_funcs:append(func)
end
---

---- Register a function to be run after a screen check
-- @param func function to run after check (no arguments)
function screen.after_check(func)
  screen.after_check_funcs:append(func)
end
---

---- Register a function to be run before a screen tap
-- @param func function to run before tap (no arguments)
function screen.before_tap(func)
  screen.before_tap_funcs:append(func)
end
---

---- Register a function to be run after a screen tap
-- @param func function to run after tap (no arguments)
function screen.after_tap(func)
  screen.after_tap_funcs:append(func)
end
---

---- Check if the screen contains a pixel/set of pixels
-- @tparam Pixel|Pixels pixel Pixel(s) instance to check position(s) of
-- @treturn boolean does the screen contain the pixel(s)
function screen.contains(pixel)
  return pixel:visible()
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
  
  with(tap_context(screen), function()
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
  with(action_context(condition), function(check) 
    
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
  with(action_context(condition), function(check) 
    
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
  with(action_context(condition), function(check) 
    
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
  with(action_context(condition), function(check) 
    
    repeat
      usleep(screen.check_interval)
    until check()
    
    end)
  return screen
end
---

---- Swipe the screen
-- @tparam Pixel|string start pixel at which to start the swipe, or one of 'left, 'right', 'top', 'bottom'
-- @tparam Pixel|string _end pixel at which to end the swipe, or one of 'left, 'right', 'top', 'bottom'
-- @tparam number speed swipe speed (1-10)
-- @treturn screen screen for method chaining
function screen.swipe(start, _end, speed)
  if is.str(start) then
    assert(screen.mid[start], 
      'Incorrect identifier: use one of (left, right, top, bottom)')
    start = screen.mid[start]
  end
  
  if is.str(_end) then
    assert(screen.mid[_end], 
      'Incorrect identifier: use one of (left, right, top, bottom)')
    _end = screen.mid[_end]
  end
  
  with(action_context(function() return true end), function(check) 
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
    end)

  return screen
end
---
