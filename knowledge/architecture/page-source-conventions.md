---
type: Architecture Concept
title: Page source conventions
description: Conventions a *.in.html page source follows — HEAD/MAIN diversions, __NAV_ITEM, fragment includes, __ENES/__ESEN, asset macros.
tags: [architecture, m4, conventions]
timestamp: 2026-06-17
---

# Page source conventions

A `*.in.html` source typically:

- Pushes content into the `HEAD` diversion via `m4_divert_text([HEAD], [...])`
  for `<title>`/`<meta>` tags.
- Pushes body content into `MAIN` via `m4_divert_push([MAIN]) ... m4_divert_pop([MAIN])`,
  starting with a `__NAV_ITEM(...)` call to register the page in the nav menu.
- Pulls in reusable sections with `__INCL([fragment-*.html])` (see
  `fragment-home.html`, `fragment-services.html`, `fragment-customers.html`).
- Uses `__ENES([English text],[Spanish text])` / `__ESEN([Spanish],[English])`
  for inline per-language strings, rather than separate files per locale.
- Asset references go through `__ASSET`, `__CP_ASSET`, `__DEFERRED_ASSET` to
  get copied/hashed into the build output.

See also: [Diversion/phase model](diversion-phase-model.md),
[HTML code review guidelines](../code-review/html.md),
[M4 code review guidelines](../code-review/m4.md).
