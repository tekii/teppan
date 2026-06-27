---
type: Architecture Concept
title: Core build files
description: The core files that make up the TEKii build — generator.m4, configure.m4, *.in.html sources, layout shells, and Makefile/Rules.mk.
tags: [architecture, m4, build]
timestamp: 2026-06-17
---

# Core build files

- **`generator.m4`** — core macro library: page/layout helpers, language
  (`__ES__`/`__EN__`/`__BR__`) and localization macros (`__LOCALIZE_URL_*`),
  path helpers (`__HREF`, `__ABSOLUTE`), and the diversion/phase dispatch at
  the bottom of the file. See [Diversion/phase model](diversion-phase-model.md).
- **`configure.m4`** / **`configure-fontawesome.m4`** — site-wide constants
  and macro definitions (org info, layout defaults, etc.), included by
  `generator.m4`. `configure-fontawesome.m4` is currently `dnl`-disabled —
  see [`__CSS_REMAP_URLS`/former `helper-css-remap` tool](../notes/css-remap-helper.md).
- **`*.in.html`** (e.g. `main.in.html`, `news.in.html`, `contact.in.html`,
  `jobs.in.html`, `404.in.html`, `redirect.in.html`, `srl-default.in.html`) —
  per-page m4 sources. Each stem gets a generated `.mk` under `TEKII_BUILD/DEP`,
  `-include`d by the `Makefile`. See [Page source conventions](page-source-conventions.md).
- **`layout.html`** / **`layout-redirect.html`** — page shells that consume
  the diversions produced by a page source.
- **`Makefile`** / **`Rules.mk`** — build orchestration; defines `M4_FLAGS`,
  domain/output paths (`__SRC__`, `__DOC__`, `__BUILD__`, `__VENDOR__`,
  `__ZIP__`, `__NAV__`), and per-stem rules. See [Build & test commands](../build/commands.md).

## Build output layout

- `TEKII_BUILD/DOC/` — published HTML output, assets, and per-page `.mk` deferred rules.
  This is what gets rsynced/published.
- `TEKII_BUILD/NAV/` — navigation intermediates only: per-stem `.m4` fragments
  (e.g. `TEKII_BUILD/NAV/www.tekii.com.ar/index.m4`) assembled into per-domain
  `NAVIGATION.m4` files and the cross-domain `NAVIGATION-LANDING.m4`. Not
  published. Kept separate from `TEKII_BUILD/DOC` so the published tree contains
  only HTML/assets.

## Generated/vendored paths

`.gitignore` excludes `TEKII_BUILD`, `VENDOR`, `*venv*`, etc. — these are
generated/vendored, not source.

See also: [Domains](domains.md), [`WITH_LAYOUT`/`__LAYOUT__` known issue](../notes/layout-mechanism-duplication.md),
[`__CSS_REMAP_URLS`/former `helper-css-remap` tool](../notes/css-remap-helper.md).
