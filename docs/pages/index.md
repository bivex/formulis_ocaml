# formulis docs

**formulis** is a radically simple reactive programming library: a
*term* stores a value that can change over time, a *formula* combines
terms (and other formulae) with operations and always evaluates to the
most up-to-date value of each term it uses.

- [Using formulis](using.md) — the public API from a user's point of
  view.
- [How it works](internals.md) — the update algorithm and the data
  structures behind it.
- [The test suite](tests.md) — what is covered and how to run it.

The API reference is generated with odoc (`dune build @doc`); start
from `Formulis` in `_build/default/_doc/_html/`.
