require('src/test')
require('src/core')
require('src/contextlib')
require('src/objects')
require('src/logic')
require('src/string')
require('src/system')
require('src/requests')
require('src/json')


-- TODO: fixture to mock wget

fixture('response', function() 
  local resp = Response({url='http://example.com', method='GET'})
  resp.status_code = 400
  resp.text = '{\n\t"a":"1",\n\t"b":"2"\n}'
  return resp
end)


describe('requests',

  it('gets json', function()
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
  
  it('posts json', function()
    local resp = requests.post{'http://httpbin.org/post', data={amount=10}}
    assert(resp.status_code == 200, 'Did not return 200')
    assertEqual(str(resp:json().form.amount), '10', 'Did not post correct data')
  end),
  
  it('gets text', function()
    local resp = requests.get('https://httpbin.org/base64/SFRUUEJJTiBpcyBhd2Vzb21l')
    assert(resp.status_code == 200, 'Did not return 200')
    assert(resp, 'Text request did not return response')
    assertEqual(resp.text, 'HTTPBIN is awesome', 'Incorrect text returned')
  end),

  it('makes request with auth', function() 
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
