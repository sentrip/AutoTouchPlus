--- OS & filesystem operations
-- @module system


local function _getType(name) 
  return exe(string.format(
    'if test -f "%s"; then echo "FILE"; elif test -d "%s"; then echo "DIR"; else echo "INVALID"; fi', 
    name, name), true, true)
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
-- @tparam boolean suppress_log supress logging of executed command
-- @treturn table|string result of command in stdout
function exe(cmd, split_output, suppress_log)
  if is.Nil(split_output) then split_output = true end
  if isNotType(cmd, 'string') then cmd = table.concat(cmd, ' ') end
  if not suppress_log then log.debug('Executing command: '..cmd:gsub('%%', '\\')) end
  if rootDir then cmd = 'cd '..rootDir()..' && '..cmd end
  
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
-- @tparam boolean prepend_rootDir should rootDir() be prepended to file name
function fcopy(src, dest, overwrite, prepend_rootDir) 
  if is.Nil(overwrite) then overwrite = true end
  log.debug('Copying files from %s to %s', src, dest)
  local cmd = list{'cp'}
  if isDir(src) then cmd:append('-R') end
  if not overwrite then cmd:append('-n') end
  if prepend_rootDir ~= false and rootDir then 
    src = pathJoin(rootDir(), src) 
    dest = pathJoin(rootDir(), dest) 
  end
  cmd:extend{src, dest}
  exe(cmd, true, true)
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
-- @tparam boolean prepend_rootDir should rootDir() be prepended to file name
-- @treturn string contents of line at lineNumber
function readLine(f, lineNumber, prepend_rootDir) 
  local lines = readLines(f, prepend_rootDir)
  return lines[lineNumber] 
end 

---- Read all the lines in a file
-- @tparam file|string f file object or file name. If a file object is passed, then it is not closed.
-- @tparam boolean prepend_rootDir should rootDir() be prepended to file name
-- @treturn table strings of each line with the newline character removed
function readLines(f, prepend_rootDir) 
  local lines = list()
  local is_file = is.file(f)
  if not is_file then 
    log.debug('Opening file: %s', f)
    if rootDir and prepend_rootDir ~= false then f = pathJoin(rootDir(), f) end
    f = assert(io.open(f, 'r')) 
  end
  log.debug('Reading lines: %s', f)
  for line in f:lines() do lines:append(line) end 
  if not is_file then assert(f:close()) end
  return lines
end

---- Get the size of a file or directory
-- @param name path name to check size of
-- @tparam boolean prepend_rootDir should rootDir() be prepended to file name
-- @treturn number size of file/directory at path in bytes
function sizeof(name, prepend_rootDir) 
  if rootDir and prepend_rootDir ~= false then name = pathJoin(rootDir(), name) end
  local f = assert(io.open(name))
  local size = tonumber(f:seek('end'))
  f:close()
  return size
end

---- Sleep for a certain amount of seconds (millisecond precision)
-- @tparam number seconds number of seconds to sleep for
function sleep(seconds)
  log.debug('Sleeping for %.1fs', seconds)
  if seconds <= 0.01 then
    local current = os.clock()
    while os.clock() - current < seconds do end
    return
  end
  local time_ns = os.time()
  while (os.time() - time_ns) < seconds do 
    io.popen('sleep 0.001'):close()
  end
end

---- Write a single line to a file
-- @tparam string line data to write to the file
-- @tparam number lineNumber line number at which to write the line
-- @tparam string filename name of file to write to 
-- @tparam boolean prepend_rootDir should rootDir() be prepended to file name
function writeLine(line, lineNumber, filename, prepend_rootDir) 
  local lines = readLines(filename, prepend_rootDir)
  lines[lineNumber] = line
  writeLines(lines, filename, 'w', prepend_rootDir)
end 

---- Write multiple lines to a file
-- @tparam table lines strings of each line
-- @tparam string filename name of file to write to
-- @tparam string mode write mode (uses same argument as io.open)
-- @tparam boolean prepend_rootDir should rootDir() be prepended to file name
function writeLines(lines, filename, mode, prepend_rootDir) 
  log.debug('Writing lines: %s', filename)
  if rootDir and prepend_rootDir ~= false then filename = pathJoin(rootDir(), filename) end
  local f = assert(io.open(filename, mode or 'w'))
  for i, v in pairs(lines) do f:write(v .. '\n') end 
  assert(f:close())
end


-- @local
function os.time()
  local f = io.popen('date +%s%N')
  local t = tonumber(f:read()) / 1000000000
  f:close()
  return t
end
