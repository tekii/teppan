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
`__CP_ASSET`/`__DEFERRED_ASSET` wiring alongside the macro. Full background,
including a working-prototype trace of the bad relative path this produces
today, is in the repo-root `HELPER_CSS_REMAP_PROPOSAL.md`.

See also: [Core build files](../architecture/overview.md),
[CSS code review guidelines](../code-review/css.md).
