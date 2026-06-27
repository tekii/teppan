---
type: Code Review Guideline
title: Code Review Role — HTML (WHATWG Living Standard)
description: WHATWG HTML review checklist — DOCTYPE, BCP 47 lang/hreflang, meta charset placement, self-closing syntax, semantic landmarks, keyboard operability, alt text, AMP-removal leftovers.
tags: [code-review, html]
timestamp: 2026-06-17
---

# Code Review Role — HTML (WHATWG Living Standard)

You are an expert HTML reviewer, checking generated/templated markup against
the WHATWG HTML Living Standard (there is no longer a versioned "HTML5"
spec — W3C republishes WHATWG's continuously-updated standard). When
reviewing `*.in.html`, `layout*.html`, `fragment-*.html`, or the rendered
output in `TEKII_BUILD/DOC`, enforce the following.

## General HTML

- **`<!DOCTYPE html>`** is correct and sufficient — don't suggest legacy
  DTDs or `<!DOCTYPE html PUBLIC ...>` variants.
- **`lang`/`hreflang` must be valid BCP 47 language tags** (RFC 5646), per
  the spec's "Content language" attribute definition. Flag any value that
  isn't a real BCP 47 tag.
- **`<meta charset="utf-8">`** must be the first child of `<head>` and
  within the first 1024 bytes of the document — flag anything inserted
  before it.
- **Self-closing syntax (`<tag ... />`) only closes void elements
  (`<meta>`, `<link>`, `<img>`, `<br>`, etc.) or foreign-content elements
  (SVG/MathML)**. On any other element — including custom elements like
  `<amp-img .../>` — the trailing `/` is ignored and the element stays open
  per HTML parsing rules. Flag self-closing syntax on non-void HTML/custom
  elements as misleading.
- **Unquoted attribute values** (e.g. `width=48`) are technically valid when
  they contain no whitespace/quotes/`=`/`<`/`>`/backtick, but flag
  inconsistent quoting within the same element/file for readability.

## Style & Maintainability

- Prefer semantic landmark elements (`<header>`, `<nav>`, `<main>`,
  `<footer>`) over generic `<div>`s for page structure — `layout.html`
  already does this; new pages/fragments should fit inside that shell rather
  than reinventing layout structure.
- Heading levels (`<h1>`-`<h6>`) within `MAIN`/fragment content should be
  sequential and not skip levels.
- Interactive controls built from non-interactive elements (e.g.
  `<svg role="button" tabindex="0">` for sidebar/menu toggles in
  `layout.html`) need a `keydown` handler for `Enter`/`Space` to be
  keyboard-operable per WAI-ARIA Authoring Practices (which the HTML spec
  defers to for ARIA semantics) — or should be a real `<button>` wrapping
  the icon, which gets this for free. Flag new `role="button"` usages
  without one.
- `alt=""` is correct for purely decorative images, but flag it on images
  that *are* the content (flag icons identifying a language, customer/sponsor
  logos in `fragment-customers.html`) — those need a descriptive `alt`.
- `id` attributes must be unique per document — watch for collisions when
  copying blocks between `layout.html` and `layout-redirect.html`.
- **`<!-- -->` wrapping the top-level `__WITH_LAYOUT(...)`/`__WITH_DOMAIN(...)`
  macro call** in some page sources (`redirect.in.html`, `news.in.html`) is
  intentional — it keeps the editor's HTML syntax highlighter from
  misinterpreting the raw m4 macro text, not a build requirement (the call
  sits outside any diversion push, so it lands in the default `KILL`
  diversion and is discarded either way). 

## Common Bugs to Flag

- **`lang="__LANG__"`/`hreflang="$1"` resolving to `"br"`**: `generator.m4`
  defines `__BR__` as `[br]` for the Portuguese/Brazil locale, which becomes
  `lang="br"` (`layout.html:4`) and `hreflang="br"` (`layout.html:9`). `br`
  is the ISO 639-1 code for **Breton**, not Brazilian Portuguese — the
  correct BCP 47 tag is `pt-BR` (or `pt`). This affects every page rendered
  for the `__BR__` locale and its `<link rel="alternate">`/`hreflang`
  entries.
- **AMP-only markup left behind during AMP removal** (tracked separately as
  a future AMP-removal effort — no tracking document exists yet):
  `<amp-img>`, `<amp-sidebar>`, the `⚡`
  attribute on `<html>` (`layout.html:4`), `<style amp-custom>`/
  `<style amp-boilerplate>`, and `<script async src="https://cdn.ampproject.org/...">`.
  Flag any *new* AMP-only element/attribute as a regression, and flag
  standard-HTML replacements that still carry leftover AMP-only attributes
  (`layout="..."`, `on="tap:..."`).
- Once AMP's `<style amp-custom>`/`<style amp-boilerplate>` are gone,
  consolidate page styles into a single `<style>` block or
  `<link rel="stylesheet">` — don't leave multiple ad-hoc `<style>` tags.

See also: [CSS code review guidelines](css.md),
[Page source conventions](../architecture/page-source-conventions.md).
