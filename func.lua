local module = {}
local internal = {}

local Iterable = {}
local iter_meta = {}
iter_meta.__index = Iterable

local unpack = table.unpack


function Iterable.create(t)
  local copy = { unpack(t) }
  local iterable = internal.base_iter(copy, internal.iter_next)

  iterable.index = 0

  return iterable
end


function Iterable:filter(predicate)
  local iterable = internal.base_iter(self, internal.filter_next)

  iterable.predicate = predicate

  return iterable
end


function Iterable:map(mapping)
  local iterable = internal.base_iter(self, internal.map_next)

  iterable.mapping = mapping

  return iterable
end


function Iterable:next()
  return self:next()
end


iter_meta.__call = Iterable.next


-- RAW FUNCTIONS --


local function iter(t)
  return Iterable.create(t)
end


local function filter(t, predicate)
  return iter(t):filter(predicate)
end


local function map(t, mapping)
  return iter(t):map(mapping)
end


local function export_funcs()
  _G.iter = iter
  _G.filter = filter

  return module
end


-- INTERNAL --


function internal.base_iter(values, next_f)
  local iterable = {}
  setmetatable(iterable, iter_meta)

  iterable.values = values
  iterable.completed = false
  iterable.next = next_f
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


function internal.assert_table(arg, arg_name)
  assert(
    type(arg) == 'table',
    internal.ERR_EXPECTED_TABLE:format(arg_name, arg)
  )
end

internal.ERR_EXPECTED_TABLE = 'argument %s is %s, expected table'


module.Iterable = Iterable
module.iter = iter
module.filter = filter
module.import = export_funcs


return module