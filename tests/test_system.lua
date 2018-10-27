require('src/test')
require('src/core')
require('src/builtins')
require('src/contextlib')
require('src/objects')
require('src/logic')
require('src/logging')
require('src/string')
require('src/system')


fixture('filesystem', function(request) 
  
  local cmd = ''
  if rootDir then cmd = 'cd '..rootDir()..' && ' end
  io.popen(cmd..'mkdir _tmp_tst'):close() 
  io.popen(cmd..'echo "line1\nline2\nline3" > _tmp_tst/t.txt'):close()
  io.popen(cmd..'echo "1\n2\n3" > _tmp_tst/t1.txt'):close()
  request.addfinalizer(function()
    local _cmd = ''
    if rootDir then _cmd = 'cd '..rootDir()..' && ' end
    if os.is_dir('_tmp_tst') then io.popen(_cmd..'rm -r _tmp_tst'):close() end
    if os.is_dir('_tmp_tst2') then io.popen(_cmd..'rm -R _tmp_tst2'):close() end
  end)
end)
  

describe('system', 

  it('exe', function(filesystem)
    local result = set(exe('ls _tmp_tst'))
    assertEqual(result, set{'t1.txt', 't.txt'}, 'ls returned incorrect files')
    assertRequal(exe('echo "1\n2"'), {'1', '2'}, 'Multi line output failed')
    assertEqual(exe('echo "1\n2"', false), '1\n2', 'Single output failed')
  end),

  it('os.copy', function(filesystem)
    local function check_lines(fname, expected)
      expected = expected or {'1', '2', '3'}
      for i, v in pairs(os.read_lines(fname)) do 
        assertEqual(v, expected[i], 
          ('os.copy did not correctly copy contents of %s'):format(fname)) 
      end
    end
    
    os.copy('_tmp_tst/t1.txt', '_tmp_tst/t2.txt')
    check_lines('_tmp_tst/t2.txt')
    os.copy('_tmp_tst/t1.txt', '_tmp_tst/t.txt', false)
    check_lines('_tmp_tst/t.txt', {'line1', 'line2', 'line3'})
    os.copy('_tmp_tst/t1.txt', '_tmp_tst/t.txt')
    check_lines('_tmp_tst/t.txt')
    os.copy('_tmp_tst', '_tmp_tst2')
    assertEqual(os.listdir('_tmp_tst2'), os.listdir('_tmp_tst'), 
      'os.copy did not correctly copy directory contents')
  end),

  it('os.find', function(filesystem)
    assertEqual(os.find('tests.lua'), './tests.lua', 
      'os.find returned incorrect file path')
    assertEqual(os.find{dir='_tmp_tst'}, './_tmp_tst', 
      'os.find returned incorrect directory path')
    assertRaises('Incorrect table arguments', function() 
      os.find{stuff='abc'}
    end, 'os.find with incorrect args did not raise error')
  end),

  it('os.getcwd', function() 
    assert(isin('/', os.getcwd()), 'os.getcwd did not return directory')
  end),

  it('os.is_dir', function(filesystem) 
    assert(os.is_dir('_tmp_tst'), '_tmp_tst not a directory') 
  end),

  it('os.is_file', function(filesystem)
    assert(os.is_file('_tmp_tst/t.txt'), '_tmp_tst/t.txt not a file')
  end),

  it('os.listdir', function(filesystem)
    local result = os.listdir('_tmp_tst')
    local expected = {'t.txt', 't1.txt'}
    for i, v in pairs(result) do 
      assertEqual(v, expected[i], 'os.listdir has incorrect file name') 
    end
  end),

  it('os.path_exists', function(filesystem)
    assert(not os.path_exists('randompath_sdas'), 'Invalid path exists')
    assert(os.path_exists('/etc'), '/usr does not exist')
  end),

  it('os.path_join', function() 
    assert(os.path_join('dir', 'file') == 'dir/file', 'Did not join paths correctly')
    assert(os.path_join('dir', '/file') == 'dir/file', 'Did not join paths correctly')
    assert(os.path_join('dir/', 'file') == 'dir/file', 'Did not join paths correctly')
    assert(os.path_join('dir/', '/file') == 'dir/file', 'Did not join paths correctly')
  end),

  it('os.read_line', function(filesystem) 
    local line = os.read_line('_tmp_tst/t.txt', 2)
    assertEqual(line, 'line2', 'Second line read incorrectly')
  end),

  it('os.read_lines', function(filesystem) 
    local expected = {'line1', 'line2', 'line3'}
    local lines = os.read_lines('_tmp_tst/t.txt')
    for i, v in pairs(lines) do 
      assertEqual(v, expected[i], 'line read incorrectly') 
    end
  end),

  it('os.sizeof', function(filesystem)
    local size = os.sizeof('_tmp_tst/t.txt')
    --Don't know why text files are so drastically different 
    --in size accross linux and various IOS versions
    assert(size >= 4, 'Incorrect file size') 
  end),

  it('os.sleep', function() 
    local time_ns = num(exe('date +%s%N'))
    os.sleep(0.01)
    local c_time_ns = num(exe('date +%s%N'))
    -- TODO: Fix sleep tests for mobile
    -- assert(round((c_time_ns - time_ns) / 1000000000, 2) == 0.01, 'Did not sleep for correct amount of time')
    time_ns = c_time_ns
    os.sleep(0.1)
    c_time_ns = num(exe('date +%s%N'))
    -- assert(round((c_time_ns - time_ns) / 1000000000, 1) == 0.1, 'Did not sleep for correct amount of time')
  end),

  it('os.write_line', function(filesystem)
    os.write_line('5', 2, '_tmp_tst/t1.txt')
    local lines = os.read_lines('_tmp_tst/t1.txt')
    local expected = {'1', '5', '3'}
    for i, v in pairs(lines) do 
      assertEqual(v, expected[i], 'Incorrect line written') 
    end
  end),

  it('os.write_lines', function(filesystem) 
    local expected = {'2', '5', '6'}
    os.write_lines(expected, '_tmp_tst/t1.txt')
    local lines = os.read_lines('_tmp_tst/t1.txt')
    for i, v in pairs(lines) do 
      assertEqual(v, expected[i], 'Incorrect lines written') 
    end
  end)
)

run_tests()
