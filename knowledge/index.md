---
type: Index
title: TEKii Knowledge Base
description: Entry point into the TEKii knowledge base; links to architecture, build/test, testing conventions, code review guidelines, and project conventions.
tags: [overview, tekii]
timestamp: 2026-06-17
---

# TEKii static site

A static website (multi-domain, multi-language) generated with GNU `m4`,
using autoconf's `m4sugar.m4f` macro library standalone (not via
`configure.ac`/`autoconf`) for its `m4_*` primitives. There is no application
server — everything is rendered ahead of time into plain HTML/CSS/assets under
`BUILD/DOC`.

## Sections

- [Architecture](architecture/index.md) — how the site is built: core
  files, the diversion/phase model, domains, and page-source conventions.
- [Build & test commands](build/commands.md) — `make build`/`make test`/`make clean`.
- [Testing conventions](testing/conventions.md) — `generator_test.m4` and `__ASSERT_EQ`.
- [Code review guidelines](code-review/index.md) — M4, GNU Makefile, HTML,
  and CSS review checklists.
- [Conventions](conventions/git-commit-attribution.md) — commit message attribution.
- Design notes & known issues — [`__ASSET` rule duplication](notes/asset-rule-duplication.md),
  [why the Makefile review role exists](notes/makefile-review-rationale.md),
  [`WITH_LAYOUT`/`__LAYOUT__` duplication](notes/layout-mechanism-duplication.md),
  [`__CSS_REMAP_URLS`/former `helper-css-remap` tool](notes/css-remap-helper.md).
