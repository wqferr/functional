local module = {}
local exports = {}
local internal = {}

local Iterable = {}
local iter_meta = {}

local unpack = table.unpack


function Iterable.create(t)
  if internal.is_iterable(t) then
    return t
  else
    local copy = { unpack(t) }
    local iterable = internal.base_iter(
      copy, internal.iter_next, internal.iter_clone)

    iterable.index = 0

    return iterable
  end
end


function Iterable:next()
  return self:next()
end


function Iterable:filter(predicate)
  local iterable = internal.base_iter(
    self, internal.filter_next, internal.filter_clone)

  iterable.predicate = predicate

  return iterable
end


function Iterable:map(mapping)
  local iterable = internal.base_iter(
    self, internal.map_next, internal.map_clone)

  iterable.mapping = mapping

  return iterable
end


function Iterable:reduce(reducer, initial_value)
  local reduced_result = initial_value
  local function reduce(next_value)
    reduced_result = reducer(reduced_result, next_value)
  end

  self:foreach(reduce)
  return reduced_result
end


function Iterable:foreach(func)
  for value in self do
    func(value)
  end
end


-- RAW FUNCTIONS --


function exports.iterate(t)
  return Iterable.create(t)
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


function exports.clone(t)
  if internal.is_iterable(t) then
    return t:clone()
  else
    return t
  end
end


function exports.negate(f)
  local negate_f = function(...)
    return not f(...)
  end
  return negate_f
end


function exports.compose(f1, f2)
  return function(...)
    return f1(f2(...))
  end
end


local function export_funcs()
  for k, v in pairs(exports) do
    _G[k] = v
  end

  return module
end


-- INTERNAL --


internal.iterable_flag = {}
Iterable[internal.iterable_flag] = true


function internal.is_iterable(t)
  return t[internal.iterable_flag] ~= nil
end


function internal.base_iter(values, next_f, clone)
  local iterable = {}
  setmetatable(iterable, iter_meta)

  iterable.values = values
  iterable.completed = false
  iterable.next = next_f
  iterable.clone = clone
  return iterable
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
  local new_iter = exports.iterate(exports.clone(iter.values))
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
    if iter.predicate(unpack(next_input)) then
      return unpack(next_input)
    end
    next_input = { iter.values:next() }
  end

  iter.completed = true
  return nil
end


function internal.filter_clone(iter)
  return exports.filter(exports.clone(iter.values), iter.predicate)
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

  return iter.mapping(unpack(next_input))
end


function internal.map_clone(iter)
  return exports.map(exports.clone(iter.values), iter.mapping)
end


internal.ERR_EXPECTED_TABLE = 'argument %s is %s, expected table'


iter_meta.__index = Iterable
iter_meta.__call = Iterable.next


module.Iterable = Iterable
module.import = export_funcs

for name, exported_func in pairs(exports) do
  module[name] = exported_func
end

return module