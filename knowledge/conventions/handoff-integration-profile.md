---
type: Convention
title: Teppan handoff integration profile
description: The host-project half of the session-handoff convention — Teppan's concrete gate command, hygiene preconditions, sanctioned worktree flow, and why the outer cannot commit here. The portable constitution lives in knowledge-infra/conventions/session-handoff.md and delegates to this file.
tags: [conventions, workflow, handoff, teppan]
timestamp: 2026-07-06
---

# Teppan — handoff integration profile

The [session-handoff constitution](../../knowledge-infra/conventions/session-handoff.md)
defines the rules between the outer and inner sessions; this file supplies
Teppan's concrete integration machinery (the constitution's extension
points).

## Gate

`make test` — currently 30 `__ASSERT_EQ` assertions, 0 FAIL required. Note
the gate's known limits and the pending change-type revision in the
[deferred-work register](../notes/deferred-work.md).

## Hygiene preconditions

**Hygiene precondition:** `findmnt -R /workspaces/teppan` must show the
`TEPPAN_BUILD` volume mount before any `make` on the main checkout, or the
[baked-root trap](../notes/realclean-recursive.md) aborts/re-poisons. If
missing, **STOP and hand back**.

## Sanctioned flow

**Apply via the sanctioned flow:** `scripts/b3-fleet.sh provision` → edits in
the worktree → `make test` gate (30 PASS / 0 FAIL) → `integrate` →
`teardown`.

## Why the outer cannot commit here

The outer/host **cannot** use the sanctioned path: `scripts/b3-fleet.sh` is
container-gated (`require_container` dies unless `TEPPAN_IN_CONTAINER=1`), and
the accidental-HEAD-move guards **fail open on the host** — a host commit to
`master` has no rails and risks the shared-HEAD trap. So repo-content lands
**only** through the inner.

See also: [session-handoff constitution](../../knowledge-infra/conventions/session-handoff.md),
[parallel development](../../knowledge-infra/notes/parallel-agent-worktrees.md),
[dev container setup](../../knowledge-infra/notes/devcontainer-setup.md).
