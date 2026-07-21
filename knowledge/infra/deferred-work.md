---
type: Design Note
title: Deferred / open work register (infrastructure & process)
description: Repo-visible register of known-but-unimplemented infra/process work items and pending decisions, so no pending task lives only in a session's private memory (per the session-memory-hygiene rules in the handoff constitution). The project-deliverable register lives in knowledge/notes/deferred-work.md.
tags: [design-note, deferred, workflow, infra]
timestamp: 2026-07-06
---

# Deferred / open work register (infrastructure & process)

Per the [session-memory-hygiene rules (Severance SPEC)](../severance/SEVERANCE.md),
pending work lives **here** — visible to every session and the user, auditable
and re-prioritizable — not in a session's private auto-memory. This register
holds the **infra/process side**; project-deliverable items live in
[the project register](../notes/deferred-work.md).

## Revise the integration gate for change type (decision needed)

`scripts/mdr.sh integrate` gates every merge on `make test` only, which
exercises `generator.m4` macros — **unnecessary for doc-only changes** and
**insufficient for build-input changes** (it doesn't cover `make build`, which
catches HTML/CSS breakage). Consider a **change-type-aware gate**: docs →
light/none; code or build inputs → `make test` **and** `make build`. Related: the
`$(PWD)`-stamp hardening's design analysis lives in
[realclean-recursive.md](../notes/realclean-recursive.md), and the
gate this would revise is documented in the [Teppan Severance
profile](../severance/profile.md).

### Visual-verification level (direction agreed 2026-07-21)

Even `make build` only proves generation succeeds — nothing in the gate
sees the rendered cascade, and every visual regression to date (the
click-swallowing permanent backdrop, the rail/container clipping) lived
below that floor. Devon agreed (2026-07-21) to a phased approach:

- **Now (per change):** agent-driven Playwright QA in the applying
  session — judgment-based screenshots plus computed-style /
  `elementFromPoint` probes. Not repeatable; each session re-derives
  what to check.
- **Near future (the agreed next step):** **scripted functional-visual
  probes** — a small deterministic script (Playwright test runner or
  headless Chrome) asserting computed facts against the `file://`
  preview build, exposed as a `make test-visual` target and run for
  CSS/layout/HTML change types under the change-type-aware gate this
  entry proposes. Seed assertions = the codified lessons to date:
  `elementFromPoint` at page center hits content, not an overlay (the
  backdrop bug); scrolled to bottom, the footer's box covers the full
  viewport and owns every hit-test point in it; no horizontal overflow
  (`scrollWidth <= innerWidth`); the drawer opens/dims/focuses via its
  checkbox; scheme-dependent token values resolve as expected under
  emulated `prefers-color-scheme`. Each future visual bug's post-mortem
  adds one assertion — the suite is the project's visual memory.
- **Later, optional:** a thin pixel-baseline layer (e.g. Playwright
  `toHaveScreenshot`) over a handful of stable pages, rendered in the
  devcontainer for determinism. Caveat that keeps it optional: baselines
  churn with environment/font rendering, and the project's worst visual
  bug (the backdrop) was **pixel-invisible** — pixel diffing complements
  the functional probes, never replaces them.

Still open (why this entry stays): choosing the runner, wiring
`test-visual` into `scripts/mdr.sh`'s change-type gate, and writing the
seed probes.

## Wayland display-forwarding decision (host/infra lane — decision needed)

VS Code auto-bind-mounts the host Wayland socket into the dev container
(`/run/user/1000/wayland-0` → `/tmp/vscode-wayland-*.sock`; not declared in
`devcontainer.json`; re-verified present 2026-07-05). Unused in this
workflow (Playwright is headless) and low-risk (Wayland isolates clients),
but a hole in the hardened-container posture. There is **no clean
`devcontainer.json` opt-out** — it's VS Code client behavior. Decide:
find/disable the client setting, or accept and document. This is
**outer/user-lane** (infrastructure); it sits in this register for
visibility, per the memory-hygiene rules.

## Conceit names for worktrees & cloud environments (to be revisited)

"Desks" (worktrees) and "branch offices" (cloud environments) were
proposed in the 2026-07-06 naming session and parked — Devon unsure.
Until decided they stay out of the Severance conceit's declaration line
(upstream RECORD); working
terms remain "worktree" / "cloud session".

## Learnings-register backfill (task)

Archaeology pass per the learnings register (upstream RECORD): mine git
history +
both knowledge trees, propose a dated step/lesson timeline for Devon's
correction and comprehension interviews (see the learnings-register
convention (Severance SPEC)).

## Dirty-main-checkout guard (decision needed)

2026-07-13: the Innie edited a tracked file in the main checkout in
place — off-process; caught by Devon (no guard fires on working-tree
edits: nothing moves HEAD), reverted, then re-applied via the
sanctioned flow. Backstop options surfaced in the Innie's
self-diagnosis (handed back by tape the same day): a hook/probe that
flags a **dirty tracked-file working tree in the main checkout**
(legitimate edits live in worktrees), and/or a session-start reminder
that repo modifications start with `mdr.sh provision`. Decide:
implement one, both, or accept discipline-only.

## Firewall `/meta` fetch resilience (retry landed; options remain)

2026-07-15: container start and rebuild failed for an evening — root
cause a GitHub unauthenticated rate limit (403 on `api.github.com/meta`
from a shared VPN exit IP), which `init-firewall.sh` treated as fatal
("missing required fields"); a latent second fragility (bare `curl`
under `set -e` dying before any error handling) was found in the same
read. Landed: retry with backoff (5 attempts) plus a diagnostic final
failure message (Devon's chosen option). **Remaining options if
recurrence proves retry insufficient:** cache the last-good `/meta`
ranges as a fallback (keeps the fail-closed posture without making
GitHub's rate limiter a single point of failure for container start),
and/or an authenticated fetch (5,000 req/h; needs a token-placement
decision).

## Probe-before-report mechanism (pinned by Devon — decision deferred)

2026-07-17: the Innie asserted a deleted file was still present —
recited from conversation memory instead of running a one-command
probe; the SPEC's "state is probed, not assumed" and private memory
were both in context and neither prevented it. The Innie handed back a
proposal (findings tape, consumed the same day): a protocol rule —
state claims in reports must be verbatim same-turn probe output ("if I
can't show it, I don't claim it") — enforced by a new `Stop` hook.
Outie review (verified against the Claude Code hooks docs, 2026-07-17):
a Stop hook can block-and-remind but cannot semantically verify
probe-vs-prose, and a blocking design adds a recompose pass to every
turn; recommendation was to piggyback a one-line reminder onto the
existing `UserPromptSubmit` gate (`scripts/iqc-gate.sh` injected
context) — no new hook, fires at turn start, one ceremony surface.
**Devon pinned the decision (2026-07-17): no implementation for now.**
Reopen triggers: the next recited-instead-of-probed incident, or
Devon's ask.

See also: [handoff constitution (Severance SPEC)](../severance/SEVERANCE.md),
[Teppan Severance profile](../severance/profile.md),
[infrastructure knowledge index](index.md).
