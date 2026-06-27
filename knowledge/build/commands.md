---
type: Build Reference
title: Build & test commands
description: make targets for building, testing, and cleaning the TEKii static site, plus the build-preview skill.
tags: [build, make, testing]
timestamp: 2026-06-17
---

# Build & test commands

- `make build` — generate the full site into `TEKII_BUILD/DOC`
- `make test` — run `generator_test.m4`; fails if any `__ASSERT_EQ` assertion
  prints `FAIL` (see `.claude/skills/run-tests`)
- `make clean` / `make realclean` — remove generated output

Use the `build-preview` skill to build and serve `TEKII_BUILD/DOC` locally for
manual inspection in a browser.

See also: [Testing conventions](../testing/conventions.md).
