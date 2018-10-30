-- AutoTouchPlus installation script, simply run to install AutoTouchPlus!

-- TODO: Download from releases instead of from GitHub raw content
-- You can change the version below to download another version if you want.
-----------------------------------------
-- AUTOTOUCHPLUS_VERSION = '0.2.3'
-----------------------------------------

-- local BASE_URL = "https://github.com/sentrip/AutoTouchPlus/releases/download/v"..AUTOTOUCHPLUS_VERSION..'/'
local BASE_URL = "https://raw.githubusercontent.com/sentrip/AutoTouchPlus/master/"


-- Check that cURL is installed
local _fcheck = io.popen('dpkg-query -W curl')
local curl_not_installed = _fcheck:read('*a') == ''
_fcheck:close()
assert(not curl_not_installed, 'cURL required to install AutoTouchPlus (install cURL in Cydia)')


-- Download fresh copy of a file from GitHub
function get(name)
  local pth = string.format('%s/%s', rootDir(), name):gsub('/+', '/')
  io.popen("if test -f "..pth.." ; then rm "..pth.."; fi;"):close()
  io.popen(table.concat({"curl", "-sk", "-o", pth, BASE_URL..name}, " ")):close()
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


-- Install was successful
if not failed then alert("Installation successful!\nNow run tests.lua to check if everything works, and you're ready to go!") end
