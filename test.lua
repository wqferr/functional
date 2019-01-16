require('func', true).import()

local t = {0, 1, 2, 3, 4, 5, 6, 7, 8}
local it1 = iterate(t)
local it2 = iterate(t)

local function n(it)
  print(it:next())
end

n(it1)
n(it1)
n(it1)
n(it2)

local it3 = it2:clone()

n(it3)
n(it2)
n(it2)
n(it2)
n(it3)