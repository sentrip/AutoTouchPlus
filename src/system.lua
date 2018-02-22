--- OS & filesystem operations
-- @module system


local function _getType(name) 
  return exe(string.format(
    'if test -f "%s"; then echo "FILE"; elif test -d "%s"; then echo "DIR"; else echo "INVALID"; fi', 
    name, name))
end

---- Execute a shell command and return the result
-- @param cmd
-- @param split_output
function exe(cmd, split_output)
  if isNil(split_output) then split_output = true end
  if isNotType(cmd, 'string') then cmd = table.concat(cmd, ' ') end
  if rootDir then cmd = 'cd '..rootDir()..'; '..cmd end
  local f = assert(io.popen(cmd, 'r'))
  local data = readLines(f)
  local success, status, code = f:close()
  if split_output then
    if #data == 1 then data = data[1] end
  else
    data = table.concat(data, '\n')
  end
  if code ~= 0 then
    return data, status, code
  else
    return data
  end
end

---- Copy a file or directory
-- @param src
-- @param dest
-- @param overwrite
function fcopy(src, dest, overwrite) 
  if isNil(overwrite) then overwrite = true end
  local cmd = list{'cp'}
  if isDir(src) then cmd:append('-R') end
  if not overwrite then cmd:append('-n') end
  cmd:extend{src, dest}
  exe(cmd)
end

---- Find a file or directory
-- @param name
-- @param starting_directory
function find(name, starting_directory) 
  local _type = 'f'
  if isTable(name) then
    starting_directory = name.start
    if name.file or name.f then 
      name = name.file or name.f
      _type = 'f'
    elseif name.dir or name.d then 
      name = name.dir or name.d
      _type = 'd'
    else 
      error('Incorrect table arguments ("file"/"f" or "dir"/"d" or "start")') 
    end 
  end
  return exe({'find', starting_directory or '.', '-type', _type, '-name', name})
  end

---- Check if a path is a directory
-- @param name
function isDir(name) return _getType(name) == 'DIR' end

---- Check if a path is a file
-- @param name
function isFile(name) return _getType(name) == 'FILE' end

---- List the contents of a directory
-- @param dirname
function listdir(dirname) return sorted(exe{'ls', dirname}) end

---- Check if a path exists
-- @param path
function pathExists(path) return _getType(path) ~= 'INVALID' end

---- Join one or more paths
-- @param ...
function pathJoin(...) 
  local values
  if isTable(...) then values = ... else values = {...} end
  local s = string.gsub(table.concat(values, '/'), '/+', '/')
  return s
  --('/'):join(values):replace('/+', '/') 
end

---- Read a single line from a file
-- @param f
-- @param lineNumber
function readLine(f, lineNumber) 
  local lines = readLines(f)
  return lines[lineNumber] 
end 

---- Read all the lines in a file
-- @param f
function readLines(f) 
  local lines = list()
  local function read(fle) for line in fle:lines() do lines:append(line) end end
  if isStr(f) then with(open(f, 'r'), read) else read(f) end
  if lines[#lines] == '' then lines[#lines] = nil end
  return lines
end

---- Get size in bytes of file or directory
-- @param name
function sizeof(name) 
  local result = exe(string.format('du %s', name))
  local size = 0
  for a in string.gmatch(result, "[0-9]*") do size = num(a); break end 
  return size
  end

---- Write a single line to a file
-- @param line
-- @param lineNumber
-- @param filename
function writeLine(line, lineNumber, filename) 
  local lines = readLines(filename)
  lines[lineNumber] = line
  writeLines(lines, filename, 'w')
end 

---- Write multiple lines to a file
-- @param lines
-- @param filename
-- @param mode
function writeLines(lines, filename, mode) 
  local function write(f) 
    for i, v in pairs(lines) do f:write(v .. '\n') end 
  end
  with(open(filename, mode or 'w'), write) 
end
