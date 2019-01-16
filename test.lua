local func = require('func')
func.import()

local t = {0, 1, 2, 3, 4, 5, 6, 7, 8}
local it = iter(t)
  :map(function(x) return (x+1)^2, x^2 end)
  :map(function(a, b) return a - b end)

for d in it do
  print(d)
end