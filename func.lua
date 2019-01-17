local module = {}
local exports = {}
local internal = {}

local Iterator = {}
local iter_meta = {}


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


function Iterator.from_coroutine(co)
  internal.assert_coroutine(co)
  return internal.wrap_coroutine(co)
end


function Iterator:filter(predicate)
  local iterator = internal.base_iter(
    self, internal.filter_next, internal.filter_clone)

  iterator.predicate = predicate

  return iterator
end


function Iterator:map(mapping)
  local iterator = internal.base_iter(
    self, internal.map_next, internal.map_clone)

  iterator.mapping = module.compose(internal.func_nil_guard, mapping)

  return iterator
end


function Iterator:reduce(reducer, initial_value)
  local reduced_result = initial_value
  local function reduce(next_value)
    reduced_result = reducer(reduced_result, next_value)
  end

  self:foreach(reduce)
  return reduced_result
end


function Iterator:foreach(func)
  local next_input = { self:next() }
  while not self:is_complete() do
    func(table.unpack(next_input))
    next_input = { self:next() }
  end
end


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


function Iterator:to_list()
  local list = {}
  self:foreach(module.partial(table.insert, list))
  return list
end


function Iterator:to_coroutine()
  return coroutine.create(internal.coroutine_iter_loop(self))
end


function Iterator:is_complete()
  return self.completed
end


-- RAW FUNCTIONS --


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


function exports.any(t, predicate)
  return exports.iterate(t):any(predicate)
end


function exports.all(t, predicate)
  return exports.iterate(t):all(predicate)
end


function module.to_list(t)
  assert_table(t)
  if internal.is_iterator(t) then
    return t:to_list()
  else
    return t
  end
end


function module.to_coroutine(t)
  return exports.iterate(t):to_coroutine()
end


function module.clone(t)
  assert_table(t)
  if internal.is_iterator(t) then
    return t:clone()
  else
    return t
  end
end


-- MISC FUNCTIONS --


function module.negate(f)
  return function(...)
    return not f(...)
  end
end


function module.compose(f1, f2, ...)
  internal.assert_not_nil(f1)
  internal.assert_not_nil(f2)

  if select('#', ...) > 0 then
    local part = module.compose(f2, ...)
    return module.compose(f1, part)
  else
    return function(...)
      return f1(f2(...))
    end
  end
end


function module.partial(f, ...)
  local saved_args = { ... }
  return function(...)
    local args = { table.unpack(saved_args) }
    for _, arg in ipairs({...}) do
      table.insert(args, arg)
    end
    return f(table.unpack(args))
  end
end


function module.accessor(t)
  assert_table(t)
  return function(k)
    return t[k]
  end
end


function module.itemgetter(k)
  return function(t)
    return t[k]
  end
end


function module.get_partial(t, k, ...)
  return module.partial(t[k], ...)
end


function module.bound_func(t, k, ...)
  return module.get_partial(t, k, t, ...)
end


local function export_funcs()
  for k, v in pairs(exports) do
    _G[k] = v
  end

  return module
end


-- INTERNAL --


internal.iterator_flag = {}
Iterator[internal.iterator_flag] = true


function internal.is_iterator(t)
  return t[internal.iterator_flag] ~= nil
end


function internal.func_nil_guard(value, ...)
  assert(value ~= nil, 'iterated function cannot return nil as the first value')
  return value, ...
end


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
  local new_iter = exports.iterate(module.clone(iter.values))
  new_iter.index = iter.index
  new_iter.completed = iter.completed
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
  return exports.filter(module.clone(iter.values), iter.predicate)
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
  return exports.map(module.clone(iter.values), iter.mapping)
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


function internal.assert_table(value)
  assert(
    type(value) == 'table',
    internal.ERR_TABLE_EXPECTED
  )
end


function internal.assert_coroutine(value)
  assert(
    type(value) == 'thread',
    internal.ERR_COROUTINE_EXPECTED:format(value)
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
internal.ERR_TABLE_EXPECTED = 'expected table, got: %s'
internal.ERR_COROUTINE_EXPECTED = 'expected coroutine, got: %s'
internal.ERR_NIL_VALUE = 'parameter %s is nil'


iter_meta.__index = Iterator
iter_meta.__call = function(iter)
  return iter:next()
end


module.Iterator = Iterator
module.import = export_funcs

for name, exported_func in pairs(exports) do
  module[name] = exported_func
end

return module