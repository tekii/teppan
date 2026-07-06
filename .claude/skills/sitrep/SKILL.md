---
name: sitrep
description: Situation report — probe live repo/channel/register state first (git, .handoff/, deferred-work register), then summarize conversation context as a separate, clearly-labeled layer. Use at session start or whenever a trustworthy "where are we" is needed. Facts come from probes run now, never from conversation memory.
allowed-tools: Bash(git status:*), Bash(git rev-list:*), Bash(git log:*), Bash(ls:*), Bash(grep:*)
---

# /sitrep — verified situation report

Produce a **two-layer report**. Never state a repo/channel fact from
conversation memory — every fact in layer 1 comes from a probe run **now**.

## 1. Probe first (read-only; run all)

    git status -sb                                   # branch + dirty files
    git rev-list --count origin/master..master       # unpushed commits
    git log -5 --oneline                             # recent movement
    ls -A .handoff/                                  # channel (session-start ritual)
    grep '^## ' knowledge/notes/deferred-work.md knowledge-infra/notes/deferred-work.md  # open-work register digest (both trees)

## 2. Report in two labeled layers

**Verified just now (<date>):**
- branch, tree cleanliness, unpushed count ("in sync with origin" when 0 —
  never suggest pushing what doesn't exist);
- channel: list artifacts (each must be explainable by its `Trigger:` line)
  or "empty — no pending interchange";
- register: the open items, by heading;
- recent commits, one line each.

**From conversation context (unverified — half-life applies):**
- current goals, decisions in flight, and next actions — phrased as
  **proposals to the user**, never as facts or self-assigned work (Rule 1).

## Rules

- Probes read `master`-side state only (safe under handoff Rule 3 in the
  outer session).
- Do **not** run `make` — a status probe needs no gate.
- If a probe **contradicts** conversation memory, say so explicitly — that
  contradiction is the report's most valuable line.
