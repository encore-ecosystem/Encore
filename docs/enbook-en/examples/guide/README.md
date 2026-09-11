# Encore book examples

Every source file in this project is compiled by the documentation check. The
named `ANCHOR` regions are included directly into individual book pages.

From this directory, using a compiler matching the source checkout:

```sh
encore format --check
encore check
encore lint
encore test --jobs 2
encore run
```

The entrypoint performs a non-interactive smoke check. Unit tests exercise the
language examples and text/parallel tutorials; standalone negative tests
require specific diagnostics for invalid radix, literal range, and use after
thread transfer. They must fail compilation for the expected reason.

The relative `path@` dependency is for this contributor fixture. Readers should
follow the book's fresh-project steps and add published dependencies rather
than copying this manifest.
