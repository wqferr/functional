local f = require('func', true)


local function even(x)
  return x % 2 == 0
end

local function succ(x)
  return x + 1
end

local function double(x)
  return 2*x
end


local mega_succ = f.compose(succ, f.compose(double, succ))


local t = {0, 1, 2, 3, 4, 5, 6, 7, 8}

local it = f.filter(t, even):map(mega_succ)

it:foreach(print)