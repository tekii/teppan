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
- `tekii.com.ar`, `www.tekii.com.ar`, `teky.com.ar`, `teky.ar` — redirect-only (→ `tekii.ar`)
- `tekii.com`, `tekii.info`, `tekii.biz`, `tekii.co`, `tekii.net` — redirect-only (→ `tekii.us`)

`tekii.srl` and `tekii.llc` were redirect-only until 2026-07-17, when they
became each legal entity's own landing site (`tekii-srl-default.in.html`,
`tekii-llc-default.in.html`); their bodies are placeholder copy pending real
content.

The four content domains (`tekii.ar`, `tekii.us`, `tekii.srl`, `tekii.llc`)
each register their index via `__AS_LANDING`, which now also drives that
domain's `firebase.json` hosting entry (see
[Firebase Hosting publish pipeline](../notes/firebase-publish.md)). The nine
redirect-only domains ship **no HTML**: since 2026-07-23 they are **Firebase
console-level redirects** (301, path-preserving), declared in-repo via
`__AS_REDIRECT_DOMAINS` at the target's landing page and verified by
`make publish-verify`. The former meta-refresh redirect pages and the
`__REDIRECT_URL` guard were removed in that change.

See also: [Overview](overview.md),
[Firebase Hosting publish pipeline](../notes/firebase-publish.md).
