require "reqpath"
local f = require "functional"
local volume = function(w, h, d)
  return w * h * d
end

local cvolume = f.curry(volume, 3)
local partial = cvolume(2)(3)
print(partial(4), partial(5), partial(6))

print()

local hypervolume = function(a, b, c, d)
  return a * b * c * d
end

local chypervolume = f.curry(hypervolume, 3)
local partialhv = chypervolume(2)(3)
print(partialhv(4, 5), partialhv(6, 7))