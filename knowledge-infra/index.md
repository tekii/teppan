---
type: Index
title: Infrastructure & collaboration knowledge
description: Teppan's infrastructure & process notes — dev container, multi-agent topology and guards, cloud environments. The workflow LAW (handoff constitution + conventions) was extracted to the Severance repo and returns vendored under knowledge/severance/; this tree keeps the Teppan-specific implementation docs.
tags: [index, infra, workflow]
timestamp: 2026-07-06
---

# Infrastructure & collaboration knowledge

The **process side** of this repository: how the actors (user, outer/host
Claude, inner/container Claude, spawned agents) work, independent of what
the project builds. Split from [the project knowledge base](../knowledge/index.md)
on 2026-07-06; the generic workflow law was extracted to the Severance
repo on 2026-07-09 (see [the trace note](notes/severance-extraction.md)).

This tree is authored in the [Open Knowledge Format](okf.md).

## Sections

- Environment — [dev container (Claude Code + Playwright MCP)](notes/devcontainer-setup.md),
  [`chrome-devtools` MCP on the host](notes/chrome-devtools-mcp-setup.md),
  [cloud environments (Claude Code web & Codespaces)](notes/cloud-environments.md).
- Multi-agent workflow — [parallel development: topology, worktrees & guards](notes/parallel-agent-worktrees.md),
  [B3 fleet runbook (FOR OPERATORS)](notes/b3-fleet-runbook.md).
- The extraction — [Severance extraction trace note](notes/severance-extraction.md).
- Registers — [deferred / open work (infra & process)](notes/deferred-work.md).

The workflow's **law** no longer lives in this tree: it arrives vendored
as [knowledge/severance/SEVERANCE.md](../knowledge/severance/SEVERANCE.md)
(+ Teppan's [profile](../knowledge/severance/profile.md)) from the
Severance repo — see the
[extraction trace note](notes/severance-extraction.md).
