require "reqpath"
local f = require "functional"
local function my_totally_real_message_queue()
  coroutine.yield("this is a message")
  coroutine.yield("hello!")
  coroutine.yield("almost done")
  coroutine.yield("bye bye")
end

local co = coroutine.create(my_totally_real_message_queue)
for count, message in f.Iterator.from_coroutine(co):enumerate() do
  io.write(count, ": ", message, "\n")
end
io.write("end\n")

letters = f.every({"a", "b", "c", "d", "e"}, 2)
for idx, letter in letters:enumerate() do
  print(idx, letter)
end

