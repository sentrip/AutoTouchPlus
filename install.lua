-- AutoTouchPlus installation script, simply run to install AutoTouchPlus!
AUTOTOUCHPLUS_VERSION = '0.1.2'
local _fcheck = io.popen('dpkg-query -W wget')
local wget_not_installed = _fcheck:read('*a'):match('no packages found')
_fcheck:close()
assert(not wget_not_installed, 'wget not installed')
local BASE_URL = "https://github.com/sentrip/AutoTouchPlus/releases/download/v"..AUTOTOUCHPLUS_VERSION..'/'

function get(name)
  local pth = string.format('%s/%s', rootDir(), name):gsub('/+', '/')
  local _check = "if test -f "..pth.." ; then rm "..pth.."; fi;"
  local _get = table.concat({"wget", "--no-check-certificate", BASE_URL..name, "-O", pth}, " ")
  io.popen(_check):close()
  io.popen(_get):close()
end


local failed = false
for _, name in pairs{"AutoTouchPlus.lua", "tests.lua"} do
  local s, r = pcall(get, name)
  if not s then 
    failed = true
    alert(r)
  end
end

if not failed then alert("Installation successful!\nNow run tests.lua to check if everything works, and you're ready to go!") end
