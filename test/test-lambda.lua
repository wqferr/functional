package.path = package.path .. ";../?.lua"
local f = require "functional"
local ten_minus = f.bind(f.lambda "x - y", 10)
for i in f.range(9) do
  print(i, ten_minus(i))
end

-- global x
X = 5
local l = f.lambda "X*2"
print(l)
print(pcall(l)) -- should error with a readable message
f.lambda"end"
