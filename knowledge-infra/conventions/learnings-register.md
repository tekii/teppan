---
type: Convention
title: Learnings register — record what each step taught
description: Every design-bearing step must ask "what did this teach about coding with LLMs?" and, if something, add an entry to the learnings register in the same change. Entries separate fact from interpretation; claims about what Devon learned are verified by a short Claude-driven comprehension interview, not assumed from exposure.
tags: [conventions, learnings, experiment, workflow, documentation]
timestamp: 2026-07-06
---

# Learnings register — record what each step taught

This project is an experiment (see
[the Severance conceit — motivation](../notes/severance-conceit.md)), and
an experiment that doesn't record its results isn't one. The
[register](../notes/learnings.md) holds what each step taught, for two
audiences: Devon, and the eventual public write-up.

This convention is the forward-looking sibling of
[trace notes on removal](trace-notes-on-removal.md): trace notes preserve
the *why* of what was removed; the learnings register preserves what each
step *taught*.

## The rule

When a change lands a **design-bearing step** (same threshold as trace
notes — no entries for routine mechanical work), ask: *did this step
teach something about working with LLMs?* If yes, the same change adds an
entry to [`notes/learnings.md`](../notes/learnings.md).

## Entry format

- **Date + step** — what was attempted, with evidence pointers (commits,
  knowledge notes, incidents).
- **Fact vs interpretation, separated** — what verifiably happened vs
  what it suggests. The write-up's credibility depends on this line
  staying sharp.
- **Learner attribution** — a lesson is marked as a *Claude finding*
  (verified against code/history) or *user-verified* (see below); never
  silently assume both.

## The comprehension interview

Devon reads every Claude finding, but **exposure is not comprehension** —
an experiment about learning to code with LLMs must test what its human
actually learned. So, on Devon's trigger (per milestone, or on demand):

- Claude conducts a **short interview** — 3–5 questions derived from the
  step's lessons, answered without looking things up.
- The entry's lesson is marked **user-verified** only after the
  interview confirms it. Partial or missed answers are **data, not
  failure** — they get recorded (that gap is a result of the experiment)
  and trigger a re-explanation.
- The interview happens in-session between Devon and one Claude; it is
  not an interchange and involves no cross-session traffic.

## Why

Publication-grade honesty: "the human read the reports" is not a
finding; "the human could answer these questions afterward" is. And
repo-visibility (per the constitution's session-memory-hygiene rules):
lessons live here, where every session and Devon can see them — never
only in a session's private memory.

See also: [learnings register](../notes/learnings.md),
[trace notes on removal](trace-notes-on-removal.md),
[the Severance conceit](../notes/severance-conceit.md).
