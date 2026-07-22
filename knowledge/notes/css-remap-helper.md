---
type: Design Note
title: __CSS_REMAP_URLS / the former helper-css-remap tool
description: History and current (dead-code) status of the CSS url() path-rewriting macro that replaced the removed Python helper-css-remap tool.
tags: [design-note, m4, css, fontawesome]
timestamp: 2026-06-18
---

# `__CSS_REMAP_URLS` / the former `helper-css-remap` tool

`helper/helper.py` used to define a Python/Click command, `helper-css-remap`,
that rewrote every `url("...")` path in a CSS file to be relative to a given
`--base` directory. Its only caller was `configure-fontawesome.m4`, which
used it to rewrite the vendored FontAwesome stylesheet's font-file URLs
before inlining it into the page's custom-styles diversion. The Python
dependency (and `helper.py` with it) was later stripped from the project
entirely, leaving that call site broken.

It was reimplemented with no external dependency as the `__CSS_REMAP_URLS`
macro in `generator.m4`, built on the existing `__HREF` path-relativization
primitive plus a `m4_bpatsubst`/`m4_dquote`/`m4_unquote` rescan trick that
lets a per-match macro call (`__HREF`) expand inside a regex replacement
template. It's covered by three `__ASSERT_EQ` cases in `generator_test.m4`
(quoted url, bare url, and mixed) — see [Testing
conventions](../testing/conventions.md).

## Current status: wired up, but inert

`configure-fontawesome.m4` calls `__CSS_REMAP_URLS` to rewrite the vendored
FontAwesome CSS's `url(...)` paths. However, the file that would `m4_include`
it (`layout.html`) has that include commented out (`dnl`-disabled), so
`configure-fontawesome.m4` — and therefore `__CSS_REMAP_URLS` — currently
plays no part in `make build`'s actual output. The macro is only exercised
today via its `generator_test.m4` assertions.

There's also a known follow-up problem if FontAwesome self-hosting is ever
revived: rewriting the `url(...)` paths to be correct relative to the output
tree isn't sufficient by itself, because the vendored font files
(`VENDOR/fontawesome-free-.../webfonts/*`) are never copied into `TEPPAN_BUILD/DOC`
in the first place (`VENDOR` is gitignored/build-only) — that would need
`__DASSET` wiring alongside the macro (the `__CP_ASSET`/`__DEFERRED_ASSET`
names this note once cited were removed when asset copying converged on
`__DASSET`). Full background — the removed Python helper's source listing
and a working-prototype trace of the correctly-computed-but-unpublishable
relative path (`../../../../VENDOR/...`) — lives in git history: the
repo-root `HELPER_CSS_REMAP_PROPOSAL.md` (implemented and superseded;
removed 2026-07-22) and `helper.py` itself (removed `4952d91`).

The proposal's open fork — self-hosted FontAwesome webfont vs moving icons
to SVG — has since been resolved by events: every shipped icon is an inline
SVG symbol (nav controls, the scroll-to-top chevron; the FontAwesome-era
footer icons are gone with the billboard redesign). That leaves the whole
`dnl`-disabled FontAwesome apparatus (`configure-fontawesome.m4`, its
vendor-zip Makefile rules, and `__CSS_REMAP_URLS` itself with its three
assertions) as dormant support for a decision history bypassed — the
registered "fontawesome / social-icon situation" item. If its deletion is
ever ruled, this note is the trace.

See also: [Core build files](../architecture/overview.md),
[CSS code review guidelines](../code-review/css.md).
