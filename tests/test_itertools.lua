require('src/test')
require('src/builtins')
require('src/itertools')
require('src/logic')
require('src/objects')


describe("itertools",
  it('map', function ()
    local input = { 1, 2, 3, 4, 5 }
    local l = itertools.collect(itertools.map(function (x) return x + 1 end,
                             itertools.each(input)))
    for i = 1, #l do
         assertEqual(i + 1, l[i])
    end
    end),
  it('cycle', function ()
    local nextvalue = itertools.cycle(itertools.values { "foo", "bar" })
    for i = 1, 10 do
         assertEqual("foo", nextvalue())
         assertEqual("bar", nextvalue())
    end
    end),
  it('takewhile', function ()
    local data = { 1, 1, 1, 1, -1, 1, -1, 1, 1 }
    local result = itertools.collect(itertools.takewhile(function (x) return x > 0 end, itertools.values(data)))
    assertEqual(4, #result)
    for _, v in ipairs(result) do
      assertEqual(1, v)
    end
    end),
  it('filter', function ()
    local data = { 6, 1, 2, 3, 4, 5, 6 }
    local result = itertools.collect(itertools.filter(function (x) return x < 4 end, itertools.values(data)))
    assertEqual(3, #result)
    for i, v in ipairs(result) do
         assertEqual(i, v)
    end
    end),
  it('count', function ()
    local nextvalue = itertools.count()
    for i = 1, 10 do
      assertEqual(i, nextvalue())
    end
    
    nextvalue = itertools.count(10)
    for i = 10, 20 do
      assertEqual(i, nextvalue())
    end
    
    nextvalue = itertools.count(nil, 2)
    for i = 1, 10, 2 do
      assertEqual(i, nextvalue())
    end
    
    nextvalue = itertools.count(10, 5)
    for i = 10, 30, 5 do
      assertEqual(i, nextvalue())
    end
    
    nextvalue = itertools.count(10, -1)
    for i = 10, 1, -1 do
      assertEqual(i, nextvalue())
    end
    end),
  it('islice', function ()
    local function check(result, nextvalue)
      local count = 0
      for _, v in ipairs(result) do
         assertEqual(v, nextvalue())
         count = count + 1
      end
      assertEqual(count, #result)
    end

    local input = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }

    check({ 5, 6, 7, 8, 9, 10 },
          itertools.islice(itertools.values(input), 5))
    check({ 1, 2, 3, 4 },
          itertools.islice(itertools.values(input), nil, 5))
    check({ 4, 5, 6, 7 },
          itertools.islice(itertools.values(input), 4, 7))
    check({ 5 }, itertools.islice(itertools.values(input), 5, 6))
    check({}, itertools.islice(itertools.values(input), 7, 3))
    end),
  it('sorted', function ()
    local data = { 1, 45, 9, 2, -2, 42, 0, 42 }
    local sorted = itertools.collect(itertools.sorted(itertools.values(data)))
    assertEqual(#data, #sorted)
    table.sort(data)
    for i = 1, #data do
         assertEqual(data[i], sorted[i])
    end
    
    data = { 1, 45, 9, 2, -2, 42, 0, 42 }
    sorted = itertools.collect(itertools.sorted(itertools.values(data), nil, true))
    assertEqual(#data, #sorted)
    table.sort(data, function (a, b) return a >= b end)
    for i = 1, #data do
         assertEqual(data[i], sorted[i])
    end
    
    data = { { z = 1 }, { z = 0 }, { z = 42 }, { z = -1 } }
    sorted = itertools.collect(itertools.sorted(itertools.values(data),
                                  function (v) return v.z end))
    assertEqual(#data, #sorted)
    table.sort(data, function (a, b) return a.z < b.z end)
    for i = 1, #data do
         assertEqual(data[i], sorted[i])
    end
    end),
  it('can repeat values', function() 
    local finite = itertools.value(1, 3)
    local infinite = itertools.value(1)
    for i=1, 3 do
      assert(finite() == 1)
      assert(infinite() == 1)
    end
    assert(finite() == nil)
    assert(infinite() == 1)
    end)
)

run_tests()
