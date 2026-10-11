# formulis

![logo](formulis_logo.svg)

[![CI](https://github.com/rxdt-labs/formulis/actions/workflows/test.yml/badge.svg)](https://github.com/rxdt-labs/formulis/actions/workflows/test.yml)
[![docs](https://github.com/rxdt-labs/formulis/actions/workflows/pages.yml/badge.svg)](https://github.com/rxdt-labs/formulis/actions/workflows/pages.yml)
[![license](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)

A radically simple reactive programming library.

A **term** stores a value that can change over time. A **formula** combines terms (and other formulae) with operations and always evaluates to the most up-to-date value of each term it uses:

```ocaml
let x = Formulis.term 3
and y = Formulis.term 5 in
let z = Formulis.Int.(Term x +~ Term y) in        (* z = 8 *)
Formulis.on_change z (fun old new_ ->
    Printf.printf "z changed from %d to %d\n" old new_);
Formulis.set x 4;
Formulis.eval z                                  (* 9 — updated automatically *)
```

The equivalent compiled example lives in
[examples/demo.ml](examples/demo.ml); run it with `dune exec examples/demo.exe`:

```
8
z changed from 8 to 9
9
```

## Features

- **Radically simple.** Terms, formulae and change listeners — that is
  the whole API.
- **Automatic updates.** Setting a term refreshes every formula that
  (transitively) uses it, and fires the listeners of every value that
  actually changed.
- **Typed operators.** OCaml has no overloading of `+` across types, so
  the operators live in small modules: [`Formulis.Int`](src/formulis.mli),
  `Formulis.Float` and `Formulis.Bool`.
- **Custom operators.** Any function becomes a reactive operator with
  `Formulis.map` and `Formulis.map2`.
- **No manual memory work.** The garbage collector owns the dependency
  graph: there is nothing to disconnect and nothing to leak.

## Documentation

- [Using formulis](docs/pages/using.md) — the public API from a user's
  point of view.
- [How it works](docs/pages/internals.md) — the update algorithm and the
  data structures behind it.
- [The test suite](docs/pages/tests.md) — what is covered and how to run
  it.
- API reference — `dune build @doc` with
  [odoc](https://ocaml.github.io/odoc/) installed.

## Building and testing

See [BUILDING.md](BUILDING.md). The short version:

```
opam install ocaml dune
dune build @runtest
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [HACKING.md](HACKING.md).

## License

[Apache License 2.0](LICENSE)
