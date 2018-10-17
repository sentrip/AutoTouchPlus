--- OS & filesystem operations
-- @module system


local function _getType(name) 
  return exe(string.format(
    'if test -f "%s"; then echo "FILE"; elif test -d "%s"; then echo "DIR"; else echo "INVALID"; fi', 
    name, name))
end

--- Get the current working directory
-- @tparam string file (Optional) file name to append to end of path
-- @treturn string path of current working directory
function get_cwd(file)
  return exe('pwd')
end

--- Execute a shell command and return the result
-- @tparam string|table cmd Unix command to execute.
-- String commands are passed directly to the shell.
-- Table commands are concatenated with the space character.
-- So exe({'ls', 'mydir'}), exe{'ls', 'mydir'} and exe('ls mydir') are all equivalent.
-- @tparam boolean split_output if false then returns the entire stdout as a string, otherwise a table of lines
-- @treturn table|string result of command in stdout
function exe(cmd, split_output)
  if is.Nil(split_output) then split_output = true end
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
    return data or ''
  end
end

---- Copy a file or directory
-- @tparam string src source to copy from (file or directory)
-- @tparam string dest desination to copy to (file or directory, but has to be a directory if src is a directory)
-- @tparam boolean overwrite whether to overwrite any existing files/directories 
function fcopy(src, dest, overwrite) 
  if is.Nil(overwrite) then overwrite = true end
  local cmd = list{'cp'}
  if isDir(src) then cmd:append('-R') end
  if not overwrite then cmd:append('-n') end
  cmd:extend{src, dest}
  exe(cmd)
end

---- Find a file or directory
-- @tparam string|table name name of file/directory to search for.
-- If you wish to search for a directory then you must pass a table as name.
-- If a table is passed then it must be of the format {type=name, start=starting_directory},
-- where type is one of f, file, dir or d, and start is an optional value in the table.
-- @tparam string starting_directory directory in which to begin search (can drastically increase speed)
-- @treturn string absolute path if it exists, an empty string otherwise
function find(name, starting_directory) 
  local _type = 'f'
  if is.table(name) then
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
-- @tparam string name path to check
-- @treturn boolean is the path a directory
function isDir(name) return _getType(name) == 'DIR' end

---- Check if a path is a file
-- @tparam string name path to check
-- @treturn boolean is the path a file
function isFile(name) return _getType(name) == 'FILE' end

---- List the contents of a directory
-- @tparam string dirname path of the directory
-- @treturn table sorted table of file names found in dirname
function listdir(dirname) return sorted(exe{'ls', dirname}) end

---- Check if a path exists
-- @tparam string path path to check
-- @treturn boolean does the path exist
function pathExists(path) return _getType(path) ~= 'INVALID' end

---- Join one or more paths
-- @param ... file paths to join
-- @treturn string concatenated path of all names with the correct number of /s
function pathJoin(...) 
  local values
  if is.table(...) then values = ... else values = {...} end
  local s = string.gsub(table.concat(values, '/'), '/+', '/')
  return s
end

---- Read a single line from a file
-- @tparam file|string f file or filename (see @{readLines})
-- @tparam number lineNumber line number to read (starts at 1)
-- @treturn string contents of line at lineNumber
function readLine(f, lineNumber) 
  local lines = readLines(f)
  return lines[lineNumber] 
end 

---- Read all the lines in a file
-- @tparam file|string f file object or file name. If a file object is passed, then it is not closed.
-- @treturn table strings of each line with the newline character removed
function readLines(f) 
  local lines = list()
  local function read(fle) for line in fle:lines() do lines:append(line) end end
  if is.str(f) then with(open(f, 'r'), read) else read(f) end
  if lines[#lines] == '' then lines[#lines] = nil end
  return lines
end

---- Get the size of a file or directory
-- @param name path name to check size of
-- @treturn number size of file/directory at path in bytes
function sizeof(name) 
  local result = exe(string.format('du %s', name))
  local size = 0
  for a in string.gmatch(result, "[0-9]*") do size = num(a); break end 
  return size
end

---- Sleep for a certain amount of seconds (millisecond precision)
-- @tparam number seconds number of seconds to sleep for
function sleep(seconds)
  if seconds <= 0.01 then
    local current = os.clock()
    while os.clock() - current < seconds do end
    return
  end
  local function get_time()
    local f = io.popen('date +%s%N')
    local t = tonumber(f:read())
    f:close()
    return t
  end
  local time_ns = get_time()
  while (get_time() - time_ns) < seconds * 1000000000 do 
    io.popen('sleep 0.001'):close()
  end
end

---- Write a single line to a file
-- @tparam string line data to write to the file
-- @tparam number lineNumber line number at which to write the line
-- @tparam string filename name of file to write to 
function writeLine(line, lineNumber, filename) 
  local lines = readLines(filename)
  lines[lineNumber] = line
  writeLines(lines, filename, 'w')
end 

---- Write multiple lines to a file
-- @tparam table lines strings of each line
-- @tparam string filename name of file to write to
-- @tparam string mode write mode (uses same argument as io.open)
function writeLines(lines, filename, mode) 
  local function write(f) 
    for i, v in pairs(lines) do f:write(v .. '\n') end 
  end
  with(open(filename, mode or 'w'), write) 
end
