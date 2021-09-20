package.path = package.path .. ";../?.lua"
local f = require "functional"
local ten_minus = f.bind(f.lambda "x - y", 10)
for i in f.range(9) do
  print(i, ten_minus(i))
end

-- global x
x = 5
print(f.lambda "x"())
print(f.lambda "_G.x"())
