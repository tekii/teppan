---
type: Design Note
title: Severance extraction — trace note
description: The multi-session workflow's law and experiment record were extracted to the Severance repo (github.com/tekii/severance) and return vendored as knowledge/severance/SEVERANCE.md (+ Teppan's profile.md). Records what moved where at v0.1.0, why fresh-start, and what remains Teppan-side.
tags: [design-note, severance, extraction, trace]
timestamp: 2026-07-09
---

# Severance extraction — trace note

On 2026-07-09 the multi-session workflow ("Severance") was extracted to
its own repo — `github.com/tekii/severance` — and returns to Teppan
**vendored**: [knowledge/severance/SEVERANCE.md](../severance/SEVERANCE.md)
(the SPEC, version-pinned by its own frontmatter) plus Teppan's
[profile](../severance/profile.md).

## What moved where (at severance v0.1.0)

- **Into the SPEC** (binding law, vendored back): the handoff
  constitution (`conventions/session-handoff.md`), commit attribution,
  no-user-specific-paths, trace-notes-on-removal, the learnings-register
  convention, and the profile contract.
- **Into the RECORD** (upstream only — humans, not sessions): the
  Severance conceit note and the learnings register's entries.
- **Retired here:** `knowledge/conventions/handoff-integration-profile.md`
  → superseded by `knowledge/severance/profile.md` (same content,
  contract-shaped).
- **Stayed here (Teppan's implementation, not law):** devcontainer
  setup, parallel-worktrees topology & guards, B3 fleet runbook, cloud
  environments, chrome-devtools MCP notes, both deferred-work registers.

## Why (and why fresh-start)

Generalization for reuse and publication; the upstream repo began from a
founding commit rather than filtered history because the law's history
is path-entangled here (3 path-reachable commits out of 526) and this
repo's formerly-public history was audited but never vetted for
re-publication (see the learnings register's Entry 3, upstream RECORD).
Full history remains in this repo; the register's backfill is the
curated substitute.

Later the same day, the residual `knowledge-infra/` tree was folded
into `knowledge/infra/` — the split's rationale (fencing the
extractable generic knowledge) was consumed by the extraction itself.

## Update mechanism / revisit triggers

Updates arrive as releases: replace the vendored SPEC, diff, commit
(`git log -- knowledge/severance/SEVERANCE.md` is the upgrade history).
The packaging is a **conditional win** — single author, whole-law
adoption, prose-dominant; the upstream DESIGN.md names the triggers that
reopen it (second contributor, selective adoption, SPEC token budget,
rendered releases). Assets (fleet scripts, devcontainer) are not yet
generalized upstream — they remain Teppan-side until a future release.
