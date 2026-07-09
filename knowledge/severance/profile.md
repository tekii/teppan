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
[infra deferred-work register](../infra/deferred-work.md).

## Hygiene preconditions

`findmnt -R /workspaces/teppan` must show the `TEPPAN_BUILD` volume
mount before any `make` on the main checkout, or the
[baked-root trap](../notes/realclean-recursive.md) aborts/re-poisons.
If missing, **STOP and hand back**.

## Sanctioned flow

`scripts/mdr.sh provision` → edits in the worktree → `make test`
gate (30 PASS / 0 FAIL) → `integrate` → `teardown`.

Why the outer cannot commit here: `scripts/mdr.sh` is
container-gated (`require_container` dies unless
`TEPPAN_IN_CONTAINER=1`), and the accidental-HEAD-move guards **fail
open on the host** — a host commit to `master` has no rails and risks
the shared-HEAD trap. So repo-content lands **only** through the inner
session.

## Subagents (Refiners): bound by accountability, not knowledge

On this harness (Claude Code), a spawned agent does **not** reliably
have the vendored law in context: general-purpose subagents inherit
the *parent's* loaded snapshot (stale if the law changed mid-session
— they may cite deleted files as their law), and Explore-class agents
load no `CLAUDE.md` at all. Nothing hard-blocks a law-violating
action except the agent's tool profile. The SPEC's "Subagents
inherit" clause therefore binds the **parent**; the child's awareness
must be engineered, not assumed. Practices (threat model: accidental
mistakes, not adversarial agents — Devon's scoping, 2026-07-09):

1. **Law-bearing steps stay in-session** — anchor verification,
   Trigger authorship, apply/commit decisions are never delegated.
2. **Inject what the agent needs** — the relevant rules travel in the
   spawn prompt; they will not auto-load.
3. **Gate the output** — treat agent replies as raw data, verified
   against the law before anything acts on them.
4. **Read-only spawns for hard prevention** — an agent without
   `Write`/`Edit` cannot write a tape; the tool profile is the only
   hard lever.

The same snapshot caveat applies to **long-lived sessions**: a session
spanning a law change carries its session-start law; after any change
to the vendored SPEC, re-read it from disk or restart the session.
(MDR's Refiners are additionally constrained by structure:
the fleet script runs the gate mechanically, so their compliance is
enforced by the flow, not their knowledge.)

## Implementation docs

[Dev container](../infra/devcontainer-setup.md),
[parallel development: topology, worktrees & guards](../infra/parallel-agent-worktrees.md),
[MDR runbook](../infra/mdr-runbook.md),
[cloud environments](../infra/cloud-environments.md),
[chrome-devtools MCP on the host](../infra/chrome-devtools-mcp-setup.md).
