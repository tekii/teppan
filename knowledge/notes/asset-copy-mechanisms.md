---
type: Design Note
title: Asset-copy mechanisms — non-deferred vs deferred, and why we converged on deferred
description: The two ways generator.m4 copied page assets into the build, why the non-deferred one was retired in favour of the deferred one, and the design of the removed code (kept here for future reference).
tags: [design-note, makefile, assets, m4]
timestamp: 2026-06-28
---

# Asset-copy mechanisms — non-deferred vs deferred

`generator.m4` historically had **two** ways to declare that a source asset
(image, font, favicon, …) should be copied into the published tree and
referenced from a page. This note records both, why one was chosen over the
other, and — because the losing mechanism is being deleted in the **next**
commit — preserves its design so the trade-off can be revisited later.

## The two mechanisms

### Non-deferred — `__ASSET` / `__CP_ASSET` / `__ASSET3`

These push a **prerequisite-only** rule into the `MAKEFILE` diversion (which
becomes the page's `DEP/<stem>.mk`, `-include`d by the top `Makefile`):

```make
$(__BUILD_ROOT__)/DOC/<root>/img/logo.png : $(__SRC__)/img/logo.png   # no recipe
```

The **copy recipe** is supplied separately by the generic per-extension
pattern rules in `Makefile` (`%.ico`, `%.png`, `%.jpg`, `%.ttf`, …):

```make
$(__BUILD_ROOT__)/DOC/%.png : | $$(@D)/
	cp $< $@
```

GNU Make merges the explicit prereq with the pattern recipe (`$<` becomes the
declared source). The macros differ only in scope: `__ASSET` fans out to every
domain in `__ROOTS__` and ties the asset to every page in `__BUILD_TARGETS__`;
`__CP_ASSET` scopes to the current `__DOMAIN__`; `__ASSET3` to a single
`__ROOT__` plus an explicit target.

**Merits:** eager, simple, no recursion; the asset participates in the main
Make dependency graph with normal incremental rebuilds. For genuinely
**static, site-wide** assets this is the lighter, more direct model.

**Why it was retired (the bugs):**

- **href / copy mismatch (broken links).** `__ASSET` returns
  `__HREF([__BUILD_ROOT__/DOC/$1])` — a *domain-less* path
  (`DOC/img/logo.png`) — while it copies the file to `DOC/<domain>/img/...`.
  The rendered `src`/`href` therefore points at a path that is never created,
  so the layout's favicon/logo/DATAWEB links 404 on **every** page.
- **Overcopy.** `__ASSET` copies into every `__ROOTS__` domain regardless of
  which pages actually reference the asset (the long-standing `TODO ... this
  is an error`).
- **Layout-context limitation.** `__CP_ASSET` fixes the scoping but keys on
  `__DOMAIN__`/`__PATH_STEM__`, which are **undefined when the layout expands
  in the `MAKEFILE` phase** (the layout is `m4_include`d after `__WITH_DOMAIN`
  has popped `__DOMAIN__`). That is why `__CP_ASSET`/`__ASSET3` were written
  but never adopted — they only work for page-source calls, not layout calls.

### Deferred — `__DASSET` (originally `__DEFERRED_ASSET2`)

Emits a **self-contained** copy rule (its own `cp` recipe) into the
`DEFERRED_MK` diversion, which becomes a per-stem `DOC/<stem>.mk` generated
during the build (`GENERATE_DEFERRED_MK_PHASE`) and run via recursive
sub-make (`-f Rules.mk -f <stem>.mk assets-copy` — see
[`Rules.mk` recursive sub-make rationale](rules-mk-rationale.md)):

```make
$(__BUILD_ROOT__)/DOC/<domain>/img/logo.png : $(__SRC__)/img/logo.png | $$(@D)/ ; cp $< $@
assets-copy : $(__BUILD_ROOT__)/DOC/<domain>/img/logo.png
```

Crucially it resolves **later**, in a per-page phase that *does* carry
`__DOMAIN__`/`__ROOT__` (passed via `-D`), so it copies to the **local** page
root and returns `__HREF([__ROOT__/$1])` for that **same** root — href and
file always agree, on root and `en/`/`br/` subdirectory pages alike. Because
every page renders the layout and registers against its own `__ROOT__`,
site-wide assets still land (correctly) in every domain.

**Merits:** correct in **all** scenarios (local placement, no overcopy, no
broken links, true per-domain isolation). **Cost:** more process — an extra
generation phase plus a recursive sub-make per stem (the "resolves later,
with more machinery" trade-off).

## The decision

We **temporarily** converge all *live* asset declarations onto the deferred
mechanism — **not** because deferred is unconditionally superior (the
non-deferred path is simpler and, for static site-wide assets, arguably the
better long-term model), but because **deferred works in every scenario today
while the non-deferred path is actively broken** (the href/copy mismatch and
the layout-context limitation above). Fixing the non-deferred path correctly
is a larger task; converging on the one that already works unblocks correct
asset links now.

## Follow-up (done in subsequent commits)

- **Deletion.** `__ASSET`, `__CP_ASSET`, `__ASSET3`, and the generic `%.ext`
  pattern rules in `Makefile` (their only consumers) were removed. This note
  is the surviving **trace of that code's existence and rationale**, so a
  future effort can resurrect a *fixed* non-deferred path for static assets if
  the extra deferred machinery proves not worth it.
- **Rename.** The deferred macro — previously `__DEFERRED_ASSET2` (an orphaned
  `2`, with internal `text_box` labels that wrongly said `DEFERRED_ASSET3` and
  a phantom `TARGET` parameter in its header comment) — was renamed to
  `__DASSET`, with its labels and comment corrected.

See also: [`Rules.mk` recursive sub-make rationale](rules-mk-rationale.md),
[`__ASSET` rule duplication](asset-rule-duplication.md),
[Page source conventions](../architecture/page-source-conventions.md).
