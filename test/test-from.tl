local f = require "functional"
local i = 0
local function my_counter(): integer
  i = i + 1
  if i > 10 then return nil end
  return i
end
f.Iterator.from(my_counter)
  :foreach(print as f.consumer<integer>) -- prints 1 through 10 and stops