local internal = {}

local Iterable = {}
local iter_meta = {}
iter_meta.__index = Iterable


function Iterable.create(t)
  local iterable = internal.base_iter(internal.iter_next)

  iterable.values = { table.unpack(t) }
  iterable.index = 0

  return iterable
end


function Iterable:filter(predicate)
  local iterable = internal.base_iter(internal.filter_next)

  iterable.values = self
  iterable.predicate = predicate

  return iterable
end


local function iter(t)
  return Iterable.create(t)
end


local function filter(t, predicate)
  return iter(t):filter(predicate)
end


function internal.base_iter(next_f)
  local iterable = {}
  setmetatable(iterable, iter_meta)
  iterable.completed = false
  iterable.next_element = next_f
  return iterable
end


function internal.iter_next(iter)
  if iter.completed then
    return nil
  end
  iter.index = iter.index + 1
  local next_value = iter.values[iter.index]
  iter.completed = next_value == nil
  return next_value
end


function internal.filter_next(iter)
  if iter.completed then
    return nil
  end
  local next_input = iter.values:next_element()
  while next_input ~= nil do
    if iter.predicate(next_input) then
      return next_input
    end
    next_input = iter.values:next_element()
  end
  return nil
end


function internal.assert_table(arg, arg_name)
  assert(
    type(arg) == 'table',
    internal.ERR_EXPECTED_TABLE:format(arg_name, arg)
  )
end

internal.ERR_EXPECTED_TABLE = 'argument %s is %s, expected table'

return {
  Iterable = Iterable,
  iter = iter,
  filter = filter
}