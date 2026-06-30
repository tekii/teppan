---
type: Build Reference
title: Build & test commands
description: make targets for building, previewing, testing, and cleaning the TEKii static site — full-site, per-domain, and per-page scoping, plus the build-mode stamp and the build-preview skill.
tags: [build, make, preview, testing]
timestamp: 2026-06-30
---

# Build & test commands

## Top-level targets

- `make build` (or just `make` — it's `.DEFAULT_GOAL`) — generate the full
  site into `TEKII_BUILD/DOC`, with absolute (`http://host/...`) URLs.
- `make preview` (equivalently `make PREVIEW=1`) — generate the full site
  into the **same** `TEKII_BUILD/DOC`, but with relative URLs, so the output
  is browsable straight off disk (`file://...`) without a host. `preview` is
  just a trampoline that re-invokes `make PREVIEW=1`.
- `make test` — run `generator_test.m4`; fails if any `__ASSERT_EQ` assertion
  prints `FAIL` (see `.claude/skills/run-tests`).
- `make clean` / `make realclean` — remove generated output. `realclean`
  recursively deletes `TEKII_BUILD` entirely (see
  [`make realclean`](../notes/realclean-recursive.md)); `clean` only removes
  files whose rules are still registered in the current source tree.

## Scoping a build to one domain or one page

Every `*.in.html` source registers itself in the generated `.mk` under a
few narrower targets, so a full `make build` isn't the only option:

- `make <domain>-build` — build (or `make PREVIEW=1 <domain>-build` —
  preview) just one domain, e.g. `make tekii-ar-build`. `<domain>` is the
  dash-substituted form of the real domain (`tekii.ar` → `tekii-ar`,
  `www.tekii.com.ar` → `www-tekii-com-ar`).
- `make $(pwd)/TEKII_BUILD/DOC/<domain>/<page>.html` — build just one page
  by its real output path. Must be the **absolute** path: `BUILD_ROOT` is
  `$(PWD)/TEKII_BUILD`, and Make matches target strings literally, so a
  relative `TEKII_BUILD/DOC/...` won't match any rule.

## Build mode (`build` vs `preview`) is stamped, not just a flag

`build` and `preview` share one `TEKII_BUILD` tree — there's no separate
preview directory. The only difference is `__PREVIEW__`'s effect on
generated HTML (relative vs absolute URLs, see `__ABSOLUTE` in
`generator.m4`). Because both modes write to the same paths, Make's
mtime-based staleness can't notice a `build`↔`preview` switch on its own —
no source file changes between the two. A `TEKII_BUILD/.mode-<domain>`
stamp file (one per domain, **not one global file** — see "BUILD MODE
STAMP" in `Makefile`) records which mode each domain's pages were last
generated in, and forces exactly the pages that need it to regenerate on a
switch:

```
$ make build                      # full site, all domains stamped "build"
$ make build                      # rerun: no-op, nothing rebuilds
$ make PREVIEW=1 tekii-ar-build    # scope a preview switch to just tekii.ar
$ make build                      # only tekii.ar rebuilds (mismatched) --
                                   # the other domains' stamps already
                                   # matched "build" and are left alone
```

Use the `build-preview` skill to build and serve `TEKII_BUILD/DOC` locally for
manual inspection in a browser.

See also: [Testing conventions](../testing/conventions.md),
[`make realclean`](../notes/realclean-recursive.md).
