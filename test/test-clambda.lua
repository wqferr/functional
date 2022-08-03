require "reqpath"
local f = require "functional"
local angle = math.pi / 3 --- @diagnostic disable-line
local offset_sin = f.clambda "math.sin(x + angle)"
print(offset_sin(math.pi))
print(offset_sin(2*math.pi/3))

print()

do
  local upvalue = 5 --- @diagnostic disable-line
  do
    local l = f.clambda "2*upvalue + x"
    print(l(1), l(2))
  end
end

print()

local x = false
local l = f.clambda "x"
assert(l(1) == 1)
assert(l() == nil)

-- assert clambda doesnt leak its own local variables
local k = f.clambda "expr"
assert(k() == nil)
print("all good on asserts")
