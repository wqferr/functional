local f = require "functional"
local deg2rad = f.lambda2 {"(x) => x*pi/180", pi=math.pi}
print(deg2rad(180))
print(deg2rad(0))
print(deg2rad(60))
