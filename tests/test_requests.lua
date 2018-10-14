require('src/test')
require('src/core')
require('src/contextlib')
require('src/objects')
require('src/logic')
require('src/string')
require('src/system')
require('src/requests')
require('src/json')


describe('requests',
  it('gets json', function()
    local url = 'http://httpbin.org/get'
    local resp = requests.get(url)
    assert(resp, 'Json request did not return response')
    local j = resp:json()
    assert(j.headers, 'Incorrect json returned')
    assert(j.origin, 'Incorrect json returned')
    assertEqual(j.url, url, 'Incorrect json returned')
    end),
  it('posts json', function()
    local resp = requests.post{'http://httpbin.org/post', data={amount=10}}
    assertEqual(str(resp:json().form.amount), '10', 'Did not post correct data')
    end),
  it('gets text', function()
    local resp = requests.get('https://httpbin.org/base64/SFRUUEJJTiBpcyBhd2Vzb21l')
    assert(resp, 'Text request did not return response')
    assertEqual(resp.text, 'HTTPBIN is awesome', 'Incorrect text returned')
    end)
)
-- TODO: failing request test


run_tests()
