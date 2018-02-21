--- OS & filesystem operations
-- @module system


local function _getType(name) 
  return exe(string.format(
    'if test -f "%s"; then echo "FILE"; elif test -d "%s"; then echo "DIR"; else echo "INVALID"; fi', 
    name, name))
end

---- PlaceHolder
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

---- PlaceHolder
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

---- PlaceHolder
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

---- PlaceHolder
-- @param name
function isDir(name) return _getType(name) == 'DIR' end

---- PlaceHolder
-- @param name
function isFile(name) return _getType(name) == 'FILE' end

---- PlaceHolder
-- @param dirname
function listdir(dirname) return sorted(exe{'ls', dirname}) end

---- PlaceHolder
-- @param path
function pathExists(path) return _getType(path) ~= 'INVALID' end

---- PlaceHolder
-- @param ...
function pathJoin(...) 
  local values
  if isTable(...) then values = ... else values = {...} end
  local s = string.gsub(table.concat(values, '/'), '/+', '/')
  return s
  --('/'):join(values):replace('/+', '/') 
end

---- PlaceHolder
-- @param f
-- @param lineNumber
function readLine(f, lineNumber) 
  local lines = readLines(f)
  return lines[lineNumber] 
end 

---- PlaceHolder
-- @param f
function readLines(f) 
  local lines = list()
  local function read(fle) for line in fle:lines() do lines:append(line) end end
  if isStr(f) then with(open(f, 'r'), read) else read(f) end
  if lines[#lines] == '' then lines[#lines] = nil end
  return lines
end

---- PlaceHolder
-- @param name
function sizeof(name) 
  local result = exe(string.format('du %s', name))
  local size = 0
  for a in string.gmatch(result, "[0-9]*") do size = num(a); break end 
  return size
  end

---- PlaceHolder
-- @param line
-- @param lineNumber
-- @param filename
function writeLine(line, lineNumber, filename) 
  local lines = readLines(filename)
  lines[lineNumber] = line
  writeLines(lines, filename, 'w')
end 

---- PlaceHolder
-- @param lines
-- @param filename
-- @param mode
function writeLines(lines, filename, mode) 
  local function write(f) 
    for i, v in pairs(lines) do f:write(v .. '\n') end 
  end
  with(open(filename, mode or 'w'), write) 
end
