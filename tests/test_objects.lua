require('src/test')
require('src/core')
require('src/contextlib')
require('src/objects')
require('src/logic')
require('src/string')
require('src/system')


fixture('dict_a', function() return dict() end)
fixture('dict_b', function() return dict{a=1, b=2} end)

fixture('list_a', function() return list() end)
fixture('list_b', function() return list{1,2,3} end)
fixture('list_c', function() return list{1, {2,3}} end)

fixture('set_a', function() return set() end)
fixture('set_b', function() return set{1,2,3} end)
fixture('set_c', function() return set{'a', 'b', 'c'} end)


describe('objects - dict',
  it('creation', function(dict_a, dict_b)
    assertNotRequal(dict_a, dict_b, 'Different dicts requal')
    assertRequal(dict_a, {}, 'Dict and table not requal')
    assertRequal(dict_b, {a=1, b=2}, 'Dict and table not requal')
    assertEqual(dict_a['thing'], nil, 'Unknown key does not return nil')
    end),
  it('addition', function(dict_a, dict_b)
    assertEqual(dict_a + dict_b, dict_b, 'Added dicts not equal')
    assertEqual(dict_b + {b=9}, dict{a=1, b=9}, 'Added dicts not equal')
    end),
  it('equality', function(dict_a, dict_b)
    dict_a:update(dict_b)
    assertEqual(dict_a, dict_b, 'Dicts not equal')
    assertRequal(dict_a, {a=1, b=2}, 'Dict and table not requal')
    assertNotEqual(dict_a, {a=1, b=2}, 'Dict and table equal')
    end),
  it('for', function(dict_a, dict_b)
    local expected
    local expected1 = {'a', 'b'}
    local expected2 = {'b', 'a'}
    local i = 1
    local st = false
    for k in dict_b() do 
      if not st then
        st = true
        if k == 'a' then expected = expected1
        else expected = expected2 end
      end
      assertEqual(k, expected[i], 'incorrect key returned in for loop')
      i = i + 1
    end
    end),
  it('pairs', function(dict_a, dict_b)
    local expected = {a=1, b=2}
    for i, v in pairs(dict_b) do
      assertEqual(v, expected[i], 'Pairs returns incorrect result')
    end
    end),
  it('clear', function(dict_a, dict_b)
    dict_a:clear()
    dict_b:clear()
    assertEqual(dict_a, dict_b, 'Dict not empty after clear')
    end),
  it('contains', function(dict_a, dict_b)
    assert(not dict_b:contains('q'), 'Dict contains unknown key')
    assert(dict_b:contains('a'), 'Dict does not contain key')
    end),
  it('get', function(dict_a, dict_b)
    assertEqual(dict_b:get('a'), 1, 'Dict get incorrect for known key')
    assertEqual(dict_b:get('q'), nil, 'Dict get incorrect for unknown key')
    assertEqual(dict_b:get('a', 5), 1, 'Dict get incorrect for known key with default')
    assertEqual(dict_b:get('q', 5), 5, 'Dict get incorrect for unknown key with default')
    end),
  it('keys', function(dict_a, dict_b)
    assert(Not(dict_a:keys(), 'Incorrect dict keys'))
    for i, v in pairs({'a', 'b'}) do
      assert(isin(v, dict_b:keys()), 'Dict key not found')
    end
    end),
  it('set', function(dict_a, dict_b)
    dict_b:set('b', 5)
    assertEqual(dict_b['b'], 5, 'Incorrect value after set')
    end), 
  it('update', function(dict_a, dict_b)
    dict_a:update(dict_b)
    assertEqual(dict_a, dict_b, 'Dicts not equal after update')
    end),
  it('values', function(dict_a, dict_b)
    assert(Not(dict_a:values(), 'Incorrect dict values'))
    for i, v in pairs({1, 2}) do
      assert(isin(v, dict_b:values()), 'Dict value not found')
    end
    end)
)


describe('objects - list',
  it('creation', function(list_a, list_b, list_c)
    assertNotEqual(list_a, list_b, 'Different lists are equal')
    assertNotEqual(list_a, list_c, 'Different lists are equal')
    assertNotEqual(list_b, list_c, 'Different lists are equal')
    assertEqual(list_a, list(), 'List and new list not equal')
    assertEqual(list_b, list{1,2,3}, 'List and new list not equal')
    assertEqual(list_c, list{1,{2, 3}}, 'List and new list not equal')
    assertRequal(list_a, {}, 'List and table not requal')
    assertRequal(list_b, {1,2,3}, 'List and table not requal')
    assertRequal(list_c, {1,{2, 3}}, 'List and table not requal')
    end),
  it('addition', function(list_a, list_b, list_c)
    assertRequal(list_a + list_b, list_b, 'Added lists returned incorrect list')
    assertRequal(list_b + list{5}, {1,2,3,5}, 'Added lists returned incorrect list')
    assertRequal(list{5} + list_b, {5,1,2,3}, 'Added lists returned incorrect list')
    end),
  it('equality', function(list_a, list_b, list_c)
    assertEqual(list_a, list(), 'Lists not equal')
    assertRequal(list_a, {}, 'List not requals table')
    assertNotEqual(list_a, {}, 'List equals table')
    assertRequal(list_b, {1,2,3}, 'List not requals table')
    assertEqual(list_b, list{1,2,3}, 'Lists not equal')
    assertNotEqual(list_b, {1,2,3}, 'List equals table')
    end),
  it('for', function(list_a, list_b, list_c)
    local count = 0
    local expected = {1, 2, 3}
    for v in list_b() do 
      count = count + 1
      assertEqual(v, expected[count], 'Unknown element returned')
    end
    assertEqual(count, len(list_b), 'Incorrect number of elements')
    end),
  it('indexing', function(list_a, list_b, list_c)
    assertEqual(list_b[2], 2, 'Positive index returned incorrect result')
    assertEqual(list_b[-2], 2, 'Negative index returned incorrect result')
    end),  
  it('pairs', function(list_a, list_b, list_c)
    local expected = {1,2,3}
    for i, v in pairs(list_b) do
      assertEqual(v, expected[i], 'Incorrect item returned in list pairs')
    end
    end),
  it('slicing', function(list_a, list_b, list_c)
    assertEqual(list_b(1), list_b, 'list slice failed')
    assertEqual(list_b(1, 2), list{1,2}, 'list slice failed')
    assertEqual(list_b(1, 3), list_b, 'list slice failed')
    assertEqual(list_b(1, -2), list{1,2}, 'list slice failed')
    assertEqual(list_b(3, 1, -1), reversed(list_b), 'list slice failed')
    assertEqual(list_b{2, -1, 1}, list{2, 3, 1}, 'list slice failed')
    end),
  it('append', function(list_a, list_b, list_c)
    list_a:append(5)
    assertEqual(list_a, list{5}, 'List and new list not equal')
    assertEqual(list_b, list{1,2,3}, 'Other lists changed after append')
    assertEqual(list_c, list{1,{2,3}}, 'Other lists changed after append')
    assertRequal(list_a, {5}, 'List and table not requal')
    assertRequal(list_b, {1,2,3}, 'Other lists changed after append')
    assertRequal(list_c, {1,{2,3}}, 'Other lists changed after append')
    end),
  it('contains', function(list_a, list_b, list_c)
    assert(list_b:contains(1), 'List does not contain number')
    assert(list_c:contains({2,3}), 'List does not contain table')
    end),
  it('extend', function(list_a, list_b, list_c)
    list_a:extend{1,2}
    assertEqual(list_a, list{1,2}, 'List and new list not equal')
    assertRequal(list_a, {1,2}, 'List and table not requal')
    end),
  it('index', function(list_a, list_b, list_c)
    assertEqual(list_b:index(1), 1, 'Incorrect list index')
    end),
  it('insert', function(list_a, list_b, list_c)
    list_b:insert(2, 5)
    assertEqual(list_b, list{1,5,2,3}, 'List and new list not equal')
    assertRequal(list_b, {1,5,2,3}, 'List and table not requal')
    end),
  it('pop', function(list_a, list_b, list_c)
    assertEqual(list_b:pop(2), 2, 'Incorrect value popped from list')
    assertEqual(list_b, list{1,3}, 'List and new list not equal')
    assertRequal(list_b, {1,3}, 'List and table not requal')
    end)
)


describe('objects - set', 
  it('creation', function(set_a, set_b, set_c)
    assertNotRequal(set_a, set_b, 'Different sets requal')
    assertRequal(set_a, {}, 'Set and table not requal')
    assertRequal(set_b, set{1,2,3}, 'Same sets not requal')
    end),
  it('equality', function(set_a, set_b, set_c)
    assertEqual(set_a, set(), 'Empty sets not equal')
    assertEqual(set_b, set{1, 2, 3}, 'Number sets not equal')
    assertEqual(set_c, set{'a', 'b', 'c'}, 'String sets not equal')
    assertNotEqual(set_b, {1, 2, 3}, 'Set and table equal')
    assertRequal(set_b, {1, 2, 3}, 'Set and table not requal')
    end),
  it('for', function(set_a, set_b, set_c)
    local count = 0
    for v in set_b() do 
      count = count + 1
      assert(isin(v, set_b), 'Unknown element returned')
    end
    assertEqual(count, len(set_b), 'Incorrect number of elements')
    end),
  it('pairs', function(set_a, set_b, set_c)
    for _, s in pairs({set_b, set_c}) do
      for k, v in pairs(s) do
        assertEqual(k, str(hash(v)), 'Set key is not hash of value')
      end
    end
    end),
  it('add', function(set_a, set_b, set_c)
    set_a:add(1)
    assertEqual(set_a, set{1}, 'Did not add element to set')
    assertEqual(len(set_a), 1, 'Incorrect number of elements after add')
    set_a:add(1)
    assertEqual(set_a, set{1}, 'Added already existing element to set')
    assertEqual(len(set_a), 1, 'Incorrect number of elements after add')
    set_a:add(2)
    set_a:add(3)
    assertEqual(set_a, set_b, 'Did not add elements to set')
    end),
  it('clear', function(set_a, set_b, set_c)
    set_b:clear()
    assertEqual(set_a, set_b, 'Did not clear set')
    set_c:clear()
    assertEqual(set_a, set_c, 'Did not clear set')
    end),
  it('contains', function(set_a, set_b, set_c)
    assert(set_b:contains(1), 'Set does not contain number element')
    assert(set_c:contains('b'), 'Set does not contain string element')
    end),
  it('difference', function(set_a, set_b, set_c)
    assertEqual(set_b - set{1}, set{2, 3}, 'Set subtraction with number items failed')
    assertEqual(set_c - set{'a', 'c'}, set{'b'}, 'Set subtraction with string items failed')
    end),
  it('pop', function(set_a, set_b, set_c)
    assertEqual(set_b:pop(1), 1, 'Did not return correct number value from pop')
    assertEqual(set_b, set{2, 3}, 'Did not number value from set after pop')
    assertEqual(set_c:pop('c'), 'c', 'Did not return correct number value from pop')
    assertEqual(set_c, set{'a', 'b'}, 'Did not number value from set after pop')
    end),
  it('remove', function(set_a, set_b, set_c)
    set_b:remove(2)
    assertEqual(set_b, set{1, 3}, 'Did not remove number item from set')
    set_c:remove('b')
    assertEqual(set_c, set{'a', 'c'}, 'Did not remove number item from set')
    end),
  it('update', function(set_a, set_b, set_c)
    set_a:update(set_b)
    assertEqual(set_a, set_b, 'Update of empty set incorrect')
    assertEqual(set_b + set_c, set{'a', 'b', 'c', 1, 2, 3}, 'Addition of filled sets incorrect')
    end),
  it('values', function(set_a, set_b, set_c)
    for k, v in pairs(set_a:values()) do
      assert(set_a:contains(v), 'Set does not contain number element in values')
    end
    for k, v in pairs(set_b:values()) do
      assert(set_b:contains(v), 'Set does not contain string element in values')
    end
    end)
)


run_tests()
