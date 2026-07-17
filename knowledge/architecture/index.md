---
type: Index
title: Architecture
description: Overview of Teppan's m4-based static-site architecture (the generator that builds the TEKii static multidomain sites); links to the diversion/phase model, domain layout, and page-source conventions.
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
- [Navigation mechanics](navigation.md) — how the nav menu is built
  end-to-end: `__NAV_ITEM` registration, the diversion → per-stem fragment →
  per-domain `NAVIGATION.m4` → `__NAV__ITEMS__` → render pipeline, menu
  ordering, and cross-domain `__NAV_HREF` resolution.
