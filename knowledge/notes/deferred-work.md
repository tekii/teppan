---
type: Design Note
title: Deferred / open work register
description: Repo-visible register of known-but-unimplemented work items and pending decisions, so no pending task lives only in a session's private memory (per the session-memory-hygiene rules in the handoff convention).
tags: [design-note, deferred, workflow]
timestamp: 2026-07-06
---

# Deferred / open work register

Per the [session-memory-hygiene rules](../conventions/session-handoff.md),
pending work lives **here** — visible to every session and the user, auditable
and re-prioritizable — not in a session's private auto-memory. Add items as they
are deferred; remove them when done. (Feature-specific deferrals may instead live
in their own note — e.g. [`make publish`](publish-target.md),
[`sitemap.xml`](sitemap-target.md); this register is for cross-cutting or
otherwise unhomed items.)

## Self-host water.css (deferred — inner-lane)

The site loads Water.css from the jsDelivr CDN (`layout.html`), which **breaks
the `file://` offline preview** (`custom.css` is `__DASSET`'d and renders
offline; water.css doesn't) and won't load in the firewalled container.
**Approach (Option B):** wire the empty `make vendor` target to
`npm pack water.css@<pin>` into gitignored `VENDOR`, then deliver via
`__DASSET([water.css])` (swap the CDN `<link>`). npm is reachable in-container;
jsDelivr is firewalled. water.css 2.x is a single self-contained file (no
`url()`), so it does **not** need the FontAwesome
`__CSS_REMAP_URLS`/VENDOR-copy machinery — follow the `custom.css` precedent, not
the FontAwesome one.

## Wire `fragment-customers.html` into a page (deferred)

The fragment was de-AMP'd (`<amp-img>`→`<img>`, `__ASSET`→`__DASSET`, alt text)
but is `__INCL`'d by no page, so the change is **latent / not build-exercised**.
When the customers section is wanted, include it in a page and confirm the
`img/logo-*.png` assets exist.

## Revise the integration gate for change type (decision needed)

`scripts/b3-fleet.sh integrate` gates every merge on `make test` only, which
exercises `generator.m4` macros — **unnecessary for doc-only changes** and
**insufficient for build-input changes** (it doesn't cover `make build`, which
catches HTML/CSS breakage). Consider a **change-type-aware gate**: docs →
light/none; code or build inputs → `make test` **and** `make build`. Related: the
`$(PWD)`-stamp hardening's design analysis lives in
[realclean-recursive.md](realclean-recursive.md).

See also: [handoff convention](../conventions/session-handoff.md),
[Knowledge base index](../index.md).
