---
type: Index
title: Architecture
description: Overview of TEKii's m4-based static site architecture; links to the diversion/phase model, domain layout, and page-source conventions.
tags: [architecture, index]
timestamp: 2026-06-17
---

# Architecture

TEKii's site is generated ahead of time by GNU `m4` into static
HTML/CSS/assets — there's no application server.

- [Overview](overview.md) — the core files: `generator.m4`, `configure.m4`,
  `*.in.html` sources, layout shells, `Makefile`/`Rules.mk`.
- [Diversion/phase model](diversion-phase-model.md) — how content is routed
  through named m4 diversions and dispatched by `__PHASE__`.
- [Domains](domains.md) — which domains are full multi-locale sites vs.
  redirect-only.
- [Page source conventions](page-source-conventions.md) — conventions a
  `*.in.html` source follows.
