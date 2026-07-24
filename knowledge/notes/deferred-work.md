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

## Pretty / extensionless URLs (`cleanUrls`) — deferred

The Firebase Hosting config sets `"cleanUrls": false` (see
[Firebase Hosting publish pipeline](firebase-publish.md)) because the generator
emits explicit `.html` links. Flipping it to `true` would let Firebase serve
`/about` for `/about.html`, but only if the in-page links are *also*
extensionless — otherwise every link triggers a sitewide 301 bounce. The unit
of work is making `__HREF`/`__ABSOLUTE` emit extensionless URLs (mode-aware:
real files browsed off disk under `preview` still need the `.html`) *plus* the
`cleanUrls` flip. **Revisit trigger:** SEO work, or a decision to prefer pretty
URLs.

## `publish-verify` aborts on the first failing domain (pending decision)

`make publish-verify`'s per-domain checks are emitted double-colon rules
(`publish-verify :: ; @$(call check-redirect,…)` per declared alias), and Make
stops at the first rule that fails — so a single dead domain masks the state
of all the others. Observed on the first live run (2026-07-24): `tekii.com.ar`
(no DNS yet) returned `000` and the remaining eight checks never executed.
**Interim:** `make -k publish-verify` (keep-going) runs every check and
reports all failures in one pass — the right invocation during the staged
`.ar`-family DNS cutover, when some domains fail by design (the `.us` family
verified green pre-deploy on the same date; `www.tekii.com.ar` deliberately
stays on the legacy hosting until `tekii.ar` content first deploys).
**Pending decision:** whether all-domains reporting should be the target's
default — e.g. guard each emitted recipe with `|| fail=1`-style continuation,
or collect results and exit once at the end — instead of relying on the
caller remembering `-k`. **Revisit trigger:** the `.ar` cutover completing
(when a failure stops being routine), or the first time `-k` is forgotten
during a real incident.

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
of `__LANDING_<DOMAIN>_URL__`). Historically this failed loudly: the former
`__REDIRECT_URL` guard hard-`m4_fatal`'d when a redirect target's
`__LANDING_<DOMAIN>_URL__` was missing, so a stale aggregate aborted
`make build` during redirect-page HTML generation. That guard and the redirect
pages were **removed 2026-07-23** (redirect domains are now Firebase
console-level redirects — see
[Firebase Hosting publish pipeline](firebase-publish.md)), so the loud abort is
gone; the staleness itself remains, since a stale `NAVIGATION-LANDING.m4` can
still feed outdated cross-domain landing URLs. **Workaround:** run
`make realclean` before rebuilding after any `generator.m4` change touching
landing-fragment format.

Observed 2026-07-17 converting `tekii.srl`/`tekii.llc` to landing sites: the
main checkout's `tekii.ar`/`tekii.us` landing fragments predated the
`__UP`-based landing naming and only a clean build refreshed them (a fresh
worktree that `realclean`s first was unaffected). That guard surfaced the
staleness loudly while it existed (removed 2026-07-23 with the redirect pages);
the underlying gap is landing-fragment staleness on the incremental path —
likely the same class as the
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

## Re-home the old footer content onto the `.srl`/`.llc` landings (deferred)

The site-wide footer was redesigned into a **full-viewport brand billboard**
(flat color, monochrome isologo only, on every content page, desktop and
mobile — `layout.html`'s `<footer>` + the FOOTER BILLBOARD block in
`custom.css`). That redesign **removed** the previous footer's informational
content, which had no new home yet:

- the ESENBR company blurb (`CONTINUIDAD + INNOVACIÓN` / "Since 2006 …"),
- the GitHub and LinkedIn inline-SVG icon links,
- the **AFIP DATA FISCAL** badge (`img/DATAWEB.jpg` linking to the AFIP QR).

**Deferred re-homing (near-future iteration, not the billboard change):** move
this content onto the `tekii.srl` / `tekii.llc` landing bodies. Mechanism
sketch: add a **new page diversion** (e.g. a `LANDING_FOOTER`-style diversion
pushed by the landing sources) plus a **footer insertion point** in
`layout.html` that undiverts it *above* the billboard — so a landing can opt
into a content block while ordinary pages keep the bare billboard. The
`.srl`/`.llc` landings currently carry only mock placeholder sections (R6);
real copy plus this re-homed content land together.

**Devon accepted (2026-07-21) the interim absence of the DATA FISCAL badge**
while it has no home — it is not lost, only unhosted until this iteration.

### Trace: the removed mobile-only footer design (design-bearing removal)

What was removed and why (per the trace-note convention): the prior footer was
a **mobile-only** element — hidden at ≥768px via `body > footer { display:
none }` in `custom.css`'s desktop media query — carrying the blurb, social
icons, and AFIP badge in a `<div>` wrapper, with a `footer svg[role="img"]`
sizing rule for the icons and a KILL-diverted legacy social block. It lost to
the billboard on the merits: Devon wanted a single full-viewport brand closing
screen on **all** devices, so the desktop-hidden informational footer no
longer fit. Git history preserves the markup/CSS bytes; **revisit trigger** is
the re-homing iteration above (which decides where the informational content
actually lives once the billboard owns the footer slot).

See also: [handoff convention (Severance SPEC)](../severance/SEVERANCE.md),
[infra/process register](../infra/deferred-work.md),
[Knowledge base index](../index.md).
