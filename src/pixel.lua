--- Pixel objects for screen manipulation
-- @module pixel

--Basic colors
BLACK = 0
WHITE = 16777215

---- Pixel object
-- @type Pixel
Pixel = class('Pixel')

function Pixel:__init(x, y, color)
  self.x = x
  self.y = y
  self.expected_color = color or WHITE
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
---

---
Pixel.__getters['color'] = function(self)
  return getColor(self.x, self.y)
end
---

---- Returns a function that checks if the pixel's color has changed
-- @treturn function check whether the color has changed
function Pixel:color_changed()
  local old_color = self.color
  return function() 
    local current_color = self.color
    if current_color ~= old_color then
      old_color = current_color
      return true
    end
    return false
  end
end
---

---- Check if the pixel is in a screen
-- @treturn boolean is the pixel visible on the screen
function Pixel:visible()
  return self.color == self.expected_color
end
---

---- Collection of Pixel objects
-- @type Pixels
Pixels = class('Pixels')

function Pixels:__init(pixels)
  self.pixels = list()
  self.expected_colors = list()
  --table of pixels
  if is(pixels) and getmetatable(pixels[1]) then
    self.pixels = pixels    
    for i, pixel in pairs(pixels) do
      self.expected_colors:append(pixel.color)
    end
  --table of tables {x, y, color}
  else
    for i, t in pairs(pixels) do
      self.pixels:append(Pixel{t[1], t[2], t[3]})
      self.expected_colors:append(t[3] or WHITE)
    end
  end
end

function Pixels:__add(pixels)
  for i, pixel in pairs(pixels) do
    self.pixels:append(pixel)
    self.expected_colors:append(pixel.expected_color)
  end
end

function Pixels:__eq(pixels)
  for i, pixel in pairs(pixels.pixels) do
    if pixel ~= self.pixels[i] then return false end
  end
  return true
end
---

---
Pixels.__getters['positions'] = function(self)
  local positions = list()
  for pixel in iter(self.pixels) do
    positions:append({pixel.x, pixel.y})
  end
  return positions
end
---

---
Pixels.__getters['colors'] = function(self)
  return getColors(self.positions)
end
---

---- Check if all the pixels are in a screen
-- @treturn boolean are all the pixels visible on the screen
function Pixels:visible()
  return requal(getColors(self.positions), self.expected_colors)
end
---

---- Count how many of the pixels are in a screen
-- @treturn number how many pixels are visible on the screen
function Pixels:count()
  local count = 0
  for i, v in pairs(self.colors) do
    if v == self.expected_colors[i] then count = count + 1 end
  end
  return count
end
---

--- Check how many pixels have changed colors comparing to expected number
local function n_colors_changed(pixels, n)
  local old_colors = pixels.colors
  
  return function()
    local count = 0
    local current_colors = pixels.colors
    for i, color in pairs(current_colors) do
      if old_colors[i] ~= color then
        count = count + 1
      end
    end
    
    local result = count >= (n or len(current_colors))
    
    if result then
      old_colors = current_colors
    end
    
    return result
  end
end

---

---- Returns a function that checks if any pixels have changed color
-- @treturn function check whether the colors have changed
function Pixels:any_colors_changed()
  return n_colors_changed(self, 1)
end
---

---- Returns a function that checks if all pixels have changed color
-- @treturn function check whether the colors have changed
function Pixels:all_colors_changed()
  return n_colors_changed(self, len(self.pixels))
end
---

---- Returns a function that checks if n pixels have changed color
-- @treturn function check whether the colors have changed
function Pixels:n_colors_changed(n)
  return n_colors_changed(self, n)
end
---
