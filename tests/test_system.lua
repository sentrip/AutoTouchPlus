

test('system tests', {  
  fcopy = function()
    local function check_lines(fname, expected)
      expected = expected or {'1', '2', '3'}
      for i, v in pairs(readLines(fname)) do 
        assertEqual(v, expected[i], 
          ('fcopy did not correctly copy contents of %s'):format(fname)) 
      end
    end
    
    fcopy('_tmp_tst/t1.txt', '_tmp_tst/t2.txt')
    check_lines('_tmp_tst/t2.txt')
    fcopy('_tmp_tst/t1.txt', '_tmp_tst/t.txt', false)
    check_lines('_tmp_tst/t.txt', {'line1', 'line2', 'line3'})
    fcopy('_tmp_tst/t1.txt', '_tmp_tst/t.txt')
    check_lines('_tmp_tst/t.txt')
    fcopy('_tmp_tst', '_tmp_tst2')
    assertEqual(listdir('_tmp_tst2'), listdir('_tmp_tst'), 
      'fcopy did not correctly copy directory contents')
    check_lines('_tmp_tst/tmp/t1.txt')
    end,
  find = function()
    assertEqual(find('tests.lua'), './tests.lua', 
      'find returned incorrect file path')
    assertEqual(find{dir='_tmp_tst'}, './_tmp_tst', 
      'find returned incorrect directory path')
    end,
  exe = function() 
    local result = set(exe('ls _tmp_tst'))
    assertEqual(result, set{'t1.txt', 't.txt'}, 'ls returned incorrect files')
    assertRequal(exe('echo "1\n2"'), {'1', '2'}, 'Multi line output failed')
    assertEqual(exe('echo "1\n"'), '1', 'Multi line output with single usable failed')
    assertEqual(exe('echo "1\n2"', false), '1\n2', 'Single output failed')
    end,
  isDir = function() 
    assert(isDir('_tmp_tst'), '_tmp_tst not a directory') 
    end,
  isFile = function()
    assert(isFile('_tmp_tst/t.txt'), '_tmp_tst/t.txt not a file')
    end,
  listdir = function()
    local result = listdir('_tmp_tst')
    local expected = {'t.txt', 't1.txt'}
    for i, v in pairs(result) do 
      assertEqual(v, expected[i], 'listdir has incorrect file name') 
    end
    end,
  pathExists = function()
    assert(not pathExists('randompath_sdas'), 'Invalid path exists')
    assert(pathExists('/etc'), '/usr does not exist')
    end,
  readLine = function() 
    local line = readLine('_tmp_tst/t.txt', 2)
    assertEqual(line, 'line2', 'Second line read incorrectly')
    end,
  readLines = function() 
    local expected = {'line1', 'line2', 'line3'}
    local lines = readLines('_tmp_tst/t.txt')
    for i, v in pairs(lines) do 
      assertEqual(v, expected[i], 'line read incorrectly') 
    end
    end,
  sizeof = function()
    local size = sizeof('_tmp_tst/t.txt')
    --Don't know why text files are so drastically different 
    --in size accross linux and various IOS versions
    assert(size >= 4, 'Incorrect file size') 
    end,
  writeLine = function()
    writeLine('5', 2, '_tmp_tst/t1.txt')
    local lines = readLines('_tmp_tst/t1.txt')
    local expected = {'1', '5', '3'}
    for i, v in pairs(lines) do 
      assertEqual(v, expected[i], 'Incorrect line written') 
    end
    end,
  writeLines = function() 
    local expected = {'2', '5', '6'}
    writeLines(expected, '_tmp_tst/t1.txt')
    local lines = readLines('_tmp_tst/t1.txt')
    for i, v in pairs(lines) do 
      assertEqual(v, expected[i], 'Incorrect lines written') 
    end
    end,
  },
  function() 
    local cmd = ''
    if rootDir then cmd = 'cd '..rootDir()..'; ' end
    io.popen(cmd..'mkdir _tmp_tst'):close() 
    io.popen(cmd..'echo "line1\nline2\nline3" > _tmp_tst/t.txt'):close()
    io.popen(cmd..'echo "1\n2\n3" > _tmp_tst/t1.txt'):close()
    end,
  function() 
    local cmd = ''
    if rootDir then cmd = 'cd '..rootDir()..'; ' end
    io.popen(cmd..'rm -r _tmp_tst'):close() 
    if isDir('_tmp_tst2') then io.popen(cmd..'rm -R _tmp_tst2'):close() end
    end)