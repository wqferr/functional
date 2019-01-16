local internal = {}

local Iterable = {}
local iter_meta = {}

iter_meta.__index = Iterable


-- function Iterable:


local function iter(t)
  local iterable = {}
  setmetatable(iterable, Iterable)

  iterable.values = { table.unpack(t) }
  iterable.index = 0
  iterable.next_element = internal.iter_next
  iterable.completed = false

  return iterable
end


-- local function filter(t, f)
--   return iter(t):filter(f)
-- end


function internal.iter_next(iter)
  if iter.completed then
    return nil
  end
  iter.index = iter.index + 1
  local next_value = iter.values[iter.index]
  iter.completed = next_value == nil
  return next_value
end


function internal.assert_table(arg, arg_name)
  assert(
    type(arg) == 'table',
    internal.ERR_EXPECTED_TABLE:format(arg_name, arg)
  )
end

internal.ERR_EXPECTED_TABLE = 'argument %s is %s, expected table'


return {
  iter = iter
}