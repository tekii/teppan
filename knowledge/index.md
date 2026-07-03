---
type: Index
title: Teppan Knowledge Base
description: Entry point into the Teppan knowledge base; links to architecture, build/test, testing conventions, code review guidelines, and project conventions.
tags: [overview, teppan, tekii]
timestamp: 2026-06-17
---

# Teppan

**Teppan** is the static-site generation project in this repo (the repo name
`www` is legacy). It builds the **TEKii static multidomain sites** — a
multi-domain, multi-language bundle of static sites for the company **TEKii** —
with GNU `m4`, using autoconf's `m4sugar.m4f` macro library standalone (not via
`configure.ac`/`autoconf`) for its `m4_*` primitives. There is no application
server — everything is rendered ahead of time into plain HTML/CSS/assets under
`TEPPAN_BUILD/DOC`. See the [glossary](glossary.md) for the
company / project / repo / deliverable distinction.

This knowledge base is authored in the [Open Knowledge Format (OKF)](okf.md) —
a directory of markdown files with YAML frontmatter.

## Sections

- [Glossary & naming](glossary.md) — canonical names: **TEKii** (company),
  **Teppan** (this project), **www** (legacy repo name), and the **TEKii static
  multidomain sites** (the deliverable bundle). Read this first — the docs
  historically conflated these terms.
- [Architecture](architecture/index.md) — how the sites are built: core
  files, the diversion/phase model, domains, and page-source conventions.
- [Build & test commands](build/commands.md) — `make build`/`preview`/`test`/`clean`,
  per-domain/per-page scoping, and the build-mode stamp.
- [Testing conventions](testing/conventions.md) — `generator_test.m4` and `__ASSERT_EQ`.
- [Code review guidelines](code-review/index.md) — M4, GNU Makefile, HTML,
  and CSS review checklists.
- Conventions — [commit message attribution](conventions/git-commit-attribution.md),
  [M4 conditional formatting](conventions/m4-conditional-formatting.md),
  [M4 comment style](conventions/m4-comment-style.md),
  [Make vs m4 variable naming](conventions/make-m4-variable-naming.md).
- Design notes & known issues — [`file://`-relative preview](notes/file-relative-preview.md),
  [`chrome-devtools` MCP setup (project-local Node/Chrome profile)](notes/chrome-devtools-mcp-setup.md),
  [dev container — Claude Code + Playwright MCP (three-scenario setup)](notes/devcontainer-setup.md),
  [asset-copy mechanisms (non-deferred vs deferred)](notes/asset-copy-mechanisms.md),
  [`__ASSET` rule duplication](notes/asset-rule-duplication.md),
  [why the Makefile review role exists](notes/makefile-review-rationale.md),
  [`WITH_LAYOUT`/`__LAYOUT__` duplication](notes/layout-mechanism-duplication.md),
  [`__CSS_REMAP_URLS`/former `helper-css-remap` tool](notes/css-remap-helper.md),
  [`make realclean` — recursive `TEPPAN_BUILD` deletion](notes/realclean-recursive.md),
  [`make publish` — intended gsutil publish flow (incomplete)](notes/publish-target.md),
  [`sitemap.xml` generation — not yet implemented](notes/sitemap-target.md),
  [`Rules.mk` recursive sub-make rationale](notes/rules-mk-rationale.md),
  [parallel development — branch workflow, worktrees & multi-agent setup](notes/parallel-agent-worktrees.md).
