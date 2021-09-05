local record Iterator<T>
  create: function({T}): Iterator<T>
  counter: function(): Iterator<integer>
  from_coroutine: function(thread): Iterator<any>
  from_iterated_call: function((function(): T)): Iterator<T>
  clone: function(Iterator<T>): Iterator<T>

  is_complete: function(Iterator<T>): boolean
  next: function(Iterator<T>): T

  to_array: function(Iterator<T>): {T}
  to_coroutine: function(Iterator<T>): thread

  filter: function(Iterator<T>, (function(T): boolean)): Iterator<T>
  map: function<U>(Iterator<T>, (function(T): U)): Iterator<U>
  reduce: function(Iterator<T>, (function(T, T): T)): T
  reduce: function<A>(Iterator<T>, (function(A, T): A), A): A
  foreach: function(Iterator<T>, (function(T)))

  take: function(Iterator<T>, integer): Iterator<T>
  skip: function(Iterator<T>, integer): Iterator<T>
  every: function(Iterator<T>, integer): Iterator<T>

  any: function(Iterator<T>, (function(T): boolean)): boolean
  all: function(Iterator<T>, (function(T): boolean)): boolean
  count: function(Iterator<T>, (function(T): boolean)): integer
end

-- FIXME this is wrong, it returns something else
return Iterator
