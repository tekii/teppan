---
type: Convention
title: Testing conventions
description: How generator_test.m4 and __ASSERT_EQ self-check macro behavior; make test's pass/fail detection.
tags: [testing, m4]
timestamp: 2026-06-17
---

# Testing conventions

`generator_test.m4` includes `generator.m4` and uses
`__ASSERT_EQ(NAME, ACTUAL, EXPECTED)` (defined at the top of that file) to
self-check macro behavior. `make test` greps the output for `^FAIL`. When
adding coverage for a macro, derive `EXPECTED` independently (don't just copy
the macro's own output) — see `.claude/skills/add-assertion`.

## Each test group owns its own `TESTS` push/pop

Unlike older revisions of this file, the top level of `generator_test.m4`
stays in `KILL`-diversion context throughout — there's no single top-level
`m4_divert([TESTS])`. Each group of related `__ASSERT_EQ` calls instead
wraps itself in its own `m4_divert_push([TESTS])dnl ... m4_divert_pop([TESTS])dnl`
pair. GNU m4 auto-flushes every numbered diversion (including `TESTS`) to
stdout at EOF regardless of how many separate push/pop spans wrote to it, so
all groups' assertions still end up concatenated in one `make test` run —
but **a new `__ASSERT_EQ` call added outside any `TESTS` push silently lands
in `KILL` and never appears in `make test`'s output** (no error, no `FAIL`,
just missing). When adding a new, unrelated assertion group, wrap it in its
own push/pop; when extending an existing group, add the line inside that
group's existing push/pop span.

This structure is also what keeps the file's legacy/scratch experiments
(left in place, unwrapped, for historical reference) from polluting
`make test`'s output — and it's what makes the file's top-level
documentation comments safe to write as `#` rather than `dnl` — see the
[M4 comment style convention](../conventions/m4-comment-style.md).

See also: [Build & test commands](../build/commands.md),
[Diversion/phase model](../architecture/diversion-phase-model.md).
