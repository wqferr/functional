local record module
  record Iterator<T>
    create: function({T}): Iterator<T>
    create: function(Iterator<T>): Iterator<T>
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

    metamethod __call: function(Iterator<T>): T
  end

  iterate: function<T>({T}): Iterator<T>
  iterate: function<T>(Iterator<T>): Iterator<T>

  filter: function<T>({T}, (function(T): boolean)): Iterator<T>
  filter: function<T>(Iterator<T>, (function(T): boolean)): Iterator<T>

  map: function<T, U>({T}, (function(T): U)): Iterator<U>
  map: function<T, U>(Iterator<T>, (function(T): U)): Iterator<U>

  reduce: function<T>({T}, (function(T, T): T)): T
  reduce: function<T>(Iterator<T>, (function(T, T): T)): T
  reduce: function<T, A>({T}, (function(A, T): A), A): A
  reduce: function<T, A>(Iterator<T>, (function(A, T): A, A)): A

  foreach: function<T>({T}, (function(T)))
  foreach: function<T>(Iterator<T>, (function(T)))

  take: function<T>({T}, integer): Iterator<T>
  take: function<T>(Iterator<T>, integer): Iterator<T>
  skip: function<T>({T}, integer): Iterator<T>
  skip: function<T>(Iterator<T>, integer): Iterator<T>
  every: function<T>({T}, integer): Iterator<T>
  every: function<T>(Iterator<T>, integer): Iterator<T>

  any: function<T>({T}, (function(T): boolean)): boolean
  all: function<T>({T}, (function(T): boolean)): boolean

  to_array: function<T>({T}): {T}
  to_array: function<T>(Iterator<T>): {T}

  to_coroutine: function<T>({T}): thread
  to_coroutine: function<T>(Iterator<T>): thread

  negate: function<T>(function(T): boolean): (function(T): boolean)
  compose: function<T, U, V>((function(T): U), (function(U): V)): (function(T): V)
  bind: function<T, U>((function(...: T): U), ...: T): (function(...: T): U)
  bind_self: function<K, T, U>(table, K, ...: T): (function(...: T): U)

  accessor: function<K, V>({K: V}): (function(K): V)
  item_getter: function<K>(K): (function<V>({K: V}): V)
  constant: function<T>(T): function(): T
end

return module
