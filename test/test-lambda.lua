package.path = package.path .. ";../?.lua"
local f = require "functional"
local ten_minus = f.bind(f.lambda2 "(x, y) => x - y", 10)
for i in f.range(9) do
  print(i, ten_minus(i))
end

-- global x
X = 5
local l = f.lambda2 "() => X*2"
print(l)
print(pcall(l)) -- should error with a readable message
print(pcall(f.lambda2, "() => end"))

print(pcall(f.lambda2, "42"))
