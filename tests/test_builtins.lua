require('src/test')
require('src/core')
require('src/builtins')
require('src/contextlib')
require('src/itertools')
require('src/logic')
require('src/objects')
require('src/string')
require('src/system')


describe('builtins',

  it('all', function()
    assert(all({true, true, true}), 'All - table of booleans')
    assert(all(list{true, true, true}), 'All - list of booleans')
    assert(all({true, false, true}) == false, 'All with false - table of booleans')
    assert(all(list{true, false, true}) == false, 'All with false - list of booleans')
    assert(all({1,2,3}), 'All - table of numbers')
    assert(all(list{1,2,3}), 'All - list of numbers')
    assert(all({1,0,3}) == false, 'All with false - table of numbers')
    assert(all(set{1,0,3}) == false, 'All with false - set of numbers')
  end),

  it('any', function()
    assert(any({true, false, true}), 'Any - table of booleans')
    assert(any(list{true, false, true}), 'Any - list of booleans')
    assert(any({false, false, false}) == false, 'Any with false - table of booleans')
    assert(any(list{false, false, false}) == false, 'Any with false - list of booleans')
    assert(any({1,2,3}), 'Any - table of numbers')
    assert(any(list{1,2,3}), 'Any - list of numbers')
    assert(any({0,0,0}) == false, 'Any with false - table of numbers')
    assert(any(list{0, 0, 0}) == false, 'Any with false - list of numbers')
  end),

  it('count', function() 
    assertEqual(count(1, {1,1,2}), 2, 'Incorrect integer count')
    assertEqual(count('a', 'aab'), 2, 'Incorrect character count')    
  end),

  it('div', function()
    assertEqual(div(3, 4), 0, 'Bad floor division no remainder')
    assertEqual(div(4, 3), 1, 'Bad floor division remainder')
  end),

  it('eval', function()
    assertEqual(eval('return 1 + 1'), 2, 'eval 1 + 1 failed')
    assertRaises('Syntax', function() eval('x =') end, 'eval of syntax error did not fail')
  end),

  it('hash', function()
    local h
    local values = {}
    for i=1, 128 do 
      h = hash(string.char(i))
      assert(isnotin(h, values), 'Hash collision in first 128 bits')
      values[#values + 1] = h
    end
    for i=0, 100 do
      h = hash(i - 50)
      assert(isnotin(h, values), 'Hash collision in first 50 +/- numbers')
      values[#values + 1] = h
    end
    assert((hash(function() end)))
  end),

  it('iter', function() 
    local c = 1
    for i in iter({1,2,3}) do
      assert(i == c, 'Iter did not yield correct value')
      c = c + 1
    end
    c = 1
    for i in iter(iter(iter(iter({1,2,3})))) do
      assert(i == c, 'Nested iter did not yield correct value')
      c = c + 1
    end
  end),

  it('len', function() 
    assertEqual(len({1,2,3}), 3, 'Incorrect table length') 
  end),

  it('max', function()
    local l, s, t = list{2,1,3}, set{3,2,1}, {3,1,2}
    assertEqual(math.max(unpack(t)), max(t), 'table max not same as math.max')
    assertEqual(math.max(unpack(t)), max(l), 'list max not same as math.max')
    assertEqual(math.max(unpack(t)), max(s), 'set max not same as math.max')
  end),

  it('min', function()
    local l, s, t = list{2,1,3}, set{3,2,1}, {3,1,2}
    assertEqual(math.min(unpack(t)), min(t), 'table min not same as math.min')
    assertEqual(math.min(unpack(t)), min(l), 'list min not same as math.min')
    assertEqual(math.min(unpack(t)), min(s), 'set min not same as math.min')
  end),

  it('range', function() 
    assert(requal(range(5), {1, 2, 3, 4, 5}), 'Range incorrect')
    assert(requal(range(0, 2), {0, 1, 2}), 'Range with start incorrect')
    assert(requal(range(0, 9, 2), {0, 2, 4, 6, 8}), 'Range incorrect')
    assert(requal(range(5, 1, -1), {5, 4, 3, 2, 1}), 'Reversed range incorrect')
  end),

  it('requal', function()
    assert(requal({'a'}, {'a'}), 'Basic tables not requal')
    assert(requal(
        {a = {b = {1, 2}, c = {3, 4}}}, 
        {a = {b = {1, 2}, c = {3, 4}}}),  'Nested tables not requal')
    assertEqual(requal(
        {a = {b = {1, 2}, c = {3, 4}, d = {5, 6}}}, 
        {a = {g = {1, 2}, c = {5, 4}}}), false, 'Different nested tables requal')
  end),

  it('reversed', function()
    local l, s = {1, 2, 3}, 'abc'
    local e1, e2 = {3, 2, 1}, {'c', 'b', 'a'}
    for i, v in pairs(reversed(l)) do 
      assertEqual(e1[i], v, 'Did not reverse table correctly')
    end
    for i, v in pairs(reversed(s)) do 
      assertEqual(e2[i], v, 'Did not reverse string correctly')
    end
  end),

  it('round', function()
    assertEqual(round(0.12, 1), 0.1, 'Decimal rounding incorrect')
    assertEqual(round(0.15, 1), 0.2, 'Decimal rounding incorrect')
    assertEqual(round(1.15, 0), 1, 'Number rounding incorrect')
    assertEqual(round(1.55, 0), 2, 'Number rounding incorrect')
    assertEqual(round(12.15, -1), 10, '10s rounding incorrect')
    assertEqual(round(15.15, -1), 20, '10s rounding incorrect')
  end),

  it('sign', function() 
    assertEqual(sign(10.2), 1, 'Positive sign incorrect')
    assertEqual(sign(-0.1), -1, 'Negative sign incorrect')
    assertEqual(sign(0), 1, 'Zero sign incorrect')
  end),

  it('sorted', function()
    --basic sort
    local a, b, c = {3, 1, 2}, {'c', 'a', 'b'}, {3, 1, 2}
    local ea, eb, ec = {1,2,3}, {'a','b','c'}, {3, 2, 1}
    for i, v in pairs(sorted(a)) do
      assertEqual(v, ea[i], 'Integer sorting failed')
    end
    for i, v in pairs(sorted(list(b))) do
      assertEqual(v, eb[i], 'String sorting failed')
    end
    for i, v in pairs(sorted(list(c), true)) do
      assertEqual(v, ec[i], 'Integer reverse sorting failed')
    end
    --key based sort
    local a2, e2 = {list{'a', 2}, list{'b', 1}}, {list{'b', 1}, list{'a', 2}}
    for i, v in pairs(sorted(list(a2), function(m) return m[2] end)) do
      assertEqual(v, e2[i], 'String sorting failed')
    end
  end),

  it('sum', function() 
    assertEqual(sum({1,2,3}), 6, 'Number sum incorrect') 
  end)

)

run_tests()
