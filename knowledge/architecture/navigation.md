---
type: Architecture Concept
title: Navigation mechanics
description: How the nav menu is built end-to-end — __NAV_ITEM registration, the NAVIGATION diversion → per-stem fragment → per-domain NAVIGATION.m4 aggregate → __NAV__ITEMS__ set → layout render pipeline; menu ordering; the URL field / __NAV_HREF cross-domain resolution; and the two render sites vs the separate __ALTERNATES__ language switcher.
tags: [architecture, m4, navigation]
timestamp: 2026-07-17
---

# Navigation mechanics

The nav menu is assembled in a small pipeline that spans **three files**
(`generator.m4`, `layout.html`, `Makefile`) and **two build phases**. It is
not obvious from any single file, so this note maps the whole thing — read it
before doing nav work rather than re-deriving it (the ordering rule in
particular has been re-concluded differently before).

## The pipeline: registration → render

1. **Register.** A page source calls `__NAV_ITEM(LANG,TEXT,URL,FRAGMENT)`
   (`generator.m4:402`). Its body does two independent things:
   - writes an `m4_set_add([__NAV__ITEMS__],[[LANG],[TEXT],[URL],[FRAGMENT]])`
     line into the **`NAVIGATION` diversion** (`generator.m4:403`) via
     `m4_divert_text` — this is *diversion-independent*: it targets
     `NAVIGATION` explicitly regardless of the active diversion;
   - emits `TEXT` inline at the call site (see "dual-purpose" below).
2. **Per-stem fragment.** In `GENERATE_NAVIGATION_PHASE` the `NAVIGATION`
   diversion is emitted to `TEPPAN_BUILD/NAV/<domain>/<stem>.m4` — one
   fragment per `*.in.html` source.
3. **Per-domain aggregate.** The Makefile assembles all of a domain's stem
   fragments into `TEPPAN_BUILD/NAV/<domain>/NAVIGATION.m4`
   (`Makefile:119-120`).
4. **Render.** In `GENERATE_HTML_PHASE`, `generator.m4` `m4_include`s that
   `NAVIGATION.m4` (`generator.m4:430`), executing the `m4_set_add` calls to
   populate the `__NAV__ITEMS__` m4 **set**; `layout.html` then renders the
   set with `__RENDER_SET` (`generator.m4:415`).

## `__NAV_ITEM` is dual-purpose — registration *and* inline label

`__NAV_ITEM` both registers the entry and emits its `TEXT` at the call site.
Callers normally *want* the inline emit — it becomes the page's `<h1>`
heading (e.g. `Home`, `Nuestra Historia`). To register a **menu-only** entry
with no body heading (e.g. the cross-domain `TEKii LLC` link on `tekii.us`),
call `__NAV_ITEM` in **`KILL`-diversion context** — i.e. outside any
`m4_divert_push([MAIN])`, at the top level of the page source (inside the
`__WITH_DOMAIN`/`__WITH_LANG` block). Registration (targeting `NAVIGATION`)
still happens; the inline `TEXT` lands in `KILL` and is discarded. See
`tekii-us-default.in.html`.

## Menu order = aggregation order (NOT source position, NOT alphabetical)

The rendered order is whatever order the `m4_set_add` lines appear in the
domain's `NAVIGATION.m4`, because an m4 set iterates in first-insertion
order. That order is fixed by the aggregation recipe (`Makefile:120`):

- **Now** (`awk '!seen[$0]++'`): **registration / first-seen order** — the
  order entries are registered as page sources are processed. Within one page
  that is call order; across pages it is prerequisite (`$^`) order.
- **Before 2026-07-17** (`sort -u`): **alphabetical** by the `m4_set_add`
  line (≈ by `LANG` then `TEXT`). Switched to `awk` because the reordering
  was an unwanted side effect of `sort -u`'s real job (dedup).

So to control menu order, order the `__NAV_ITEM` **calls**. Source position
relative to `__MAKE_PAGE` does not govern it, and it is no longer
alphabetical. A change to this recipe needs `make realclean` to take effect —
a recipe-text edit alone does not mark existing `NAVIGATION.m4` targets
stale.

### The aggregation's non-obvious dependency edge

`$(BUILD_ROOT)/NAV/%/NAVIGATION.m4` (`Makefile:119`) declares only an
**order-only** prerequisite (`| $$(@D)/`), so `$^` looks empty in isolation.
It works because each page's generated `.mk` (from `generator.m4`'s
`MAKEFILE` diversion) adds a *prerequisite-only* rule for the same target,
and Make merges same-target prerequisites — so `$^` ends up as all of that
domain's stem fragments. This is the least obvious edge in the nav build; the
same pattern feeds `NAVIGATION-LANDING.m4`. (This subsumes the former
"NAVIGATION.m4 dependency edge" deferred-work item.)

## URL field & cross-domain resolution

The `URL` field (`$3`) stores a **URL-id macro name** (e.g.
`__TEKII_US_INDEX_EN_URL__`) or a path — resolved to an href only at *render*
time, not registration time. The render (`layout.html:77,133`) calls
`__NAV_HREF(URL,FRAGMENT)` (`generator.m4:399`), which:

- computes the target's domain via `__NAV_TARGET_DOMAIN__`
  (`generator.m4:386`, the first path segment under `DOC`), and
- if it differs from the current page's `__DOMAIN__`, routes through
  **`__ABSOLUTE`** — the sole build-mode-aware cross-domain chokepoint
  (`http://host/...` in build, relative under `__PREVIEW__`); otherwise it
  uses bare **`__HREF`** + optional `#FRAGMENT`.

This makes the cross-domain review rule *structural*: a nav item cannot
bypass `__ABSOLUTE` across a domain boundary (see
[HTML code review guidelines](../code-review/html.md)).

## Two render sites; `__ALTERNATES__` is a separate set

`__NAV__ITEMS__` is rendered in **two** places in `layout.html` — the
off-canvas drawer (`layout.html:74`) and the desktop nav (`layout.html:130`)
— both via `__NAV_HREF`. Do not confuse `__NAV__ITEMS__` (the page/menu
links) with the separate **`__ALTERNATES__`** set (`layout.html:81,99,116,137`),
which drives the per-locale language switcher (flag links / `hreflang`).
Editing one does not affect the other.

## Signature

`__NAV_ITEM(LANG, TEXT, URL, FRAGMENT)`:

- `LANG` — the locale the entry belongs to (rendered only when it matches the
  page's `__LANG__`).
- `TEXT` — the label (also emitted inline unless called in `KILL` context).
- `URL` — a URL-id macro or path, resolved at render time via `__NAV_HREF`.
- `FRAGMENT` — an optional `#anchor`, same-origin only.

See also: [Diversion/phase model](diversion-phase-model.md),
[Page source conventions](page-source-conventions.md),
[Overview](overview.md),
[HTML code review guidelines](../code-review/html.md),
[GNU Makefile code review guidelines](../code-review/makefile.md).
