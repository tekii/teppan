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
  [trace notes on removal](conventions/trace-notes-on-removal.md),
  [no user-specific or hardcoded absolute paths](conventions/no-user-specific-paths.md),
  [outer↔inner session handoff — the `.handoff/` constitution](conventions/session-handoff.md),
  [learnings register — record what each step taught](conventions/learnings-register.md).
- Environment — [dev container (Claude Code + Playwright MCP)](notes/devcontainer-setup.md),
  [`chrome-devtools` MCP on the host](notes/chrome-devtools-mcp-setup.md),
  [cloud environments (Claude Code web & Codespaces)](notes/cloud-environments.md).
- Multi-agent workflow — [parallel development: topology, worktrees & guards](notes/parallel-agent-worktrees.md),
  [B3 fleet runbook (FOR OPERATORS)](notes/b3-fleet-runbook.md).
- The experiment — [the Severance conceit (workflow name, cast & naming tiers)](notes/severance-conceit.md),
  [learnings register (what each step taught)](notes/learnings.md).
- Registers — [deferred / open work (infra & process)](notes/deferred-work.md).

The Teppan-specific half of the handoff convention — the concrete gate,
hygiene preconditions, and sanctioned flow the constitution delegates to —
lives project-side in
[knowledge/conventions/handoff-integration-profile.md](../knowledge/conventions/handoff-integration-profile.md).
