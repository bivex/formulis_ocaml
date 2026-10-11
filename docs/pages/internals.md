# How formulis works

The whole library is a hundred-odd lines in
[formulis.ml](../../src/formulis.ml); this page walks through them.

## The two node kinds

```ocaml
type 'a term = {
  mutable value : 'a;
  mutable parents : dependent list;             (* formulae using it *)
  mutable listeners : ('a -> 'a -> unit) list; (* on_change callbacks *)
}

type 'a formula = {
  mutable dirty : bool;          (* cache may be out of date *)
  compute : unit -> 'a;          (* how to recompute *)
  mutable cached : 'a;           (* last computed value *)
  mutable listeners : ('a -> 'a -> unit) list;
  mutable parents : dependent list;
}
```

Expressions (`'a expr` = `Const` / `Term` / `Formula`) are what users
handle; constants are plain values carried in the closure, so the GC
owns their lifetime and the C++ lifted-constant registry disappears.

## The dependent link

Terms and formulae both hold a list of *parents*: formulae that must
react when they change. OCaml node types differ in their value type,
so the list stores an existential-free handle — a record with a single
`notify` closure:

```ocaml
type dependent = { notify : unit -> unit }
```

When a formula is built over operands, it links itself into each
operand's `parents` (constants are skipped — they never change). A
`notify` does two things, mirroring C++ `formula::update`:

```ocaml
let notify f () = f.dirty <- true; update_formula f
```

`compute` closures replace the C++ `stmt` variant (`unary_expr` /
`bin_expr` over `std::function`): `map2 f a b` is literally
`fun () -> f (eval a) (eval b)`.

## The update algorithm

`set t v`:

1. Store `v`, compare old and new with structural equality.
2. If changed, run the term's listeners with `(old, new)`.
3. Then notify each parent formula, in registration order.

`update_formula f`:

1. Save `old = f.cached`, recompute `f.cached`.
2. If the value changed: run listeners, clear the dirty flag, notify
   the parents (which recurses depth-first, synchronously).
3. If it did not change: do nothing — and leave the dirty flag set.

Two deliberate oddities inherited from the C++ original:

- **A formula evaluates once at construction** (the cache is primed
  with `compute ()`), but its dirty flag stays true until the first
  *update* that changes the value.
- **`eval` is pure.** Reading a dirty formula recomputes without
  writing the cache or clearing the flag.

The combination yields the same "glitch" semantics as the C++ library:
in a diamond (`w = x + y`, `y = x + 1`), one `set x` propagates
depth-first and the outer formula may briefly observe a stale inner
cache. That is observable, tested behaviour — do not "fix" it.

## What the garbage collector bought us

The C++ library spends most of its bulk on ownership: `const_`
registries, observer formulae forwarding to originals, `m_owns_tree`
destructor walks. In OCaml, values are shared by reference and freed
by the GC, so:

- a formula value *is* the node — no observer layer, ever;
- lifting a constant is the `Const` constructor;
- dropping the last reference to a sub-graph silently unlinks it.

Registering the same operand twice (as in `x + x`) simply stores two
identical `dependent` records; the duplicate notification is harmless
because updates are idempotent under value equality.
