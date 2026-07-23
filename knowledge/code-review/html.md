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
output in `TEPPAN_BUILD/DOC`, enforce the following.

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
- Interactive controls built from non-interactive elements need to be
  keyboard-operable per WAI-ARIA Authoring Practices (which the HTML spec
  defers to for ARIA semantics): an element given `role="button"` needs
  `tabindex` **and** a `keydown` handler for `Enter`/`Space` — or should be
  a real `<button>`, or (as `layout.html`'s navigation now does) a `<label>`
  paired with a visually-hidden-but-focusable checkbox, which gets keyboard
  operation for free. The nav drawer, its close control, and the language
  switch are all built this way (labels driving one `#nav-toggle` checkbox,
  plus plain `<a>` links for the locales), so there are **no** `role="button"`
  elements left in `layout.html`: the former `.lang-dd` hover-dropdown `<div>`
  — a `role="button"` with no keydown handler *and* an antipattern *positive*
  `tabindex="1"` — was removed in the Pico migration. Flag any *new*
  `role="button"` without a keydown handler, and any positive `tabindex`.
- `alt=""` is correct for purely decorative images — decided by the
  **same-control test**: an image *inside a link/control whose text already
  names it* is decorative, so `alt=""` is right (the accessible name comes from
  the text; a filled `alt` would duplicate the announcement — "English English"
  — or assert the country-for-language category error aloud, e.g. "United
  States flag English"). The language switch is exactly this case as of
  2026-07-21: each locale link pairs its text name with a decorative region
  flag `<img alt="">`, so the flag announces nothing and the link's name stays
  the text. The **contrast case** is an image that is a link's *sole* content:
  the switch's former flags-only links were nameless precisely because the
  image carried no text alongside it. Separately, flag `alt=""` on images that
  *are* the content (customer/sponsor logos in `fragment-customers.html`) —
  those need a descriptive `alt`.
- `id` attributes must be unique per document — watch for collisions when
  copying blocks between `layout.html` and the fragments it includes.
- **`<!-- -->` wrapping the top-level `__WITH_LAYOUT(...)`/`__WITH_DOMAIN(...)`
  macro call** in some page sources (e.g. `news.in.html`) is
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
- **AMP and Water have both been removed.** The initial AMP removal (commit
  `c9621d8` plus a follow-up markup cleanup) stripped `<amp-img>`,
  `<amp-sidebar>`, the `⚡` attribute on `<html>`,
  `<style amp-custom>`/`<style amp-boilerplate>`, and the
  `<script async src="https://cdn.ampproject.org/...">` runtime from the live
  sources. The later Pico migration (see
  [the Water→Pico note](../notes/water-to-pico-migration.md)) then replaced
  Water.css with Pico and collapsed the duplicated `#sidebar`/`#desktop-sidebar`
  nav lists into a single `#sidebar` source — so the old `#desktop-sidebar`
  element and its `amp-sidebar` explanatory comment are both gone. Stylesheet
  delivery is an external `<link rel="stylesheet">` to Pico plus a later one to
  `custom.css`, not inline `<style amp-custom>`, and the pages make zero
  external rendering requests (the brand font is self-hosted). **Flag any *new*
  AMP-only element/attribute as a regression**, any standard-HTML still carrying
  leftover AMP-only attributes (`layout="..."`, `on="tap:..."`), and any
  reintroduced `water.css` `<link>`.
- Page styles are delivered via external `<link rel="stylesheet">`; don't
  reintroduce ad-hoc inline `<style>` blocks.
- **Cross-domain references must go through `__ABSOLUTE`, never bare
  `__HREF`** — `__HREF` (`generator.m4`) produces a reference relative to
  the current document's origin (per RFC 3986, a relative ref cannot name a
  different scheme/host). A bare `__HREF` whose target spells *another*
  domain as a path segment (e.g. `../../tekii.ar/index.html`) only "means"
  cross-domain inside the artificially colocated build/preview tree; in
  production each content domain ships to its **own Firebase Hosting site**
  (`make publish` → `firebase deploy --only hosting`; see
  [Firebase Hosting publish pipeline](../notes/firebase-publish.md)), so that
  path 404s against the *current* domain's origin. `__ABSOLUTE`
  (`generator.m4`) is the sole cross-domain chokepoint and the only macro that
  is build-mode-aware (production: literal `http://` + domain-as-directory;
  preview, under `__PREVIEW__`: bare `__HREF` so the link stays valid off disk
  — see [`file://`-relative preview](../notes/file-relative-preview.md)).
  **Flag any cross-domain reference — an explicit cross-domain link or a
  `hreflang`/canonical alternate (`layout.html`) — that does not resolve
  through `__ABSOLUTE`**, and flag any bare `__HREF` call whose target crosses
  a domain boundary. A page/template that hardcodes its own `http://<domain>`
  instead of routing through `__ABSOLUTE` is the exact regression this rule
  exists to catch. (Cross-*domain* **redirects** are no longer an in-page
  concern: the redirect-only domains are Firebase console-level 301s, and the
  former `__REDIRECT_URL` / `layout-redirect.html` meta-refresh machinery was
  removed 2026-07-23 — see
  [Firebase Hosting publish pipeline](../notes/firebase-publish.md).)

See also: [CSS code review guidelines](css.md),
[Page source conventions](../architecture/page-source-conventions.md),
[`file://`-relative preview](../notes/file-relative-preview.md).
