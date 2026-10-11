# Hacking on formulis

## Layout

```
src/formulis.ml      the whole library (~150 lines)
src/formulis.mli     its documented interface
test/formulis_test.ml  port of the original C++ Catch2 suite
examples/demo.ml     the README example, runnable
docs/pages/          prose documentation
```

## Core invariants

The library is small, but its behaviour is precise. When changing it,
preserve these properties (they are what the C++ original guarantees
and what the test suite pins down):

1. **`term` listeners run before parent formulae.** `set` stores the
   new value, runs the term's own listeners with `(old, new)`, and only
   then notifies each dependent formula.
2. **A formula updates only when its value actually changed.**
   `update_formula` fires listeners, clears the dirty flag and
   propagates to parents only under structural inequality of old and
   new values. If the recomputed value equals the cached one, nothing
   happens — and the dirty flag deliberately *stays set*.
3. **A formula evaluates once, at construction.** The cache is primed
   with `compute ()` while the dirty flag remains true until the first
   successful `update_formula`.
4. **`eval` is pure.** Reading a dirty formula recomputes it without
   writing the cache or clearing the flag.
5. **Registration order is propagation order.** Listeners and parents
   are stored in the order they were registered (`list @ [ x ]`).

Consequence of 2 + 5, kept on purpose: in a diamond (`w = x + y`,
`y = x + 1`) a single `set x` propagates depth-first and inner nodes
may be read with stale caches mid-propagation — the same "glitch"
semantics the C++ library has.

## Adding an operator

Every operator is a thin wrapper over `map`/`map2`. To add one, put it
in the matching module in `src/formulis.ml`, mirror it in
`src/formulis.mli`, and add a test section. There is no macro layer —
`map2 f a b` *is* the `REGISTER_BIN_OP` of this port.

## Porting notes (C++ → OCaml)

| C++                                  | OCaml                            |
| ------------------------------------ | -------------------------------- |
| operator overloads                   | `Int` / `Float` / `Bool` modules |
| `REGISTER_BIN_OP` / macros           | `map2`                           |
| `REGISTER_UNARY_PROC`                | `map`                            |
| `const_<T>` lifted-constant registry | the `Const` constructor (GC-owned) |
| `std::function` expr trees           | `compute : unit -> 'a` closures  |
| term copy ctor (value only)          | `term (get x)`                   |
| observer formulae, `m_owns_tree`     | not needed — values are shared by reference |
| manual disconnect in destructors     | not needed — the GC owns the graph |

## Testing

```
dune build @runtest
```

The suite must stay green; when porting new C++ sections, keep the
original scenario names so the suites stay comparable.
