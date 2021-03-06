--- Pixel objects for screen watching
-- @module pixel

--- Basic colors
colors = {
  aqua    = 65535,    -- 65535
  black   = 0,        -- 0
  blue    = 255,      -- 255
  fuchsia = 16711935, -- 16711935
  gray    = 8421504,  -- 8421504
  green   = 32768,    -- 32768
  lime    = 65280,    -- 65280
  maroon  = 8388608,  -- 8388608
  navy    = 128,      -- 128
  olive   = 8421376,  -- 8421376
  orange  = 16753920, -- 16753920
  purple  = 8388736,  -- 8388736
  red     = 16711680, -- 16711680
  silver  = 12632256, -- 12632256
  teal    = 32896,    -- 32896
  yellow  = 16776960, -- 16776960
  white   = 16777215  -- 16777215
}



---- Pixel object
-- @type Pixel
Pixel = class('Pixel')

--- Create a Pixel object
-- @int x x-position of pixel
-- @int y y-position of pixel
-- @int color expected color of pixel (default @{colors}.white)
-- @see core.class
function Pixel:__init(x, y, color)
  self.x = x
  self.y = y
  self.expected_color = color or colors.white
end

function Pixel:__add(position)
  local x = self.x + (position.x or position[1] or 0)
  local y = self.y + (position.y or position[2] or 0)
  return Pixel(x, y, self.expected_color)
end

function Pixel:__sub(position)
  local x = self.x - (position.x or position[1] or 0)
  local y = self.y - (position.y or position[2] or 0)
  return Pixel(x, y, self.expected_color)
end

function Pixel:__eq(pixel)
  return self.x == pixel.x and self.y == pixel.y and self.expected_color == pixel.expected_color
end

function Pixel:__hash()
  return self.x * 1000000000000 + self.y * 100000000 + self.expected_color
end

function Pixel:__tostring()
  return string.format('<Pixel(%d, %d)>', self.x, self.y)
end

---
property(Pixel, 'color', function(self)
  return getColor(self.x, self.y)
end)

---- Returns a function that checks if the pixel's color has changed
-- @treturn func check whether the color has changed
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

---- Check if the pixel is in a screen
-- @treturn boolean is the pixel visible on the screen
function Pixel:visible()
  return self.color == self.expected_color
end



---- Collection of Pixel objects
-- @type Pixels
Pixels = class('Pixels')

--- Create a Pixels object
-- @list pixels iterable of @{Pixel} objects
-- @see core.class
function Pixels:__init(pixels)
  self.pixels = list()
  self.expected_colors = list()
  local pixel_set = set()
  for i, pixel in pairs(pixels or {}) do
    if not isinstance(pixel, Pixel) then
      pixel = Pixel(pixel[1], pixel[2], pixel[3])
    end
    if not pixel_set:contains(pixel) then
      pixel_set:add(pixel)
      self.pixels:append(pixel)
      self.expected_colors:append(pixel.expected_color)
    end
  end
end

function Pixels:__add(other)
  local pixel_set = set(self.pixels)
  local new_pixels = list()
  for i, pixel in pairs(other.pixels) do
    local pix = Pixel(pixel.x, pixel.y, pixel.expected_color)
    if not pixel_set:contains(pix) then new_pixels:append(pix) end
  end
  return Pixels(self.pixels + new_pixels)
end

function Pixels:__sub(other)
  local pixel_set = set(other.pixels)
  local new_pixels = list()
  for p in iter(self.pixels) do 
    if not pixel_set:contains(p) then new_pixels:append(p)  end
  end
  return Pixels(new_pixels)
end

function Pixels:__eq(other)
  if len(self.pixels) ~= len(other.pixels) then return false end
  for i, pixel in pairs(other.pixels) do
    if pixel ~= self.pixels[i] then return false end
  end
  return true
end

function Pixels:__pairs() 
  return pairs(self.pixels) 
end

function Pixels:__tostring()
  return string.format('<Pixels(n=%d)>', len(self.pixels))
end

---
property(Pixels, 'colors', function(self)
  local positions = list()
  for p in iter(self.pixels) do positions:append({p.x, p.y}) end
  return getColors(positions)
end)

---- Check if all the pixels are in a screen
-- @treturn boolean are all the pixels visible on the screen
function Pixels:visible()
  return requal(self.colors, self.expected_colors)
end

---- Count how many of the pixels are in a screen
-- @treturn number how many pixels are visible on the screen
function Pixels:count()
  local colors = self.colors
  local count = 0
  for i, v in pairs(colors) do
    if v == self.expected_colors[i] then count = count + 1 end
  end
  return count
end

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

---- Returns a function that checks if any pixels have changed color
-- @treturn func check whether the colors have changed
function Pixels:any_colors_changed()
  return n_colors_changed(self, 1)
end

---- Returns a function that checks if all pixels have changed color
-- @treturn func check whether the colors have changed
function Pixels:all_colors_changed()
  return n_colors_changed(self, len(self.pixels))
end

---- Returns a function that checks if n pixels have changed color
-- @treturn func check whether the colors have changed
function Pixels:n_colors_changed(n)
  return n_colors_changed(self, n)
end



---- Group of evenly spaced pixels
-- @type Region
Region = class('Region', 'Pixels')

--- Create a Region object
-- @param positions iterable of positions
-- @int color color of region
-- @see core.class
function Region:__init(positions, color)
  self.color = color or colors.white
  local pixels = list()
  local pixel_set = set()
  for p in iter(positions) do 
    local pix = Pixel(p.x or p[1], p.y or p[2], self.color)
    if not pixel_set:contains(pix) then 
      pixel_set:add(pix)
      pixels:append(pix)
    end  
  end
  Pixels.__init(self, pixels)
end

function Region:__add(other)
  assert(other:isinstance(Region), 'Can only add Region objects to other Region objects')
  assert(other.color == self.color, 'Can only add Regions of the same color')
  return Region(self.pixels + other.pixels, self.color)
end

function Region:__sub(other)
  assert(other:isinstance(Region), 'Can only subtract Region objects from other Region objects')
  assert(other.color == self.color, 'Can only subtract Regions of the same color')
  return Region(set(self.pixels) - set(other.pixels), self.color)
end

function Region:__tostring()
  return string.format('<Region(pixels=%d, color=%d)>', len(self.pixels), self.color)
end

property(Region, 'center', function(self)
  local x, y = 0, 0
  for p in iter(self.pixels) do x, y = x + p.x, y + p.y end
  return Pixel(x / len(self.pixels), y / len(self.pixels), self.color)
end)



---- Ellipse @{Region}
-- @type Ellipse
Ellipse = class('Ellipse', 'Region')

--- Create a Ellipse object
-- @tparam table options (x, y, width, height, spacing)
-- @see core.class
function Ellipse:__init(options)
  self.x = options.x or 0
  self.y = options.y or 0
  self.width = options.width or 10
  self.height =  options.height or 10
  self.spacing = options.spacing or 10
  local max_d = max(self.width, self.height)
  local min_d = min(self.width, self.height)
  local max_w = max_d / max(self.width / self.height, self.height / self.width)
  local steps = int(360 * (math.pi * (self.width + self.height)) / (2 * math.pi * 20))

  local positions = set()
  for w=0, int(max_w), self.spacing do
    local theta, a, b = 0, int(w * min_d / max_d), int(w * min_d / max_d)
    positions:add(Pixel(int(self.x + a * self.width / max_w), self.y))
    if a > 0 and b > 0 then
      for i=1, steps do 
        theta = theta + 2 * math.pi / steps
        positions:add(Pixel(
          int(self.x + a * self.width / max_w * math.cos(theta)), 
          int(self.y + b * self.height / max_w * math.sin(theta)))
        )
      end
    end
  end

  Region.__init(self, positions, options.color)
end

function Ellipse:__tostring()
  return string.format('<Ellipse(%d, %d, width=%d, height=%d, spacing=%d, color=%d, pixels=%d)>', 
  self.x, self.y, self.width, self.height, self.spacing, self.color, len(self.pixels))
end



---- Rectangle @{Region}
-- @type Rectangle
Rectangle = class('Rectangle', 'Region')

--- Create a Rectangle object
-- @tparam table options (x, y, width, height, spacing)
-- @see core.class
function Rectangle:__init(options)
  self.x = options.x or 0
  self.y = options.y or 0
  self.width = options.width or 10
  self.height =  options.height or 10
  self.spacing = options.spacing or 10
  local positions = list()
  for i=self.x, self.x + self.width, self.spacing do
    for j=self.y, self.y + self.height, self.spacing do
      positions:append({i, j})
    end
  end
  Region.__init(self, positions, options.color)
end

function Rectangle:__tostring()
  return string.format('<Rectangle(%d, %d, width=%d, height=%d, spacing=%d, color=%d, pixels=%d)>', 
  self.x, self.y, self.width, self.height, self.spacing, self.color, len(self.pixels))
end



---- Triangle @{Region}
-- @type Triangle
Triangle = class('Triangle', 'Region')

--- Create a Triangle object
-- @tparam table options
-- @see core.class
function Triangle:__init(options)
  -- TODO: Triangle creation
  local positions = list()
  Region.__init(self, positions, options.color)
end

function Triangle:__tostring()
  return string.format('<Triangle(n=%d, color=%d)>', len(self.pixels), self.color)
end
