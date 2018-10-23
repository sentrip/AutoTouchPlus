-- AutoTouchPlus installation script, simply run to install AutoTouchPlus!

local BASE_URL = "https://raw.githubusercontent.com/sentrip/AutoTouchPlus/master/"


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
