-- AutoTouchPlus installation script, simply run to install AutoTouchPlus!

local base_url = "https://raw.githubusercontent.com/sentrip/AutoTouchPlus/master/"

function get(name)
  local pth = rootDir()..name
  local url = base_url..name
  local _check = "if test -f "..pth.." ; then rm "..pth.."; fi;"
  local _get = table.concat({"wget", "--no-check-certificate", url, "-O", pth}, " ")
  os.execute(_check)
  assert(os.execute(_get), "Failed to get "..name)
end

local modules = {
"AutoTouchPlus.lua",
"tests.lua"
}

local s, r
local failed = false
for i, name in pairs(modules) do
  s, r = pcall(get, name)
  if not s then 
    failed = true
    alert(r)
  end
end

if not failed then alert("Installation successful!\nNow run tests.lua to check if everything works, and you're ready to go!") end






