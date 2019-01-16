local func = require('func')
func.import()

local t = {1, 2, 3, 4, 5, 6, 7, 8}
local it = iter(t)
  :filter(function(x) return x % 2 == 0 end)
  :map(math.sqrt)
  :map(function(x) return x + 1 end)
  :map(function(x) return x^2 end)
  :filter(function(x) return x > 10 end)

for value in it do
  print(value)
end