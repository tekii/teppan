---
type: Index
title: Teppan Knowledge Base
description: Entry point into the Teppan knowledge base; links to architecture, build/test, testing conventions, code review guidelines, and project conventions.
tags: [overview, teppan, tekii]
timestamp: 2026-06-17
---

# Teppan

**Teppan** is the static-site generation project in this repo `tekii/teppan`
(renamed from the legacy `www` on 2026-07-04). It builds the **TEKii static
multidomain sites** — a
multi-domain, multi-language bundle of static sites for the company **TEKii** —
with GNU `m4`, using autoconf's `m4sugar.m4f` macro library standalone (not via
`configure.ac`/`autoconf`) for its `m4_*` primitives. There is no application
server — everything is rendered ahead of time into plain HTML/CSS/assets under
`TEPPAN_BUILD/DOC`. See the [glossary](glossary.md) for the
company / project / repo / deliverable distinction.

This knowledge base is authored in the [Open Knowledge Format (OKF)](okf.md) —
a directory of markdown files with YAML frontmatter.

Infrastructure & collaboration knowledge (dev container, multi-agent
workflow, handoff) lives in [infra/](infra/index.md).

## Sections

- [Glossary & naming](glossary.md) — canonical names: **TEKii** (company),
  **Teppan** (this project — and now the repo name), **www** (the former repo
  name), and the **TEKii static
  multidomain sites** (the deliverable bundle). Read this first — the docs
  historically conflated these terms.
- [Architecture](architecture/index.md) — how the sites are built: core
  files, the diversion/phase model, domains, and page-source conventions.
- [Build & test commands](build/commands.md) — `make build`/`preview`/`test`/`clean`,
  per-domain/per-page scoping, and the build-mode stamp.
- [Testing conventions](testing/conventions.md) — `generator_test.m4` and `__ASSERT_EQ`.
- [Code review guidelines](code-review/index.md) — M4, GNU Makefile, HTML,
  and CSS review checklists.
- Conventions — [M4 conditional formatting](conventions/m4-conditional-formatting.md),
  [M4 comment style](conventions/m4-comment-style.md),
  [Make vs m4 variable naming](conventions/make-m4-variable-naming.md),
  [no user-specific or hardcoded absolute paths (Severance SPEC)](severance/SEVERANCE.md),
  [Severance consumer profile (Teppan's half of the workflow contract)](severance/profile.md).
- Design notes & known issues — [`file://`-relative preview](notes/file-relative-preview.md),
  [asset-copy mechanisms (non-deferred vs deferred)](notes/asset-copy-mechanisms.md),
  [`__ASSET` rule duplication](notes/asset-rule-duplication.md),
  [why the Makefile review role exists](notes/makefile-review-rationale.md),
  [`WITH_LAYOUT`/`__LAYOUT__` duplication](notes/layout-mechanism-duplication.md),
  [`__CSS_REMAP_URLS`/former `helper-css-remap` tool](notes/css-remap-helper.md),
  [Water.css → Pico.css migration (framework swap trace)](notes/water-to-pico-migration.md),
  [`make realclean` — recursive `TEPPAN_BUILD` deletion](notes/realclean-recursive.md),
  [Firebase Hosting publish pipeline (`firebase.json` + deploy targets)](notes/firebase-publish.md),
  [gsutil publish flow (retired — replaced by Firebase Hosting)](notes/publish-target.md),
  [`sitemap.xml` generation — not yet implemented](notes/sitemap-target.md),
  [deferred / open work register (project; infra/process items in `infra/`)](notes/deferred-work.md),
  [`Rules.mk` recursive sub-make rationale](notes/rules-mk-rationale.md).
