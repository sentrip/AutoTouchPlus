---- Web requests and data parsing.
-- Mimics basic api of Python's <a href="http://docs.python-requests.org/en/master/">requests</a> module.
-- Requires <a href="https://curl.haxx.se/">cURL</a> to work, as @{requests.lua} is simply a lua wrapper for the cURL command line interface.
-- @module requests.lua

require('src/core')

requests = {}

---- Make a DELETE request
-- @tparam string url url to request
-- @tparam table args request arguments
-- @treturn Response response to request
-- @see requests.request
function requests.delete(url, args) return requests.request("DELETE", url, args) end

---- Make a GET request
-- @tparam string url url to request
-- @tparam table args request arguments
-- @treturn Response response to request
-- @see requests.request
function requests.get(url, args) return requests.request("GET", url, args) end

---- Make a POST request
-- @tparam string url url to request
-- @tparam table args request arguments
-- @treturn Response response to request
-- @see requests.request
function requests.post(url, args) return requests.request("POST", url, args) end

---- Make a PUT request
-- @tparam string url url to request
-- @tparam table args request arguments
-- @treturn Response response to request
-- @see requests.request
function requests.put(url, args) return requests.request("PUT", url, args) end

---- Make an HTTP request
-- @tparam string method one of GET, POST, PUT, DELETE
-- @tparam string url url to request
-- @tparam table args request arguments
-- @treturn Response response to request
function requests.request(method, url, args)
  local _req = args or {}
  if is.table(url) then _req = url else _req.url = url end
  _req.method = method
  local request = Request(_req)
  request:verify()
  log.debug('Sending %s request: %s with data: %s', _req.method, _req.url or _req[1], _req.data or 'none')
  return request:send(request:build())
end


---Parse curl output and patch attributes of response
local function parse_data(lines, response)
  local before_empty_line = true
  
  for i, ln in pairs(lines(2, nil)) do
    ln = ln:replace('\13', '')
    if before_empty_line then
      if ln == '' then 
        before_empty_line = false 
      else
        local kv = ln:split(':')
        local k, v = kv[1], (':'):join(list(kv)(2, nil)):strip(' ')
        if v == 'true' then v = true elseif v == 'false' then v = false end
        response.headers[k] = tonumber(v) or v
      end
    else
      response.text = response.text..ln..'\n'
    end
  end
  local info = lines[1]:replace('\13', ''):split(' ')
  response.http_version, response.status_code, response.reason = info[1], info[2], (' '):join(info(3, nil))  
  response.ok, response.status_code = response.reason == 'OK', num(response.status_code)
end

---Url-encode a dictionary 
local function urlencode(params)
  if is.str(params) then return params end
  local s = ''
  if not params or next(params) == nil then return s end
  for key, value in pairs(params) do
    if is(s) then s = s..'&' end
    if tostring(value) then s = s..tostring(key)..'='..tostring(value) end
  end
  return s
end


---- Request object
-- @type Request
Request = class('Request')
function Request:__init(request)
  for k, v in pairs(request) do
    setattr(self, k, v)
  end
  self.headers = dict(self.headers or dict())
  self.method = request.method or "GET"
  self.url = request.url or request[1] or ''
  -- luacov: disable
  if rootDir then
    self._response_fn = os.path_join(rootDir(), '_response.txt')
  else
    self._response_fn = '_response.txt'
  end
  -- luacov: enable
end

--- Build command for curl from request
-- @treturn objects.list curl command in list form
function Request:build()
  local cmd = list{'curl', '-si', '-X', self.method:upper()}
  if is(self.params) then
    self.url = self.url .. '?' .. urlencode(self.params)
  end
  for k in iter{'auth', 'data', 'headers', 'proxies', 'ssl', 'user_agent'} do
    cmd:extend(getattr(self, '_add_'..k)(self) or {})
  end
  cmd:append("'"..self.url.."'")
  return cmd
end

--- Send curl command and return parsed response
-- @tparam table cmd list of commands
-- @treturn Response response to request
function Request:send(cmd)
  local response = Response(self)
  try(function() 
    local lines = exe(cmd, true, true) 
    parse_data(lines, response) 
  end,
  except(function(err) 
    log.error('Failed to request url: %s - %s ', self.url, str(err)) 
  end))
  return response
end

--- Verify request parameters
-- @raise error with format described by following regex: <i><b>Invalid request: (.*)</b></i>
function Request:verify()
  local prefix = 'Invalid request: '
  assert(requal(self.data, json.decode(json.encode(self.data))), prefix..'Incorrect json formatting')
  assert(self.url:startswith('http'), prefix..'Only http(s) urls are supported')
end

function Request:_add_auth()
  if is(self.auth) then
    local usr = self.auth.user or self.auth[1]
    local pwd = self.auth.password or self.auth[2]
    return {'--basic', '--user', "''"..usr..':'..pwd.."''"}
  end
end

function Request:_add_data()
  if is(self.data) then
    if Not.string(self.data) then
      self.data = urlencode(self.data)
    end
    return {'--data', "'"..self.data.."'"}
  end
end

function Request:_add_headers()
  local cmd = list()
  if is(self.headers) then
    for k, v in pairs(self.headers) do 
      cmd:extend{"--header", "'"..k..': '..str(v).."'"}
    end
  end
  return cmd
end

function Request:_add_proxies()
  -- TODO: request with proxy and test
  -- if is(self.proxies) then
  --   local usr, pwd
  --   for k, v in pairs(self.proxies) do
  --     if isin('@', v) then usr, pwd = unpack(v:split('//')[2]:split('@')[1]:split(':')) end
  --   end
  -- end
end

function Request:_add_ssl()
  if not self.verify_ssl or (self.url:startswith('https') and self.verify_ssl) then
    return {'--insecure'}
  end
end

function Request:_add_user_agent()
  if is(self.user_agent) then
    return {'--user-agent', "'"..self.user_agent.."'"}
  end
end

---- Response object returned by @{requests.request}
-- @type Response
Response = class('Response')
function Response:__init(request)
  assert(request, 'Cannot create response with no request')
  self.request = request or {}
  self.headers = dict()
  self.ok = false
  self.method = self.request.method
  self.reason = ''
  self.status_code = -1
  self.text = ''
  self.url = self.request.url
end

function Response:__tostring()
  return string.format('<Response [%d]>', self.status_code)
end

---- Iterate over the lines in the text of a response
-- @return iterator of lines in response text
function Response:iter_lines()
  local i, v
  local lines = self.text:split('\n')
  return function() i, v = next(lines, i) return v end
end

---- Convert a json formatted response text to a lua table
-- @treturn table dictionary-like table of response
function Response:json()
  return json.decode(self.text)
end

---- Check if the response was successful.
-- A successful response has a status_code between 200 and 399.
-- @raise error with format described by following regex: <i><b>error in ([^ ]+) response: ([0-9]+)</b></i>
function Response:raise_for_status()
  if self.status_code < 200 or self.status_code >= 400 then 
    error('Error in '..self.method..' response: '..self.status_code) 
  end
end

---- Content length of response
-- @within Class Response - properties
-- @field Response.content_length number of bytes in response data
property(Response, 'content_length', 
function(self, k) return self.headers:get('Content-Length', 0) end)

---- Content type of response
-- @within Class Response - properties
-- @field Response.content_type mime type of response data (e.g. text/html)
property(Response, 'content_type', 
function(self, k) return self.headers:get('Content-Type', ''):split(';')[1] end)

---- Encoding type of response
-- @within Class Response - properties
-- @field Response.encoding response encoding (e.g. utf-8)
property(Response, 'encoding', 
function(self, k) return self.headers:get('Content-Type', ''):match('charset=(.*)') end)
