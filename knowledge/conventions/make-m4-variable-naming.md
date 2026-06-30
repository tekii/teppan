---
type: Convention
title: Make vs m4 variable naming — `__X__` is the m4 facet, plain `X` is the Make facet
description: A path constant that exists in both the m4 (compile-time) and Make (run-time) worlds carries two names that name the two facets — `__X__` for the m4 macro, plain `X` for the Make variable — bridged by the uniform `-D __X__=$(X)` pattern. Make-only variables stay plain; this naming is never applied to m4-only macros.
tags: [m4, makefile, conventions, naming]
timestamp: 2026-06-29
---

# Make vs m4 variable naming

This project's path constants (`BUILD_ROOT`, `SRC`, `VENDOR`) genuinely live
in **two worlds**, and the build relies on the difference:

- the **m4 (compile-time) facet** — e.g. `__BUILD_ROOT__/DOC/...` in
  `generator.m4`'s `__HREF`/`__ABSOLUTE`/`m4_include` — expands *now*, while
  the generator runs, to the path the run was invoked under (m4 needs a real
  path for `realpath`).
- the **Make (run-time) facet** — e.g. `$(BUILD_ROOT)` emitted into the
  generated `.mk` files — is resolved *later*, by Make. `build` and
  `preview` now share the single `TEKII_BUILD` root (see the "BUILD MODE
  STAMP" block in `Makefile`); historically this facet's root-agnosticism
  was also what let the same `.mk` work under either of two separate
  `TEKII_BUILD`/`TEKII_PREVIEW` roots.

## The rule

- **`__X__`** (double-underscore prefix and suffix) = the **m4** facet — an
  m4 macro, consistent with [the m4 review convention](../code-review/m4.md)
  that `__name__` denotes a custom m4 macro.
- **plain `X`** (no affix) = the **Make** facet — a Make variable.
- **Make-only variables stay plain** (`M4_FLAGS`, `EXTRA_*_FLAGS`,
  `GSUTIL_EXTRA_FLAGS`, `M4`, `TMP`): they have no m4 twin, were never
  error-prone, and get no decoration.

The two facets are bridged by the uniform pattern the `Makefile` already
uses to hand a value from Make to a nested m4 run:

```make
-D __BUILD_ROOT__=$(BUILD_ROOT)
```

— the flag *name* is the m4 macro (`__BUILD_ROOT__`), its *value* comes from
the Make variable (`$(BUILD_ROOT)`).

## Why distinct names (the bug this prevents)

When both facets shared the single name `__BUILD_ROOT__`, the *only* thing
distinguishing "expand now (m4)" from "defer to Make" was whether the token
was bracket-quoted: `[$(__BUILD_ROOT__)]` (emit a literal Make reference)
versus a bare `__BUILD_ROOT__` (expand immediately). That signal is invisible
and easy to get wrong — drop the brackets on a dual-named token and m4
silently expands it to the baked compile-time path. Distinct names make the
phase explicit at every site, and a bare `$(BUILD_ROOT)` in emitted text no
longer needs bracket-quoting to stay literal, because `BUILD_ROOT` is not a
defined m4 macro.

## When editing

The discriminator is **per-occurrence, not per-identifier** — never blind-sed
a dual identifier:

- `$(X)` (a Make reference) → the Make facet → plain `X`.
- bare `__X__` used as an m4 macro (path building, `m4_include`, a value
  passed after `=`) → the m4 facet → keep `__X__`.

Emit a Make reference **without** m4 quotes — write `$(BUILD_ROOT)`, not
`[$(BUILD_ROOT)]`. The `[...]` only protected the *old* name when it doubled
as an m4 macro; a plain Make name is never an m4 macro (and m4's `$` is
special only before a digit/`#`/`*`/`@`, not `(`), so the quotes are inert
noise. Flag `[$(X)]` in newly emitted Make text. (This is distinct from the
genuinely load-bearing `[$]@` / `[$$]` / `[#]` quotes, which protect
characters m4 *does* treat specially — keep those.)

See also: [M4 code review guidelines](../code-review/m4.md),
[GNU Makefile code review guidelines](../code-review/makefile.md),
[Diversion/phase model](../architecture/diversion-phase-model.md).
