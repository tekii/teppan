---
type: Design Note
title: file://-relative preview — why and how `make preview` is filesystem-browsable
description: make preview deliberately emits relative URLs (via __ABSOLUTE's __PREVIEW__ branch) instead of absolute http://host ones, so the generated site can be opened and navigated directly off disk as file:// pages, with no local HTTP server needed.
tags: [build, make, preview, m4]
timestamp: 2026-06-30
---

# `file://`-relative preview

`make preview` (`make PREVIEW=1`) exists so the generated site can be opened
straight off disk in a browser — `file:///.../TEKII_BUILD/DOC/<domain>/index.html`
— and navigated link-by-link, with **no local HTTP server**. This is a
deliberate design goal, not an incidental side effect of the build-mode-stamp
machinery (see [Build & test commands](../build/commands.md)): the stamp
mechanism exists *to support* switching into this mode cheaply, not the other
way around.

## Why this matters

A browser resolves a relative `href` against the *current page's own URL*.
For `http://...` pages that's a real host; for a page opened via
`file:///path/to/index.html`, the "host" is the page's own directory on disk.
So as long as every link in the generated HTML is relative (`en/index.html`,
not `http://tekii.ar/en/index.html`), the whole site is mutually
cross-linkable straight from the filesystem — no `python -m http.server`,
no CORS, no deploy step, just opening one file and clicking around. `build`
mode's absolute URLs would break this: opening `TEKII_BUILD/DOC/tekii.ar/index.html`
directly would still *render*, but every link on it would point at the real
`http://tekii.ar/...` production host instead of the sibling file next to it.

## How it works

The entire mechanism is one `m4_ifdef` branch in `__ABSOLUTE` (`generator.m4`):

```m4
m4_define([__ABSOLUTE],[m4_ifdef([__PREVIEW__],
[__HREF([$1])],
[http://__HREF([$1],__BUILD_ROOT__/DOC)])])dnl
```

- **`build`**: `__PREVIEW__` is undefined, so `__ABSOLUTE` takes the second
  branch — `__HREF` relative to `__BUILD_ROOT__/DOC` (treating the first path
  component as the host), prefixed with `http://`.
- **`preview`**: `Makefile`'s `ifdef PREVIEW` block adds `-D __PREVIEW__` to
  `M4_FLAGS`, so `__ABSOLUTE` takes the first branch — `__HREF([$1])` alone,
  i.e. a path relative to the *current page's own directory* (`__TDIR__`),
  with no host prefix at all.

Every `<link rel="canonical"/alternate">`/`href` that goes through
`__ABSOLUTE` (directly, or via `__REDIRECT_URL`) inherits this for free —
there is no separate "preview-mode" templating path; it's the same HTML
generation, with one macro's branch flipped by whether `__PREVIEW__` is
defined for that m4 invocation.

See also: [Build & test commands](../build/commands.md) (the
build/preview/test commands and the per-domain mode stamp that lets a
`build`↔`preview` switch be detected and rebuilt correctly).
