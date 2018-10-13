

describe('logic', 
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

  it('isType', function()
    assert(isType(true, 'boolean'), 'basic isType failed')
    assert(isType(true, 'string', 'bool'), 'multi arg isType failed')
    assert(not isType(true, 'string', 'table'), 'multi arg isType failed')
    end),
  it('is', function()
    local f = io.tmpfile()
    --truthy checks
    assert(is(true), 'boolean is failed')
    assert(is(1), 'number is failed')
    assert(is('thing'), 'string(5) is failed')
    assert(is({1,2,3}), 'table(3) is failed')
    assert(is(function() end), 'function is failed')
    assert(is(f), 'file is failed')
    --type checks
    assert(is.str(''), 'is.str failed')
    assert(is.num(0), 'is.num failed')
    assert(is.bool(true), 'is.bool failed')
    assert(is.tbl({}), 'is.tbl failed')
    assert(is.func(function() end), 'is.func failed')
    assert(is.file(f), 'is.file failed')
    assert(is.string(''), 'is.string failed')
    assert(is.number(0), 'is.number failed')
    assert(is.boolean(true), 'is.boolean failed')
    assert(is.table({}), 'is.table failed')
    assert(is.userdata(f), 'is.userdata failed')
    f:close()
    end),
  it('Not', function()
    assert(Not(nil), 'nil Not failed')
    assert(Not(0), 'number Not failed')
    assert(Not(false), 'boolean Not failed')
    assert(Not(''), 'string(0) Not failed')
    assert(Not({}), 'table(0) Not failed')
    assert(is(true) == not is.Not(true), 
      'is and is.Not did not return opposite results')
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
  it('count', function() 
    assertEqual(count(1, {1,1,2}), 2, 'Incorrect integer count')
    assertEqual(count('a', 'aab'), 2, 'Incorrect character count')    
    end),
  it('div', function()
    assertEqual(div(3, 4), 0, 'Bad floor division no remainder')
    assertEqual(div(4, 3), 1, 'Bad floor division remainder')
    end),
  it('len', function() 
    assertEqual(len({1,2,3}), 3, 'Incorrect table length') end),
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
  it('sum', function() 
    assertEqual(sum({1,2,3}), 6, 'Number sum incorrect') 
    end)
)
