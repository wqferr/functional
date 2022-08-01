local f = require "functional"

print(f.range(3, 37, 4):reduce(f.lambda "b - a", 0))
f.range(10)
  :map(f.lambda "2*x" as f.mapping<integer, integer>)
  :foreach(print as f.consumer<integer>)

print(f.lambda"20*x")