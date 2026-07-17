---
type: Code Review Guideline
title: Code Review Role — CSS
description: CSS review checklist — custom properties, modern media queries, logical properties, avoiding !important/@import, unused custom properties, AMP-coupling leftovers, focus-visible.
tags: [code-review, css]
timestamp: 2026-06-17
---

# Code Review Role — CSS

You are an expert CSS reviewer for this project's stylesheets — primarily
`custom.css` (renamed from `amp-custom.css`), delivered site-wide via an
external `<link rel="stylesheet">` alongside Water.css, plus the per-page CSS
pushed into the `CUSTOM_STYLES` diversion by `configure-fontawesome.m4`,
`contact.in.html`, and `srl-default.in.html`, and the inline
`style="..."`/`var(...)` usage in `layout.html`. When reviewing these, enforce
modern, vendor-neutral CSS best practices on their own merits. AMP has been
removed, so its former constraints (inline-only delivery, the 75KB
`<style amp-custom>` cap) no longer apply — judge the CSS against current
standards, and flag any leftover AMP artifact for removal (see "Common Bugs
to Flag").

**Out of scope: `third_party/`.** Real third-party artifacts (Water.css:
`third_party/water.css` + its license file) are vendored — pinned by the
`vendor` refresh helper, reviewed upstream, never hand-edited. Do not review
their style; instead flag any diff that hand-edits a file under
`third_party/` (the fix belongs upstream, or in a pin bump).

## General CSS

- **Custom properties (`var(--name)`) for themed values are the right
  pattern** — `#header-layout-logo`/`#footer-layout-logo`
  (`custom.css:47-52`) each declare `--logo-text-color`/`--logo-bird-color`
  once, consumed via `var(...)` in `layout.html`'s inline SVG `style`
  attributes. Prefer extending this pattern over hardcoding repeated color/
  spacing values.
- **Modern media query syntax**: `@media only screen and (...)`
  (`custom.css:104,195`) uses the legacy `only screen and` prefix, a
  holdover from pre-Media-Queries-Level-3 syntax meant to exclude older user
  agents. Write `@media (max-width: 767px)` / `@media (min-width: 768px)`
  directly — flag `only screen and` in any new media query as unnecessary.
- **Logical properties over physical**: prefer `margin-inline`/
  `padding-block`/`inset-*`/`block-size`/`inline-size` etc. over
  `margin-left`/`right`/`top`/`bottom`/`width`/`height` in new or touched
  rules, so layout adapts correctly under `dir="rtl"` or vertical writing
  modes without extra overrides.
- **Avoid `!important`/`@import` as general hygiene** — specificity escape
  hatches and `@import`'s render-blocking, serial-fetch behavior are
  problems independent of any AMP restriction. If a new rule reaches for
  `!important` to win a specificity fight, treat it as a signal to fix the
  selector instead, not as a now-permitted workaround once AMP is gone.

## Style & Maintainability

- **Unused custom properties**: `--small-air: 0.5rem` (`custom.css:2`,
  defined in `:root`) has no `var(--small-air)` consumer anywhere in the
  tree — only `--big-air` is referenced (e.g. `srl-default.in.html`'s
  `bottom`/`right: var(--big-air)`). Flag declared-but-unused custom
  properties; either use them or remove them.
- **Large commented-out CSS blocks** — several dead `/* ... */` blocks remain
  in `custom.css`, masquerading as comments. Either restore with a
  `/* why kept */` explanation or delete — git history already preserves it.
- **Trailing whitespace** — same class of issue flagged in the Makefile
  review; clean up when touching a nearby line in `custom.css`.
- **Vendor prefixes**: `-moz-user-select`, `-webkit-user-select`,
  `-webkit-tap-highlight-color` appear mostly inside commented-out blocks.
  Before carrying these forward into new rules, check whether the project's
  supported-browser baseline still needs them rather than copying them out
  of habit.

## Common Bugs to Flag

- **Blanket `outline: none` on focusable header/drawer elements**
  (`custom.css:169` `header *`, and `custom.css:177` `header svg, .drawer svg`)
  removes the focus indicator from
  keyboard-focusable SVG icons with no replacement — a WCAG 2.4.7 (Focus
  Visible) violation regardless of AMP. Cross-reference the
  [HTML role's note](html.md) on `role="button"`/`tabindex` SVG icons in
  `layout.html`: any focusable element needs *some* visible focus style.
  Related, post-AMP-removal: the drawer toggles' checkboxes
  (`.drawer-toggle`, `custom.css:61` — `position: absolute; opacity: 0`) are
  correctly focusable-but-invisible, so keyboard focus on them shows nothing
  at all; give the *visible* part a focus style, e.g.
  `body:has(#sidebar-toggle:focus-visible) label[for="sidebar-toggle"] svg { outline: 2px solid; }`.
- **AMP has been removed** (the Water.css migration, commit `c9621d8`):
  - The former `amp-sidebar`-coupled selectors (`amp-sidebar ul`,
    `amp-sidebar svg`) and the orphaned
    `.amp-sidebar-toolbar-target-shown`/`.amp-sidebar-toolbar-target-hidden`
    state classes are gone; the off-canvas nav is now a CSS-only
    checkbox/`:has()` drawer rather than `<amp-sidebar>`'s runtime. `amp-custom.css`
    was renamed to `custom.css`. **Flag any change that reintroduces
    `<amp-*>`-coupled selectors or those dead state classes.**
  - Stylesheet delivery moved from the inline `<style amp-custom>` concatenation
    — which repeated the *entire combined CSS* verbatim, inline, on every page
    (because AMP forbade external stylesheets) — to a single external,
    browser-cached `<link rel="stylesheet">` (Water.css + `custom.css`). **Flag
    any change that goes back to emitting per-page inline `<style>` blocks**
    instead of the shared external stylesheet.
- **`__CSS_REMAP_URLS`'s `__HREF` is same-origin by design — don't misapply
  the cross-domain rule to it.** The cross-domain-reference rule in the
  [HTML role](html.md) (cross-domain refs must go through `__ABSOLUTE`, not
  bare `__HREF`) does **not** touch `url(...)` rewriting: a stylesheet's
  asset URLs (fonts, background images, icons) are always same-origin, so
  `__CSS_REMAP_URLS` (`generator.m4:102`) rewriting them to `__TDIR__`-relative
  paths via bare `__HREF` is correct, not a violation. Flag a `url(...)` that
  reaches *across* domains (there should be none), but never "upgrade" a
  legitimately same-origin CSS asset path to `__ABSOLUTE`.

See also: [HTML code review guidelines](html.md),
[`__CSS_REMAP_URLS`/former `helper-css-remap` tool](../notes/css-remap-helper.md).
