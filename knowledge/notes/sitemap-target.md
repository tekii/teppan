---
type: Design Note
title: sitemap.xml generation (not yet implemented)
description: Planned make rule to generate sitemap.xml via m4, with an open design question about how to pass the page list and handle source dependencies.
tags: [design-note, makefile, m4, sitemap]
timestamp: 2026-06-28
---

# `sitemap.xml` generation (not yet implemented)

A `sitemap.xml` output was planned as an m4-generated file, using a rule
along the lines of:

```makefile
$(__BUILD_ROOT__)/DOC/sitemap.xml : $(__SRC__)/sitemap.xml | $$(@D)/
    $(M4) $(M4_FLAGS) $(EXTRA_BUILD_FLAGS) \
        -D __TNAME__=$(@F) \
        -D __LIST__="$(filter-out 404.html,$(PAGES))" \
        $(__SRC__)/sitemap.xml >$@
```

## Open design question

The original note (in Spanish) flagged two unresolved points:

1. **`$^` vs explicit `__LIST__`**: whether to use `$^` (all prerequisites,
   letting Make track the page list as dependencies) or pass an explicit
   `$(filter-out 404.html,$(PAGES))` list via `-D __LIST__=`. Using `$^`
   would make the rule naturally re-run when any source page changes, but
   requires the page sources to be listed as real prerequisites.

2. **Source dependency completeness**: the sitemap content depends on all
   `*.in.html` sources (their URLs, titles, last-modified dates), but wiring
   all of them as prerequisites may be unnecessary if we can instead take the
   modification date from the source file at generation time. The rule may be
   safe to always regenerate.

## What remains

- Define `$(PAGES)` or wire per-page prerequisites.
- Decide `$^` vs `__LIST__` approach.
- Write `sitemap.xml` m4 template.
- Add the target as a prerequisite of `build`.

## Possibly related: abandoned per-target `EXTRA_BUILD_FLAGS` stubs

These commented-out target-specific variable assignments were found near the
navigation map rules in the Makefile — their relationship to sitemap
generation is unclear, but they concern how per-file build context
(`__D__`, `__N__`, `__S__`) would be passed to m4 via `EXTRA_BUILD_FLAGS`:

```makefile
#$(__DEP__)/%.d:   EXTRA_BUILD_FLAGS+= -D __D__=$(dir $<) -D __N__=$(notdir $(basename $<)) -D __S__=$(suffix $<)
#$(__DEP__)/%.txt: EXTRA_BUILD_FLAGS+= -D __D__=$(dir $<) -D __N__=$(notdir $(basename $<)) -D __S__=$(suffix $<)
#%.html:           EXTRA_BUILD_FLAGS+= -D __D__=$(dir $<) -D __S__=$(suffix $<)
```

Whether these belong here, in the navigation mechanism, or elsewhere is TBD.

See also: [Build & test commands](../build/commands.md),
[Page source conventions](../architecture/page-source-conventions.md).