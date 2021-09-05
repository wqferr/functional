local record Iterator<T>
  create: function({T}): Iterator<T>
  counter: function(): Iterator<integer>
  from_coroutine: function(thread): Iterator<any>
  from_iterated_call: function((function(): T)): Iterator<T>
  clone: function(Iterator<T>): Iterator<T>
end

return Iterator
