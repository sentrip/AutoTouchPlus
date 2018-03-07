---- Web requests.
-- Mirrors basic methods and api of Python's 'requests' module.
-- Requires wget to work, as @{requests} is simply a lua wrapper for the wget cli.
-- @module requests

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
--  local clean = self.text:replace('[\n\t\r]', ''):replace('[ ]+', ' ')
--  clean = clean:replace('"(.+)": ', function(m) return m..'=' end)
--  clean = clean:replace('%[', '{'):replace('%]', '}')
--  clean = clean:replace('{[ ]+', '{'):replace('}[ ]+', '}')
--  return dict(eval(string.format('return %s', clean)))
  return json.decode(self.text)
end

---- Check if the request was successful
-- @raise error if the response status code is not 200
function Response:raise_for_status()
  if self.status_code ~= 200 then error('error in '..self.method..' request: '..self.status_code) end
end

--Parse log file of wget (debug) and patch attributes of response
local function parse_log(f, request, response)
  local err_msg = 'error in '..request.method..' request: '
  local lines = readLines(f)

  assert(isnotin('failed', lines[6]), err_msg..'Url does not exist')
  local req = lines(lines:index('---request begin---') + 1, lines:index('---request end---') - 1)
  local resp = lines(lines:index('---response begin---') + 1, lines:index('---response end---') - 1)

  _, response.status_code, response.reason = unpack(resp[1]:split(' '))
  response.status_code = num(response.status_code)
  response.ok = response.status_code < 400

  local k, v
  for i, lns in pairs({request=req(2, nil), response=resp(2, nil)}) do
    for line in lns() do 
      k = line:split(':')[1]
      v = line:replace(k..': ', '')
      v = tonumber(v) or v
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

--Web requesting and data parsing
local _requests = {
  tdata = '_response_data',
  tlog = '_response_log',
  tbody = '_request_body'
}

--checks for correct json format in case a table is passed as data
function _requests.check_data(request) 
  if not request.data then
    return
  elseif isType(request.data, 'table') and not request.data[1] then 
    assert(requal(request.data, json.decode(json.encode(request.data))),
      'Incorrect json formatting')
    --request.data = json.encode(request.data)
  end
end

function _requests.check_url(request) 
  assert(request.url:startswith('http'), 'Only http(s) urls are supported')
end


function _requests.format_params(request) 
  if is(request.params) then
    request.url = request.url..'?'.._requests.urlencode(request.params)
  end
end


function _requests.urlencode(params)
  if is.str(params) then return params end
  local s = ''
  if not params or next(params) == nil then return s end
  for key, value in pairs(params) do
    if is(s) then s = s..'&' end
    if tostring(value) then s = s..tostring(key)..'='..tostring(value) end
  end
  return s
end


function _requests.make_request(request)
  local cmd = list{'wget', '--method', request.method:upper()}
  --ssl verification
  if (request.url:startswith('https') and not request.verify) or request.verify == false then
    cmd:append('--no-check-certificate')
  end
  -- request data
  if is(request.data) and isType(request.data, 'table') then
    local fle = request.data[1] or _requests.tbody
    cmd:extend{'--body-file', fle}
  end
  -- http authentication
  if is(request.auth) then
    local usr = request.auth.user or request.auth[1]
    local pwd = request.auth.password or request.auth[2]
    assert(is.str(usr) and is.str(pwd), 'Incorrect authentication format')
    cmd:extend{'--http-user', usr, '--http-password', pwd}
  end
  -- proxies
  if is(request.proxies) then
    assert(request.proxies.http or request.proxies.https, 'Incorrect proxy format')
    local usr, pwd
    for k, v in pairs(request.proxies) do
      if isin('@', v) then usr, pwd = unpack(v:split('//')[2]:split('@')[1]:split(':')) end
    end
  else cmd:append('--no-proxy') end
  -- user agent
  if is(request.user_agent) then
    cmd:extend{'-U', request.headers.user_agent}
  end
  -- headers
  if is(request.headers) then
    for k, v in pairs(request.headers) do 
      cmd:append("--header='"..k..': '..str(v).."'")
    end
  else request.headers = {} end
  -- output options
  if isType(request.data, 'string') then 
    local d = _requests.urlencode(request.data)
    with(open(_requests.tbody, 'wb'), function(f) 
        f:write(d) 
        end)
    cmd:append("--header='"..'Content-Length'..': '..str(len(d)).."'")
  end
  cmd:extend{"'"..request.url.."'", '-d'}
  cmd:extend{'--output-document', _requests.tdata}
  cmd:extend{'--output-file', _requests.tlog}
  local response = Response(request)
  -- execute request
  try(
   function() 
      exe(cmd)
      with(open(_requests.tdata, 'rb'), 
        function(f) response.text = f:read('*all') end)
      with(open(_requests.tlog), 
        function(f) parse_log(f, request, response) end)
   end,
   except(function(err) 
       end)
  )
  -- temporary file cleanup
  if isType(request.data, 'string') then
    exe{'rm', _requests.tbody}
  end
  exe{'rm', _requests.tdata, _requests.tlog} 
  return response
end


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
  local request
  if is.table(url) then 
    if Not.Nil(url[1]) then 
      url.url = url[1] 
      url[1] = nil 
    end
    request = url
  else
    request = args or {}
    request.url = url
  end
  
  request.method = method
  _requests.check_url(request)
  _requests.check_data(request)
  _requests.format_params(request)
  
  return _requests.make_request(request)
end

