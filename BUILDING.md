# Building formulis

formulis is a plain [dune](https://dune.build) project with a single
dependency: the OCaml compiler and dune itself. The easiest way to get
both is [opam](https://opam.ocaml.org), the OCaml package manager.

## Requirements

- OCaml ≥ 4.08
- dune ≥ 3.0

## Setup

```
opam install ocaml dune
eval $(opam env)
```

`eval $(opam env)` is needed in every fresh shell before running dune;
omitted below for brevity.

## Build

```
dune build
```

Builds the library, the tests and the examples into `_build/`.

## Test

```
dune runtest          # or: dune build @runtest
```

## Run the example

```
dune exec examples/demo.exe
```

## Use as a library

The opam package is called `formulis`. Once
[installed](https://opam.ocaml.org/doc/Install.html) (or pinned to this
checkout with `opam pin add formulis .`), depend on it from your own
dune project:

```
(executable
 (name my_program)
 (libraries formulis))
```

## API documentation

With [odoc](https://ocaml.github.io/odoc/) installed:

```
opam install odoc
dune build @doc
```

The generated HTML lands in `_build/default/_doc/_html/`. This is what
the `pages` workflow publishes.
