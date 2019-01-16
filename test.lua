require('func', true).import()

local t = {0, 1, 2, 3, 4, 5, 6, 7, 8}
local it = iterate(t)
  :map(function(x) return (x+1)^2, x^2 end)
  :map(function(a, b) return a - b end)

local function add(acc, new)
  return acc + new
end

-- print(it:reduce(add, 0))
print(reduce(it, add, 0))