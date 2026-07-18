---
type: Design Note / Trace
title: Water.css → Pico.css migration (framework swap)
description: Why the classless CSS base moved from Water.css to Pico.css v2.1.1 — what Water provided, why it lost, and what would justify revisiting.
tags: [css, third-party, trace-note, migration]
timestamp: 2026-07-18
---

# Water.css → Pico.css migration

On 2026-07-18 the vendored classless CSS base moved from **Water.css** to
**Pico.css v2.1.1 (classless build)**, and the brand wordmark font moved from a
Google Fonts `<link>` to a self-hosted, vendored **'Days One'** woff2. This is
a design-bearing removal (a whole framework retired in favour of a survivor),
so per the [trace-notes-on-removal convention](../severance/SEVERANCE.md) this
note preserves the *why* that git history can't.

## What Water provided (the lost design's mechanics)

- A **classless, typography-only base**: sensible defaults for bare elements
  (`body`, headings, `a`, `p`, form controls) with **zero layout opinions** —
  no grid, no container, no components. `custom.css` supplied *all* structure
  (the flex app-shell, the off-canvas drawer, the desktop sidebar column).
- **Light/dark via `prefers-color-scheme`**, exposing a small set of CSS
  variables. Notably `custom.css`'s drawer coupled to Water's `--background`
  (`background: var(--background, #fff)`) so the drawer picked up the scheme's
  page background for free.
- Delivered exactly like Pico is now: a tracked `third_party/water.css` copied
  per-domain via `__DASSET`, offline-safe, pinned by the `vendor` refresh
  helper. Roughly **32 KB** unminified.

## Why it lost (conditional, not on the merits of Water's output)

Water's *output* was fine — this was a **maintenance/health** decision, so the
loss is **conditional**, not a judgment that Water's CSS was wrong:

- **Upstream dormancy.** Water's `master` last shipped a commit **2021-08-23**
  (not archived, but ~4 years quiet) with a large backlog of untriaged issues.
  Pico is actively maintained (repo pushed **2026-05-09**; npm latest 2.1.1
  from 2025-03-15).
- **Pico buys more with the same delivery mechanism.** Its classless build
  still needs no classes on our markup, but ships a fuller variable system
  (`--pico-*`) our nav/logo theming now wires into, plus dark-mode and
  spacing tokens — for ~**71 KB** minified (~80 KB unminified), a size increase
  accepted for the maintenance win.
- **Simple.css was considered and rejected**: archived **May 2026**, and its
  720px breakpoint misaligned with the project's 768px boundary.

## What was accepted as fallout

- `custom.css` shrank to: the two logo color blocks, the `@font-face` +
  brand-font class, minimal logo/social-icon sizing, and **one** navigation
  block (the single-source drawer/sidebar hybrid). IBM Plex fonts, the footer
  dark theme, `--big-air`/`--small-air`, `scroll-behavior`, and all
  commented-out blocks were removed.
- The duplicated `#sidebar`/`#desktop-sidebar` nav lists collapsed to one
  `#sidebar`; the two language switches (`.lang-dd` hover dropdown +
  `#lang-sidebar` drawer) collapsed to one in-sidebar list.
- Pages now make **zero external rendering requests** (Pico, `custom.css`, the
  font, and all images are same-origin).
- A hard-won Pico-specific gotcha: Pico's **classless** selectors can outrank a
  plain class — `[type=checkbox] ~ label` (0,1,1) beat `.nav-backdrop` (0,1,0)
  and left the drawer backdrop permanently overlaying the page. Fixed by
  qualifying as `label.nav-backdrop`. Captured in the
  [CSS review guidelines](../code-review/css.md).

## What would justify revisiting

- **Pico's weight or opinions prove wrong** for the project — if the ~71 KB
  (vs Water's ~32 KB) or Pico's default component styling starts fighting the
  design more than it helps, a lighter classless base (or hand-rolled resets)
  becomes worth reconsidering.
- **Pico goes dormant** the way Water did — the maintenance argument that
  justified the swap would then cut the other way.

See also: [CSS review guidelines](../code-review/css.md),
[HTML review guidelines](../code-review/html.md),
[asset-copy mechanisms](asset-copy-mechanisms.md).
