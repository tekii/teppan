---
type: Convention
title: Severance consumer profile — Teppan
description: Teppan's answers to the vendored SEVERANCE.md profile contract — gate, hygiene preconditions, sanctioned flow, implementation docs. Successor of knowledge/conventions/handoff-integration-profile.md (retired by the same change).
tags: [conventions, severance, profile, handoff]
timestamp: 2026-07-09
---

# Severance consumer profile — Teppan

Teppan's answers to the profile contract in the vendored
[Severance SPEC](SEVERANCE.md).

## Gate

`make test` — currently 30 `__ASSERT_EQ` assertions, 0 FAIL required.
Note the gate's known limits and the pending change-type revision in the
[infra deferred-work register](../../knowledge-infra/notes/deferred-work.md).

## Hygiene preconditions

`findmnt -R /workspaces/teppan` must show the `TEPPAN_BUILD` volume
mount before any `make` on the main checkout, or the
[baked-root trap](../notes/realclean-recursive.md) aborts/re-poisons.
If missing, **STOP and hand back**.

## Sanctioned flow

`scripts/b3-fleet.sh provision` → edits in the worktree → `make test`
gate (30 PASS / 0 FAIL) → `integrate` → `teardown`.

Why the outer cannot commit here: `scripts/b3-fleet.sh` is
container-gated (`require_container` dies unless
`TEPPAN_IN_CONTAINER=1`), and the accidental-HEAD-move guards **fail
open on the host** — a host commit to `master` has no rails and risks
the shared-HEAD trap. So repo-content lands **only** through the inner
session.

## Implementation docs

[Dev container](../../knowledge-infra/notes/devcontainer-setup.md),
[parallel development: topology, worktrees & guards](../../knowledge-infra/notes/parallel-agent-worktrees.md),
[B3 fleet runbook](../../knowledge-infra/notes/b3-fleet-runbook.md),
[cloud environments](../../knowledge-infra/notes/cloud-environments.md),
[chrome-devtools MCP on the host](../../knowledge-infra/notes/chrome-devtools-mcp-setup.md).
