-- AutoTouchPlus installation script, simply run to install AutoTouchPlus!

-- TODO: Download from releases instead of from GitHub raw content
-- You can change the version below to download another version if you want.
-----------------------------------------
-- AUTOTOUCHPLUS_VERSION = '0.2.2'
-----------------------------------------

-- local BASE_URL = "https://github.com/sentrip/AutoTouchPlus/releases/download/v"..AUTOTOUCHPLUS_VERSION..'/'
local BASE_URL = "https://raw.githubusercontent.com/sentrip/AutoTouchPlus/master/"


-- Check wget is installed
local _fcheck = io.popen('dpkg-query -W wget')
local wget_not_installed = _fcheck:read('*a'):match('no packages found')
_fcheck:close()
assert(not wget_not_installed, 'wget not installed')


-- Download fresh copy of a file from GitHub
function get(name)
  local pth = string.format('%s/%s', rootDir(), name):gsub('/+', '/')
  local _check = "if test -f "..pth.." ; then rm "..pth.."; fi;"
  local _get = table.concat({"wget", "--no-check-certificate", "-O", pth, BASE_URL..name}, " ")  
  io.popen(_check):close()
  io.popen(_get):close()
end


-- Download AutoTouchPlus.lua and tests.lua - errors if fails
local failed = false
for _, name in pairs{"AutoTouchPlus.lua", "tests.lua"} do
  local s, r = pcall(get, name)
  if not s then 
    failed = true
    alert(r)
  end
end


-- Tests were successful
if not failed then alert("Installation successful!\nNow run tests.lua to check if everything works, and you're ready to go!") end
