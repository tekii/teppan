---
type: Build Reference
title: Build & test commands
description: Teppan's make targets for building, previewing, testing, and cleaning the TEKii static multidomain sites — full-bundle, per-domain, and per-page scoping, plus the build-mode stamp and the build-preview skill.
tags: [build, make, preview, testing]
timestamp: 2026-06-30
---

# Build & test commands

## Top-level targets

- `make build` (or just `make` — it's `.DEFAULT_GOAL`) — generate the full
  site into `TEPPAN_BUILD/DOC`, with absolute (`http://host/...`) URLs.
- `make preview` (equivalently `make PREVIEW=1`) — generate the full site
  into the **same** `TEPPAN_BUILD/DOC`, but with relative URLs, so the output
  is browsable straight off disk (`file://...`) without a host. `preview` is
  just a trampoline that re-invokes `make PREVIEW=1`.
- `make test` — run `generator_test.m4`; fails if any `__ASSERT_EQ` assertion
  prints `FAIL` (see `.claude/skills/run-tests`).
- `make clean` / `make realclean` — remove generated output. `realclean`
  **empties** `TEPPAN_BUILD` recursively (and removes the directory itself only
  where it isn't the container's volume mount point — see
  [`make realclean`](../notes/realclean-recursive.md)); `clean` only removes
  files whose rules are still registered in the current source tree.

## Scoping a build to one domain or one page

Every `*.in.html` source registers itself in the generated `.mk` under a
few narrower targets, so a full `make build` isn't the only option:

- `make <domain>-build` — build (or `make PREVIEW=1 <domain>-build` —
  preview) just one domain, e.g. `make tekii-ar-build`. `<domain>` is the
  dash-substituted form of the real domain (`tekii.ar` → `tekii-ar`,
  `www.tekii.com.ar` → `www-tekii-com-ar`).
- `make $(pwd)/TEPPAN_BUILD/DOC/<domain>/<page>.html` — build just one page
  by its real output path. Must be the **absolute** path: `BUILD_ROOT` is
  `$(PWD)/TEPPAN_BUILD`, and Make matches target strings literally, so a
  relative `TEPPAN_BUILD/DOC/...` won't match any rule.

## Publishing (Firebase Hosting)

Publishing is **host-side only** (the container network is firewalled) and
**never builds** — it deploys whatever is already in `TEPPAN_BUILD/DOC`,
refusing if that is stale/preview output. See
[Firebase Hosting publish pipeline](../notes/firebase-publish.md) for the full
design.

- `make publish` — `firebase deploy … --only hosting` for all four content
  sites. Requires `FIREBASE_PROJECT` in the environment (no tracked default) —
  a publish goal without it is a parse-time error. Auth is ambient
  (`firebase login` / `GOOGLE_APPLICATION_CREDENTIALS`), never in Make.
- `make <dashed-domain>-publish` — deploy one site, e.g. `make tekii-ar-publish`
  → `--only hosting:tekii-ar-teppan-site`. Guarded by `<dashed-domain>-mode-guard`,
  which refuses unless that domain was last built in `build` mode (the
  `.mode-<domain>` stamp).
- `make publish-verify` — probe the nine console-level domain redirects
  (`curl`, 301 + `Location`, path-preserving) against the in-repo declared map.
  Exempt from the `FIREBASE_PROJECT` requirement (no CLI/project involved).
- `PREVIEW=1` with any publish goal is refused at parse time (preview output has
  `file://`-relative URLs, unfit to deploy).

`make build` generates `TEPPAN_BUILD/firebase.json` (the multi-site deploy
config) alongside the site; validate it with `jq -e . TEPPAN_BUILD/firebase.json`.

## Build mode (`build` vs `preview`) is stamped, not just a flag

See [`file://`-relative preview](../notes/file-relative-preview.md) for why
`preview` produces relative URLs in the first place (so the output is
directly browsable off disk, no server) — this section covers how the build
correctly detects and rebuilds across a `build`↔`preview` switch.

`build` and `preview` share one `TEPPAN_BUILD` tree — there's no separate
preview directory. The only difference is `__PREVIEW__`'s effect on
generated HTML (relative vs absolute URLs, see `__ABSOLUTE` in
`generator.m4`). Because both modes write to the same paths, Make's
mtime-based staleness can't notice a `build`↔`preview` switch on its own —
no source file changes between the two. A `TEPPAN_BUILD/.mode-<domain>`
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

Use the `build-preview` skill to build and serve `TEPPAN_BUILD/DOC` locally for
manual inspection in a browser.

See also: [Testing conventions](../testing/conventions.md),
[Firebase Hosting publish pipeline](../notes/firebase-publish.md),
[`make realclean`](../notes/realclean-recursive.md).
