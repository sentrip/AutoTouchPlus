

describe('string', 
  it('startswith', function() 
     assert(('\nabc'):startswith('\n'), 'Startswith \\n')
     assert(not ('abc'):startswith('\n'), 'Not Startswith \\n')
    end),
  it('endswith', function() 
    assert(('abc\n'):endswith('\n'), 'Endswith \\n')
    assert(not ('abc'):endswith('\n'), 'Not endswith \\n')
    end),
  it('format', function() 
    local o = 'Hello {}, {} and {}'
    local x = 'Hello {:-8}, {:2}, {:3}'
    local y = 'hello {j}, i am {d}'
    local eo = 'Hello jayjay, bob and 1000'
    local ex = 'Hello k       , bob, 1000'
    local ey = 'hello john, i am djordje'
    assertEqual(o:format('jayjay', 'bob', 1000), eo, 'Bad string format')
    assertEqual(x:format('k', 'bob', 1000), ex, 'Bad string format')
    assertEqual(y:format{j='john', d='djordje'}, ey, 'Bad string format')
    assertEqual(('%s, %d'):format('hello', 100), 'hello, 100', 'Bad string format')
    end),
  it('join', function() 
    assertEqual(('\n'):join({'a', 'b'}), 'a\nb', 
      'String join table failed')
    assertEqual(('\n'):join(list{'a', 'b'}), 'a\nb', 
      'String join list failed')
    end),
  it('replace', function()  
    assertEqual(('abcba'):replace('b', 'q'), 'aqcqa', 'String replacement incorrect') 
    end),
  it('split', function()
    local s1 = 'abc'
    local s2 = 'aabbcc'
    local s3 = 'a 20 300 dddd'
    assertRequal(s1:split(), {'a', 'b', 'c'}, 'Split with no args')
    assertRequal(s1:split('b'), {'a', 'c'}, 'Split with char arg')
    assertRequal(s2:split('bb'), {'aa', 'cc'}, 'Split with string arg')
    assertRequal(s3:split(' '), {'a', '20', '300', 'dddd'}, 'Split with spaces')
    end),
  it('strip', function()
    local x = 'abacbabacabab'
    local expected = 'cbabac'
    assertEqual(x:strip('ab'), expected, 'String not stripped correctly')
    end),
  it('str_add', function() 
    assertEqual('a' + 'b', 'ab', 'String add incorrect')
    end),
  it('str_mul', function() 
    assertEqual('ab' * 2, 'abab', 'String mul incorrect') 
    end),
  it('str_pairs', function() 
    local c = 1
    local _t = {'a', 'b', 'c'}
    for i, v in pairs('abc') do 
      assertEqual(i, c, 'String pairs index incorrect')
      assertEqual(v, _t[c], 'String pairs value incorrect')
      c = c + 1 
    end
    end),
  it('str_index', function() 
    local s = 'abc'
    for i, v in pairs(string) do
      assert(Not.Nil(s[i]), 'string missing function '..i)
    end
    assertEqual(s[1], 'a', 'Positive string index failed')
    assertEqual(s[-1], 'c', 'Negative string index failed')
    end)
)
