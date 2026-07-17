---
type: Design Note
title: Deferred / open work register
description: Repo-visible register of known-but-unimplemented work items and pending decisions, so no pending task lives only in a session's private memory (per the session-memory-hygiene rules in the handoff convention).
tags: [design-note, deferred, workflow]
timestamp: 2026-07-06
---

# Deferred / open work register

Per the [session-memory-hygiene rules (Severance SPEC)](../severance/SEVERANCE.md),
pending work lives **here** — visible to every session and the user, auditable
and re-prioritizable — not in a session's private auto-memory. Add items as they
are deferred; remove them when done. This register holds the
**project-deliverable side**; process/infra items live in
[the infra register](../infra/deferred-work.md). (Feature-specific
deferrals may instead live in their own note — e.g. [`make publish`](publish-target.md),
[`sitemap.xml`](sitemap-target.md); this register is for cross-cutting or
otherwise unhomed items.)

## Self-host water.css (deferred — inner-lane)

The site loads Water.css from the jsDelivr CDN (`layout.html:27`), which
**breaks the `file://` offline preview** (`custom.css` is `__DASSET`'d and
renders offline; water.css does not) and **fails in the firewalled
container**. Verified 2026-07-17: `cdn.jsdelivr.net:443` → connection refused
(blocked), while `registry.npmjs.org` returns 200 and
`npm pack water.css@2.1.1` fetches a complete 32 KB `out/water.css`
(sha256 `47073611dda0977c57c95d5bbda291084a589e5c7af197fa4d09822657249a0e`,
MIT-licensed).

**Decision: commit the vendored file — do not generate it.** Extract
`out/water.css` from `npm pack water.css@2.1.1` and commit it to the repo root
as `water.css` (a tracked source asset, sibling to the already-committed
`custom.css`), delivered via `__DASSET(water.css)` — swap the CDN `<link>`.
That yields a **fully offline / zero-build-network** styled build and removes
all vendoring machinery. Keep `make vendor` only as an optional *refresh*
helper (`npm pack` → overwrite `water.css`, checked against the sha256 above),
**never** a build prerequisite. Pin: **water.css@2.1.1**.

Why commit rather than the earlier gitignore-`VENDOR` + `make vendor` plan:
`__DASSET` copies from `$(SRC)`, not `VENDOR` (`generator.m4:360`), so generate
would need an extract-into-`$(SRC)` step plus a `build`→`vendor` order
dependency anyway, and it keeps a build-time dependency on
`registry.npmjs.org` (reachable, but still a network dep) — a committed file
needs zero network. water.css 2.x is one self-contained file (no `url()`), so
neither path needs the FontAwesome `__CSS_REMAP_URLS`/VENDOR-copy machinery;
the register previously said "follow the `custom.css` precedent," and
`custom.css` is **committed**, so committing water.css is the faithful reading.
The only cost is ~32 KB of MIT third-party bytes in history (carry the MIT
notice) — trivial for a rarely-changing single file.

## Wire `fragment-customers.html` into a page (deferred)

The fragment was de-AMP'd (`<amp-img>`→`<img>`, `__ASSET`→`__DASSET`, alt text)
but is `__INCL`'d by no page, so the change is **latent / not build-exercised**.
When the customers section is wanted, include it in a page and confirm the
`img/logo-*.png` assets exist.

## `generator.m4` review leftovers (parked, low priority)

From the 2026-06-14 M4 code review (items done then are in git history);
migrated out of the outer session's private memory 2026-07-06, each
re-verified live that day:

- **Quote-everything pass:** `__LOOKUP_LANG_NAME`'s `m4_if($1,$2,$3,…)`
  still has unquoted `$1,$2,$3` (`generator.m4:43`); the same pass should
  sweep `__UP`, `__FNAME`, and `m4_set_add([__ROOTS__],…)` — per the
  [M4 review role](../code-review/m4.md)'s "quote everything".
- **`__MAKE_PAGE` decomposition:** the macro does many unrelated things in
  one ~70-line body — candidate for smaller named macros (re-measure at
  pick-up; the count predates the AMP removal).
- **TODO sweep:** 4 `TODO`/leftover-exploration comments remain in
  `generator.m4` — resolve or convert each into either a register entry or
  a trace note.

## Stale landing fragments after a `generator.m4` change need `make realclean` (build hygiene)

An incremental `make build` after a `generator.m4` change that alters the
`*.landing.m4` fragment format does **not** reliably regenerate *existing*
domains' landing fragments, so the `NAVIGATION-LANDING.m4` aggregate can
carry stale `m4_define` entries (e.g. an ancient path-as-name form instead
of `__LANDING_<DOMAIN>_URL__`). Because `__REDIRECT_URL` (`generator.m4`)
now hard-`m4_fatal`s when a redirect target's `__LANDING_<DOMAIN>_URL__` is
missing, a stale aggregate makes `make build` **abort** during redirect-page
HTML generation — where previously the silent `http://DOMAIN` fallback
masked it. **Workaround:** run `make realclean` before rebuilding after any
`generator.m4` change touching landing-fragment format.

Observed 2026-07-17 converting `tekii.srl`/`tekii.llc` to landing sites: the
main checkout's `tekii.ar`/`tekii.us` landing fragments predated the
`__UP`-based landing naming and only a clean build refreshed them (a fresh
worktree that `realclean`s first was unaffected). The guard surfacing this
loudly is working as intended; the underlying gap is landing-fragment
staleness on the incremental path — likely the same class as the
[`NAVIGATION.m4` dependency edge](#navigationm4s-non-obvious-dependency-edge)
item below. **Hypothesis to confirm at pickup:** `NAV/%.landing.m4`'s
prerequisite on `generator.m4` isn't forcing regeneration when the declaring
DEP `.mk` is itself being regenerated in the same run (Make include-remake
ordering). A proper fix removes the need for the `realclean` workaround.

## `NAVIGATION.m4`'s non-obvious dependency edge

The order-only-prerequisite edge behind
`$(BUILD_ROOT)/NAV/%/NAVIGATION.m4 : | $$(@D)/` (`Makefile:119`) — `$^` looks
empty in isolation but each page's generated `.mk` adds prerequisite-only
rules for the same target, which Make merges — is now documented in
[Navigation mechanics](../architecture/navigation.md#the-aggregations-non-obvious-dependency-edge)
(the navigation work that was parked on landed 2026-07-17). **Residual
(optional, low priority):** a one-line inline `Makefile` comment on that
specific edge per the [Makefile review role](../code-review/makefile.md)'s
"comment non-obvious dependency edges" — the recipe currently carries a
comment about the `awk` dedup/ordering, but not about the order-only
prerequisite itself.

See also: [handoff convention (Severance SPEC)](../severance/SEVERANCE.md),
[infra/process register](../infra/deferred-work.md),
[Knowledge base index](../index.md).
