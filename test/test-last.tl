local f = require "functional"
local function is_prime(n: integer): boolean
  for i = 2, math.ceil(math.sqrt(n)) do
    if n % i == 0 then
      return false
    end
  end
  return true
end

print(
  f.range(100, 110)
    :filter(is_prime)
    :last()
)

local fname = debug.getinfo(1,'S').source:sub(2)
local lines = f.Iterator.from(io.lines(fname))
print(lines:last())

print(f.last {1, 2, 3, 4, 5})