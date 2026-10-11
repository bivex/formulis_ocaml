# The test suite

The suite is a port of the original C++ Catch2 tests. Catch2 is C++'s;
OCaml needs no framework at this size, so [formulis_test.ml](../../test/formulis_test.ml)
keeps the familiar TEST_CASE/SECTION shape with a tiny hand-rolled
harness: every `check_*` bumps a counter, a failed suite prints what
failed and exits non-zero.

Currently: **42 sections, 117 checks**, covering:

- **simple terms** — `set`, `incr`/`decr` (including the C++
  post-increment "returns the old value" behaviour), `+=`, `-=`.
- **2/3/4-term formulae** — creation, updating on each term change,
  two parenthesizations for the 3- and 4-term cases.
- **constants in formulae** — both operand sides, chained constants,
  several formulae sharing one term, constants nested in
  sub-expressions, term copies staying independent.
- **boolean operators** — `&&~`, `||~`, `not`, constants on either
  side, mixed expressions, `bool` terms. (The C++ sections operate on
  `int` truthiness; here they operate on real `bool` terms via the
  `Bool` module.)
- **custom boolean operator** — `is_even` via `map`.
- **unary operators** — `neg` on terms, formulae and mixed
  expressions; unary plus as `map (fun v -> v)`; `bit_not`.
- **set from formula and term** — `set_from` copies the current value
  only.
- **on_change** — old/new capture on auto-bound formulae, multiple
  listeners, operators applied to bound formulae staying reactive,
  listeners on nested formulae.
- **custom operator** — `my_func = 3·x + 1` via `map`.

## Running

```
dune build @runtest     # or: dune runtest
```

Expected output:

```
117 passed, 0 failed
```

## Adapting C++ sections

Most sections port verbatim. The systematic adaptations:

- int-truthiness boolean tests run over `bool` terms (`Bool` module);
- `!f` over an int formula becomes `not (map (fun v -> v <> 0) f)`;
- term copies are `term (get x)`;
- the C++ "copy of a copy" observer test reduces to registering on the
  formula itself, since OCaml formula values are the node — there is
  no observer indirection to exercise.
