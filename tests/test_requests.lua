require('src/test')
require('src/core')
require('src/builtins')
require('src/contextlib')
require('src/itertools')
require('src/objects')
require('src/logic')
require('src/logging')
require('src/string')
require('src/system')
require('src/requests')
require('src/json')


fixture('patched_curl', function(monkeypatch, request) 
  local old_exe = exe
  monkeypatch.setattr('exe', function(...) 
    if (...)[1] == 'curl' then
      local url
      for k, v in pairs(...) do 
        if v:startswith("'http") then url = v:strip("'") end
      end
      local path = url:replace('http://httpbin.org', ''):replace('https://httpbin.org', ''):split('?')[1]
      local response_data
      if path:startswith('/get') then
        response_data = 'HTTP/1.1 200 OK\13\nConnection: keep-alive\13\nServer: gunicorn/19.9.0\13\nDate: Tue, 30 Oct 2018 03:42:19 GMT\13\nContent-Type: application/json\13\nContent-Length: 262\13\nAccess-Control-Allow-Origin: *\13\nAccess-Control-Allow-Credentials: true\13\nVia: 1.1 vegur\13\n\13\n{\n  "args": {\n      "stuff": "1"\n    },\n    "headers": {\n      "Accept": "*/*",\n      "Accept-Encoding": "identity",\n      "Connection": "close",\n      "Host": "httpbin.org",\n      "User-Agent": "myAgent",\n      "X-Stuff": "abc"\n    },\n    "origin": "194.59.251.59",\n    "url": "http://httpbin.org/get?stuff=1"\n  }'
      elseif path:startswith('/post') then 
        response_data = 'HTTP/1.1 200 OK\13\nConnection: keep-alive\13\nServer: gunicorn/19.9.0\13\nDate: Tue, 30 Oct 2018 03:42:20 GMT\13\nContent-Type: application/json\13\nContent-Length: 387\13\nAccess-Control-Allow-Origin: *\13\nAccess-Control-Allow-Credentials: true\13\nVia: 1.1 vegur\13\n\13\n{\n  "args": {},\n  "data": "",\n  "files": {},\n  "form": {\n    "amount": "10"\n  },\n  "headers": {\n    "Accept": "*/*",\n    "Accept-Encoding": "identity",\n    "Connection": "close",\n    "Content-Length": "9",\n    "Content-Type": "application/x-www-form-urlencoded",\n    "Host": "httpbin.org",\n    "User-Agent": "curl/7.47.0"\n  },\n  "json": null,\n  "origin": "194.59.251.59",\n  "url": "http://httpbin.org/post"\n}'
      elseif path:startswith('/base64') then 
        response_data = 'HTTP/1.1 200 OK\13\nConnection: keep-alive\13\nServer: gunicorn/19.9.0\13\nDate: Tue, 30 Oct 2018 03:42:21 GMT\13\nContent-Type: text/html; charset=utf-8\13\nContent-Length: 18\13\nAccess-Control-Allow-Origin: *\13\nAccess-Control-Allow-Credentials: true\13\nVia: 1.1 vegur\13\n\13\nHTTPBIN is awesome\n'
      elseif path:startswith('/basic-auth') then 
        response_data = 'HTTP/1.1 200 OK\13\nConnection: keep-alive\13\nServer: gunicorn/19.9.0\13\nDate: Tue, 30 Oct 2018 03:42:22 GMT\13\nContent-Type: application/json\13\nContent-Length: 47\13\nAccess-Control-Allow-Origin: *\13\nAccess-Control-Allow-Credentials: true\13\nVia: 1.1 vegur\13\n\13\n{\n          "authenticated": true,\n          "user": "name"\n        }'
      elseif path:startswith('/doesntexist') then
        response_data = 'HTTP/1.1 404 NOT FOUND\13\nConnection: keep-alive\13\nServer: gunicorn/19.9.0\13\nDate: Tue, 30 Oct 2018 12:19:14 GMT\13\nContent-Type: text/html\13\nContent-Length: 233\13\nAccess-Control-Allow-Origin: *\13\nAccess-Control-Allow-Credentials: true\13\nVia: 1.1 vegur\13\n\13\n<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 3.2 Final//EN\">\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server.  If you entered the URL manually please check your spelling and try again.</p>'
      end
      return response_data:split('\n')

      -- Use this to make requests over network
      -- local data = old_exe(...)
      -- pprint(data)
      -- return data
    end
    return old_exe(...)
  end)  
end)


fixture('response', function() 
  local resp = Response({url='http://example.com', method='GET'})
  resp.status_code = 400
  resp.text = '{\n\t"a":"1",\n\t"b":"2"\n}'
  return resp
end)


describe('requests',

  it('gets json', function(patched_curl)
    local url = 'http://httpbin.org/get'
    local header_key = 'X-Stuff'
    local head, ua = {[header_key]='abc'}, 'myAgent'
    local resp = requests.get{url, params={stuff=1}, headers=head, user_agent=ua}
    assert(resp.status_code == 200, 'Did not return 200')
    assert(resp.reason == 'OK', 'Did not return correct reason')
    assert(resp, 'Json request did not return response')
    local j = resp:json()
    assert(j.headers, 'Incorrect json returned')
    assert(j.origin, 'Incorrect json returned')
    assertEqual(j.url, url..'?stuff=1', 'Incorrect json returned')
    assertEqual(j.url, resp.url, 'Incorrect json returned')
    assert(j.headers['User-Agent'] == ua, 'Did not get correct user agent header')
    assert(j.headers[header_key] == head[header_key], 'Did not get correct custom header')
  end),
  
  it('posts file', function(patched_curl) 
    local resp = requests.post{'http://httpbin.org/post', files={file='t.txt'}}
    assert(resp.status_code == 200, 'Did not return 200')
    assert(resp.reason == 'OK', 'Did not return correct reason')
  end),

  it('posts json', function(patched_curl)
    local resp = requests.post{'http://httpbin.org/post', data={amount=10}}
    assert(resp.status_code == 200, 'Did not return 200')
    assert(resp.reason == 'OK', 'Did not return correct reason')
    assertEqual(str(resp:json().form.amount), '10', 'Did not post correct data')
  end),
  
  it('gets text', function(patched_curl)
    local resp = requests.get('https://httpbin.org/base64/SFRUUEJJTiBpcyBhd2Vzb21l')
    assert(resp.status_code == 200, 'Did not return 200')
    assert(resp.reason == 'OK', 'Did not return correct reason')
    assert(resp, 'Text request did not return response')
    assertEqual(resp.text:strip('\n'), 'HTTPBIN is awesome', 'Incorrect text returned')
  end),

  it('makes request with auth', function(patched_curl) 
    local resp = requests.get{'https://httpbin.org/basic-auth/name/password', auth={user='name', password='password'}, verify_ssl=true}
    assert(resp.status_code == 200, 'Did not return 200')
    assert(resp.reason == 'OK', 'Did not return correct reason')
    assert(resp:json().authenticated == true, 'Not authenticated with basic http auth')
    assert(resp:json().user == 'name', 'Did not get correct username')
  end),

  it('makes and parses failed request', function(patched_curl) 
    local resp = requests.get('https://httpbin.org/doesntexist')
    assert(resp.status_code == 404, 'Did not return 404 for unknown url')
    assert(resp.reason == 'NOT FOUND', 'Did not return correct reason')
    assert(is(resp.text), 'Did not return any text in failed response')
  end),

  it('returns empty response when curl fails', function(patched_curl) 
    local resp = requests.get('https://httpbin.org/reallydoesntexist')
    assert(resp.status_code == -1, 'Parsed status code for empty response')
    assert(resp.text == '', 'Parsed text for empty response')
  end),

  it('Response tostring', function(response) 
    assert(tostring(response) == string.format('<Response [%d]>', response.status_code), 
    'Response does not have correct tostring')
  end),
  
  it('Response iter_lines', function(response) 
    local expected = {'{', '\t"a":"1",', '\t"b":"2"', '}'}
    local count = 1
    for line in response:iter_lines() do
      assert(line == expected[count], 'Incorrect line in response')
      count = count + 1
    end
    assert(count, 'Did not iterate over response text')
  end),
  
  it('Response json', function(response) 
    assert(response:json().b == '2', 'Did not parse response json')
  end),
  
  it('Response raise_for_status', function(response) 
    assertRaises(response.method..' response: '..response.status_code, function() 
      response:raise_for_status()
    end, 'Did not raise error for response')
  end)
)


run_tests()
