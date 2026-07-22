---
type: Code Review Guideline
title: Code Review Role — CSS
description: CSS review checklist — Pico custom properties, modern media queries, logical properties, avoiding !important/@import, Pico-vs-class specificity, AMP/Water leftovers, focus-visible.
tags: [code-review, css]
timestamp: 2026-06-17
---

# Code Review Role — CSS

You are an expert CSS reviewer for this project's stylesheets — primarily
`custom.css`, delivered site-wide via an external `<link rel="stylesheet">`
*after* Pico.css (`third_party/pico.classless.css`, Pico's **classless**
build), so `custom.css` layers on top of and overrides Pico. Also in scope:
any per-page CSS pushed into the `CUSTOM_STYLES` diversion — currently only
`configure-fontawesome.m4` carries such a block, and its `m4_include` is
`dnl`-disabled, so no active page ships a per-page `CUSTOM_STYLES` block (the
former `tekii-ar-default.in.html` scroll-to-top styles moved site-wide into
`custom.css`) — and the inline `style="..."`/`var(...)` usage in `layout.html`.
When reviewing these, enforce modern, vendor-neutral CSS best practices on their own merits.
AMP has been removed (its former inline-only-delivery and 75KB
`<style amp-custom>` cap no longer apply), and the base framework is now
**Pico, not Water** (see [the Water→Pico migration note](../notes/water-to-pico-migration.md)).
Judge the CSS against current standards, prefer Pico's custom properties
(`--pico-*`) for theming, and flag any leftover AMP or Water artifact for
removal.

**Out of scope: `third_party/`.** Real third-party artifacts (Pico.css:
`third_party/pico.classless.css`; the 'Days One' brand wordmark font:
`third_party/days-one-latin.woff2`; each with its `.LICENSE` file) are
vendored — pinned by the `vendor` refresh helper, reviewed upstream, never
hand-edited. Do not review their style; instead flag any diff that hand-edits
a file under `third_party/` (the fix belongs upstream, or in a pin bump).

## General CSS

- **Custom properties (`var(--name)`) for themed values are the right
  pattern** — `#header-layout-logo`/`#footer-layout-logo` each set
  `--logo-text-color`/`--logo-bird-color` (consumed via `var(...)` in
  `layout.html`'s inline SVG `style` attributes). Post-Pico, prefer wiring
  themed values to Pico's own variables so light/dark follows Pico
  automatically — the logo text color is `var(--pico-muted-color)`, which
  flips with the scheme, rather than a fixed gray. Prefer extending this
  pattern over hardcoding repeated color/spacing values; use `--pico-spacing`
  in place of the removed `--big-air`/`--small-air` tokens.
- **Modern media query syntax**: write `@media (min-width: 768px)` directly,
  not the legacy `@media only screen and (...)` prefix (a pre-Media-Queries-
  Level-3 holdover). `custom.css`'s surviving media query already uses the
  modern form and Pico's 768px boundary — flag `only screen and` in any new
  media query as unnecessary.
- **Logical properties over physical**: prefer `margin-inline`/
  `padding-block`/`inset-*`/`block-size`/`inline-size` etc. over
  `margin-left`/`right`/`top`/`bottom`/`width`/`height` in new or touched
  rules, so layout adapts correctly under `dir="rtl"` or vertical writing
  modes without extra overrides. `custom.css` now follows this throughout
  (e.g. `inline-size`/`block-size` for logo and icon sizing,
  `inset-block`/`inset-inline-start` for the drawer); hold new rules to the
  same standard.
- **Avoid `!important`/`@import` as general hygiene** — specificity escape
  hatches and `@import`'s render-blocking, serial-fetch behavior are
  problems independent of any AMP restriction. If a new rule reaches for
  `!important` to win a specificity fight, treat it as a signal to fix the
  selector instead (see the Pico-specificity note under "Common Bugs").

## Style & Maintainability

- **Unused / dead declarations**: flag declared-but-unused custom properties
  and large commented-out `/* ... */` blocks masquerading as comments. The
  old `custom.css` carried both (`--small-air`, several dead blocks); the
  Pico rewrite removed them. Either use a value or delete it — git history
  already preserves removals.
- **Trailing whitespace** — same class of issue flagged in the Makefile
  review; clean up when touching a nearby line in `custom.css`.
- **Vendor prefixes** (`-moz-user-select`, `-webkit-*`): before carrying any
  forward into a new rule, check whether the project's supported-browser
  baseline still needs it rather than copying out of habit.

## Common Bugs to Flag

- **Pico's element/attribute selectors can outrank a plain class — check
  specificity before assuming `custom.css` wins.** Because Pico is classless,
  it styles bare elements and attribute-qualified selectors, some of which
  are *more specific* than a single class. The migration hit this concretely:
  Pico's `[type=checkbox] ~ label { display: inline-block }` (specificity
  0,1,1) silently overrode the drawer backdrop's `.nav-backdrop { display:
  none }` (0,1,0), leaving a full-viewport overlay permanently rendered over
  the page and swallowing every click. The fix was to qualify as
  `label.nav-backdrop` (0,1,1) — a tie that `custom.css`, loading after Pico,
  wins. Flag any `custom.css` rule that *relies on* class-vs-element ordering
  where a Pico attribute/pseudo-class selector could tie or beat it (checkbox/
  radio-adjacent labels, `a[aria-current]`, form controls); verify the winner
  in-browser rather than assuming class beats element.
- **Focus visibility on the drawer's hidden checkbox** — the no-JS drawer's
  control (`#nav-toggle`) is `position: absolute; opacity: 0` (focusable but
  invisible), so keyboard focus on it must be surfaced on the *visible*
  labels. `custom.css` does this with
  `body:has(#nav-toggle:focus-visible) .nav-open svg, ... .nav-close svg { outline }`.
  Flag any new focusable-but-invisible control that removes or omits a visible
  focus style, or any blanket `outline: none` on a focusable element with no
  replacement — a WCAG 2.4.7 (Focus Visible) violation. Cross-reference the
  [HTML role's note](html.md) on `role="button"`/`tabindex` SVG icons.
- **AMP and Water have both been removed.** AMP left first (the initial
  migration, commit `c9621d8`, replacing `<amp-sidebar>` with the CSS-only
  checkbox/`:has()` drawer and renaming `amp-custom.css` → `custom.css`);
  Water was then replaced by Pico (see
  [the Water→Pico migration note](../notes/water-to-pico-migration.md)).
  - **Flag any change that reintroduces `<amp-*>`-coupled selectors** (e.g.
    `amp-sidebar ul`) or the dead
    `.amp-sidebar-toolbar-target-shown`/`-hidden` state classes.
  - **Flag any change that goes back to per-page inline `<style>` blocks**
    instead of the shared, browser-cached external stylesheet. Delivery is a
    single external `<link>` to Pico plus a later `<link>` to `custom.css`
    (cascade order is load-bearing: custom overrides Pico).
  - **Flag any reintroduced Water artifact** (`third_party/water.css`, a
    `water.css` `<link>`, or Water-specific selectors/variables).
- **`__CSS_REMAP_URLS`'s `__HREF` is same-origin by design — don't misapply
  the cross-domain rule to it.** The cross-domain-reference rule in the
  [HTML role](html.md) (cross-domain refs must go through `__ABSOLUTE`, not
  bare `__HREF`) does **not** touch `url(...)` rewriting: a stylesheet's
  asset URLs (fonts, background images, icons) are always same-origin, so
  `__CSS_REMAP_URLS` (`generator.m4`) rewriting them to `__TDIR__`-relative
  paths via bare `__HREF` is correct, not a violation. The same logic covers
  `custom.css`'s `@font-face` `src: url("days-one-latin.woff2")`: the font is
  delivered same-origin (to each domain's DOC root, beside `custom.css`), so
  the bare-filename url resolves stylesheet-relative — flag a `url(...)` that
  reaches *across* domains (there should be none), but never "upgrade" a
  legitimately same-origin CSS asset path to `__ABSOLUTE`.

See also: [HTML code review guidelines](html.md),
[Water→Pico migration note](../notes/water-to-pico-migration.md),
[`__CSS_REMAP_URLS`/former `helper-css-remap` tool](../notes/css-remap-helper.md).
