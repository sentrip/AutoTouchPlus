--- Path objects for complex swiping
-- @module path


local function add_locations(locations, other, relative)
  if (relative and other[1].x == 0 and other[1].y == 0) or (locations[-1].x == other[1].x and locations[-1].y == other[1].y) then
    other = other(2, nil)
  end
  local x, y
  local new_locations = list()
  for loc in iter(other) do 
    x, y = loc.x, loc.y
    if relative then 
      x, y = x + locations[-1].x, y + locations[-1].y 
    end
    new_locations:append({x=x, y=y})
  end
  return locations + new_locations
end


---- List of absolute positions that define a path on the screen
-- @type Path
Path = class('Path')

--- Create a Path object
-- @param locations iterable of x, y locations that define a path
-- @see core.class
-- @usage path = Path{{x=0, y=0}, {x=10, y=10}} 
--path = Path{Pixel(0, 0), Pixel(10, 10)}
function Path:__init(locations)
  self.locations = list(locations or {})
  self.point_count = len(locations)
  self.duration = self.point_count * 0.016
  self.absolute = true
end

function Path:__add(other)
  assert(other:isinstance(Path), 'Can only add Path objects to other Path objects')
  if len(self.locations) + len(other.locations) == 0 then return Path() end
  if len(self.locations) == 0 then self.locations:append(other.locations[1]) end
  return Path(add_locations(self.locations, other.locations, not other.absolute))
end

function Path:__index(key)
  if is.num(key) then return self.locations[key] end
  return class('').__index(self, key)
end

function Path:__newindex(key, value)
  if is.num(key) then self.locations[key] = value end
  class('').__newindex(self, key, value)
end

function Path:__pairs()
  return pairs(self.locations)
end

function Path:__tostring()
  return string.format('<%s(points=%s, duration=%.2fs)>', getmetatable(self).__name, len(self.locations), self.duration)
end


---- Begin swiping the path by placing a finger on the starting position
-- @param fingerID (optional) ID of finger to use for swipe
-- @param speed (optional) swipe speed (number of points to skip at each move)
function Path:begin_swipe(fingerID, speed)
  assert(speed and speed >= 1 and speed <= 10, 'speed '..speed..' is not in range 1-10')
  touchDown(fingerID or 2, self.locations[1].x, self.locations[1].y)
  usleep(16000)
  self.cancelled = false
  self.speed = speed or 5
  self.idx = self.speed + 1
end

---- Move to the next position in the swipe
-- @param fingerID (optional) ID of finger to use for swipe
-- @param on_move (optional) function to run at each movement
-- @treturn boolean whether the path will continue swiping or not
function Path:step(fingerID, on_move)
  if is.Nil(on_move) then on_move = function() end end
  if is.Nil(self.idx) then error('Cannot step a path before begin_swipe has been called') end
  if self.idx < len(self.locations) and not self.cancelled then 
    touchMove(fingerID or 2, self.locations[self.idx].x, self.locations[self.idx].y)
    self.idx = math.min(len(self.locations), self.idx + self.speed)
    usleep(16000)
    if on_move() == true then return true end
    return false
  else
    touchUp(fingerID or 2, self.locations[self.idx].x, self.locations[self.idx].y)
    self.idx = nil
    self.cancelled = nil
    self.speed = nil
    return true
  end
end

---- Swipe the path from beginning to end
-- @tparam table options options for swipe (fingerID, speed, on_move)
-- @see path.Path.begin_swipe
-- @see path.Path.step
-- @treturn screen screen for method chaining
function Path:swipe(options)
  with(screen.action_context(function() return true end), function(check) 
    self:begin_swipe(options.fingerID, options.speed)
    local done = false
    while not done do 
      done = self:step(options.fingerID, options.on_move)
    end
    end)
  return screen
end

---- Arc path with an angle and radius from a center pixel
-- @tparam number radius distance from center_pixel in pixels to draw arc
-- @tparam number start_angle angle where the arc begins (in degrees)
-- @tparam number end_angle (optional) angle where the arc ends (in degrees)
-- @pixel center (optional) center pixel of arc
-- @treturn Path|RelativePath desired path (@{RelativePath} if center argument omitted)
function Path.arc(radius, start_angle, end_angle, center)
  
  -- Angle = 0 -> start_angle if no end_angle specified
  if not end_angle then
    start_angle, end_angle = 0, start_angle
  end

  local absolute = true
  -- Relative path if no center specified
  if not center then
    -- TODO: make relative arc center adaptive to radius and angles
    center = {x=0, y=0}
    absolute = false
  end
  
  local function radians(a) return a / 360 * 2 * math.pi end
  -- TODO: Better arc step resolution (for arcs with large radius)
  local steps = abs(end_angle - start_angle)
  local deltaTheta = (radians(end_angle) - radians(start_angle)) / steps
  local theta = radians(start_angle)
  
  local function angle_to_pos(angle)
    return {x=center.x + radius * math.cos(angle), y=center.y + radius * math.sin(angle)}
  end

  local path = list{angle_to_pos(theta)}
  for i=1, steps do
    theta = theta + deltaTheta
    path:append(angle_to_pos(theta))
  end
  if absolute then return Path(path) else return RelativePath(path) end
end

---- Linear path between two pixels
-- @pixel start_pixel beginning of path
-- @pixel end_pixel (optional) end of path
-- @treturn Path|RelativePath desired path (@{RelativePath} if end_pixel argument omitted)
function Path.linear(start_pixel, end_pixel)
  -- Relative path if only one pixel specified
  local absolute = true
  if not end_pixel then
    start_pixel, end_pixel = {x=0, y=0}, start_pixel
    absolute = false
  end
  local distanceX = end_pixel.x - start_pixel.x
  local distanceY = end_pixel.y - start_pixel.y
  local steps = math.min(50, math.max(math.abs(distanceX), math.abs(distanceY)))
  local x, y = start_pixel.x, start_pixel.y
  local deltaX = distanceX / steps
  local deltaY = distanceY / steps
  local path = list{{x=x, y=y}}
  for i=1, steps do
    x = x + deltaX
    y = y + deltaY
    path:append({x=x, y=y})
  end
  if absolute then return Path(path) else return RelativePath(path) end
end


---- List of relative positions that define a path on the screen
-- @type RelativePath
RelativePath = class('RelativePath', 'Path')

--- Create a RelativePath object
-- @param locations iterable of x, y locations that define a path
-- @see core.class
-- @see path.Path.__init
function RelativePath:__init(locations)
  Path.__init(self, locations)
  self.absolute = false
end


function RelativePath:__add(other)
  assert(other:isinstance(RelativePath), 'Can only add RelativePath objects to other RelativePath objects')
  return RelativePath(add_locations(self.locations, other.locations, true))
end
