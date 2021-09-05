local record module
  type producer = function<T>(): T
  type consumer = function<T>(T)

  type predicate = function<T>(T): boolean
  type mapping = function<T, U>(T): U
  type reducer = function<T, A>(A, T): A

  record Iterator<T>
    create: function({T}): Iterator<T>
    create: function(Iterator<T>): Iterator<T>
    counter: function(): Iterator<integer>
    from_coroutine: function(thread): Iterator<any>
    from_iterated_call: function(producer<T>): Iterator<T>
    clone: function(Iterator<T>): Iterator<T>

    is_complete: function(Iterator<T>): boolean
    next: function(Iterator<T>): T

    to_array: function(Iterator<T>): {T}
    to_coroutine: function(Iterator<T>): thread

    filter: function(Iterator<T>, predicate<T>): Iterator<T>
    map: function<U>(Iterator<T>, mapping<T, U>): Iterator<U>
    reduce: function(Iterator<T>, reducer<T, T>): T
    reduce: function<A>(Iterator<T>, reducer<T, A>, A): A
    foreach: function(Iterator<T>, consumer<T>)

    take: function(Iterator<T>, integer): Iterator<T>
    skip: function(Iterator<T>, integer): Iterator<T>
    every: function(Iterator<T>, integer): Iterator<T>

    any: function(Iterator<T>, predicate<T>): boolean
    all: function(Iterator<T>, predicate<T>): boolean
    count: function(Iterator<T>, predicate<T>): integer

    metamethod __call: function(Iterator<T>): T
  end

  iterate: function<T>({T}): Iterator<T>
  iterate: function<T>(Iterator<T>): Iterator<T>

  filter: function<T>({T}, predicate<T>): Iterator<T>
  filter: function<T>(Iterator<T>, predicate<T>): Iterator<T>

  map: function<T, U>({T}, mapping<T, U>): Iterator<U>
  map: function<T, U>(Iterator<T>, mapping<T, U>): Iterator<U>

  reduce: function<T>({T}, reducer<T, T>): T
  reduce: function<T>(Iterator<T>, reducer<T, T>): T
  reduce: function<T, A>({T}, reducer<T, A>, A): A
  reduce: function<T, A>(Iterator<T>, reducer<T, A>, A): A

  foreach: function<T>({T}, consumer<T>)
  foreach: function<T>(Iterator<T>, consumer<T>)

  take: function<T>({T}, integer): Iterator<T>
  take: function<T>(Iterator<T>, integer): Iterator<T>
  skip: function<T>({T}, integer): Iterator<T>
  skip: function<T>(Iterator<T>, integer): Iterator<T>
  every: function<T>({T}, integer): Iterator<T>
  every: function<T>(Iterator<T>, integer): Iterator<T>

  any: function<T>({T}, predicate<T>): boolean
  all: function<T>({T}, predicate<T>): boolean

  to_array: function<T>({T}): {T}
  to_array: function<T>(Iterator<T>): {T}

  to_coroutine: function<T>({T}): thread
  to_coroutine: function<T>(Iterator<T>): thread

  negate: function<T>(predicate<T>): predicate<T>
  compose: function<T, U, V>(mapping<T, U>, mapping<U, V>): mapping<T, V>

  -- FIXME these will get proper support once
  --    https://github.com/teal-language/tl/pull/449
  -- gets merged
  bind: function<T, U>((function(...: T): U), ...: T): (function(...: T): U)
  bind_self: function<K, T, U>(table, K, ...: T): (function(...: T): U)

  accessor: function<K, V>({K: V}): mapping<K, V>
  item_getter: function<K>(K): (function<V>({K: V}): V)
  constant: function<T>(T): producer<T>
end

return module
