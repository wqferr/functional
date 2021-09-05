local record Iterator<T>
  create: function({T}): Iterator<T>
  counter: function(): Iterator<integer>
  from_coroutine: function(thread): Iterator<any>
  from_iterated_call: function((function(): T)): Iterator<T>
  clone: function(Iterator<T>): Iterator<T>

  is_complete: function(Iterator<T>): boolean
  next: function(Iterator<T>): T

  filter: function(Iterator<T>, (function(T): boolean)): Iterator<T>
  map: function<U>(Iterator<T>, (function(T): U)): Iterator<U>
  reduce: function(Iterator<T>, (function(T, T): T)): T
  reduce: function<A>(Iterator<T>, (function(A, T): A), A): A
  foreach: function(Iterator<T>, (function(T)))
end

-- FIXME this is wrong, it returns something else
return Iterator
