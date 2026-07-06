---
type: Index
title: Infrastructure & collaboration knowledge
description: The process side of the repo — dev container, multi-agent topology and guards, the outer↔inner handoff constitution's future home, agent-memory hygiene, cloud environments, and cross-project conventions. Split out of knowledge/ on 2026-07-06; candidate to become its own shareable project.
tags: [index, infra, workflow]
timestamp: 2026-07-06
---

# Infrastructure & collaboration knowledge

The **process side** of this repository: how the actors (user, outer/host
Claude, inner/container Claude, spawned agents) work, independent of what
the project builds. Split from [the project knowledge base](../knowledge/index.md)
on 2026-07-06; a future candidate for extraction as its own shareable
project (see that decision's trail in the session history of 2026-07-06).

This tree is authored in the [Open Knowledge Format](okf.md).

## Sections

- Conventions — [commit message attribution](conventions/git-commit-attribution.md),
  [trace notes on removal](conventions/trace-notes-on-removal.md).
- Environment — [dev container (Claude Code + Playwright MCP)](notes/devcontainer-setup.md),
  [`chrome-devtools` MCP on the host](notes/chrome-devtools-mcp-setup.md),
  [cloud environments (Claude Code web & Codespaces)](notes/cloud-environments.md).
- Multi-agent workflow — [parallel development: topology, worktrees & guards](notes/parallel-agent-worktrees.md),
  [B3 fleet runbook (FOR OPERATORS)](notes/b3-fleet-runbook.md).

## Pending Stage 2 (still living in `knowledge/`)

The both-sided files await their seam-splits:
[session handoff](../knowledge/conventions/session-handoff.md) (constitution →
here; project integration profile → stays),
[no user-specific paths](../knowledge/conventions/no-user-specific-paths.md),
[deferred-work register](../knowledge/notes/deferred-work.md).
