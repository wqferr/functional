local f = require "functional"
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

local function expect_pairs(iter: f.Iterator<{integer, integer}>, correct: {{integer}})
  local result = iter:to_array()
  assert(#result == #correct)
  for i = 1, #result do
    assert(#result[i] == #correct[i])
    assert(result[i][1] == correct[i][1])
    assert(result[i][2] == correct[i][2])
  end
  test_successful()
end

do
  local a = {1, 3, 5, 7}
  local b = {2, 4, 6, 8, 10, 12}
  expect(f.concat(a, b), {1, 3, 5, 7, 2, 4, 6, 8, 10, 12})
  expect_pairs(f.packed_zip(a, b), {{1, 2}, {3, 4}, {5, 6}, {7, 8}})
  expect_pairs(f.packed_zip(b, a), {{2, 1}, {4, 3}, {6, 5}, {8, 7}, {10, nil}, {12, nil}})
end
