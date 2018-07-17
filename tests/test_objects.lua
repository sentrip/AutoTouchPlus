

test('object tests', {
  dict_creation = function(self)
    assertNotRequal(self.dict_a, self.dict_b, 'Different dicts requal')
    assertRequal(self.dict_a, {}, 'Dict and table not requal')
    assertRequal(self.dict_b, {a=1, b=2}, 'Dict and table not requal')
    assertEqual(self.dict_a['thing'], nil, 'Unknown key does not return nil')
    end,
  dict_addition = function(self)
    assertEqual(self.dict_a + self.dict_b, self.dict_b, 'Added dicts not equal')
    assertEqual(self.dict_b + {b=9}, dict{a=1, b=9}, 'Added dicts not equal')
    end,
  dict_equality = function(self)
    self.dict_a:update(self.dict_b)
    assertEqual(self.dict_a, self.dict_b, 'Dicts not equal')
    assertRequal(self.dict_a, {a=1, b=2}, 'Dict and table not requal')
    assertNotEqual(self.dict_a, {a=1, b=2}, 'Dict and table equal')
    end,
  dict_for = function(self)
    local expected
    local expected1 = {'a', 'b'}
    local expected2 = {'b', 'a'}
    local i = 1
    local st = false
    for k in self.dict_b() do 
      if not st then
        st = true
        if k == 'a' then expected = expected1
        else expected = expected2 end
      end
      assertEqual(k, expected[i], 'incorrect key returned in for loop')
      i = i + 1
    end
    end,
  dict_pairs = function(self)
    local expected = {a=1, b=2}
    for i, v in pairs(self.dict_b) do
      assertEqual(v, expected[i], 'Pairs returns incorrect result')
    end
    end,
  dict_clear = function(self)
    self.dict_a:clear()
    self.dict_b:clear()
    assertEqual(self.dict_a, self.dict_b, 'Dict not empty after clear')
    end,
  dict_contains = function(self)
    assert(not self.dict_b:contains('q'), 'Dict contains unknown key')
    assert(self.dict_b:contains('a'), 'Dict does not contain key')
    end,
  dict_get = function(self)
    assertEqual(self.dict_b:get('a'), 1, 'Dict get incorrect for known key')
    assertEqual(self.dict_b:get('q'), nil, 'Dict get incorrect for unknown key')
    assertEqual(self.dict_b:get('a', 5), 1, 'Dict get incorrect for known key with default')
    assertEqual(self.dict_b:get('q', 5), 5, 'Dict get incorrect for unknown key with default')
    end,
  dict_keys = function(self)
    assert(Not(self.dict_a:keys(), 'Incorrect dict keys'))
    for i, v in pairs({'a', 'b'}) do
      assert(isin(v, self.dict_b:keys()), 'Dict key not found')
    end
    end,
  dict_set = function(self)
    self.dict_b:set('b', 5)
    assertEqual(self.dict_b['b'], 5, 'Incorrect value after set')
    end, 
  dict_update = function(self)
    self.dict_a:update(self.dict_b)
    assertEqual(self.dict_a, self.dict_b, 'Dicts not equal after update')
    end,
  dict_values = function(self)
    assert(Not(self.dict_a:values(), 'Incorrect dict values'))
    for i, v in pairs({1, 2}) do
      assert(isin(v, self.dict_b:values()), 'Dict value not found')
    end
    end,
  list_creation = function(self)
    assertNotEqual(self.list_a, self.list_b, 'Different lists are equal')
    assertNotEqual(self.list_a, self.list_c, 'Different lists are equal')
    assertNotEqual(self.list_b, self.list_c, 'Different lists are equal')
    assertEqual(self.list_a, list(), 'List and new list not equal')
    assertEqual(self.list_b, list{1,2,3}, 'List and new list not equal')
    assertEqual(self.list_c, list{1,{2, 3}}, 'List and new list not equal')
    assertRequal(self.list_a, {}, 'List and table not requal')
    assertRequal(self.list_b, {1,2,3}, 'List and table not requal')
    assertRequal(self.list_c, {1,{2, 3}}, 'List and table not requal')
    end,
  list_addition = function(self)
    assertRequal(self.list_a + self.list_b, self.list_b, 'Added lists returned incorrect list')
    assertRequal(self.list_b + list{5}, {1,2,3,5}, 'Added lists returned incorrect list')
    assertRequal(list{5} + self.list_b, {5,1,2,3}, 'Added lists returned incorrect list')
    end,
  list_equality = function(self)
    assertEqual(self.list_a, list(), 'Lists not equal')
    assertRequal(self.list_a, {}, 'List not requals table')
    assertNotEqual(self.list_a, {}, 'List equals table')
    assertRequal(self.list_b, {1,2,3}, 'List not requals table')
    assertEqual(self.list_b, list{1,2,3}, 'Lists not equal')
    assertNotEqual(self.list_b, {1,2,3}, 'List equals table')
    end,
  list_for = function(self)
    local count = 0
    local expected = {1, 2, 3}
    for v in self.list_b() do 
      count = count + 1
      assertEqual(v, expected[count], 'Unknown element returned')
    end
    assertEqual(count, len(self.list_b), 'Incorrect number of elements')
    end,
  list_indexing = function(self)
    assertEqual(self.list_b[2], 2, 'Positive index returned incorrect result')
    assertEqual(self.list_b[-2], 2, 'Negative index returned incorrect result')
    end,  
  list_pairs = function(self)
    local expected = {1,2,3}
    for i, v in pairs(self.list_b) do
      assertEqual(v, expected[i], 'Incorrect item returned in list pairs')
    end
    end,
  list_slicing = function(self)
    assertEqual(self.list_b(1), self.list_b, 'list slice failed')
    assertEqual(self.list_b(1, 2), list{1,2}, 'list slice failed')
    assertEqual(self.list_b(1, 3), self.list_b, 'list slice failed')
    assertEqual(self.list_b(1, -2), list{1,2}, 'list slice failed')
    assertEqual(self.list_b(3, 1, -1), reversed(self.list_b), 'list slice failed')
    assertEqual(self.list_b{2, -1, 1}, list{2, 3, 1}, 'list slice failed')
    end,
  list_append = function(self)
    self.list_a:append(5)
    assertEqual(self.list_a, list{5}, 'List and new list not equal')
    assertEqual(self.list_b, list{1,2,3}, 'Other lists changed after append')
    assertEqual(self.list_c, list{1,{2,3}}, 'Other lists changed after append')
    assertRequal(self.list_a, {5}, 'List and table not requal')
    assertRequal(self.list_b, {1,2,3}, 'Other lists changed after append')
    assertRequal(self.list_c, {1,{2,3}}, 'Other lists changed after append')
    end,
  list_contains = function(self)
    assert(self.list_b:contains(1), 'List does not contain number')
    assert(self.list_c:contains({2,3}), 'List does not contain table')
    end,
  list_extend = function(self)
    self.list_a:extend{1,2}
    assertEqual(self.list_a, list{1,2}, 'List and new list not equal')
    assertRequal(self.list_a, {1,2}, 'List and table not requal')
    end,
  list_index = function(self)
    assertEqual(self.list_b:index(1), 1, 'Incorrect list index')
    end,
  list_insert = function(self)
    self.list_b:insert(2, 5)
    assertEqual(self.list_b, list{1,5,2,3}, 'List and new list not equal')
    assertRequal(self.list_b, {1,5,2,3}, 'List and table not requal')
    end,
  list_pop = function(self)
    assertEqual(self.list_b:pop(2), 2, 'Incorrect value popped from list')
    assertEqual(self.list_b, list{1,3}, 'List and new list not equal')
    assertRequal(self.list_b, {1,3}, 'List and table not requal')
    end,
  
  
  set_creation = function(self)
    assertNotRequal(self.set_a, self.set_b, 'Different sets requal')
    assertRequal(self.set_a, {}, 'Set and table not requal')
    assertRequal(self.set_b, set{1,2,3}, 'Same sets not requal')
    end,
  set_equality = function(self)
    assertEqual(self.set_a, set(), 'Empty sets not equal')
    assertEqual(self.set_b, set{1, 2, 3}, 'Number sets not equal')
    assertEqual(self.set_c, set{'a', 'b', 'c'}, 'String sets not equal')
    assertNotEqual(self.set_b, {1, 2, 3}, 'Set and table equal')
    assertRequal(self.set_b, {1, 2, 3}, 'Set and table not requal')
    end,
  set_for = function(self)
    local count = 0
    for v in self.set_b() do 
      count = count + 1
      assert(isin(v, self.set_b), 'Unknown element returned')
    end
    assertEqual(count, len(self.set_b), 'Incorrect number of elements')
    end,
  set_pairs = function(self)
    for _, s in pairs({self.set_b, self.set_c}) do
      for k, v in pairs(s) do
        assertEqual(k, str(hash(v)), 'Set key is not hash of value')
      end
    end
    end,
  set_add = function(self)
    self.set_a:add(1)
    assertEqual(self.set_a, set{1}, 'Did not add element to set')
    assertEqual(len(self.set_a), 1, 'Incorrect number of elements after add')
    self.set_a:add(1)
    assertEqual(self.set_a, set{1}, 'Added already existing element to set')
    assertEqual(len(self.set_a), 1, 'Incorrect number of elements after add')
    self.set_a:add(2)
    self.set_a:add(3)
    assertEqual(self.set_a, self.set_b, 'Did not add elements to set')
    end,
  set_clear = function(self)
    self.set_b:clear()
    assertEqual(self.set_a, self.set_b, 'Did not clear set')
    self.set_c:clear()
    assertEqual(self.set_a, self.set_c, 'Did not clear set')
    end,
  set_contains = function(self)
    assert(self.set_b:contains(1), 'Set does not contain number element')
    assert(self.set_c:contains('b'), 'Set does not contain string element')
    end,
  set_difference = function(self)
    assertEqual(self.set_b - set{1}, set{2, 3}, 'Set subtraction with number items failed')
    assertEqual(self.set_c - set{'a', 'c'}, set{'b'}, 'Set subtraction with string items failed')
    end,
  set_pop = function(self)
    assertEqual(self.set_b:pop(1), 1, 'Did not return correct number value from pop')
    assertEqual(self.set_b, set{2, 3}, 'Did not number value from set after pop')
    assertEqual(self.set_c:pop('c'), 'c', 'Did not return correct number value from pop')
    assertEqual(self.set_c, set{'a', 'b'}, 'Did not number value from set after pop')
    end,
  set_remove = function(self)
    self.set_b:remove(2)
    assertEqual(self.set_b, set{1, 3}, 'Did not remove number item from set')
    self.set_c:remove('b')
    assertEqual(self.set_c, set{'a', 'c'}, 'Did not remove number item from set')
    end,
  set_update = function(self)
    self.set_a:update(self.set_b)
    assertEqual(self.set_a, self.set_b, 'Update of empty set incorrect')
    assertEqual(self.set_b + self.set_c, set{'a', 'b', 'c', 1, 2, 3}, 'Addition of filled sets incorrect')
    end,
  set_values = function(self)
    for k, v in pairs(self.set_a:values()) do
      assert(self.set_a:contains(v), 'Set does not contain number element in values')
    end
    for k, v in pairs(self.set_b:values()) do
      assert(self.set_b:contains(v), 'Set does not contain string element in values')
    end
    end,
  },
  function(self) 
    self.dict_a = dict()
    self.dict_b = dict{a=1, b=2}
    
    self.list_a =  list()
    self.list_b = list{1,2,3}
    self.list_c = list{1, {2,3}}
    
    
    self.set_a =  set()
    self.set_b = set{1,2,3}
    self.set_c = set{'a', 'b', 'c'}
  end)


