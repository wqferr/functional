---
-- <h2>A module for functional programming utils.</h2>
-- <p>
-- An <code>iterable</code> refers to either of:
-- <ul>
-- <li> A table with contiguous non-<code>nil</code> values (an "array"); or </li>
-- <li> An <code>Iterator</code> instance. </li>
-- </ul>
-- </p>
-- @module functional
-- @release 0.8.1
-- @alias M
-- @author William Quelho Ferreira
---

local M = {}
local exports = {}
local internal = {}

local Iterator = {}
local iter_meta = {}


--- Module version.
M._VERSION = '0.8.1'


--- @type Iterator

--- Iterate over the given <code>iterable</code>.
-- <p>If <code>t</code> is a table, create an Iterator instance
-- that returns its values one by one. If it is an
-- iterator, return itself.</p>
-- @tparam iterable t the values to be iterated
function Iterator.create(t)
  internal.assert_table(t)

  if internal.is_iterator(t) then
    return t
  else
    local copy = { table.unpack(t) }
    local iterator = internal.base_iter(
      copy, internal.iter_next, internal.iter_clone)

    iterator.index = 0

    return iterator
  end
end


--- Iterate over the integers in increments of 1.
-- @treturn Iterator the counter
-- @see take
-- @see skip
-- @see every
function Iterator.counter()
  local iterator = internal.base_iter(
    nil, internal.counter_next, internal.counter_clone)
  
  iterator.n = 0

  return iterator
end


function Iterator.from_coroutine(co)
  internal.assert_coroutine(co)
  return internal.wrap_coroutine(co)
end


function Iterator.from_iterated_call(func)
  internal.assert_not_nil(func, 'func')
  local iterator = internal.base_iter(
    nil, internal.func_call_next, internal.func_try_clone)
  
  iterator.func = func

  return iterator
end


--- Nondestructively return an indepent iterable from the given one.
-- <p>If <code>t</code> is an Iterator, clone it according to its subtype.
-- If <code>t</code> is an array, then return itself.</p>
-- <p>Please note that coroutine and iterated function call iterators
-- cannot be cloned.</p>
-- @tparam iterable t the iterable to be cloned
-- @treturn iterable the clone
function Iterator.clone(t)
  internal.assert_not_nil(t, 't')
  if internal.is_iterator(t) then
    return t:clone()
  else
    return t
  end
end


function Iterator:filter(predicate)
  internal.assert_not_nil(predicate, 'predicate')
  local iterator = internal.base_iter(
    self, internal.filter_next, internal.filter_clone)

  iterator.predicate = predicate

  return iterator
end


function Iterator:map(mapping)
  internal.assert_not_nil(mapping, 'mapping')
  local iterator = internal.base_iter(
    self, internal.map_next, internal.map_clone)

  iterator.mapping = M.compose(internal.func_nil_guard, mapping)

  return iterator
end


function Iterator:reduce(reducer, initial_value)
  internal.assert_not_nil(reducer, 'reducer')
  local reduced_result = initial_value
  local function reduce(next_value)
    reduced_result = reducer(reduced_result, next_value)
  end

  self:foreach(reduce)
  return reduced_result
end


function Iterator:foreach(func)
  internal.assert_not_nil(func, 'func')

  local next_input = { self:next() }
  while not self:is_complete() do
    func(table.unpack(next_input))
    next_input = { self:next() }
  end
end


--- Iterate over the <code>n</code> first elements and stop.
-- @tparam integer n amount of elements to take
function Iterator:take(n)
  internal.assert_integer(n, 'n')

  local iterator = internal.base_iter(
    self, internal.take_next, internal.take_clone)

  iterator.n_remaining = n

  return iterator
end


--- Iterate over the values, starting at the <code>n+1</code>th one.
-- @tparam integer n amount of elements to skip
function Iterator:skip(n)
  internal.assert_integer(n, 'n')

  local iterator = internal.base_iter(
    self, internal.skip_next, internal.skip_clone)
  
  iterator.n_remaining = n

  return iterator
end


--- Take 1 element every <code>n</code>.
-- The first element is always taken.
-- @tparam integer n one more than the number of skipped elements
function Iterator:every(n)
  internal.assert_integer(n, 'n')

  local iterator = internal.base_iter(
    self, internal.every_next, internal.every_clone)

  iterator.n = n
  iterator.first_call = true

  return iterator
end


--- Checks if any elements evaluate to <code>true</code>.<br>
-- @tparam predicate predicate function to evaluate for each element, defaults to <pre>not (value == nil or value == false)</pre>
function Iterator:any(predicate)
  if predicate then
    return self:map(predicate):any()
  else
    for value in self do
      if value then
        return true
      end
    end
    return false
  end
end


--- Checks if all elements evaluate to <code>true</code>.<br>
-- @tparam predicate predicate function to evaluate for each element, defaults to <pre>not (value == nil or value == false)</pre>
function Iterator:all(predicate)
  if predicate then
    return self:map(predicate):all()
  else
    for value in self do
      if not value then
        return false
      end
    end
    return true
  end
end


--- Counts how many elements evaluate to <code>true</code>.<br>
-- @tparam predicate predicate function to evaluate for each element; if <code>nil</code>, then counts all elements.
function Iterator:count(predicate)
  if not predicate then
    predicate = M.constant(true)
  end
  return self:map(predicate):map(internal.bool_to_int):reduce(internal.sum, 0)
end



function Iterator:to_list()
  local list = {}
  self:foreach(M.partial(table.insert, list))
  return list
end


function Iterator:to_coroutine()
  return coroutine.create(internal.coroutine_iter_loop(self))
end


function Iterator:is_complete()
  return self.completed
end


-- RAW FUNCTIONS --


--- @section end


function exports.iterate(t)
  return Iterator.create(t)
end


function exports.filter(t, predicate)
  return exports.iterate(t):filter(predicate)
end


function exports.map(t, mapping)
  return exports.iterate(t):map(mapping)
end


function exports.foreach(t, func)
  return exports.iterate(t):foreach(func)
end


function exports.reduce(t, func, initial_value)
  return exports.iterate(t):reduce(func, initial_value)
end


function exports.take(t, n)
  return exports.iterate(t):take(n)
end


function exports.skip(t, n)
  return exports.iterate(t):skip(n)
end


function exports.every(t, n)
  return exports.iterate(t):every(n)
end


function exports.any(t, predicate)
  return exports.iterate(t):any(predicate)
end


function exports.all(t, predicate)
  return exports.iterate(t):all(predicate)
end


function M.to_list(t)
  assert_table(t)
  if internal.is_iterator(t) then
    return t:to_list()
  else
    return t
  end
end


function M.to_coroutine(t)
  return exports.iterate(t):to_coroutine()
end


-- MISC FUNCTIONS --


function M.negate(f)
  internal.assert_not_nil(f, 'f')
  return function(...)
    return not f(...)
  end
end


function M.compose(f1, f2, ...)
  internal.assert_not_nil(f1, 'f1')
  internal.assert_not_nil(f2, 'f2')

  if select('#', ...) > 0 then
    local part = M.compose(f2, ...)
    return M.compose(f1, part)
  else
    return function(...)
      return f1(f2(...))
    end
  end
end


function M.partial(f, ...)
  internal.assert_not_nil(f, 'f')

  local saved_args = { ... }
  return function(...)
    local args = { table.unpack(saved_args) }
    for _, arg in ipairs({...}) do
      table.insert(args, arg)
    end
    return f(table.unpack(args))
  end
end


function M.accessor(t)
  internal.assert_table(t)
  return function(k)
    return t[k]
  end
end


function M.itemgetter(k)
  return function(t)
    return t[k]
  end
end


function M.get_partial(t, k, ...)
  internal.assert_not_nil(t, 't')
  return M.partial(t[k], ...)
end


function M.bound_func(t, k, ...)
  internal.assert_not_nil(t, 't')
  return M.get_partial(t, k, t, ...)
end


function M.constant(value)
  return function(...)
    return value
  end
end


local function export_funcs()
  for k, v in pairs(exports) do
    _G[k] = v
  end

  return M
end


-- INTERNAL --


internal.iterator_flag = {}
Iterator[internal.iterator_flag] = true


function internal.is_iterator(t)
  return t[internal.iterator_flag] ~= nil
end


function internal.func_nil_guard(value, ...)
  assert(
    value ~= nil,
    'iterated function cannot return nil as the first value'
  )
  return value, ...
end


function internal.bool_to_int(value)
  if value then
    return 1
  else
    return 0
  end
end


function internal.sum(a, b)
  return a + b
end


-- ITER FUNCTIONS --


function internal.base_iter(values, next_f, clone)
  local iterator = {}
  setmetatable(iterator, iter_meta)

  iterator.values = values
  iterator.completed = false
  iterator.next = next_f
  iterator.clone = clone
  return iterator
end


function internal.iter_next(iter)
  if iter.completed then
    return nil
  end
  iter.index = iter.index + 1
  local next_input = iter.values[iter.index]
  iter.completed = next_input == nil
  return next_input
end


function internal.iter_clone(iter)
  local new_iter = exports.iterate(Iterator.clone(iter.values))
  new_iter.index = iter.index
  new_iter.completed = iter.completed
  return new_iter
end


function internal.counter_next(iter)
  iter.n = iter.n + 1
  return iter.n
end


function internal.counter_clone(iter)
  local new_iter = Iterator.counter()
  new_iter.count = iter.count
  return new_iter
end


function internal.filter_next(iter)
  if iter.completed then
    return nil
  end
  local next_input = { iter.values:next() }
  while #next_input > 0 do
    if iter.predicate(table.unpack(next_input)) then
      return table.unpack(next_input)
    end
    next_input = { iter.values:next() }
  end

  iter.completed = true
  return nil
end


function internal.filter_clone(iter)
  return exports.filter(Iterator.clone(iter.values), iter.predicate)
end


function internal.map_next(iter)
  if iter.completed then
    return nil
  end
  local next_input = { iter.values:next() }
  if #next_input == 0 then
    iter.completed = true
    return nil
  end

  return iter.mapping(table.unpack(next_input))
end


function internal.map_clone(iter)
  return exports.map(Iterator.clone(iter.values), iter.mapping)
end


function internal.take_next(iter)
  if iter.completed then
    return nil
  end
  local next_input = { iter.values:next() }
  if #next_input == 0 then
    iter.completed = true
    return nil
  end

  if iter.n_remaining > 0 then
    iter.n_remaining = iter.n_remaining - 1
    return table.unpack(next_input)
  else
    iter.completed = true
    return nil
  end
end


function internal.take_clone(iter)
  return exports.take(Iterator.clone(iter.values), iter.n_remaining)
end


function internal.skip_next(iter)
  if iter.completed then
    return nil
  end

  while iter.n_remaining > 0 do
    local v = iter.values:next()
    iter.n_remaining = iter.n_remaining - 1
  end
  
  local next_input = { iter.values:next() }
  if #next_input == 0 then
    iter.completed = true
    return nil
  end

  return table.unpack(next_input)
end


function internal.skip_clone(iter)
  return exports.skip(Iterator.clone(iter.values), iter.n_remaining)
end


function internal.every_next(iter)
  if iter.completed then
    return nil
  end

  local next_input
  if iter.first_call then
    iter.first_call = nil
  else
    for i = 1, iter.n - 1 do
      iter.values:next()
    end
  end

  next_input = { iter.values:next() }
  if #next_input == 0 then
    iter.completed = true
    return nil
  end

  return table.unpack(next_input)
end


function internal.every_clone(iter)
  return exports.every(Iterator.clone(iter.values), iter.n)
end


function internal.wrap_coroutine(co)
  local iter = internal.base_iter(
    nil, internal.iter_coroutine_next, internal.coroutine_try_clone)
  iter.coroutine = co
  return iter
end


function internal.iter_coroutine_next(iter)
  if iter.completed then
    return nil
  end
  local yield = { coroutine.resume(co) }
  local status = yield[1]
  assert(status, yield[2])

  local next_value = { select(2, table.unpack(yield)) }
  if #next_value == 0 then
    iter.completed = true
    return nil
  end

  return table.unpack(next_value)
end


function internal.coroutine_try_clone(iter)
  error(internal.ERR_COROUTINE_CLONE)
end


function internal.coroutine_iter_loop(iter)
  return function()
    iter:foreach(coroutine.yield)
  end
end


function internal.func_call_next(iter)
  if iter.completed then
    return nil
  end
  local result = { iter.func() }
  if #result == 0 then
    iter.completed = true
    return nil
  end

  return table.unpack(result)
end


function internal.func_try_clone(iter)
  error(internal.ERR_FUNCTION_CLONE)
end


-- ERROR CHECKING --


function internal.assert_table(value, param_name)
  assert(
    type(value) == 'table',
    internal.ERR_TABLE_EXPECTED:format(param_name, value)
  )
end


function internal.assert_integer(value, param_name)
  assert(
    type(value) == 'number' and value % 1 == 0,
    internal.ERR_INTEGER_EXPECTED:format(param_name, value)
  )
end


function internal.assert_coroutine(value, param_name)
  assert(
    type(value) == 'thread',
    internal.ERR_COROUTINE_EXPECTED:format(param_name, value)
  )
end


function internal.assert_not_nil(value, param_name)
  assert(
    value ~= nil,
    internal.ERR_NIL_VALUE:format(param_name)
  )
end


internal.ERR_COROUTINE_CLONE =
  'cannot clone coroutine iterator; try to_list and iterate over it'
internal.ERR_FUNCTION_CLONE =
  'cannot clone iterated function call; try to_list and iterate over it'

internal.ERR_INTEGER_EXPECTED = 'param %s expected integer, got: %s'
internal.ERR_TABLE_EXPECTED = 'param %s expected table, got: %s'
internal.ERR_COROUTINE_EXPECTED = 'param %s expected coroutine, got: %s'
internal.ERR_NIL_VALUE = 'parameter %s is nil'


iter_meta.__index = Iterator
iter_meta.__call = function(iter)
  return iter:next()
end


exports.Iterator = Iterator


M.import = export_funcs

for name, exported_func in pairs(exports) do
  M[name] = exported_func
end


return M