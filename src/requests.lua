---- Web requests and data parsing.
-- Mirrors basic methods and api of Python's 'requests' module.
-- Requires wget to work, as @{requests} is simply a lua wrapper for the wget cli.
-- @module requests


---- Api object for @{requests}
-- @type requests
requests = {}

---- Make a DELETE request
-- @tparam string url url to request (see @{requests.request})
-- @tparam table args request arguments (see @{requests.request})
-- @treturn Response
function requests.delete(url, args)
  return requests.request("DELETE", url, args)
end

---- Make a GET request
-- @tparam string url url to request (see @{requests.request})
-- @tparam table args request arguments (see @{requests.request})
-- @treturn Response
function requests.get(url, args)
  return requests.request("GET", url, args)
end

---- Make a POST request
-- @tparam string url url to request (see @{requests.request})
-- @tparam table args request arguments (see @{requests.request})
-- @treturn Response
function requests.post(url, args)
  return requests.request("POST", url, args)
end

---- Make a PUT request
-- @tparam string url url to request (see @{requests.request})
-- @tparam table args request arguments (see @{requests.request})
-- @treturn Response
function requests.put(url, args)
  return requests.request("PUT", url, args)
end

---- Make an HTTP request
-- @tparam string method one of GET, POST, PUT, DELETE
-- @tparam string url url to request
-- @tparam table args request arguments
-- @treturn Response
function requests.request(method, url, args)
  local _req = args or {}
  
  if is.table(url) then 
    _req = url
  else
    _req.url = url
  end

  _req.method = method
  local request = Request(_req)
  
  if request:verify() then
    local cmd = request:build()
    return request:send(cmd)
  else
    return "failed"
  end
end
---

---Parse wget debug output and patch attributes of response
local function parse_data(lines, request, response)         
  
  local err_msg = 'error in '..request.method..' request: '
  assert(isnotin('failed', lines[6]), err_msg..'Url does not exist')
  
  local req = lines(lines:index('---request begin---') + 1, lines:index('---request end---') - 1)
  local resp = lines(lines:index('---response begin---') + 1, lines:index('---response end---') - 1)
  
  _, response.status_code, response.reason = unpack(resp[1]:strip('\13'):split(' '))
  response.status_code = num(response.status_code)
  response.ok = response.status_code < 400

  local k, v
  for i, lns in pairs({request=req(2, nil), response=resp(2, nil)}) do
    for line in lns() do 
      k = line:split(':')[1]:strip('\13')
      v = line:replace(k..': ', ''):strip('\13')
      v = tonumber(v) or v
      if v then
        if i == 'request' then 
          request.headers[k] = v 
        else 
          response.headers[k] = v 
          if k == 'Content-Type' then 
            if isin('charset=', v) then response.encoding = v:split('charset=')[2] end
          end
        end
      end
    end
  end
end
---

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
---

---- Request object
-- @type Request
Request = class('Request')
function Request:__init(request)
  for k, v in pairs(request) do
    setattr(self, k, v)
  end
  self.headers = dict()
  self.method = request.method or "GET"
  self.url = request.url or request[1] or ''
  self._response_fn = '_response.txt'
end
---

--- Build command for wget from request
-- @return wget command in list form
function Request:build()
  local cmd = list{'wget', '--method', self.method:upper()}
  if is(self.params) then
    self.url = self.url .. '?' .. urlencode(self.params)
  end
  cmd:extend(self:_add_auth() or {})
  cmd:extend(self:_add_data() or {})
  cmd:extend(self:_add_headers() or {})
  cmd:extend(self:_add_proxies() or {})
  cmd:extend(self:_add_ssl() or {})
  cmd:extend(self:_add_user_agent() or {})
  cmd:extend{"'"..self.url.."'"}
  cmd:extend{'--output-file', '-'}
  cmd:extend{'--output-document', self._response_fn}
  return cmd
end
---

--- Send wget command and return parsed response
-- @param cmd command list
-- @return Reponse of request
function Request:send(cmd)
  local response = Response(self)
  
  try(function() 
      local lines = exe(cmd) 
      
      with(open(self._response_fn), function(f) 
          response.text = f:read('*a') end)
      
      try(function() parse_data(lines, self, response) end)
      
      end,
    
    except(function(err) 
       print('Requesting '..self.url..' failed - ' .. str(err)) 
     end),
   
    function()
      exe{'rm', self._response_fn}
      end
   )   
   
  return response
end
---

--- Verify request parameters
-- @return boolean is request valid
function Request:verify()
  assert(requal(self.data, json.decode(json.encode(self.data))),'Incorrect json formatting')
  assert(self.url:startswith('http'), 'Only http(s) urls are supported')
  return true
end
---

---
function Request:_add_auth()
  if is(self.auth) then
    local usr = self.auth.user or self.auth[1]
    local pwd = self.auth.password or self.auth[2]
    retur {'--http-user', usr, '--http-password', pwd}
  end
end
---

---
function Request:_add_data()
  if is(self.data) then
    if Not.string(self.data) then
      self.data = urlencode(self.data)
    end
    return {'--body-data', "'"..self.data.."'"}
  end
end
---

---
function Request:_add_headers()
  if is(self.headers) then
    for k, v in pairs(self.headers) do 
      cmd:append("--header='"..k..': '..str(v).."'")
    end
  end
end
---

---
function Request:_add_proxies()
  if is(self.proxies) then
    local usr, pwd
    for k, v in pairs(self.proxies) do
      if isin('@', v) then usr, pwd = unpack(v:split('//')[2]:split('@')[1]:split(':')) end
    end
  end
end
---

---
function Request:_add_ssl()
  if not self.verify or (self.url:startswith('https') and self.verify) then
    return {'--no-check-certificate'}
  end
end
---

---
function Request:_add_user_agent()
  if is(self.user_agent) then
    return {'-U', self.user_agent}
  end
end
---

---- Response object returned by methods of @{requests}
-- @type Response
Response = class('Response')
function Response:__init(request)
  self.request = request or {}
  self.url = self.request.url
  self.status_code = -1
  self.text = ''
  self.encoding = ''
  self.reason = ''
  self.headers = dict()
  self.ok = false
end
---

---
function Response:__tostring()
  return string.format('<Response [%d]>', self.status_code)
end
---

---- Iterate over the lines in the text of a response
-- @return iterator of lines in response text
function Response:iter_lines()
  local i, v
  local lines = self.text:split('\n')
  return function() i, v = next(lines, i) return v end
end
---

---- Convert a json formatted response text to a lua table
-- @treturn table dictionary-like table of response
function Response:json()
  return json.decode(self.text)
end
---

---- Check if the request was successful
-- @raise error if the response status code is not 200
function Response:raise_for_status()
  if self.status_code ~= 200 then error('error in '..self.method..' request: '..self.status_code) end
end
---
