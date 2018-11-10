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
-- TODO: mock and test with all AutoTouch functions (rootDir, usleep, ...)
-- luacov: disable
local _width, _height
if Not.Nil(getScreenResolution) then
  _width, _height = getScreenResolution()
else
  _width, _height = 200, 400
end
-- luacov: enable

---- Number of microseconds after which the screen is checked for updates
screen.check_interval = 150000
---- Number of seconds to hold a finger on the screen by default
screen.hold_duration = 0.75
---- Number of microseconds between each consecutive tap
screen.tap_interval = 10000
---- Number of seconds to wait before each action (_tap\_if_, _tap\_until_, ...)
screen.wait_before_action = 0
---- Number of seconds to wait after each action (_tap\_if_, _tap\_until_, ...)
screen.wait_after_action = 0
---- Number of seconds to wait before each tap
screen.wait_before_tap = 0
---- Number of seconds to wait after each tap
screen.wait_after_tap = 0
---- Print detailed information about taps, swipes and checks
screen.debug = false
---- Width of screen from getScreenResolution (not writable)
screen.width = _width
---- Height of screen from getScreenResolution (not writable)
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

--- Context manager for tapping
-- @within Contexts
screen.tap_context = contextmanager(function()
  
  local ctx = create_context(
    screen.wait_before_tap, screen.wait_after_tap,
    screen.before_tap_funcs, screen.after_tap_funcs
  )
  
  with(ctx, function() yield() end)
  
end)

--- Context manager for holding down a finger the screen
-- @within Contexts
-- @tparam int|pixel.Pixel x
-- @int y (optional)
screen.hold_context = contextmanager(function(x, y)
  if isNotType(x, 'number') then x, y = x.x, x.y end
  with(screen.tap_context(), function() 
    touchDown(0, x, y)
    usleep(8000)
    yield(check)
    usleep(8000)
    touchUp(0, x, y)
  end)
end)
---

---- Register a function to be run before an action (_tap\_if_, _tap\_until_, ...)
-- @within Listeners
-- @func func function to run before action (no arguments)
function screen.before_action(func)
  screen.before_action_funcs:add(func)
end


---- Register a function to be run after an action (_tap\_if_, _tap\_until_, ...)
-- @within Listeners
-- @func func function to run after action (no arguments)
function screen.after_action(func)
  screen.after_action_funcs:add(func)
end


---- Register a function to be run before the screen is checked for updates
-- @within Listeners
-- @func func function to run before check (no arguments)
function screen.before_check(func)
  screen.before_check_funcs:add(func)
end


---- Register a function to be run after the screen is checked for updates
-- @within Listeners
-- @func func function to run after check (no arguments)
function screen.after_check(func)
  screen.after_check_funcs:add(func)
end


---- Register a function to be run before a finger touches the screen
-- @within Listeners
-- @func func function to run before tap (no arguments)
function screen.before_tap(func)
  screen.before_tap_funcs:add(func)
end


---- Register a function to be run after a finger touches the screen
-- @within Listeners
-- @func func function to run after tap (no arguments)
function screen.after_tap(func)
  screen.after_tap_funcs:add(func)
end


---- Register a function to be run after a number of consecutive screen checks
-- @within Listeners
-- @tparam int|table n number of checks to execute before calling function
-- @func func function to run after n consecutive checks
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
-- @tparam pixel.Pixel|pixel.Pixels pix Pixel(s) instance to check position(s) of
-- @treturn boolean does the screen contain the pixel(s)
function screen.contains(pix)
  return pix:visible()
end



---- Hold a finger on the screen
-- @tparam number|pixel.Pixel x x-position/pixel(s) to hold
-- @int y (optional) y position to hold
-- @number seconds (optional) Number of seconds to hold finger on the screen (default: 0.5s)
-- @treturn screen screen for method chaining
-- @usage -- hold x=10, y=10 for 0.5 seconds
-- screen.hold(10, 10, 0.5)
-- -- or
-- screen.hold(Pixel(10, 10), 0.5)
function screen.hold(x, y, seconds)
  if isNotType(x, 'number') then
    x, y, seconds = x.x, x.y, y
  end
  with(screen.hold_context(x, y), function() 
    usleep((seconds or screen.hold_duration) * 1000000)
  end)
  return screen
end


---- Hold the screen if a pixel/set of pixels is visible
-- @tparam pixel.Pixel|pixel.Pixels|func condition condition to hold if
-- @pixel to_hold (optional) pixel to hold
-- @treturn screen screen for method chaining
-- @see screen.tap_if
function screen.hold_if(condition, to_hold)
  _log_action(condition, 'Hold if', 'true')
  with(screen.action_context(condition), function(check) 
    
    if check() then
      screen.hold(to_hold or condition)
    end
    
    end)
  return screen
end


---- Hold the screen until a pixel/set of pixels is visible
-- @tparam pixel.Pixel|pixel.Pixels|func condition condition to hold until
-- @pixel to_hold (optional) pixel to hold
-- @treturn screen screen for method chaining
-- @see screen.tap_if
function screen.hold_until(condition, to_hold)
  _log_action(condition, 'Hold until', 'true')
  
  with(screen.action_context(condition), function(check) 
    with(screen.hold_context(to_hold or condition), function() 
      repeat usleep(screen.check_interval) until check()
      end)
    end)
  return screen
end


---- Hold the screen while a pixel/set of pixels is visible
-- @tparam pixel.Pixel|pixel.Pixels|func condition condition to hold while
-- @pixel to_hold (optional) pixel to hold
-- @treturn screen screen for method chaining
-- @see screen.tap_if
function screen.hold_while(condition, to_hold)
  _log_action(condition, 'Hold while', 'false')
  with(screen.action_context(condition), function(check) 
    with(screen.hold_context(to_hold or condition), function() 
      while check() do usleep(screen.check_interval) end
      end)
    end)
  return screen
end


---- Tap the screen
-- @tparam pixel.Pixel|int x x-position or pixel to tap
-- @int y (optional) y-position to tap
-- @int times (optional) number of times to tap
-- @number interval (optional) interval (in seconds) between taps
-- @treturn screen screen for method chaining
-- @usage -- tap x=10, y=10 twice and wait 1 second between taps
-- screen.tap(10, 10, 2, 1)
-- -- or
-- screen.tap(Pixel(10, 10), 2, 1)
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
      usleep(screen.tap_interval)
      if interval then usleep(max(0, interval * 10 ^ 6 - screen.tap_interval)) end
    end
    end)
    
  return screen
end


local function create_coro_and_repeat(f, times)
  return coroutine.create(function() 
    local c = 0
    while c < times do 
      local coro = coroutine.create(f)
      coroutine.resume(coro)
      yield() 
      coroutine.resume(coro)
      c = c + 1
    end
  end)
end

local function execute_concurrently(fs, times, stop)
  stop = stop or function() return false end

  local coros = list()
  for f in iter(fs) do 
    coros:append(create_coro_and_repeat(f, times)) 
  end

  local running = true
  while running do
    running = false
    for co in iter(coros) do 
      coroutine.resume(co)
      running = running or coroutine.status(co) ~= 'dead'
    end
    if stop() then break end
  end
end

local function get_positions(positions, x, y, n)
  if positions then return positions end
  -- TODO: tap multiple adjacent pixels in spiral when single position given
  return list{{x=x, y=y}} * n
end

---- Tap the screen quickly with multiple fingers.
-- With multitouch, more fingers mean more taps/sec.<br>
-- <strong>Tap speed: approx. 50 taps/sec per finger</strong>
-- @tparam number|pixel.Pixel|table x x-position/pixel(s) to tap
-- @int y (optional) y position to tap (not required if x is not a number)
-- @tparam int|pixel.Pixel|func times (optional) <ul>
-- <li>Number of taps per finger (total taps: n * fingers)</li> 
-- <li>Pixel that when visible stops tapping</li>
-- <li>Function that returns true when tapping should stop</li></ul>
-- @int fingers (optional) number of fingers to use
-- @treturn screen screen for method chaining
-- @usage -- tap x=10, y=10 twice with 2 fingers (4 total taps)
-- screen.tap_fast(10, 10, 2, 2)
-- -- or
-- screen.tap_fast(Pixel(10, 10), 2, 2)
-- 
-- -- tap each position with a unique finger twice (4 total taps)
-- screen.tap_fast({{x=10, y=10}, {x=20, y=20}}, 2)
-- -- or
-- screen.tap_fast(Pixels{{10, 10}, {20, 20}}, 2)
--
-- -- tap x=10, y=10 with 2 fingers until x=20, y=20 is red
-- local check_pixel = Pixel(20, 20, colors.red)
-- screen.tap_fast(10, 10, check_pixel, 2)
-- -- or
-- screen.tap_fast(Pixel(10, 10), check_pixel, 2)
--
-- -- tap x=10, y=10 with 2 fingers a random number of times
-- local check_func = function() return math.random() < 0.3 end
-- screen.tap_fast(10, 10, check_func, 2)
-- -- or
-- screen.tap_fast(Pixel(10, 10), check_func, 2)
function screen.tap_fast(x, y, times, fingers)
  -- Get positions to tap
  local positions
  if isinstance(x, 'Pixel') then 
    x, y, times, fingers = x.x, x.y, y, (times or 1)
  elseif isType(x, 'table') then
    fingers, positions, times = len(x), list(x), y
  end
  positions = get_positions(positions, x, y, fingers)
  -- Create tap functions
  local tap_funcs = list()
  for i=1, (fingers or 1) do 
    tap_funcs:append(function() 
      touchDown(i, positions[i].x, positions[i].y)
      yield(usleep(8000))
      touchUp(i, positions[i].x, positions[i].y)
      usleep(1000)
    end)
  end
  -- Get number of taps and optional stop condition from times argument
  local condition
  local n = math.huge -- tap forever by default
  if isinstance(times, 'Pixel') then 
    condition = function() return screen.contains(times) end
  elseif isinstance(times, 'function') then 
    condition = times
  elseif times ~= 0 then 
    n = times or 1
  end
  -- Run tap functions concurrently until all are done
  execute_concurrently(tap_funcs, n, condition)
  return screen
end


---- Tap the screen if a pixel/set of pixels is visible
-- @tparam pixel.Pixel|pixel.Pixels|func condition pixel(s) to search for or a function that returns true if tapping is required
-- @pixel to_tap (optional) pixel to tap
-- @treturn screen screen for method chaining
-- @usage -- tap x=10, y=10 if x=10, y=10 is red
-- screen.tap_if(Pixel(10, 10, colors.red))
-- -- tap x=50, y=50 if x=10, y=10 is red
-- screen.tap_if(Pixel(10, 10, colors.red), Pixel(50, 50))
-- -- tap x=50, y=50 if x=10, y=10 is red AND x=20, y=20 is red
-- screen.tap_if(Pixels{{10, 10, colors.red}, {20, 20, colors.red}}, Pixel(50, 50))
-- -- tap x=50, y=50 if function returns true
-- function needs_tap() return true end
-- screen.tap_if(needs_tap, Pixel(50, 50))
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
-- @tparam pixel.Pixel|pixel.Pixels|func condition condition to tap until
-- @pixel to_tap (optional) pixel to tap
-- @treturn screen screen for method chaining
-- @see screen.tap_if
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
-- @tparam pixel.Pixel|pixel.Pixels|func condition condition to tap while
-- @pixel to_tap (optional) pixel to tap
-- @treturn screen screen for method chaining
-- @see screen.tap_if
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


---- Swipe the screen.
-- <br>Possible string arguments are:<ul>
--<li>left, right, top, bottom, center</li>
--<li>top\_left, top\_right, bottom\_left, bottom\_right</li>
--</ul>
-- @tparam pixel.Pixel|string start_ pixel at which to start the swipe
-- @tparam pixel.Pixel|string end_ pixel at which to end the swipe
-- @int speed swipe speed (1-10)
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
-- @tparam pixel.Pixel|pixel.Pixels|func condition condition to wait for
-- @treturn screen screen for method chaining
-- @see screen.tap_if
function screen.wait(condition)
  _log_action(condition, 'Wait', 'true')
  with(screen.action_context(condition), function(check) 
    
    repeat
      usleep(screen.check_interval)
    until check()
    
    end)
  return screen
end
