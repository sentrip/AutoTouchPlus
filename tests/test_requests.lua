require('src/test')
require('src/core')
require('src/contextlib')
require('src/objects')
require('src/logic')
require('src/string')
require('src/system')
require('src/requests')
require('src/json')


fixture('patched_wget', function(monkeypatch, request) 
  local old_exe = exe
  local output
  monkeypatch.setattr('exe', function(...) 
    if (...)[1] == 'wget' then
      local next_is_output = false
      local url
      for k, v in pairs(...) do 
        if v:startswith("'http") then url = v:strip("'") end
        if next_is_output then output = v; break end
        if v:startswith('--output-document') then next_is_output = true end
      end
      local path = url:replace('http://httpbin.org', ''):replace('https://httpbin.org', ''):split('?')[1]
      local stdout, response_data
      if path:startswith('/get') then
        stdout = '--2018-10-20 04:17:13--  http://httpbin.org/get?stuff=1\nResolving httpbin.org (httpbin.org)... 52.44.144.199, 52.2.175.150, 52.0.94.50, ...\nConnecting to httpbin.org (httpbin.org)|52.44.144.199|:80... connected.\nHTTP request sent, awaiting response... 200 OK\nLength: 297 [application/json]\nSaving to: ‘_response.txt’\n\n     0K                                                       100% 28,1M=0s\n\n2018-10-20 04:17:13 (28,1 MB/s) - ‘_response.txt’ saved [297/297]'
        response_data = '{\n  "args": {\n      "stuff": "1"\n    },\n    "headers": {\n      "Accept": "*/*",\n      "Accept-Encoding": "identity",\n      "Connection": "close",\n      "Host": "httpbin.org",\n      "User-Agent": "myAgent",\n      "X-Stuff": "abc"\n    },\n    "origin": "194.59.251.59",\n    "url": "http://httpbin.org/get?stuff=1"\n  }'
      elseif path:startswith('/post') then 
        stdout = '--2018-10-20 04:23:20--  http://httpbin.org/post\nResolving httpbin.org (httpbin.org)... 34.226.180.131, 34.231.150.116, 34.231.75.48, ...\nConnecting to httpbin.org (httpbin.org)|34.226.180.131|:80... connected.\nHTTP request sent, awaiting response... 200 OK\nLength: 434 [application/json]\nSaving to: ‘_response.txt’\n\n     0K                                                       100% 29,2M=0s\n\n2018-10-20 04:23:21 (29,2 MB/s) - ‘_response.txt’ saved [434/434]'
        response_data = '{\n  "args": {},\n  "data": "",\n  "files": {},\n  "form": {\n    "amount": "10"\n  },\n  "headers": {\n    "Accept": "*/*",\n    "Accept-Encoding": "identity",\n    "Connection": "close",\n    "Content-Length": "9",\n    "Content-Type": "application/x-www-form-urlencoded",\n    "Host": "httpbin.org",\n    "User-Agent": "Wget/1.17.1 (linux-gnu)"\n  },\n  "json": null,\n  "origin": "194.59.251.59",\n  "url": "http://httpbin.org/post"\n}'
      elseif path:startswith('/base64') then 
        stdout = '--2018-10-20 04:23:21--  https://httpbin.org/base64/SFRUUEJJTiBpcyBhd2Vzb21l\nResolving httpbin.org (httpbin.org)... 34.226.180.131, 34.231.150.116, 34.231.75.48, ...\nConnecting to httpbin.org (httpbin.org)|34.226.180.131|:443... connected.\nHTTP request sent, awaiting response... 200 OK\nLength: 18 [text/html]\nSaving to: ‘_response.txt’\n\n     0K                                                       100% 3,59M=0s\n\n2018-10-20 04:23:22 (3,59 MB/s) - ‘_response.txt’ saved [18/18]'
        response_data = 'HTTPBIN is awesome'
      elseif path:startswith('/basic-auth') then 
        stdout = '--2018-10-20 04:29:38--  https://httpbin.org/basic-auth/name/password\nResolving httpbin.org (httpbin.org)... 52.44.92.122, 52.4.75.11, 52.45.111.123, ...\nConnecting to httpbin.org (httpbin.org)|52.44.92.122|:443... connected.\nHTTP request sent, awaiting response... 401 UNAUTHORIZED\nAuthentication selected: Basic realm=\"Fake Realm\"\nReusing existing connection to httpbin.org:443.\nHTTP request sent, awaiting response... 200 OK\nLength: 47 [application/json]\nSaving to: ‘_response.txt’\n     0K                                                       100% 8,17M=0s\n2018-10-20 04:29:39 (8,17 MB/s) - ‘_response.txt’ saved [47/47]'
        response_data = '{\n          "authenticated": true,\n          "user": "name"\n        }'
      end
      local root_dir = ''
      if rootDir then root_dir = rootDir() end
      local f = io.open(root_dir..output, 'w')
      f:write(response_data)
      f:close()
      return stdout:split('\n')

      -- Use this to make requests over network
      -- local data = old_exe(...)
      -- pprint(data)
      -- local f = io.open(output)
      -- local stdout = f:read('*a')
      -- f:close()
      -- print('-' * 50)
      -- print(stdout)
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

  it('gets json', function(patched_wget)
    local url = 'http://httpbin.org/get'
    local header_key = 'X-Stuff'
    local head, ua = {[header_key]='abc'}, 'myAgent'
    local resp = requests.get{url, params={stuff=1}, headers=head, user_agent=ua}
    assert(resp.status_code == 200, 'Did not return 200')
    assert(resp, 'Json request did not return response')
    local j = resp:json()
    assert(j.headers, 'Incorrect json returned')
    assert(j.origin, 'Incorrect json returned')
    assertEqual(j.url, url..'?stuff=1', 'Incorrect json returned')
    assertEqual(j.url, resp.url, 'Incorrect json returned')
    assert(j.headers['User-Agent'] == ua, 'Did not get correct user agent header')
    assert(j.headers[header_key] == head[header_key], 'Did not get correct custom header')
  end),
  
  it('posts json', function(patched_wget)
    local resp = requests.post{'http://httpbin.org/post', data={amount=10}}
    assert(resp.status_code == 200, 'Did not return 200')
    assertEqual(str(resp:json().form.amount), '10', 'Did not post correct data')
  end),
  
  it('gets text', function(patched_wget)
    local resp = requests.get('https://httpbin.org/base64/SFRUUEJJTiBpcyBhd2Vzb21l')
    assert(resp.status_code == 200, 'Did not return 200')
    assert(resp, 'Text request did not return response')
    assertEqual(resp.text, 'HTTPBIN is awesome', 'Incorrect text returned')
  end),

  it('makes request with auth', function(patched_wget) 
    local resp = requests.get{'https://httpbin.org/basic-auth/name/password', auth={user='name', password='password'}, verify_ssl=true}
    assert(resp.status_code == 200, 'Did not return 200')
    assert(resp:json().authenticated == true, 'Not authenticated with basic http auth')
    assert(resp:json().user == 'name', 'Did not get correct username')
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
    assertRaises(response.method..' request: '..response.status_code, function() 
      response:raise_for_status()
    end, 'Did not raise error for response')
  end)
)


run_tests()
