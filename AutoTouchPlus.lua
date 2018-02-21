---- AutoTouchPlus stuff and things.
-- @module AutoTouchPlus
-- @author Djordje Pepic
-- @license Apache 2.0
-- @copyright Djordje Pepic 2018
-- @usage require("AutoTouchPlus")
require("src/argcheck")
require("src/core")
require("src/contextlib")
require("src/json")
require("src/logic")
require("src/objects")
require("src/requests")
require("src/screen")
require("src/string")
require("src/system")
require("src/test") 
--check if wget is installed
assert(is(exe('dpkg-query -W wget')), 'wget not installed')

--Global variable patching
abs = math.abs
local _execute = os.execute
os.execute = function(s) 
  if rootDir then s = 'cd '..rootDir()..'; '..s end
  return _execute(s)
end

--Some useful exceptions
AssertionError = Exception('AssertionError')
IOError = Exception('IOError')
KeyError = Exception('KeyError')
OSError = Exception('OSError')
TypeError = Exception('TypeError')
ValueError = Exception('ValueError')

--argcheck wrapping
