require "reqpath"
local f = require "functional"

local l = f.lambda "(x) => (y)   => x+y"
print(l(1)(3))
print(l.body)
print(tostring(l))
print(f.lambda(("()=>"):rep(5) .. "'lol'").body)

assert(not pcall(f.lambda2, "(x) (what) => 3*x"))
assert(not pcall(f.lambda2, ("()=>"):rep(20) .. "'lol'"))
