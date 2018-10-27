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


fixture('touches', function(monkeypatch)
  local touches = list()
  monkeypatch.setattr('usleep', function(...) end)
  monkeypatch.setattr('touchDown', function(i, x, y) touches:append({'down', i, x, y}) end)
  monkeypatch.setattr('touchUp', function(i, x, y) touches:append({'up', i, x, y}) end)
  monkeypatch.setattr('touchMove', function(i, x, y) touches:append({'move', i, x, y}) end)
  return touches
end)


describe('path', 

  it('can stringify Path and RelativePath', function() 
    local absolute = Path{{x=0, y=0}, {x=10, y=10}}
    local relative = RelativePath{{x=0, y=0}, {x=10, y=10}}
    assert(tostring(absolute) == string.format('<Path(points=%s, duration=%.2fs)>', len(absolute.locations), absolute.duration))
    assert(tostring(relative) == string.format('<RelativePath(points=%s, duration=%.2fs)>', len(relative.locations), relative.duration))
  end),

  it('can get pairs of a Path', function() 
    for i, v in pairs(Path{{x=1,y=1},{x=2,y=2}}) do
      assert(v.x == i and v.y == i, 'Did not yield correct position in pairs')
    end
  end),

  it('can do Path + Path', function() 
    local path = Path{{x=0, y=0}, {x=10, y=10}}
    assert(path.point_count == 2, 'Did not create path with correct number of points')
    assert(path.absolute, 'Path is not absolute')
    assert(path.locations[-1].x == 10, 'Did not add correct points to path')
    path = path + Path{{x=10, y=10}, {x=20, y=20}}
    assert(path.point_count == 3, 'Did not create path with correct number of points')
    assert(path.locations[-1].x == 20, 'Did not add correct points to path')
    path = path + Path{{x=30, y=30}, {x=40, y=40}}
    assert(path.point_count == 5, 'Did not create path with correct number of points')
    assert(path.locations[-1].x == 40, 'Did not add correct points to path')
  end),

  it('can do Path + RelativePath', function() 
    local path = Path{{x=0, y=0}, {x=10, y=10}}
    assert(path.point_count == 2, 'Did not create path with correct number of points')
    assert(path.absolute, 'Path is not absolute')
    assert(path.locations[-1].x == 10, 'Did not add correct points to path')
    path = path + RelativePath{{x=0, y=0}, {x=10, y=10}}
    assert(path.point_count == 3, 'Did not create path with correct number of points')
    assert(path.absolute, 'Path is not absolute')
    assert(path.locations[-1].x == 20, 'Did not add correct points to path')
    path = path + RelativePath{{x=10, y=10}}
    assert(path.point_count == 4, 'Did not create path with correct number of points')
    assert(path.locations[-1].x == 30, 'Did not add correct points to path')
  end),

  it('can do RelativePath + RelativePath', function() 
    local path = RelativePath{{x=0, y=0}, {x=10, y=10}}
    assert(path.point_count == 2, 'Did not create path with correct number of points')
    assert(not path.absolute, 'Path is absolute')
    assert(path.locations[-1].x == 10, 'Did not add correct points to path')
    path = path + RelativePath{{x=0, y=0}, {x=10, y=10}}
    assert(path.point_count == 3, 'Did not create path with correct number of points')
    assert(not path.absolute, 'Path is absolute')
    assert(path.locations[-1].x == 20, 'Did not add correct points to path')
    path = path + RelativePath{{x=10, y=10}}
    assert(path.point_count == 4, 'Did not create path with correct number of points')
    assert(path.locations[-1].x == 30, 'Did not add correct points to path')
  end),

  it('cannot do RelativePath + Path', function() 
    assertRaises('Can only add RelativePath objects to other RelativePath objects', function() 
      local path = RelativePath{{x=0, y=0}, {x=10, y=10}} + Path{{x=0, y=0}, {x=10, y=10}}
    end, 'RelativePath + Path did not raise error')
  end),

  it('can step through path manually', function(touches) 
    local path = Path.linear(Pixel(10, 10), Pixel(100, 100))
    local calls = list()
    local actions = list()
    screen.before_action(function() actions:append('before') end)
    screen.after_action(function() actions:append('after') end)

    for speed in iter{1, 5, 10} do
      path:begin_swipe(2, speed)
      local done, l = false, 1
      while not done do
        done = path:step(2, function() calls:append(1) end)
        assert(len(calls) == math.min(l, 50 / speed - 1), 'Did not increment calls')
        l = l + 1
      end
      assert(len(touches) == 50 / speed + 1, 'Did not touch and move correctly')
      assert(len(calls) == 50 / speed - 1, 'Did not call on_move correct number of times')
      assert(touches[1][1] == 'down', 'Did not swipe in correct order')
      assert(touches[2][1] == 'move', 'Did not swipe in correct order')
      assert(touches[-1][1] == 'up', 'Did not swipe in correct order')
      assert(len(actions) == 0, 'Called action context functions in manual step')
      touches:clear()
      calls:clear()
    end

    screen.before_action_funcs:clear()
    screen.after_action_funcs:clear()
  end),
  
  it('can swipe path', function(touches) 
    local path = Path.linear(Pixel(10, 10), Pixel(100, 100))
    local calls = list()
    local actions = list()
    screen.before_action(function() actions:append('before') end)
    screen.after_action(function() actions:append('after') end)

    for speed in iter{1, 5, 10} do
      path:swipe{speed=speed, on_move=function() calls:append(1) end}
      assert(len(touches) == 50 / speed + 1, 'Did not touch and move correctly')
      assert(len(calls) == 50 / speed - 1, 'Did not call on_move correct number of times')
      assert(touches[1][1] == 'down', 'Did not swipe in correct order')
      assert(touches[2][1] == 'move', 'Did not swipe in correct order')
      assert(touches[-1][1] == 'up', 'Did not swipe in correct order')
      assert(requal(actions, {'before', 'after'}), 'Did not call action context functions')
      touches:clear()
      calls:clear()
      actions:clear()
    end

    screen.before_action_funcs:clear()
    screen.after_action_funcs:clear()
  end),

  it('can create arc', function() 
    local absolute = Path.arc(5, 45, 90, {x=10, y=10})
    local relative = Path.arc(5, 45, 90)
    local relative_origin = Path.arc(5, 45)
    -- TODO assertions about arcs
  end),
  
  it('can create line', function() 
    local absolute = Path.linear({x=50, y=50}, {x=100, y=100})
    local relative = Path.linear({x=50, y=50})
    local relative_neg = Path.linear({x=-50, y=-50})
    assert(absolute.absolute, 'Absolute linear path not absolute')
    assert(not relative.absolute, 'Relative linear path is absolute')
    assert(absolute[1].x == 50, 'Incorrect absolute location')
    assert(relative[1].x == 0, 'Incorrect relative location')
    assert(relative_neg[-1].x == -50, 'Incorrect relative location')
  end)
)


run_tests()
