local f = require('func', true)

local function even(x)
  return x % 2 == 0
end

local function succ(x)
  return x + 1
end

local t = {0, 1, 2, 3, 4, 5, 6, 7, 8}
local it1 = f.iterate(t):filter(even):map(succ)
local it2 = f.iterate(t):filter(even):map(succ)

local names = {}
names[it1] = '1'
names[it2] = '2'

local function n(it)
  print(names[it], it:next())
end

n(it1)
n(it1)
n(it1)
n(it2)

local it3 = it2:clone()
names[it3] = '3'

n(it2)
n(it3)
n(it2)
n(it2)
n(it3)