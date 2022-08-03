local f = require 'functional'
local test_n = 0

local function test_successful()
  test_n = test_n + 1
  print("Passed test " .. test_n)
end

local function expect(iter: f.Iterator<integer>, correct: {integer})
  local result = iter:to_array()
  assert(#result == #correct)
  for i = 1, #result do
    assert(result[i] == correct[i])
  end
  test_successful()
end

local function is_odd(x: integer): boolean
  return x % 2 == 1
end

local seq = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
expect(f.iterate(seq), seq)
expect(f.iterate(seq):filter(is_odd), {1, 3, 5, 7, 9})
expect(f.iterate(seq):filter(f.negate(is_odd)), {2, 4, 6, 8, 10})

do
  local function test_co_f()
    local a, b = 0, 1
    while true do
      coroutine.yield(a)
      a, b = b, a+b
    end
  end
  local test_co = coroutine.create(test_co_f)
  local iter_co = f.Iterator.from_coroutine(test_co):take(10) as f.Iterator<integer>
  expect(iter_co, {0, 1, 1, 2, 3, 5, 8, 13, 21, 34})
end

do
  local file = io.open("seq.txt", "w+")
  for i in f.range(10) do
    file:write(i.."\n")
  end
  file:close()
end

do
  -- reads from file from last test
  local read_iter = f.Iterator.from(io.lines "seq.txt"):map(tonumber as f.mapping<string, integer>)
  expect(read_iter, f.range(10):to_array())
end

do
  local test_co = f.range(3, 10, 2):to_coroutine()
  local function cont(): integer
    local _, n: boolean, any = coroutine.resume(test_co)
    return n as integer
  end
  assert(cont() == 3)
  assert(coroutine.status(test_co) == "suspended")
  assert(cont() == 5)
  assert(coroutine.status(test_co) == "suspended")
  assert(cont() == 7)
  assert(coroutine.status(test_co) == "suspended")
  assert(cont() == 9)
  assert(coroutine.status(test_co) == "suspended")
  assert(cont() == nil)
  assert(coroutine.status(test_co) == "dead")
  test_successful()
end
