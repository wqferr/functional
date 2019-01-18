---
-- <h2>A module for functional programming utils.</h2>
-- <p>
-- An <code>iterable</code> refers to either of:
-- <ul>
-- <li> A table with contiguous non-<code>nil</code> values
-- (an "array"); or </li>
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
-- <p>If <code>iterable</code> is an array, create an Iterator instance
-- that returns its values one by one. If it is an
-- iterator, return itself.</p>
-- @tparam iterable iterable the values to be iterated over
-- @treturn Iterator the new Iterator
function Iterator.create(iterable)
  internal.assert_table(iterable)

  if internal.is_iterator(iterable) then
    return iterable
  else
    local copy = { table.unpack(iterable) }
    local iterator = internal.base_iter(
      copy, internal.iter_next, internal.iter_clone)

    iterator.index = 0

    return iterator
  end
end


--- Iterate over the naturals starting at 1.
-- @treturn Iterator the counter
-- @see Iterator:take
-- @see Iterator:skip
-- @see Iterator:every
function Iterator.counter()
  local iterator = internal.base_iter(
    nil, internal.counter_next, internal.counter_clone)
  
  iterator.n = 0

  return iterator
end


--- Iterate over the <code>coroutine</code>'s yielded values.
-- @tparam thread co the <code>coroutine</code> to iterate
-- @treturn Iterator the new <code>@{Iterator}</code>
function Iterator.from_coroutine(co)
  internal.assert_coroutine(co)
  return internal.wrap_coroutine(co)
end


--- Iterate over the function's returned values upon repeated calls
-- @tparam function func the function to call
-- @treturn Iterator the new <code>@{Iterator}</code>
function Iterator.from_iterated_call(func)
  internal.assert_not_nil(func, 'func')
  local iterator = internal.base_iter(
    nil, internal.func_call_next, internal.func_try_clone)
  
  iterator.func = func

  return iterator
end


--- Nondestructively return an indepent iterable from the given one.
-- <p>If <code>iterablet</code> is an Iterator, clone it according
-- to its subtype. If <code>iterable</code> is an array, then
-- return itself.</p>
-- <p>Please note that coroutine and iterated function call iterators
-- cannot be cloned.</p>
-- @tparam iterable iterable the iterable to be cloned
-- @treturn iterable the clone
function Iterator.clone(iterable)
  internal.assert_not_nil(iterable, 'iterable')
  if internal.is_iterator(iterable) then
    return iterable:clone()
  else
    return iterable
  end
end


--- Select only values which match the predicate.
-- @tparam predicate predicate the function to evaluate for each value
-- @treturn Iterator the filtering <code>@{Iterator}</code>
function Iterator:filter(predicate)
  internal.assert_not_nil(predicate, 'predicate')
  local iterator = internal.base_iter(
    self, internal.filter_next, internal.filter_clone)

  iterator.predicate = predicate

  return iterator
end


--- Map values into new values.
-- <p>Please note that at no point during iteration may
-- the <code>mapping</code> function return <code>nil</code>
-- as its first value.</p>
-- @tparam function mapping the function to evaluate for each value
-- @treturn Iterator the mapping <code>@{Iterator}</code>
function Iterator:map(mapping)
  internal.assert_not_nil(mapping, 'mapping')
  local iterator = internal.base_iter(
    self, internal.map_next, internal.map_clone)

  iterator.mapping = M.compose(internal.func_nil_guard, mapping)

  return iterator
end


--- Collapse values into a single value.
-- <p>A reducer is a function of the form
-- <pre>function(accumulated_value, new_value)</pre>
-- which returns the reducing or "accumulation" of
-- <code>accumulated_value</code> and <code>new_value</code></p>
-- <p>The definition of "reducing" is flexible, and a few common examples
-- include sum and concatenation.</p>
-- @tparam reducer reducer the collapsing function
-- @param initial_value the initial value passed to the <code>reducer</code>
-- @return the accumulation of all values
function Iterator:reduce(reducer, initial_value)
  internal.assert_not_nil(reducer, 'reducer')
  local reduced_result = initial_value
  local function reduce(next_value)
    reduced_result = reducer(reduced_result, next_value)
  end

  self:foreach(reduce)
  return reduced_result
end


--- Apply a function to all values.
-- <p>The main difference between <code>@{Iterator:foreach}</code> and
-- <code>@{Iterator:map}</code> is that <code>foreach</code> ignores the
-- return value(s) of its function, while map uses them and has restrictions
-- on what it can return.</p>
-- <p>Another important difference is that <code>@{Iterator:map}</code>
-- is a lazy evaluator, while <code>@{Iterator:foreach}</code> iterates over
-- its values immediately.</p>
-- @tparam function func the function to apply for each value
function Iterator:foreach(func)
  internal.assert_not_nil(func, 'func')

  local next_input = { self:next() }
  while not self:is_complete() do
    func(table.unpack(next_input))
    next_input = { self:next() }
  end
end


--- Iterate over the <code>n</code> first values and stop.
-- @tparam integer n amount of values to take
-- @treturn Iterator the new <code>@{Iterator}</code>
function Iterator:take(n)
  internal.assert_integer(n, 'n')

  local iterator = internal.base_iter(
    self, internal.take_next, internal.take_clone)

  iterator.n_remaining = n

  return iterator
end


--- Iterate over the values, starting at the <code>(n+1)</code>th one.
-- @tparam integer n amount of values to skip
-- @treturn Iterator the new <code>@{Iterator}</code>
function Iterator:skip(n)
  internal.assert_integer(n, 'n')

  local iterator = internal.base_iter(
    self, internal.skip_next, internal.skip_clone)
  
  iterator.n_remaining = n

  return iterator
end


--- Take 1 value every <code>n</code>.
-- <p>The first value is always taken.</p>
-- @tparam integer n one more than the number of skipped values
-- @treturn Iterator the new <code>@{Iterator}</code>
-- @see Iterator:skip
function Iterator:every(n)
  internal.assert_integer(n, 'n')

  local iterator = internal.base_iter(
    self, internal.every_next, internal.every_clone)

  iterator.n = n
  iterator.first_call = true

  return iterator
end


--- Checks if any values evaluate to <code>true</code>.
-- @tparam predicate predicate the function to evaluate for each value,
-- defaults to <pre>not (value == nil or value == false)</pre>
-- @treturn boolean <code>true</code> if and only if at least one of the
-- values evaluate to <code>true</code>
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


--- Checks if all values evaluate to <code>true</code>.
-- @tparam predicate predicate the function to evaluate for each value,
-- defaults to <pre>not (value == nil or value == false)</pre>
-- @treturn boolean <code>true</code> if and only if all of the
-- values evaluate to <code>true</code>
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


--- Counts how many values evaluate to <code>true</code>.
-- @tparam predicate predicate function to evaluate for each value; if
-- <code>nil</code>, then counts all values.
-- @treturn integer the number of values that match the <code>predicate</code>
function Iterator:count(predicate)
  if not predicate then
    predicate = M.constant(true)
  end
  return self:map(predicate):map(internal.bool_to_int):reduce(internal.sum, 0)
end


--- Create an array out of the <code>@{Iterator}</code>'s values.
-- @treturn array the array of values
function Iterator:to_array()
  local array = {}
  self:foreach(M.bind(table.insert, array))
  return array
end


--- Create a <code>coroutine</code> that yields the values
-- of the <code>@{Iterator}</code>.
-- @treturn thread The new <code>coroutine</code>
function Iterator:to_coroutine()
  return coroutine.create(internal.coroutine_iter_loop(self))
end


--- Check whether or not the iterator is done.
-- <p>Please note that even if the iterator has reached its actual last
-- value, it has no way of knowing it was the last. Therefore, this function
-- will only return true once the iterator returns <code>nil</code> for the
-- first time.</p>
-- @treturn boolean <code>true</code> if the <code>@{Iterator}</code>
-- has iterated over all its values.
function Iterator:is_complete()
  return self.completed
end


--- @section end


-- RAW FUNCTIONS --


--- Create an <code>@{Iterator}</code> for the <code>iterable</code>.
-- <p>Equivalent to <pre>Iterator.create(iterable)</pre>.</p>
-- @tparam iterable iterable the values to be iterated over
-- @treturn Iterator the new <code>@{Iterator}</code>
-- @function iterate
function exports.iterate(iterable)
  return Iterator.create(iterable)
end


--- Select only values which match the predicate.
-- <p>Equivalent to <pre>iterate(iterable):filter(predicate)</pre>.</p>
-- @tparam iterable iterable the values to be filtered
-- @tparam predicate predicate the function to evaluate for each value
-- @treturn Iterator the filtering <code>@{Iterator}</code>
-- @see iterate
-- @see Iterator:filter
-- @function filter
function exports.filter(iterable, predicate)
  return exports.iterate(iterable):filter(predicate)
end


--- Map values into new values.
-- <p>Equivalent to <pre>iterate(iterable):map(mapping)</pre>.</p>
-- <p>Please note that at no point during iteration may
-- the <code>mapping</code> function return <code>nil</code>
-- as its first value.</p>
-- @tparam iterable iterable the values to be mapped
-- @tparam function mapping the function to evaluate for each value
-- @treturn Iterator the mapping <code>@{Iterator}</code>
-- @see iterate
-- @see Iterator:map
-- @function map
function exports.map(iterable, mapping)
  return exports.iterate(iterable):map(mapping)
end


--- Collapse values into a single value.
-- <p>Equivalent to <pre>iterate(iterable):reduce(reducer)</pre>.</p>
-- <p>A reducer is a function of the form
-- <pre>function(accumulated_value, new_value)</pre>
-- which returns the reducing or "accumulation" of
-- <code>accumulated_value</code> and <code>new_value</code></p>
-- <p>The definition of "reducing" is flexible, and a few common examples
-- include sum and concatenation.</p>
-- @tparam iterable iterable the values to be collapsed
-- @tparam reducer reducer the collapsing function
-- @param initial_value the initial value passed to the <code>reducer</code>
-- @return the accumulation of all values
-- @see iterate
-- @see Iterator:reduce
-- @function reduce
function exports.reduce(iterable, reducer, initial_value)
  return exports.iterate(iterable):reduce(reducer, initial_value)
end


--- Apply a function to all values.
-- <p>Equivalent to <pre>iterate(iterable):foreach(func)</pre>.</p>
-- <p>The main difference between <code>@{foreach}</code> and
-- <code>@{map}</code> is that <code>foreach</code> ignores the
-- return value(s) of its function, while map uses them and has restrictions
-- on what it can return.</p>
-- <p>Another important difference is that <code>@{map}</code>
-- is a lazy evaluator, while <code>@{foreach}</code> iterates over
-- its values immediately.</p>
-- @tparam iterable iterable the values to be iterated over
-- @tparam function func the function to apply for each value
-- @see iterate
-- @see Iterator:foreach
-- @function foreach
function exports.foreach(iterable, func)
  return exports.iterate(iterable):foreach(func)
end


--- Iterate over the <code>n</code> first values and stop.
-- <p>Equivalent to <pre>iterate(iterable):take(n)</pre>.</p>
-- @tparam iterable iterable the values to be iterated over
-- @tparam integer n amount of values to take
-- @treturn Iterator the new <code>@{Iterator}</code>
-- @see iterate
-- @see Iterator:take
-- @function take
function exports.take(iterable, n)
  return exports.iterate(iterable):take(n)
end


--- Iterate over the values, starting at the <code>(n+1)</code>th one.
-- <p>Equivalent to <pre>iterate(iterable):skip(n)</pre>.</p>
-- @tparam iterable iterable the values to be iterated over
-- @tparam integer n amount of values to skip
-- @treturn Iterator the new <code>@{Iterator}</code>
-- @see iterate
-- @see Iterator:skip
-- @function skip
function exports.skip(iterable, n)
  return exports.iterate(iterable):skip(n)
end


--- Take 1 value every <code>n</code>.
-- <p>Equivalent to <pre>iterate(iterable):every(n)</pre>.</p>
-- <p>The first value is always taken.</p>
-- @tparam iterable iterable the values to be iterated over
-- @tparam integer n one more than the number of skipped values
-- @treturn Iterator the new <code>@{Iterator}</code>
-- @see Iterator:every
-- @see iterate
-- @see skip
-- @function every
function exports.every(iterable, n)
  return exports.iterate(iterable):every(n)
end


--- Checks if any values evaluate to <code>true</code>.
-- <p>Equivalent to <pre>iterate(iterable):any(predicate)</pre>.</p>
-- @tparam iterable iterable the values to be iterated over
-- @tparam predicate predicate the function to evaluate for each value,
-- defaults to <pre>not (value == nil or value == false)</pre>
-- @treturn boolean <code>true</code> if and only if at least one of the
-- values evaluate to <code>true</code>
-- @see Iterator:any
-- @see iterate
-- @function any
function exports.any(iterable, predicate)
  return exports.iterate(iterable):any(predicate)
end


--- Checks if all values evaluate to <code>true</code>.
-- <p>Equivalent to <pre>iterate(iterable):all(predicate)</pre>.</p>
-- @tparam iterable iterable the values to be iterated over
-- @tparam predicate predicate the function to evaluate for each value,
-- defaults to <pre>not (value == nil or value == false)</pre>
-- @treturn boolean <code>true</code> if and only if all of the
-- values evaluate to <code>true</code>
-- @see Iterator:all
-- @see iterate
-- @function all
function exports.all(iterable, predicate)
  return exports.iterate(iterable):all(predicate)
end


--- Return an array version of the <code>iterable</code>.
-- <p>If <code>iterable</code> is an array, return itself.</p>
-- <p>If <code>iterable</code> is an <code>@{Iterator}</code>,
-- return <pre>iterable:to_array()</pre>
-- @tparam iterable iterable the values to make an array out of
-- @treturn array the array
-- @see Iterator:to_array
-- @see iterate
-- @function to_array
function M.to_array(iterable)
  assert_table(iterable)
  if internal.is_iterator(iterable) then
    return iterable:to_array()
  else
    return iterable
  end
end


--- Create a <code>coroutine</code> that yields the values
-- of the <code>iterable</code>.
-- <p>Equivalent to <pre>iterate(iterable):to_coroutine()</pre>.</p>
-- @tparam iterable iterable the values to be iterated over
-- @treturn thread The new <code>coroutine</code>
-- @see Iterator:to_coroutine
-- @see iterate
-- @function to_coroutine
function M.to_coroutine(iterable)
  return exports.iterate(iterable):to_coroutine()
end


-- MISC FUNCTIONS --


--- Create a negated function of <code>predicate</code>.
-- @tparam predicate predicate the function to be negated
-- @treturn predicate the inverted predicate
function M.negate(predicate)
  internal.assert_not_nil(predicate, 'predicate')
  return function(...)
    return not predicate(...)
  end
end


--- Create a function composition from the given functions.
-- @tparam function f1 the outermost function of the composition
-- @tparam function f2 the second outermost function of the composition
-- @tparam function... ... any further functions to add to the composition,
-- in order
-- @treturn function the composite function
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


--- Create a function with bound arguments.
-- <p>The bound function returned will call <code>func</code>
-- with the arguments passed on to its creation.</p>
-- <p>If more arguments are given during its call, they are
-- appended to the original ones.</p>
-- @tparam function func the function to create a binding of
-- @param ... the arguments to bind to the function.
-- @treturn function the bound function
function M.bind(func, ...)
  internal.assert_not_nil(func, 'func')

  local saved_args = { ... }
  return function(...)
    local args = { table.unpack(saved_args) }
    for _, arg in ipairs({...}) do
      table.insert(args, arg)
    end
    return func(table.unpack(args))
  end
end


--- Create a function that accesses <code>t</code>.
-- <p>The argument passed to the returned function is used as the key
-- <code>k</code> to be accessed. The value of <code>t[k]</code>
-- is returned.</p>
-- @tparam table t the table to be accessed
-- @treturn function the accessor
function M.accessor(t)
  internal.assert_table(t, 't')
  return function(k)
    return t[k]
  end
end


--- Create a function that accesses the key <code>k</code> for a table.
-- <p>The argument passed to the returned function is used as the table
-- <code>t</code> to be accessed. The value of <code>t[k]</code>
-- is returned.</p>
-- @param k the key to access
-- @treturn function the item getter
function M.item_getter(k)
  return function(t)
    return t[k]
  end
end


--- Create f bound function whose first argument is <code>t</code>.
-- <p>Particularly useful to pass a method as a function.</p>
-- <p>Equivalent to <pre>bind(t[k], t, ...)</pre>.</p>
-- @tparam table t the table to be accessed
-- @param k the key to be accessed
-- @param ... further arguments to bind to the function
-- @treturn function the binding for <code>t[k]</code>
function M.bind_self(t, k, ...)
  internal.assert_not_nil(t, 't')
  return M.bind(t[k], t, ...)
end


--- Create a function that always returns the same value.
-- @param value the constant to be returned
-- @treturn function the constant function
function M.constant(value)
  return function(...)
    return value
  end
end


--- Import <code>@{Iterator}</code> and commonly used
-- functions into global scope.
-- <p>Upon calling this, the following values will be
-- added to global scope (<code>_G</code>) with the same names:
-- <ul>
-- <li> @{Iterator} </li>
-- <li> @{iterate} </li>
-- <li> @{filter} </li>
-- <li> @{map} </li>
-- <li> @{reduce} </li>
-- <li> @{foreach} </li>
-- <li> @{take} </li>
-- <li> @{skip} </li>
-- <li> @{every} </li>
-- <li> @{any} </li>
-- <li> @{all} </li>
-- </ul></p>
-- <p>They can still be accessed through the module after the call.</p>
-- @function import
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
  'cannot clone coroutine iterator; try to_array and iterate over it'
internal.ERR_FUNCTION_CLONE =
  'cannot clone iterated function call; try to_array and iterate over it'

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