--- Basic logging utilities
-- @module logging

local _level_str_to_int = {DEBUG=10, INFO=20, WARNING=30, ERROR=40, CRITICAL=50}

---- Callable log object - improved `log` from AutoTouch
-- @usage -- All of the following usages result in the same message:
-- log('message')
-- log('%s', 'message')
-- log('INFO', 'message')
-- log('INFO', '%s', 'message')
-- log.info('message')
-- log.info('%s', 'message')
-- --[INFO    ] message
log = {}
-- @local
log._default_log_func = log or print
---- Default log format
log.default_format = '[%(level)-8s] %(message)s'
---- Default log level - levels: (DEBUG, INFO, WARNING, ERROR, CRITICAL)
log.default_level = 'INFO'
log.handlers = {}
---- @{LogHandler} that logs messages to a file
log.file_handler = FileHandler
---- @{LogHandler} that logs messages to stdout (or to log.txt in AutoTouch)
log.stream_handler = StreamHandler


---- Add a @{LogHandler} that listens for and logs messages
-- @tparam LogHandler handler to add
function log.add_handler(handler) table.insert(log.handlers, handler) end

---- Add a logger that will log messages to stdout (or to log.txt in AutoTouch)
-- @tparam string level log level - one of (DEBUG, INFO, WARNING, ERROR, CRITICAL)
-- @tparam string fmt log format to use for all messages
function log.basic_config(level, fmt) log.add_handler(log.stream_handler{level=level, fmt=fmt}) end

---- Log a DEBUG level message
-- @tparam string s log message
-- @param ... arguments to format string `s`
function log.debug(s, ...) log('DEBUG', s, ...) end

---- Log an INFO level message
-- @tparam string s log message
-- @param ... arguments to format string `s`
function log.info(s, ...) log('INFO', s, ...) end

---- Log a WARNING level message
-- @tparam string s log message
-- @param ... arguments to format string `s`
function log.warning(s, ...) log('WARNING', s, ...) end

---- Log an ERROR level message
-- @tparam string s log message
-- @param ... arguments to format string `s`
function log.error(s, ...) log('ERROR', s, ...) end

---- Log a CRITICAL level message
-- @tparam string s log message
-- @param ... arguments to format string `s`
function log.critical(s, ...) log('CRITICAL', s, ...) end


---- LogHandler object
-- @type LogHandler
LogHandler = class('LogHandler')
function LogHandler:__init(options)
  assert(type(options) == 'table', string.format('Required syntax: %s{...}', getmetatable(self).__name))
  self.fmt = options.fmt or log.default_format
  self.level = options.level or log.default_level
end

--- Filter log message based on level
-- @param level level to check
-- @treturn boolen is level high enough to log
function LogHandler:filter(level) 
  return _level_str_to_int[level] >= _level_str_to_int[self.level]
end

--- Create formatted log message
-- @tparam string level level of message
-- @tparam string s format string of message
-- @param ... (optional) arguments for format string `s`
function LogHandler:format(level, s, ...)  
  local formatted = self.fmt
  local _args = {...} 
  if not ... then _args = {} end
  local msg = string.format(s or '', unpack(_args))
  for _, v in pairs({'level', 'message'}) do
    local reg = '%%%('..v..'%)([^s]*s)'
    local match = formatted:match(reg)
    if match then 
      local inner = ''
      if v == 'level' then inner = level else inner = msg or inner end
      formatted = formatted:gsub(reg, string.format('%'..match, inner))
    end
  end
  return string.format(formatted, unpack({...}) or '')
end

--- Record the log message to an output.
-- This can be overwritten to send log messages anywhere.
-- @tparam string s message to record
function LogHandler:record(s) end


---- StreamHandler - LogHandler for logging to stdout
-- @type StreamHandler
StreamHandler = class('StreamHandler', 'LogHandler')
function StreamHandler:record(s) log._default_log_func(s) end


---- FileHandler - LogHandler for logging to a file
-- @type FileHandler
FileHandler = class('FileHandler', 'LogHandler')
function FileHandler:__init(options)
  LogHandler.__init(self, options)
  self.filename = options[1] or options.file
  assert(self.filename, 'Must provide filename for FileHandler')
  if rootDir then self.filename = pathJoin(rootDir(), self.filename) end
end

function FileHandler:record(s) 
  local _file = io.open(self.filename, 'a')
  _file:write(s..'\n') 
  _file:close()
end


--allows for log('msg') and log.debug('msg') syntax
log = setmetatable(log, {
  __call = function(_, level, s, ...)
    local _args = {...}
    if (not s and #_args == 0) or level:match('%%') then 
      level, s, _args = log.default_level, level, {s}
    end
    for _, h in pairs(log.handlers) do 
      if h:filter(level) then h:record(h:format(level, s, unpack(_args))) end
    end
  end
})
log.stream_handler = StreamHandler
log.file_handler = FileHandler