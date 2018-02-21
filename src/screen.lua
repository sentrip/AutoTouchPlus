--- Screen observation and application navigation helpers for AutoTouch
-- @module screen

---- Pixel object
-- @type Pixel
Pixel = class('Pixel')

function Pixel:__init(x, y, color)
  self.x = x
  self.y = y
  if isType(color, 'table') then
    self.color = rgbToInt(unpack_(color))
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

---- PlaceHolder
-- @param screen
function Pixel:abs_position(screen)
  local x, y
  if self.x < 0 then x = screen.right + self.x
  else x = screen.x + self.x end
  if self.y < 0 then y = screen.bottom + self.y
  else y = screen.y + self.y end
  return x, y
end

---- PlaceHolder
-- @param screen
function Pixel:in_(screen)
  return getColor(self:abs_position(screen)) == self.color
end


---- Collection of Pixel objects
-- @type Pixels
Pixels = class('Pixels')

function Pixels:__init(pixels)
  self.pixels = pixels or list()
  self.colors = list()
  for i, pixel in pairs(pixels) do
    self.colors:append(pixel.color)
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

---- PlaceHolder
-- @param screen
function Pixels:in_(screen)
  local positions = {}
  for i, pixel in pairs(self.pixels) do 
    positions[#positions + 1] = {pixel:abs_position(screen)}
  end
  return requal(getColors(positions), self.colors)
end


---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

---- Screen object
-- @type Screen
Screen = class('Screen')

function Screen:__init(width, height, xOffSet, yOffSet)
  self.width = width
  self.height = height
  self.x = xOffSet or 0
  self.y = yOffSet or 0
  self.right = self.x + self.width
  self.bottom = self.y + self.height
  self.check_interval = 50000 --checks every 50ms (0.05s)
end

---- PlaceHolder
-- @param pixel
function Screen:contains(pixel)
  return pixel:in_(self)
end

---- PlaceHolder
-- @param x
-- @param y
-- @param times
-- @param interval
function Screen:tap(x, y, times, interval)
  local pixel
  if isType(x, 'number') then
    pixel = Pixel(x, y)
  else
    pixel, times, interval = x, y, times
  end
  for i=1, times or 1 do
    tap(pixel.x, pixel.y)
    if interval then usleep(interval * 10 ^ 6) end
  end
  return self
end

---- PlaceHolder
-- @param pixel pixel to search for
-- @param ... arguments for @{screen.Screen.tap}
function Screen:tap_if(pixel, ...)
  if self:contains(pixel) then
    self:tap(...)
  end
  return self
end

---- PlaceHolder
-- @param pixel pixel(s) to search for
-- @param ... arguments for @{screen.Screen.tap}
function Screen:tap_while(pixel, ...)
  while self:contains(pixel) do
    self:tap(...)
    usleep(self.check_interval)
  end
  return self
end

---- PlaceHolder
-- @param pixel pixel(s) to search for
-- @param ... arguments for @{screen.Screen.tap}
function Screen:tap_until(pixel, ...)
  repeat  
    self:tap(...)
    usleep(self.check_interval)
  until self:contains(pixel)
  return self
end

---- PlaceHolder
-- @param pixel
function Screen:swipe()
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
  if isNil(backward) then self.backward = forward
  else
    self.forward = forward
    self.backward = backward
  end
  self.nodes = {}
end

function TransitionTree:__index(value)
  return rawget(TransitionTree, value) or rawget(self, value) or self.nodes[value]
end

---- Placeholder
-- @param name
-- @param forward
-- @param backward
function TransitionTree:add(name, forward, backward)
  self.nodes[name] = TransitionTree(name, self, forward, backward)
end

---- Placeholder
function TransitionTree:path_to_root()
  local path = list{self}
  local parent = self.parent
  while isNotNil(parent) do
    path:append(parent)
    parent = parent.parent
  end
  return path
end

---- Placeholder
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

---- Placeholder
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

---- Placeholder
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
