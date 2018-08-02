


test('navigation tests', {
  tree_root_nagivation = function()
    local l = list()
    local function f(v) return function() l:append({'fw', v}) end end
    local function b(v) return function() l:append({'bw', v}) end end
    local t = TransitionTree()
    t:add('left', f('left'), b('root'))
    t:add('mid', f('mid'), b('root'))
    t:add('right', f('right'), b('root'))

    t['left']:add('a', f('a'), b('left'))
    t['left']:add('b', f('b'), b('left'))

    t['mid']:add('c', f('c'), b('mid'))
    t['mid']:add('d', f('d'), b('mid'))

    t['right']:add('e', f('e'), b('right'))
    t['right']:add('f', f('f'), b('right'))
    t:navigate('a', 'f')
    local ea = {'bw', 'bw', 'fw', 'fw'}
    local en = {'left', 'root', 'right', 'f'}
    for i, v in pairs(ea) do
      assertEqual(l[i][1], ea[i], 'Did not navigate in correct direction')
      assertEqual(l[i][2], en[i], 'Did not navigate to correct node')
    end
  end,
  
  tree_lca_nagivation = function()
    local l = list()
    local function f(v) return function() l:append({'fw', v}) end end
    local function b(v) return function() l:append({'bw', v}) end end
    local t = TransitionTree()
    t:add('left', f('left'), b('root'))
    t:add('mid', f('mid'), b('root'))
    t:add('right', f('right'), b('root'))

    t['left']:add('a', f('a'), b('left'))
    t['left']:add('b', f('b'), b('left'))

    t['mid']:add('c', f('c'), b('mid'))
    t['mid']:add('d', f('d'), b('mid'))

    t['right']:add('e', f('e'), b('right'))
    t['right']:add('f', f('f'), b('right'))
    t:navigate('a', 'b')
    local ea = {'bw', 'fw'}
    local en = {'left', 'b'}
    for i, v in pairs(ea) do
      assertEqual(l[i][1], ea[i], 'Did not navigate in correct direction')
      assertEqual(l[i][2], en[i], 'Did not navigate to correct node')
    end
  end,

})

