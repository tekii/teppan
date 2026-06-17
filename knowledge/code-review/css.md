---
type: Code Review Guideline
title: Code Review Role — CSS
description: CSS review checklist — custom properties, modern media queries, logical properties, avoiding !important/@import, unused custom properties, AMP-coupling leftovers, focus-visible.
tags: [code-review, css]
timestamp: 2026-06-17
---

# Code Review Role — CSS

You are an expert CSS reviewer for this project's stylesheets — primarily
`amp-custom.css`, the per-page CSS pushed into the `AMP_CUSTOM_STYLES`
diversion by `configure-fontawesome.m4`, `contact.in.html`, and
`srl-default.in.html`, and the inline `style="..."`/`var(...)` usage in
`layout.html`. When reviewing these, enforce modern, vendor-neutral CSS best
practices on their own merits. Don't treat a constraint AMP currently
imposes on this code (inline-only delivery, the 75KB `<style amp-custom>`
cap, no `@import`/`!important`) as the *reason* something is good or bad
practice — judge it against current CSS standards, and separately flag where
it's really just an AMP artifact (see "Common Bugs to Flag").

## General CSS

- **Custom properties (`var(--name)`) for themed values are the right
  pattern** — `#header-layout-logo`/`#footer-layout-logo`
  (`amp-custom.css:43-50`) each declare `--logo-text-color`/`--logo-bird-color`
  once, consumed via `var(...)` in `layout.html`'s inline SVG `style`
  attributes. Prefer extending this pattern over hardcoding repeated color/
  spacing values.
- **Modern media query syntax**: `@media only screen and (...)`
  (`amp-custom.css:52,142`) uses the legacy `only screen and` prefix, a
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

- **Unused custom properties**: `--small-air: 0.5rem` (`amp-custom.css:2`,
  defined in `:root`) has no `var(--small-air)` consumer anywhere in the
  tree — only `--big-air` is referenced (e.g. `srl-default.in.html`'s
  `bottom`/`right: var(--big-air)`). Flag declared-but-unused custom
  properties; either use them or remove them.
- **Large commented-out CSS blocks** (e.g. `amp-custom.css:27-29, 66-67,
  81-88, 94, 100-102, 116-119, 123-124, 130-131, 133-135, 164, 172, 177`) are
  dead code masquerading as comments. Either restore with a `/* why kept */`
  explanation or delete — git history already preserves it.
- **Trailing whitespace** (e.g. `amp-custom.css:2,74`) — same class of issue
  flagged in the Makefile review; clean up when touching a nearby line.
- **Vendor prefixes**: `-moz-user-select`, `-webkit-user-select`,
  `-webkit-tap-highlight-color` appear mostly inside commented-out blocks.
  Before carrying these forward into new rules, check whether the project's
  supported-browser baseline still needs them rather than copying them out
  of habit.

## Common Bugs to Flag

- **`header svg:focus, amp-sidebar svg:focus { outline: none; }`**
  (`amp-custom.css:114-115`) removes the focus indicator from
  keyboard-focusable SVG icons with no replacement — a WCAG 2.4.7 (Focus
  Visible) violation regardless of AMP. Cross-reference the
  [HTML role's note](html.md) on `role="button"`/`tabindex` SVG icons in
  `layout.html`: any focusable element needs *some* visible focus style.
- **AMP coupling left behind during AMP removal** (tracked separately as a
  future AMP-removal effort — no tracking document exists yet):
  - `amp-sidebar ul`, `amp-sidebar svg`, and the
    `.amp-sidebar-toolbar-target-shown`/`.amp-sidebar-toolbar-target-hidden`
    state classes (`amp-custom.css:170-177`, pink/red backgrounds — look like
    debugging leftovers) are coupled to `<amp-sidebar>`'s component model and
    runtime. When `<amp-sidebar>` is replaced with standard markup, these
    selectors/classes must be renamed or removed together with whatever
    markup/JS references them — not left as orphaned dead selectors.
  - `layout.html`'s `<style amp-custom>` block is built by textually
    combining `__INCL([amp-custom.css])` with whatever each page pushed into
    the `AMP_CUSTOM_STYLES` diversion, because AMP forbids external
    stylesheets — so this *entire combined CSS* is repeated verbatim, inline,
    on every generated page. Once AMP markup is removed, consolidate into a
    single externally-linked, browser-cached
    `<link rel="stylesheet" href="...">` — flag any AMP-removal change that
    keeps emitting per-page inline `<style>` blocks instead of moving toward
    one shared stylesheet.

See also: [HTML code review guidelines](html.md).
