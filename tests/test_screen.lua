require('src/test')
require('src/core')
require('src/builtins')
require('src/contextlib')
require('src/itertools')
require('src/logic')
require('src/logging')
require('src/objects')
require('src/pixel')
require('src/path')
require('src/screen')
require('src/string')
require('src/system')

usleep = function(...) end

fixture('do_after', function() 
  return function(n, f, f_before)
    local count = 0
    return function()
      if f_before then f_before() end
      count = count + 1
      if count >= n then
        f()
      end
    end 
  end
end)


fixture('pixels', function(monkeypatch) 
  local pixels = list{
    Pixel(10, 10, 10),
    Pixel(20, 20, 20),
    Pixel(30, 30, 30),
    Pixel(40, 40, 40),
  }
  local function _getColor(x, y) 
    for p in iter(pixels) do if p.x == x and p.y == y then return p.expected_color end end
  end
  local function _getColors(pos) 
    local colors = list()
    for p in iter(pos) do colors:append(_getColor(p[1], p[2])) end
    return colors
  end
  
  monkeypatch.setattr('getColor', _getColor)
  monkeypatch.setattr('getColors', _getColors)
  return pixels
end)


fixture('taps', function(monkeypatch)
  screen.before_action_funcs = set()
  screen.after_action_funcs = set()
  screen.before_check_funcs = set()
  screen.after_check_funcs = set()
  screen.before_tap_funcs = set()
  screen.after_tap_funcs = set() 
  screen.nth_check_funcs = dict()
  screen.check_interval = 150
  local taps = list()
  monkeypatch.setattr('tap', function(x, y) taps:append(list{x, y}) end)
  return taps
end)


fixture('touches', function(monkeypatch)
  screen.hold_duration = 0.001
  local touches = list()
  monkeypatch.setattr('usleep', function(...) end)
  monkeypatch.setattr('touchDown', function(i, x, y) touches:append({'down', i, x, y}) end)
  monkeypatch.setattr('touchUp', function(i, x, y) touches:append({'up', i, x, y}) end)
  monkeypatch.setattr('touchMove', function(i, x, y) touches:append({'move', i, x, y}) end)
  return touches
end)


describe('screen - Basic', 
  it('can run functions after consecutive checks', function(monkeypatch, pixels, taps)
    
    local calls = list()
    local c = 0
    screen.before_check(function() c = c + 1 end)
    screen.on_nth_check({4, 6}, function() 
      calls:append(c)
    end)

    screen.on_nth_check(10, function() 
      calls:append(c)
      pixels:clear()
    end)

    screen.tap_while(pixels[1])
    assert(len(calls) == 3, 'Did not call on_nth_check correct number of times')
    assert(requal(calls, {4, 6, 10}), 'Did not execute nth check funcs in correct order')
  end),

  it('can run screen functions inside check after consecutive checks', function(monkeypatch, pixels, taps)

    local calls = list()
    local c = 0
    local remove_second = false

    screen.before_check(function() 
      c = c + 1 
      if remove_second and c >= 10 and pixels[2] then pixels:remove(pixels[2]) end
    end)
    screen.on_nth_check(5, function() 
      calls:append(c)
      remove_second = true
      screen.tap_while(pixels[2])
      pixels:clear()
    end)

    screen.tap_while(pixels[1])
    assert(len(calls) == 2, 'Did not call on_nth_check correct number of times')
    assert(requal(calls, {5, 10}), 'Did not execute nth check funcs in correct order')
  end),

  it('can tap_fast a single position', function(pixels, taps, touches) 
    screen.tap_fast(10, 10, 2, 2)
    local ex = {{'down', 1, 10, 10}, {'down', 2, 10, 10}, {'up', 1, 10, 10}, {'down', 1, 10, 10}, {'up', 2, 10, 10}, {'down', 2, 10, 10}, {'up', 1, 10, 10}, {'up', 2, 10, 10}}
    assert(requal(touches, ex), 'Did not tap_fast single number position in correct order')
    touches:clear()
    screen.tap_fast(pixels[1], 2, 2)
    assert(requal(touches, ex), 'Did not tap_fast single table position in correct order')
  end),

  it('can tap_fast multiple positions', function(pixels, taps, touches) 
    screen.tap_fast(pixels(1,2), 2, 2)
    local ex = {{'down', 1, 10, 10}, {'down', 2, 20, 20}, {'up', 1, 10, 10}, {'down', 1, 10, 10}, {'up', 2, 20, 20}, {'down', 2, 20, 20}, {'up', 1, 10, 10}, {'up', 2, 20, 20}}
    assert(requal(touches, ex), 'Did not tap_fast multiple positions in correct order')
  end),

  it('can cancel tap_fast', function(pixels, touches) 
    local c = 0
    local function cancel()
      c = c + 1
      return c >= 3
    end
    screen.tap_fast(pixels[1], cancel)
    assert(len(touches) == 5, 'Did not touch correct number of times')
    assert(touches[1][1] == 'down', 'Did not touch down to start')
    touches:clear()
    screen.tap_fast(pixels[1], pixels[1])
    assert(len(touches) == 1, 'Did not touch correct number of times')
    assert(touches[1][1] == 'down', 'Did not touch down to start')
  end),

  it('can swipe between pixels', function(touches) 
    local start_pix = Pixel(10, 10)
    local end_pix = Pixel(100, 100)
    for speed in iter{1, 5, 10} do
      screen.swipe(start_pix, end_pix, speed)
      assert(len(touches) == 50 / speed + 1, 'Did not touch and move correctly')
      assert(touches[1][1] == 'down', 'Did not swipe in correct order')
      assert(touches[2][1] == 'move', 'Did not swipe in correct order')
      assert(touches[-1][1] == 'up', 'Did not swipe in correct order')
      touches:clear()
    end
  end),

  it('can swipe in a direction', function(touches) 
    local positions = {'left', 'right', 'top', 'bottom', 'center', 'top_left', 'top_right', 'bottom_left', 'bottom_right'}
    for pos1 in iter(positions) do
      for pos2 in iter(positions) do
        if pos1 ~= pos2 then
          screen.swipe(pos1, pos2, 10)
          assert(len(touches) == 6, 'Did not touch and move correctly')
          assert(touches[1][1] == 'down', 'Did not swipe in correct order')
          assert(touches[2][1] == 'move', 'Did not swipe in correct order')
          assert(touches[-1][1] == 'up', 'Did not swipe in correct order')
          touches:clear()
        end
      end
    end
  end),

  it('can wait for a pixel', function(taps, pixels, do_after) 
    local checks = 0
    local pix = Pixel(100, 100)
    local required_checks = 3
    screen.before_check(do_after(required_checks, 
      function() pixels:append(pix) end,
      function() checks = checks + 1 end
    ))
    screen.wait(pix)
    assert(checks == required_checks, 'Checked less than required amount')
  end),
  
  it('can wait for a condition', function(taps, do_after) 
    local checks = 0
    local cond = false
    local required_checks = 3
    screen.before_check(do_after(required_checks, 
      function() cond = true end,
      function() checks = checks + 1 end
    ))
    screen.wait(function() return cond end)
    assert(checks == required_checks, 'Checked less than required amount')
  end)
)

describe('screen - Hold',

  it('can hold a position', function(touches) 
    local x, y, seconds = 10, 10, 0.001
    screen.hold(x, y, seconds)
    assert(len(touches) == 2, 'Did not hold screen at position')
    assert(touches[1][3] == x, 'Did not hold screen at correct position')
  end),
  
  it('can hold a pixel', function(touches) 
    local pix, seconds = Pixel(10, 10), 0.001
    screen.hold(pix, seconds)
    assert(len(touches) == 2, 'Did not hold screen at pixel')
    assert(touches[1][3] == pix.x, 'Did not hold screen at correct pixel position')
  end),
  
  it('can hold with context', function(touches, do_after) 
    local action_calls = list()
    local check_calls = list()
    local hold_calls = list()
    screen.before_action(function() action_calls:append('begin') end)
    screen.after_action(function() action_calls:append('end') end)
    screen.before_check(function() check_calls:append('begin') end)
    screen.after_check(function() check_calls:append('end') end)
    screen.before_tap(function() hold_calls:append('begin') end)
    screen.after_tap(function() hold_calls:append('end') end)
    
    local count = 0
    screen.hold_while(function() count = count + 1; return count < 3 end, Pixel(100, 100))
    
    assertRequal(action_calls, {'begin', 'end'}, 'action calls order incorrect')
    assertRequal(check_calls, {'begin', 'end', 'begin', 'end', 'begin', 'end'}, 'check calls order incorrect')
    assertRequal(hold_calls, {'begin', 'end'}, 'hold calls order incorrect')
  end),
  
  it('can hold if a pixel is visible', function(touches, pixels) 
    local pix = Pixel(100, 100)
    screen.hold_if(pix)
    assert(len(touches) == 0, 'Held when pixel is not visible')
    pixels:append(pix)
    screen.hold_if(pix)
    assert(len(touches) == 2, 'Did not hold when pixel is visible')
    assert(touches[-1][3] == 100, 'Did not hold correct position')
    screen.hold_if(pix, Pixel(200, 200))
    assert(touches[-1][3] == 200, 'Did not hold correct position')
  end),
  
  it('can hold while a pixel is visible', function(touches, pixels, do_after) 
    local pix = Pixel(100, 100)
    pixels:append(pix)
    screen.before_tap(do_after(1, function() pixels:remove(pix) end))
    screen.hold_while(pix)
    assert(len(touches) == 2, 'Held less than required amount')
  end),
  
  it('can hold until a pixel is visible', function(touches, pixels, do_after) 
    local pix = Pixel(100, 100)
    screen.before_tap(do_after(1, function() pixels:append(pix) end))
    screen.hold_until(pix)
    assert(len(touches) == 2, 'Held less than required amount')
  end),
  
  it('can hold if a condition is met', function(touches) 
    screen.hold_if(function() return false end, Pixel(100, 100))
    assert(len(touches) == 0, 'Held when condition not met')
    screen.hold_if(function() return true end, Pixel(100, 100))
    
    assert(len(touches) == 2, 'Did not hold when condition is met')
    -- assert(touches[-1][3] == 100, 'Did not hold correct position')
  end),
  
  it('can hold while a condition is met', function(touches, do_after) 
    local cond = true
    screen.before_tap(do_after(1, function() cond = false end))
    screen.hold_while(function() return cond end, Pixel(100, 100))
    assert(len(touches) == 2, 'Held less than required amount')
  end),
  
  it('can hold until a condition is met', function(touches, do_after) 
    local cond = false
    screen.before_tap(do_after(1, function() cond = true end))
    screen.hold_until(function() return cond end, Pixel(100, 100))
    assert(len(touches) == 2, 'Held less than required amount')
  end)
)

describe('screen - Tap',
  it('can tap a position', function(taps) 
    local x, y, times = 10, 10, 5
    screen.tap(x, y, times)
    assert(len(taps) == times, 'Did not tap screen at position')
    assert(taps[1][1] == x, 'Did not tap screen at correct position')
  end),
  
  it('can tap a pixel', function(taps) 
    local pix, times = Pixel(10, 10), 5
    screen.tap(pix, times)
    assert(len(taps) == times, 'Did not tap screen at pixel')
    assert(taps[1][1] == pix.x, 'Did not tap screen at correct pixel position')
  end),
  
  it('can tap with context', function(taps, do_after) 
    local action_calls = list()
    local check_calls = list()
    local tap_calls = list()
    screen.before_action(function() action_calls:append('begin') end)
    screen.after_action(function() action_calls:append('end') end)
    screen.before_check(function() check_calls:append('begin') end)
    screen.after_check(function() check_calls:append('end') end)
    screen.before_tap(function() tap_calls:append('begin') end)
    screen.after_tap(function() tap_calls:append('end') end)
    
    local count = 0
    screen.tap_while(function() count = count + 1; return count < 3 end, Pixel(100, 100))
    
    assertRequal(action_calls, {'begin', 'end'}, 'action calls order incorrect')
    assertRequal(check_calls, {'begin', 'end', 'begin', 'end', 'begin', 'end'}, 'check calls order incorrect')
    assertRequal(tap_calls, {'begin', 'end', 'begin', 'end'}, 'tap calls order incorrect')
  end),
  
  it('can tap if a pixel is visible', function(taps, pixels) 
    local pix = Pixel(100, 100)
    screen.tap_if(pix)
    assert(len(taps) == 0, 'Tapped when pixel is not visible')
    pixels:append(pix)
    screen.tap_if(pix)
    assert(len(taps) == 1, 'Did not tap when pixel is visible')
    assert(taps[-1][1] == 100, 'Did not tap correct position')
    screen.tap_if(pix, Pixel(200, 200))
    assert(taps[-1][1] == 200, 'Did not tap correct position')
  end),
  
  it('can tap while a pixel is visible', function(taps, pixels, do_after) 
    local pix = Pixel(100, 100)
    pixels:append(pix)
    local required_taps = 3
    screen.before_tap(do_after(required_taps, 
      function() pixels:remove(pix) end
    ))
    screen.tap_while(pix)
    assert(len(taps) == required_taps, 'Tapped less than required amount')
  end),
  
  it('can tap until a pixel is visible', function(taps, pixels, do_after) 
    local pix = Pixel(100, 100)
    local required_taps = 3
    screen.before_tap(do_after(required_taps, 
      function() pixels:append(pix) end
    ))
    screen.tap_until(pix)
    assert(len(taps) == required_taps, 'Tapped less than required amount')
  end),
  
  it('can tap if a condition is met', function(taps) 
    screen.tap_if(function() return false end, Pixel(100, 100))
    assert(len(taps) == 0, 'Tapped when condition not met')
    screen.tap_if(function() return true end, Pixel(100, 100))
    assert(len(taps) == 1, 'Did not tap when condition is met')
    assert(taps[-1][1] == 100, 'Did not tap correct position')
  end),
  
  it('can tap while a condition is met', function(taps, do_after) 
    local cond = true
    local required_taps = 3
    screen.before_tap(do_after(required_taps, 
      function() cond = false end
    ))
    screen.tap_while(function() return cond end, Pixel(100, 100))
    assert(len(taps) == required_taps, 'Tapped less than required amount')
  end),
  
  it('can tap until a condition is met', function(taps, do_after) 
    local cond = false
    local required_taps = 3
    screen.before_tap(do_after(required_taps, 
      function() cond = true end
    ))
    screen.tap_until(function() return cond end, Pixel(100, 100))
    assert(len(taps) == required_taps, 'Tapped less than required amount')
  end)
)


run_tests()
