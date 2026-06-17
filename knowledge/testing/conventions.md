---
type: Convention
title: Testing conventions
description: How generator_test.m4 and __ASSERT_EQ self-check macro behavior; make test's pass/fail detection.
tags: [testing, m4]
timestamp: 2026-06-17
---

# Testing conventions

`generator_test.m4` includes `generator.m4`, diverts into `TESTS`, and uses
`__ASSERT_EQ(NAME, ACTUAL, EXPECTED)` (defined at the top of that file) to
self-check macro behavior. `make test` greps the output for `^FAIL`. When
adding coverage for a macro, derive `EXPECTED` independently (don't just copy
the macro's own output) — see `.claude/skills/add-assertion`.

See also: [Build & test commands](../build/commands.md),
[Diversion/phase model](../architecture/diversion-phase-model.md).
