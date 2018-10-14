require('src/test')
require('src/core')
require('src/contextlib')
require('src/objects')
require('src/string')
require('src/system')


fixture('temp_dir', function(monkeypatch, request) 
  -- local l = {}
  -- local _open = io.open
  io.popen('mkdir _tmp_tst'):close()
  -- monkeypatch.setattr(io, 'open', function(...) 
  --   local f = _open(...)
  --   table.insert(l, f)
  --   return f
  -- end)
  request.addfinalizer(function() io.popen('rm -R _tmp_tst'):close() end)
  return l
end)


describe('contextlib',
  it('Exception', function()
    --local Ex = Exception('Ex')
    --local x, y = tostring(Ex), tostring(Ex())
    --local s = ''
    --for i, v in pairs(x) do 
    --  if y[i] ~= v then s = s..v end
    --end
    --print(x, y)
    --print(s)
    --assertEqual(tostring(Ex), tostring(Ex()),  
    --  'Exceptions return different messages')
    --local _, e1 = pcall(error, tostring(Ex))
    --local _, e2 = pcall(error, tostring(Ex()))
    --assertRequal(e1, e2, 'Exceptions return different messages')
    end),
  it('try', function()
    local result = try(function() return 1 end)
    assertEqual(result, 1, 'try did not return function result')
    result = try(function() error() end, function() end)
    assertEqual(result, nil, 'Failing try did not return nil')
    local l = list()
    result = try(
      function() l:append(1) error() end, 
      function() l:append(2) end, 
      function() l:append(3) end
      )
    assertEqual(result, nil, 'Failing try did not return nil')
    assertEqual(l, list{1,2,3}, 
      'Incorrect execution order for try, except, finally')
    end),
  it('except', function()
    local l = list()
    local x
    assertEqual(except()('err'), nil, 'Empty except returned exception')
    assertEqual(except(function(err) return err end)('err'), 'err', 
      'Return exception except did not return exception')
    x = except(
        '.*',
        function(err) l:append(err) end
        )('err')
    assertEqual(l[-1], 'err', 'Catch all except did not append error')
    assertEqual(x, nil, 'Caught exception returned error')
    x = except(
        'err',
        function(err) l:append(err) end
        )('err')
    assertEqual(l[-1], 'err', 'Catch err except did not return error')
    assertEqual(x, nil, 'Caught exception returned error')
    x = except(
        {'err'},
        function(err) l:append(err) end
        )('err')
    assertEqual(l[-1], 'err', 'Catch {err} except did not return error')
    assertEqual(x, nil, 'Caught exception returned error')
    x = except(
        'arbitrary',
        function(err) l:append(err) end
        )('errortastic')
    assertEqual(l[-1], 'err', 'Catch arbitrary except returned error')
    assertEqual(x, 'errortastic', 'Uncaught exception did not return error')
    local Ex = Exception('Ex')
    local e = Ex('err1')
    x = except(
        Ex,
        function(err) l:append(tostring(err):split('\n')[1]) end
        )(e)
    assertEqual(l[-1], '<Ex> err1', 'Did not catch Exception')
    assertEqual(x, nil, 'Caught Exception returned error')
    local e = Ex('err2')
    x = except(
        'arbitrary',
        function(err) l:append(tostring(err):split('\n')[1]) end
        )(e)
    assertEqual(l[-1], '<Ex> err1', 'Did not catch Exception')
    assertEqual(x, e, 'Caught Exception returned error')
    end),
  it('try_except', function()
    local Ex = Exception('Ex')
    local e = Ex('err1')
    local exFail = function() error(e) end
    local l = list()
    --successful try
    local result = try(
      exFail,
      except()
    )
    assertEqual(result, nil, 'TryExceptPass did not return nil')
    result = try(
      exFail,
      except(Ex)
    )
    assertEqual(result, nil, 'Caught exception did not return nil')
    result = try(
      exFail,
      except('.*', function(e) l:append(e) end)
    )
    assertEqual(result, nil, 'Caught exception did not return nil')
    assertEqual(l[-1], e, 'Catch function did not execute')
    result = try(
      exFail,
      except(Ex, function(e) l:append('a') end)
    )
    assertEqual(result, nil, 'Caught exception did not return nil')
    assertEqual(l[-1], 'a', 'Catch function did not execute')
    --failing try
    assertRaises(Ex, function() 
        try(
          exFail,
          except('sdfsdfsdf')
        )
      end, 'Uncaught exception did not raise')
    assertRaises(Ex, function() 
        try(
          exFail,
          except(Exception('other'))
        )
      end, 'Uncaught exception did not raise')
    assertRaises(Ex, function() 
        try(
          exFail,
          except({Exception('other'), Exception('other2')})
        )
      end, 'Uncaught exception did not raise')
    assertRaises(Ex, function() 
        try(
          exFail,
          except({'asdsdf', 'sfsdfsdf'})
        )
      end, 'Uncaught exception did not raise')
    assertRaises(Ex, function() 
        try(
          exFail,
          except({Exception('other'), Exception('other2')})
        )
      end, 'Uncaught exception did not raise')
   end),
  it('try_except_nested', function()
    local Ex = Exception('Ex')
    local Ex2 = Exception('Xe2')
    local e = Ex('err1')
    local e2 = Ex2('err1')
    local l = list()
    result = try(
      function() error(e) end,
      except(Ex, function() 
          try(
            function() error(e2) end,
            except(function(err) l:append(err) end)
            )
          end)
    )
    assertEqual(result, nil, 'Caught exception did not return nil')
    assertEqual(l[-1], e2, 'Caught exception returned incorrect error')
    assertRaises(Ex2, function() 
        try(
          function() error(e) end,
          except(Ex, function() 
              try(
                function() error(e2) end,
                except(Ex, function(err) l:append('a') end)
              )
            end)
          )
      end, 'Uncaught exception did not raise')
    assertEqual(l[-1], e2, 'Caught exception returned incorrect error')
    end),
  it('ContextManager', function()
    local l = list()
    local Q = class('Q', ContextManager)
    function Q:__enter()
      l:append(1)
      return 2
    end
    function Q:__exit(_type, value)
      ContextManager.__exit(self, _type, value)
      l:append(3)
    end
    with(Q(), function(v) l:append(v) end)
    assertEqual(l, list{1,2,3}, 'with ContextManager: incorrect execution order')
    end),
  it('contextmanager', function()
    local l = list()
    local q = contextmanager(function(a) 
        l:append(1)
        yield(a)
        l:append(3)
        end)
    with(q(2), function(v) l:append(v) end)
    assertEqual(l, list{1,2,3}, 'with contextmanager: incorrect execution order')
    end),
  it('open', function(temp_dir)
    local fle
    with(open('_tmp_tst/t.txt', 'w'), function(f) fle = f; f:write('hello') end)
    assert(type(fle == 'userdata'), 'with open did not open a file')
    assertRaises(
      'attempt to use a closed file',  
      function() fle:read() end, 
      'with open did not close file after operation'
    )
    assert(isFile('_tmp_tst/t.txt'), 'open did not create file')
    assertEqual(readLines('_tmp_tst/t.txt'), list{'hello'}, 
      'with open did not write to file')
    end),
  it('suppress', function()
    assertEqual(with(suppress(), function() error(ValueError) end), nil,
      'Empty suppress raised error')
    assertEqual(with(suppress('.*'), function() error(ValueError) end), nil,
      'All suppress returned error')
    assertEqual(with(suppress(ValueError), function() error(ValueError) end), nil,
      'ValueError suppress returned error')
    assertRaises(ValueError, function()
        with(suppress(AssertionError), function() error(ValueError) end) 
      end, 'AssertionError suppress did not return error')
    end)
)

run_tests()
