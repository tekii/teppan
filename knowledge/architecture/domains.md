---
type: Architecture Concept
title: Domains
description: The TEKii domains and which ones are full sites (multi-locale or single-locale landing) vs. redirect-only.
tags: [architecture, domains]
timestamp: 2026-06-17
---

# Domains

- `tekii.ar` — main Spanish site: ES at root, `en/` and `br/` locale subdirs
- `tekii.us` — main English site: EN at root
- `tekii.srl` — TEKii SRL landing site: ES at root (single locale)
- `tekii.llc` — TEKii LLC landing site: EN at root (single locale)
- `www.tekii.com.ar`, `teky.com.ar`, `teky.ar` — redirect-only (→ `tekii.ar`)
- `tekii.com`, `tekii.info` — redirect-only (→ `tekii.us`)

`tekii.srl` and `tekii.llc` were redirect-only until 2026-07-17, when they
became each legal entity's own landing site (`tekii-srl-default.in.html`,
`tekii-llc-default.in.html`); their bodies are placeholder copy pending real
content. Each registers its index via `__AS_LANDING`, which is also what the
redirect guard (`__REDIRECT_URL`, `generator.m4`) now requires of any
redirect *target*.

See also: [Overview](overview.md).
