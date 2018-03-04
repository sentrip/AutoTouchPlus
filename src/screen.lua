--- Screen observation and application navigation helpers for AutoTouch
-- @module screen

--Basic colors
WHITE = 16777215

---- Pixel object
-- @type Pixel
Pixel = class('Pixel')

function Pixel:__init(x, y, color)
  self.x = x
  self.y = y
  color = color or WHITE
  if isType(color, 'table') then
    self.color = rgbToInt(unpack(color))
    self.rgb = color
  else
    self.color = color
    self.rgb = {intToRgb(color)}
  end
end

function Pixel:__add(position)
  self.x = self.x + (position.x or position[1] or 0)
  self.y = self.y + (position.y or position[1] or 0)
end

function Pixel:__sub(position)
  self.x = self.x - (position.x or position[1] or 0)
  self.y = self.y - (position.y or position[1] or 0)
end

function Pixel:__eq(pixel)
  return self.x == pixel.x and self.y == pixel.y and self.color == pixel.color
end

---- Get the absolute x, y location of the pixel in a screen
-- @tparam Screen screen instance to check for pixel
-- @return x, y position of pixel relative to screen 
function Pixel:abs_position(screen)
  local x, y
  if self.x < 0 then x = screen.right + self.x
  else x = screen.x + self.x end
  if self.y < 0 then y = screen.bottom + self.y
  else y = screen.y + self.y end
  return x, y
end

---- Check if the pixel is in a screen
-- @tparam Screen screen instance to check for pixel
-- @treturn boolean is the pixel visible on the screen
function Pixel:in_(screen)
  return getColor(self:abs_position(screen)) == self.color
end


---- Collection of Pixel objects
-- @type Pixels
Pixels = class('Pixels')

function Pixels:__init(pixels)
  self.pixels = list()
  self.colors = list()
  --table of pixels
  if is(pixels) and getmetatable(pixels[1]) then
    self.pixels = pixels    
    for i, pixel in pairs(pixels) do
      self.colors:append(pixel.color)
    end
  --table of tables {x, y, color}
  else
    for i, t in pairs(pixels) do
      self.pixels:append(Pixel{t[1], t[2], t[3]})
      self.colors:append(t[3])
    end
  end
end

function Pixels:__add(pixels)
  for i, pixel in pairs(pixels) do
    self.pixels:append(pixel)
    self.colors:append(pixel.color)
  end
end

function Pixels:__eq(pixels)
  for i, pixel in pairs(pixels.pixels) do
    if pixel ~= self.pixels[i] then return false end
  end
  return true
end

---- Check if all the pixels are in a screen
-- @tparam Screen screen instance to check for pixels
-- @treturn boolean are all the pixels visible on the screen
function Pixels:in_(screen)
  local positions = {}
  for i, pixel in pairs(self.pixels) do 
    positions[#positions + 1] = {pixel:abs_position(screen)}
  end
  return requal(getColors(positions), self.colors)
end


---- Count how many of the pixels are in a screen
-- @tparam Screen screen instance to check for pixels
-- @treturn number how many pixels are visible on the screen
function Pixels:count(screen)
  local positions = {}
  for i, pixel in pairs(self.pixels) do 
    positions[#positions + 1] = {pixel:abs_position(screen)}
  end
  local count = 0
  for i, v in pairs(getColors(positions)) do
    if v == self.colors[i] then count = count + 1 end
  end
  return count
end

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

---- Screen object
-- @type Screen
Screen = class('Screen')

function Screen:__init(width, height, xOffSet, yOffSet)
  if is.Nil(width) then
    self.width, self.height = getScreenResolution()
  else
    self.width = width
  self.height = height
  end
  self.x = xOffSet or 0
  self.y = yOffSet or 0
  self.right = self.x + self.width
  self.bottom = self.y + self.height
  self.check_interval = 50000 --checks every 50ms (0.05s)
  self.mid = {
    left = {self.x, self.bottom / 2},
    right = {self.right, self.bottom / 2},
    top = {self.y, self.right / 2},
    bottom = {self.bottom, self.right / 2}
  }
end

---- Check if the screen contains a pixel/set of pixels
-- @tparam Pixel|Pixels pixel Pixel(s) instance to check position(s) of
-- @treturn boolean does the screen contain the pixel(s)
function Screen:contains(pixel)
  return pixel:in_(self)
end

---- Improved tap function
-- @param x
-- @param y
-- @param times
-- @param interval
-- @treturn Screen screen instance for method chaining
function Screen:tap(x, y, times, interval)
  local pixel
  if isType(x, 'number') then
    pixel = Pixel(x, y)
  else
    pixel, times, interval = x, y, times
  end
  for i=1, times or 1 do
    tap(pixel:abs_position(self))
    if interval then usleep(interval * 10 ^ 6) end
  end
  return self
end

--creates a checker function from a function or pixel
local function create_check(screen, condition)
  if is.func(condition) then
    return condition
  else
    return function() return screen:contains(condition) end
  end
end

---- Tap the screen if a pixel/set of pixels is visible
-- @tparam Pixel|func condition pixel(s) to search for or an argumentless function hat returns a boolean
-- @param ... arguments for @{screen.Screen.tap}
-- @treturn Screen screen instance for method chaining
function Screen:tap_if(condition, ...)
  local check = create_check(self, condition)
  if check() then
    self:tap(... or condition)
  end
  return self
end

---- Tap the screen while a pixel/set of pixels is visible
-- @tparam Pixel|func condition see @{screen.Screen.tap_if}
-- @param ... arguments for @{screen.Screen.tap}
-- @treturn Screen screen instance for method chaining
function Screen:tap_while(condition, ...)
  local check = create_check(self, condition)
  while check() do
    self:tap(... or condition)
    usleep(self.check_interval)
  end
  return self
end

---- Tap the screen until a pixel/set of pixels is visible
-- @tparam Pixel|func condition see @{screen.Screen.tap_if}
-- @param ... arguments for @{screen.Screen.tap}
-- @treturn Screen screen instance for method chaining
function Screen:tap_until(condition, ...)
  local check = create_check(self, condition)
  repeat  
    self:tap(... or condition)
    usleep(self.check_interval)
  until check()
  return self
end

---- Wait until a pixel/set of pixels is visible
-- @tparam Pixel|func condition see @{screen.Screen.tap_if}
-- @treturn Screen screen instance for method chaining
function Screen:wait_for(condition)
  local check = create_check(self, condition)
  repeat
    usleep(self.check_interval)
  until check()
  return self
end

---- Swipe the screen
-- @tparam Pixel|string start pixel at which to start the swipe, or one of 'left, 'right', 'top', 'bottom'
-- @tparam Pixel|string _end pixel at which to end the swipe, or one of 'left, 'right', 'top', 'bottom'
-- @tparam number speed swipe speed (1-10)
-- @treturn Screen screen instance for method chaining
function Screen:swipe(start, _end, speed)
  if is.str(start) then
    assert(self.mid[start], 
      'Incorrect identifier: use one of (left, right, top, bottom)')
    start = self.mid[start]
  end
  
  if is.str(_end) then
    assert(self.mid[_end], 
      'Incorrect identifier: use one of (left, right, top, bottom)')
    _end = self.mid[_end]
  end
  
  local steps = 50 / speed
  local x, y = start[1], start[2]
  local deltaX = (_end[1] - start[1]) / steps
  local deltaY = (_end[2] - start[2]) / steps
  touchDown(2, x, y)
  usleep(16000)
  for i=1, steps do
    x = x + deltaX
    y = y + deltaY
    touchMove(2, x, y)
    usleep(16000)
  end
  touchUp(2, x, y)
  return self
end

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

---- Tree object
-- @type TransitionTree
TransitionTree = class('TransitionTree')

function TransitionTree:__init(name, parent, forward, backward)
  self.name = name or 'root'
  self.parent = parent
  if is.Nil(backward) then self.backward = forward
  else
    self.forward = forward
    self.backward = backward
  end
  self.nodes = {}
end

function TransitionTree:__index(value)
  return rawget(TransitionTree, value) or rawget(self, value) or self.nodes[value]
end

---- Add a node to the tree
-- @param name
-- @param forward
-- @param backward
function TransitionTree:add(name, forward, backward)
  self.nodes[name] = TransitionTree(name, self, forward, backward)
end

---- Get the path from the current node to the root node
function TransitionTree:path_to_root()
  local path = list{self}
  local parent = self.parent
  while Not.Nil(parent) do
    path:append(parent)
    parent = parent.parent
  end
  return path
end

---- Get the path from the current node to the named node
-- @param name
function TransitionTree:path_to(name)
  local q = list()
  for i, v in pairs(self.nodes) do q:append({i, v}) end
  local item
  while len(q) > 0 do
    item = q:pop(1)
    for i, v in pairs(item[2].nodes) do q:append({i, v}) end
    if item[1] == name then return reversed(item[2]:path_to_root()) end
  end
end

---- Least common ancestor of two nodes
-- @param name1
-- @param name2
function TransitionTree:lca(name1, name2)
  local lca = 'root'
  local v1, v2
  local path1, path2 = self:path_to(name1), self:path_to(name2)
  for i=2, math.min(len(path1), len(path2)) do
    v1, v2 = path1[i], path2[i]
    if v1.name == v2.name then lca = v1.name; break end
    if v1.parent ~= v2.parent then break else lca = v1.parent.name end
  end
  return lca 
end

---- Navigate the tree calling forward and backward functions
-- @param start
-- @param _end
function TransitionTree:navigate(start, _end)
  local counting = false
  local lca = self:lca(start, _end)
  local path1, path2 = reversed(self:path_to(start)), self:path_to(_end)
  for i, v in pairs(path1) do 
    if v.name == lca then break end
    v.backward()
  end

  for i, v in pairs(path2) do 
    if counting then v.forward() end
    if v.name == lca then counting = true end
  end
end

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------


Navigator = class('Navigator')
