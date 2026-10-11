# Using formulis

Everything lives in one module:

```ocaml
open Formulis
```

## Terms

A term is a mutable cell whose value can change over time:

```ocaml
let x = term 3          (* a term holding 3 *)
let v = get x           (* read it: 3 *)
let () = set x 4        (* write it *)
```

`set` is a no-op propagation-wise when the value does not actually
change: listeners fire and formulae update only under real changes
(values are compared with structural equality, the OCaml equivalent of
C++ `operator==`).

A "copy" of a term copies only its value — an independent term sharing
no formulae and no listeners with the original, exactly like C++
copy-construction:

```ocaml
let y = term (get x)
```

## Formulae and operators

There is no operator overloading in OCaml, so each operator family
lives in a module matching the operand type — `Int`, `Float` and
`Bool`. Operators are suffixed with `~` to keep them apart from the
plain OCaml ones:

```ocaml
module I = Formulis.Int

let x = term 2
let y = term 3
let z = I.(Term x +~ Term y)        (* 5 *)
let w = I.(Term x +~ Const 1)       (* constants lift automatically *)
let o = I.(Term x +~ Const 1 +~ Const 2 +~ Term y)   (* chains compose *)
```

Since every operator takes and returns an `expr` (a constant, a term
or a formula), sub-expressions nest freely:

```ocaml
let a = term 2 and b = term 3
let z = I.((Term a +~ Const 1) *~ (Term b +~ Const 2))   (* 15 *)
```

Available modules:

- `Int` — `+~ -~ *~ /~ %~`, `^~`/`bit_and`/`bit_or` (bitwise),
  `neg`, `bit_not`, and the term mutators `incr`, `decr`, `+=`, `-=`,
  `*=`, `/=`, `+=~`, `-=~`, `*=~`, `/=~`.
- `Float` — `+~ -~ *~ /~ **~` and `neg`.
- `Bool` — `&&~ ||~` (non-short-circuiting, as befits reactive
  expressions) and `not`.

## Custom operators

Any function becomes a reactive operator. This replaces the C++
`REGISTER_UNARY_PROC` macro:

```ocaml
let my_func x = 3 * x + 1
let is_even x = x mod 2 = 0

let x = term 3
let z = map my_func (Term x)     (* 10 *)
let b = map is_even (Term x)     (* true *)
```

`map2` is the binary version and is what every operator above is
built from:

```ocaml
let hypot a b = Float.sqrt (a *. a +. b *. b)
let h = map2 hypot (Term a) (Term b)
```

## Reading values

```ocaml
eval (Term x)       (* the term's value *)
eval (Const 5)      (* 5 *)
eval z              (* the formula's cached value, recomputed if stale *)
```

`eval` is pure: recomputing a stale formula never writes its cache.

## Observing changes

```ocaml
on_change z (fun old new_ ->
    Printf.printf "z changed from %d to %d\n" old new_)
```

Listeners run in registration order, receive the old and the new
value, and fire only when the observed value actually changed.
Registering on a `Const` raises `Invalid_argument`, since constants
never change.

## Setting a term from a formula

`set_from` stores the *current* value of an expression into a term;
the term does not become reactive on the expression:

```ocaml
let x = term 1 and y = term 2
let f = I.(Term x +~ Const 41)
set_from y f        (* y = 42 *)
set x 0             (* f = 41 now, but y stays 42 *)
```
