require('src/test')

local stdout = ''
io.write = function(s) stdout = stdout..s end


function _reset_stdout_and_run_tests(func)
  stdout = ''
  func()
  run_tests()
end 

-- test definition
_reset_stdout_and_run_tests(function()
  describe('Basic', 
    it('can define test', function() 
      io.popen('sleep 0.01'):close()
    end)
  )
end)
assert(stdout:match('1 passed in 0%.[0-9][1-9]'), 'Basic tests did not pass')
assert(stdout:match('%.\n'), 'Incorrect test results')



-- fixture definition
_reset_stdout_and_run_tests(function() 
  local total_func = 0
  local total_group = 0
  local total_module = 0

  fixture('increment_func', function()
      total_func = total_func + 1
      return total_func
  end)
  
  fixture('increment_group', 'group', function()
    total_group = total_group + 1
    return total_group
  end)
  
  fixture('increment_module', 'module', function()
    total_module = total_module + 1
    return total_module
  end)

  describe('Fixtures', 
    it('can use fixture', function(increment_func)
      assert(increment_func == 1, 'Fixture value not correct')
    end
    ),
    it('creates new fixtures', function(increment_func)
      assert(increment_func == 2, 'Fixture value not correct')
    end
    ),
    it('can use multiple fixtures', function(increment_func, increment_group, increment_module)
      assert(increment_func == 3, 'Fixture value not correct')
      assert(increment_group == 1, 'Fixture value not correct')
      assert(increment_module == 1, 'Fixture value not correct')
    end
    )
  )
  describe('Fixture scope', 
    it('creates fixtures according to scope', function(increment_func, increment_group, increment_module)
      assert(increment_func == 4, 'Fixture value not correct')
      assert(increment_group == 2, 'Fixture value not correct')
      assert(increment_module == 1, 'Fixture value not correct')
    end
    )
  )

end)
assert(stdout:match('4 passed in'), 'Fixture tests did not pass')
assert(stdout:match('%....\n'), 'Incorrect test results')



--- fixture parametrization
_reset_stdout_and_run_tests(function()

  fixture('first', function()
    return 1
  end)

  fixture('second', function(first)
    return first + 1
  end)

  describe('Fixture parametrization', 
    it('can use fixtures that use other fixtures', function(second) 
      assert(second == 2)
    end)
  )
end)
assert(stdout:match('1 passed in'), 'Fixture parametrization tests did not pass')



--- teardown
local expected_stv = {'begin', 'test', 'end', 'begin', 'test', 'end', 'direct', 'test', 'direct', 'end_module'}
local setup_teardown_values = {}
_reset_stdout_and_run_tests(function()

  fixture('values', function(request)
    table.insert(setup_teardown_values, 'begin')
    request.addfinalizer(function() table.insert(setup_teardown_values, 'end') end)
    return setup_teardown_values
  end)

  fixture('values_module', 'module', function(request)
    request.addfinalizer(function() table.insert(setup_teardown_values, 'end_module') end)
    return setup_teardown_values
  end)

  describe('Fixture parametrization', 
    it('can use scoped fixtures with teardown', function(values_module) 
    end),  
    it('can use fixtures that use other fixtures', function(values) 
      table.insert(values, 'test')
    end),
    it('can add finalizers in test directly', function(values, request) 
      table.insert(setup_teardown_values, 'test')
      request.addfinalizer(function() table.insert(setup_teardown_values, 'direct') end)
    end),
    parametrize('val', {1},
    it('can add finalizers in parametrized test directly', function(val, request) 
      table.insert(setup_teardown_values, 'test')
      request.addfinalizer(function() table.insert(setup_teardown_values, 'direct') end)
    end)
    )
  )
end)
assert(stdout:match('4 passed in'), 'Fixture teardown tests did not pass')
assert(#setup_teardown_values == #expected_stv)
for k, v in pairs(setup_teardown_values) do assert(v == expected_stv[k], 'Fixture setup teardown order is incorrect') end



--- monkeypatch
local object_to_patch  = {value = 1}
function patchable_function(value)
  return value
end
function patchable_function_module(value)
  return value
end
_reset_stdout_and_run_tests(function()
  
  fixture('patched_object', function(monkeypatch) 
    monkeypatch.setattr(object_to_patch, 'value', 2)
  end)
  
  fixture('patched_global', function(monkeypatch) 
    monkeypatch.setattr('patchable_function', function(v) return v * 2 end)
  end)
  
  fixture('patched_global_module', 'module', function(monkeypatch) 
    monkeypatch.setattr('patchable_function_module', function(v) return v * 3 end)
  end)

  describe('Monkeypatch', 
    it('can patch global', function(patched_global, patched_global_module) 
      assert(patchable_function(1) == 2)
      assert(patchable_function_module(1) == 3)
    end),
    it('can patch object', function(patched_object) 
      assert(object_to_patch.value == 2)
    end),
    it('can patch according to scope', function() 
      assert(patchable_function_module(1) == 3)
    end)
  )
end)
assert(stdout:match('3 passed in'), 'Monkeypatch tests did not pass')
assert(object_to_patch.value == 1, 'Monkeypatch did not reset object value after tests')
assert(patchable_function(1) == 1, 'Monkeypatch did not reset global value after tests')
assert(patchable_function_module(1) == 1, 'Monkeypatch did not reset global value after tests')



--- parametrize
local total_value_parametrize = 1
local total_value_parametrize_multi = 1
_reset_stdout_and_run_tests(function()
  describe('Parametrize', 
    parametrize('value', {1, 2, 3}, 
    it('can parametrize test', function(value) 
      assert(value == total_value_parametrize)
      total_value_parametrize = total_value_parametrize + 1
    end)
    ),
    parametrize(
    'value1, value2', 
    {
      {1, 9},
      {2, 9},
      {3, 9},
    }, 
    it('can parametrize test with multiple arguments and nested parameters', function(value1, value2) 
      assert(value1 == total_value_parametrize_multi)
      assert(value2 == 9)
      total_value_parametrize_multi = total_value_parametrize_multi + 1
    end)
    )
  )
end)
assert(stdout:match('6 passed in'), 'Parametrize tests did not pass')



--error in test, parametrized test
_reset_stdout_and_run_tests(function()
  describe('Failing tests', 
    it('passes', function() end),
    it('fails', function() error('fail') end),
    parametrize('value', {1, 2},
    it('fails', function(value, request) error('fail') end)
    )
  )
end)
assert(stdout:match('3 failed, 1 passed in'), 'Failing tests did not have correct message')
assert(stdout:match('%.FFF\n'), 'Incorrect test results')



--error in fixture create, fixture teardown
_reset_stdout_and_run_tests(function()

  fixture('fail_before', function(request)
    error('before')
  end)

  fixture('fail_after', function(request)
    request.addfinalizer(function() error('after') end)
  end)
  
  fixture('fail_before_and_after', function(request)
    request.addfinalizer(function() error('after') end)
    error('before')
  end)

  describe('Failing fixture tests 1', 
    it('errors during fixture setup', function(fail_before) 
    end),
    it('errors during fixture setup with failing test', function(fail_before) 
      error('during')
    end)
  )
  describe('Failing fixture tests 2', 
    it('errors during fixture teardown', function(fail_after) 
    end),
    it('errors during fixture teardown with failing test', function(fail_after) 
      error('during')
    end)
  )
  describe('Failing fixture tests 3', 
    it('errors during fixture setup and teardown', function(fail_before_and_after) 
    end),
    it('errors during fixture setup and teardown with failing test', function(fail_before_and_after) 
      error('during')
    end)
  )
end)
assert(stdout:match('5 failed, 1 passed, 8 error in'), 'Failing fixture tests did not pass')
assert(stdout:match('Failing fixture tests 1: EFEF'), 'Incorrect success/fail/error status written to stdout')
assert(stdout:match('Failing fixture tests 2: %.EFE'), 'Incorrect success/fail/error status written to stdout')
assert(stdout:match('Failing fixture tests 3: EFEEFE'), 'Incorrect success/fail/error status written to stdout')


-- TODO: Skiped test tests
