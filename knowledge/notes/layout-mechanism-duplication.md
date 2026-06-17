---
type: Known Issue
title: WITH_LAYOUT / __LAYOUT__ duplication
description: Duplicated default-layout logic between configure.m4 and the WITH_LAYOUT macro; proposed fix making the layout parameter mandatory.
tags: [known-issue, m4, layout]
timestamp: 2026-06-17
---

# WITH_LAYOUT Problems

As the Claude code review reveals, the `__LAYOUT__` definition mechanism
needs to be reviewed and revisited, specially related to the `WITH_LAYOUT`
macro duplication bug.

## Current situation / Problems / Bugs

- The file `generator.m4` at line 333 includes a layout file assuming the
  macro `__LAYOUT__` was defined in `configure.m4` and/or modified after
  `m4_include(__FIRST__)` (around line 329) by the `WITH_LAYOUT` macro
  itself. There is a duplication of the default layout definitions in the
  design: one in `configure.m4`, and a second in the macro definition
  itself through the `m4_default` (see `m4_include(__LAYOUT__)dnl`). The
  definition in `configure.m4` allows simple content files `*.in.html`
  without a `WITH_XXX` macro invocation, but as the code review reveals,
  this creates a duplication.

- The command line in the test's direct invocation of the generator has a
  `-D __LAYOUT__ = XXX`.

- Since we assume only one layout per page generation, there is no reason
  for `m4_pushdef` / `m4_popdef`; any previous definition should be
  considered a fatal error and invoke `m4_fatal`, aborting the generation.

## An initial approach

- Since we already have a default mechanism through the `configure.m4`
  file, the optional parameter in `WITH_LAYOUT` looks redundant: if you
  decide to use the macro, it's to change the layout, so the parameter
  should be mandatory — if you use the macro you MUST provide the
  alternative layout, otherwise the macro has no purpose.

See also: [Core build files](../architecture/overview.md),
[M4 code review guidelines](../code-review/m4.md).
