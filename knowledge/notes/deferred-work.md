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

The site loads Water.css from the jsDelivr CDN (`layout.html`), which **breaks
the `file://` offline preview** (`custom.css` is `__DASSET`'d and renders
offline; water.css doesn't) and won't load in the firewalled container.
**Approach (Option B):** wire the empty `make vendor` target to
`npm pack water.css@<pin>` into gitignored `VENDOR`, then deliver via
`__DASSET([water.css])` (swap the CDN `<link>`). npm is reachable in-container;
jsDelivr is firewalled. water.css 2.x is a single self-contained file (no
`url()`), so it does **not** need the FontAwesome
`__CSS_REMAP_URLS`/VENDOR-copy machinery — follow the `custom.css` precedent, not
the FontAwesome one.

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

## `NAVIGATION.m4`'s non-obvious dependency edge (parked until navigation work)

`$(BUILD_ROOT)/NAV/%/NAVIGATION.m4 : | $$(@D)/` (`Makefile:115`) has a
`cat $^ > $@` recipe but only an order-only prerequisite, so `$^` is empty
in isolation — it works because generated per-stem `.mk` files add
prerequisite-only rules for the same target and Make merges them. This is
the file's least obvious dependency edge; it needs an explanatory comment
(per the [Makefile review role](../code-review/makefile.md)'s "comment
non-obvious dependency edges"). **Parked by the user (2026-06-14) until the
navigation mechanism itself is worked on — don't pick it up standalone.**

See also: [handoff convention (Severance SPEC)](../severance/SEVERANCE.md),
[infra/process register](../infra/deferred-work.md),
[Knowledge base index](../index.md).
