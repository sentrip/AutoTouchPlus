require('src/test')
require('src/core')
require('src/builtins')
require('src/contextlib')
require('src/itertools')
require('src/logging')
require('src/logic')
require('src/objects')
require('src/pixel')
require('src/path')
require('src/screen')
require('src/string')
require('src/system')


fixture('patched_stdout', function(monkeypatch) 
  log.handlers = {StreamHandler{level='DEBUG'}}
  local lines = list()
  monkeypatch.setattr(log, '_default_log_func', function(s) lines:append(s) end)
  return lines
end)

fixture('file_handler', function(request) 
  local fn = 'log.txt'
  local handler = FileHandler{fn}
  log.handlers = {handler}
  request.addfinalizer(function() 
    local r
    if rootDir then r = os.path_join(rootDir(), fn) else r = fn end
    io.popen('rm '..r):close() 
    log.handlers = {}
  end)
  return handler
end)


describe('logging', 

  it('can log like in AutoTouch', function(patched_stdout) 
    log('test')
    log('%s', 'test')
    log('INFO', 'test')
    log('INFO', '%s', 'test')
    for _, ln in pairs(patched_stdout) do 
      assert(ln == '[INFO    ] test', 'Incorrect formatting for log')
    end
  end),

  it('can log datetime', function(patched_stdout) 
    log.handlers = {StreamHandler{level='INFO', fmt='%(datetime)s'}}
    log('')
    assert(patched_stdout[1]:match('%d%d/%d%d/%d%d %d%d:%d%d:%d%d'), 'Did not log datetime')
  end),

  it('can log with multiple levels', function(patched_stdout)   
    log.debug('test')
    assert(patched_stdout[-1] == '[DEBUG   ] test', 'Incorrect formatting for log.debug')
    log.info('test')
    assert(patched_stdout[-1] == '[INFO    ] test', 'Incorrect formatting for log.info')
    log.warning('test')
    assert(patched_stdout[-1] == '[WARNING ] test', 'Incorrect formatting for log.warning')
    log.error('test')
    assert(patched_stdout[-1] == '[ERROR   ] test', 'Incorrect formatting for log.error')
    log.critical('test')
    assert(patched_stdout[-1] == '[CRITICAL] test', 'Incorrect formatting for log.critical')
  end),

  it('can filter logs based on levels', function(patched_stdout) 
    log.handlers = {StreamHandler{level='ERROR'}}
    log.debug('test')
    assert(len(patched_stdout) == 0, 'Did not filter log based on level')
    log.warning('test')
    assert(len(patched_stdout) == 0, 'Did not filter log based on level')
    log.error('test')
    assert(len(patched_stdout) == 1, 'Filtered log based on incorrect level')
  end),

  it('can log to multiple handlers', function(patched_stdout) 
    log.handlers = {StreamHandler{level='DEBUG'}, StreamHandler{level='INFO'}}
    log.debug('test')
    assert(len(patched_stdout) == 1, 'Did not filter logs based on level correctly for multiple handlers')
    patched_stdout:clear()
    log.info('test')
    assert(len(patched_stdout) == 2, 'Did not send logs to all handlers')
  end),

  it('can log to a file', function(file_handler) 
    log.info('test')
    assert(requal(os.read_lines('log.txt'), {'[INFO    ] test'}), 'FileHandler did not write to file')
  end),

  it('can rotate logs based on file size', function(file_handler) 
    file_handler.max_size = 40
    for i=1, 6 do log.info('test%d', i) end
    assert(requal(os.read_lines('log.txt'), {'[INFO    ] test4', '[INFO    ] test5', '[INFO    ] test6'}), 'FileHandler did not write to file')
  end)
)


run_tests()
