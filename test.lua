local func = require('func')

local t = {1, 2, 3, 4, 5, 6, 7, 8}
local it = func.iter(t)
it = it:filter(function(x) return x % 2 == 1 end)

print(it:next_element())
print(it:next_element())
print(it:next_element())
print(it:next_element())
print(it:next_element())
print(it:next_element())