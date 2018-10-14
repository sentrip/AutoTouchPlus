require('src/test')
require('src/core')
require('src/contextlib')
require('src/objects')
require('src/logic')
require('src/string')
require('src/system')


fixture('filesystem', function(request) 
  local cmd = ''
  if rootDir then cmd = 'cd '..rootDir()..'; ' end
  io.popen(cmd..'mkdir _tmp_tst'):close() 
  io.popen(cmd..'echo "line1\nline2\nline3" > _tmp_tst/t.txt'):close()
  io.popen(cmd..'echo "1\n2\n3" > _tmp_tst/t1.txt'):close()
  request.addfinalizer(function()
    local _cmd = ''
    if rootDir then _cmd = 'cd '..rootDir()..'; ' end
    io.popen(_cmd..'rm -r _tmp_tst'):close() 
    if isDir('_tmp_tst2') then io.popen(_cmd..'rm -R _tmp_tst2'):close() end
  end)
end)
  

describe('system', 
  it('fcopy', function(filesystem)
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
    end),
  it('find', function(filesystem)
    assertEqual(find('tests.lua'), './tests.lua', 
      'find returned incorrect file path')
    assertEqual(find{dir='_tmp_tst'}, './_tmp_tst', 
      'find returned incorrect directory path')
    end),
  it('exe', function(filesystem) 
    local result = set(exe('ls _tmp_tst'))
    assertEqual(result, set{'t1.txt', 't.txt'}, 'ls returned incorrect files')
    assertRequal(exe('echo "1\n2"'), {'1', '2'}, 'Multi line output failed')
    assertEqual(exe('echo "1\n"'), '1', 'Multi line output with single usable failed')
    assertEqual(exe('echo "1\n2"', false), '1\n2', 'Single output failed')
    end),
  it('isDir', function(filesystem) 
    assert(isDir('_tmp_tst'), '_tmp_tst not a directory') 
    end),
  it('isFile', function(filesystem)
    assert(isFile('_tmp_tst/t.txt'), '_tmp_tst/t.txt not a file')
    end),
  it('listdir', function(filesystem)
    local result = listdir('_tmp_tst')
    local expected = {'t.txt', 't1.txt'}
    for i, v in pairs(result) do 
      assertEqual(v, expected[i], 'listdir has incorrect file name') 
    end
    end),
  it('pathExists', function(filesystem)
    assert(not pathExists('randompath_sdas'), 'Invalid path exists')
    assert(pathExists('/etc'), '/usr does not exist')
    end),
  it('readLine', function(filesystem) 
    local line = readLine('_tmp_tst/t.txt', 2)
    assertEqual(line, 'line2', 'Second line read incorrectly')
    end),
  it('readLines', function(filesystem) 
    local expected = {'line1', 'line2', 'line3'}
    local lines = readLines('_tmp_tst/t.txt')
    for i, v in pairs(lines) do 
      assertEqual(v, expected[i], 'line read incorrectly') 
    end
    end),
  it('sizeof', function(filesystem)
    local size = sizeof('_tmp_tst/t.txt')
    --Don't know why text files are so drastically different 
    --in size accross linux and various IOS versions
    assert(size >= 4, 'Incorrect file size') 
    end),
  it('writeLine', function(filesystem)
    writeLine('5', 2, '_tmp_tst/t1.txt')
    local lines = readLines('_tmp_tst/t1.txt')
    local expected = {'1', '5', '3'}
    for i, v in pairs(lines) do 
      assertEqual(v, expected[i], 'Incorrect line written') 
    end
    end),
  it('writeLines', function(filesystem) 
    local expected = {'2', '5', '6'}
    writeLines(expected, '_tmp_tst/t1.txt')
    local lines = readLines('_tmp_tst/t1.txt')
    for i, v in pairs(lines) do 
      assertEqual(v, expected[i], 'Incorrect lines written') 
    end
    end)
)

run_tests()
