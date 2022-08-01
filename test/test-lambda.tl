local f = require "functional"

print(f.range(3, 37, 4):reduce(f.lambda "b - a", 0))
f.range(10)
  :map(f.lambda "2*x" as f.mapping<integer, integer>)
  :foreach(print as f.consumer<integer>)

print(f.lambda"20*x")

print(f.lambda("2*pi", {pi=math.pi})())

print(pcall(f.lambda"2*pi")) -- this should error with a readable message
local meta_lambda_creator = f.lambda("l'2*pi'", {l=f.lambda})
local meta_lambda = meta_lambda_creator() as function
print(pcall(meta_lambda)) -- still readable error message