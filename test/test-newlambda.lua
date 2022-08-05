require "reqpath"
local f = require "functional"

local l = f.lambda2 "(x) => (y)   => x+y"
print(l(1)(3))
