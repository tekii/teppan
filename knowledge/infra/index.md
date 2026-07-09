---
type: Index
title: Infrastructure & collaboration knowledge
description: Teppan's infrastructure & process notes — dev container, multi-agent topology and guards, cloud environments, extraction trace. Folded from the former knowledge-infra/ tree on 2026-07-09 (the split's rationale was consumed by the Severance extraction); the workflow LAW arrives vendored under knowledge/severance/.
tags: [index, infra, workflow]
timestamp: 2026-07-06
---

# Infrastructure & collaboration knowledge

The **process side** of this repository: how the actors (user, outer/host
Claude, inner/container Claude, spawned agents) work, independent of what
the project builds. Split out of knowledge/ on 2026-07-06 while it hosted the
generic workflow knowledge; the law was extracted to the Severance repo on
2026-07-09 and the residual tree folded back as knowledge/infra/ the same day
(see [the trace note](severance-extraction.md)).

## Sections

- Environment — [dev container (Claude Code + Playwright MCP)](devcontainer-setup.md),
  [`chrome-devtools` MCP on the host](chrome-devtools-mcp-setup.md),
  [cloud environments (Claude Code web & Codespaces)](cloud-environments.md).
- Multi-agent workflow — [parallel development: topology, worktrees & guards](parallel-agent-worktrees.md),
  [B3 fleet runbook (FOR OPERATORS)](b3-fleet-runbook.md).
- The extraction — [Severance extraction trace note](severance-extraction.md).
- Registers — [deferred / open work (infra & process)](deferred-work.md).

The workflow's **law** no longer lives in this tree: it arrives vendored
as [knowledge/severance/SEVERANCE.md](../severance/SEVERANCE.md)
(+ Teppan's [profile](../severance/profile.md)) from the
Severance repo — see the
[extraction trace note](severance-extraction.md).
