---
type: Design Note
title: The Severance conceit — workflow name, cast & naming tiers
description: The multi-session workflow is named "Severance" (after the TV show) — this note declares the cast (Devon, Outie, Innie, Refiners, MDR, the camcorder, tapes), the two naming tiers, the casing rule, the anti-overstretch principle, and the generic Lumon/Cold Harbor mapping for the planned extraction. Names are mnemonic decoration; the handoff constitution defines the behavior.
tags: [design-note, severance, naming, workflow, handoff]
timestamp: 2026-07-06
---

# The Severance conceit

The multi-session workflow described by the
[handoff constitution](../conventions/session-handoff.md) is named
**Severance**, after the TV show. The name is earned, not just borrowed:
the severance is real here — the sessions' private memories are
architecturally invisible to each other, and each session is dormant
(experiencing nothing) while the other drives the shared repo. A
**conceit** is an extended metaphor sustained through a work; this note
declares ours once, so the rest of the tree doesn't have to.

The central irony, and the reason the name fits this project better than
the show it quotes: Lumon's severance *hides* the two selves from each
other, while ours **legislates an auditable channel between them** — the
constitution took an illicit channel and legalized it.

## Why this project exists (the experiment)

This infrastructure is the process side of the user's **first attempt at
coding with LLMs** — an experiment. The sites project (Teppan) is the
driver: a real problem solved with the new technology, and an important
deliverable in its own right, so the experiment must succeed on both
counts. When this tree is extracted to its own repo, the work will be
presented publicly as an experiment (paper/publication); the Severance
conceit is that publication's **hook** — it draws readers honestly,
because every mapping below describes the real architecture. What each
step taught is recorded in the [learnings register](learnings.md).

## The cast (working vocabulary — used throughout these docs)

| Name | Is | Descriptive form (also valid) |
|---|---|---|
| **Devon** | the user | "the user" |
| **Outie** | the outer/host Claude session | "outer Claude" |
| **Innie** | the inner/container Claude session | "inner Claude" |
| **Refiners** | spawned agents (worktree / fleet / Agent-tool children) | "agents" |
| **MDR** | the Refiner fleet, collectively | "the fleet" |
| **the camcorder** | `.handoff/` (the literal path remains the real name) | "the handoff channel" |
| **tapes** | `.handoff/` artifacts (`plan-*`/`draft-*`/`findings-*`) | "handoff artifacts" |

An interchange, in this vocabulary: **Devon passes the camcorder** — that
pass *is* the activation (one pass = one user-triggered leg, the
constitution's Rule 1; no further protocol name). The addressed session
finds a tape; a reply is a **new** tape, never an edit of the other's;
the consumer destroys the tape after viewing. Devon can hold the role
because Devon is the only **unsevered** participant — the one memory
continuous on both sides of the boundary.

Show-fidelity deltas, owned rather than hidden (see the anti-overstretch
principle below): in the show the equivalent channel is contraband, ours
is constituted by the authority itself; the show's camcorder crosses a
threshold one body walks through, ours passes between two concurrent
sessions; and the Outie's unawareness during the Innie's turns is the
default state of dormant sessions, not an enforced rule.

## The environments (declaration-only — stated here, then retired)

In this conceit, the container is *the severed floor* and the host is
*the outside*. Everywhere else these docs say **container** and **host**
— documentation must be understood first and enjoyed second.

(Names for the worktrees and the future cloud environments were
considered and parked — see the
[deferred-work register](deferred-work.md).)

## Rules of the conceit

- **Casing:** docs and agent-directed text always write **Devon, Outie,
  Innie, Refiners, MDR** capitalized. Lowercase forms are accepted only
  when Devon types them; never write them back.
- **Two tiers:** *working vocabulary* (the cast table — names that aid
  precision because they name things that had no short name) vs
  *declaration-only* (the environments — where exact technical terms
  already exist and must stay the working terms).
- **Anti-overstretch (binds Devon and every Claude):** the goal is naming
  things, possibly in a funny way — not maximizing the metaphor. Names
  are mnemonic decoration; the constitution defines the behavior; when
  show fidelity and mechanical truth conflict, mechanical truth wins.
  Every name must also work on its plain-English merits for readers who
  have never seen the show.

## Generic mapping (for the planned extraction)

When this tree becomes its own generalized repo: **Lumon** = the generic
company (TEKii's slot), **Cold Harbor** = the generic project (Teppan's
slot). Both are **doc-only terms** — they never name a real filesystem
path; if an identifier form is ever forced, use `cold-harbor` or
`cold_harbor`. (Pleasingly, "Cold Harbor" is the show's flagship
project — and the title of the episode in which the tapes are exchanged.)

See also: [handoff constitution](../conventions/session-handoff.md),
[learnings register](learnings.md),
[parallel development](parallel-agent-worktrees.md),
[glossary](../../knowledge/glossary.md).
