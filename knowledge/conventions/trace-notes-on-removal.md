---
type: Convention
title: Trace notes on removal
description: When a change removes or abandons a non-trivial, design-bearing mechanism, the same change must leave (or update) a trace note in knowledge/notes/ recording the lost design's mechanics, why it lost, and what would justify revisiting it.
tags: [conventions, documentation, knowledge, workflow]
timestamp: 2026-07-05
---

# Trace notes on removal

When a change **removes or abandons a non-trivial, design-bearing mechanism**,
the same change must **leave — or update — a trace note** under
`knowledge/notes/`. A *trace* is the preserved evidence of something that no
longer exists in the code: enough of the lost design to revisit the decision
later without re-deriving it from scratch.

## When it applies

Design-bearing removals only:

- a macro or mechanism (e.g. the retired `__ASSET`/`__CP_ASSET`/`__ASSET3`
  family),
- a Make target or build pathway,
- project tooling (e.g. the former `helper-css-remap` Python tool),
- an approach abandoned in favour of an alternative.

It does **not** apply to routine deletions — dead lines, stale comments,
trailing whitespace, mechanical refactor fallout with no design content behind
it. Do not demand a note for every deleted hunk.

## What the note must capture

Exactly what git history can't: history preserves the **bytes**, not the
**why**.

1. **The lost design's mechanics** — concrete enough to resurrect it (the
   asset-copy note keeps the actual Makefile shapes the deleted macros
   emitted).
2. **Why it lost** — and whether the decision was *conditional* ("the survivor
   works in every scenario today while this path is actively broken") or *on
   the merits*. A conditional loss is an open invitation to revisit; say so.
3. **What would justify revisiting** — the trigger that should reopen the
   trade-off.

An update to an existing note is fine — when a removal completes or extends a
story an existing note already tells, extend that note rather than creating a
near-duplicate file.

## Why

This convention is what makes "just delete it — git history already preserves
it" [review guidance](../code-review/css.md) actually safe: deletion is cheap
only when the rationale survives somewhere findable. Models to follow:
[asset-copy mechanisms](../notes/asset-copy-mechanisms.md) (the exemplar —
explicitly "the surviving trace of that code's existence and rationale"),
[`__CSS_REMAP_URLS`/former `helper-css-remap` tool](../notes/css-remap-helper.md),
[`make publish`](../notes/publish-target.md),
[`sitemap.xml` generation](../notes/sitemap-target.md).

See also: [Knowledge base index](../index.md),
[CSS code review guidelines](../code-review/css.md).
