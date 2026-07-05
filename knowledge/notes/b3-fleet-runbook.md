---
type: Runbook
audience: operator
title: B3 fleet runbook — working in the container and launching agents (FOR OPERATORS)
description: Operator how-to for the B3 multi-agent setup — whether to work in /workspaces/teppan vs. a per-task worktree, the exact scripts/b3-fleet.sh provision/spawn/up/integrate/teardown/list commands, what the accidental-HEAD-move guards block and the TEPPAN_MAIN_HEAD_OK override, and who launches the agents. Consumed by a human operator, not by spawned agents (agents work only inside their own worktree; the guards self-inject the rules they need).
tags: [runbook, operator, b3, agents, worktree, devcontainer, workflow]
timestamp: 2026-07-04
---

# B3 fleet runbook — working in the container & launching agents

> **FOR OPERATORS / HUMAN CONSUMPTION.** This is an orchestration runbook: how
> *you* (the human at the keyboard, or a parent orchestrating session) launch
> and integrate a fleet. A *spawned* agent does not need this — it works only
> inside its own worktree, and the guards self-inject the one rule it must
> follow ("don't move the shared `/workspaces/teppan` HEAD"). The design rationale
> lives in [Parallel development](parallel-agent-worktrees.md); this file is the
> operational checklist that sits on top of it.

## 🚨🚨 DO NOT "Add Folder to Workspace" for a worktree 🚨🚨

> **⚠️ READ THIS FIRST — it will drop your session.**
> In the dev container, opening a worktree (`/workspaces/wt-<task>`) via VS
> Code's **"Add Folder to Workspace"** forces a **multi-root workspace → window
> reload → container reconnect**, which can throw a *"cannot reconnect"* error
> and **kill your terminal / live Claude session** (learned the hard way,
> 2026-07-04). Your container and commits survive — but you lose the running
> session.
>
> **To look at a worktree instead:** `cd /workspaces/wt-<task>` in a terminal,
> **or** open a *separate* VS Code window attached to the same container.
>
> **And always run Claude/agents under `tmux`** — `tmux new -s work 'claude'`,
> or just `scripts/b3-fleet.sh up <task>` (which does it for you). Then *any*
> reload/reconnect/detach is survivable: `tmux attach -t <session>` brings the
> live session straight back. A bare integrated-terminal session survives only
> by VS Code's fragile terminal-persistence and dies on a full window close.

## Mental model (read once)

- **`/workspaces/teppan` is the protected integration checkout.** It stays on
  `master`. It is the shared, bind-mounted tree (host ⇄ container are **one
  HEAD**), so moving its HEAD out from under a live session is the
  "shared-HEAD trap" the guards exist to prevent.
- **Worktrees are where work happens** — one per task, at
  `/workspaces/wt-<task>`, *outside* `/workspaces/teppan` (container-local,
  ephemeral working tree; commits still land in the host-persisted `.git`).
  **You get one too** — worktrees are not only for agents.
- **The guards** (`scripts/guard-main-head.sh` + the
  `reference-transaction`/`post-checkout` git hooks) make direct git HEAD-moves
  on `/workspaces/teppan` fail inside the container — see the cheat-sheet below.

## Prerequisites (verify once per container)

```bash
printenv TEPPAN_IN_CONTAINER          # -> 1  (guards active; you're in the container)
git -C /workspaces/teppan branch --show-current   # -> master  (integration checkout on trunk)
```
If VS Code opened without the folder (terminal lands in `~`), reopen
`/workspaces/teppan` as the workspace folder — see the note on the shared-HEAD trap
for why terminals otherwise default to home.

## A. Doing your own work

**Editing / building / testing / previewing on `/workspaces/teppan` — always fine**
(the guards only touch git HEAD-moves):

```bash
make test            # 30 assertions
make build           # or: make preview
```

**But to *commit your own work*, use a worktree** (recommended — zero friction,
no guards on your own HEAD):

```bash
# from /workspaces/teppan:
scripts/b3-fleet.sh provision mywork       # -> /workspaces/wt-mywork on agent/mywork
cd /workspaces/wt-mywork
#   ... edit, git commit, git switch, git reset freely -- your OWN HEAD ...
cd /workspaces/teppan
scripts/b3-fleet.sh integrate mywork       # make test -> merge --no-ff -> master
scripts/b3-fleet.sh teardown mywork        # remove worktree + branch + tmux
```

**One-off commit straight on the trunk** (when a worktree is overkill): prefix
the single git command with the sanctioned override:

```bash
TEPPAN_MAIN_HEAD_OK=1 git -C /workspaces/teppan commit -am "quick trunk fix"
```

## B. Launching agents (you are the orchestrator — "Model A")

```bash
scripts/b3-fleet.sh up <task>          # provision a worktree + spawn `claude` in it under tmux
tmux attach -t agent-<task>            # jump into that agent (detach: Ctrl-b d)
scripts/b3-fleet.sh list               # worktrees + agent tmux sessions
scripts/b3-fleet.sh integrate <task>   # gate on make test, then merge --no-ff to master
scripts/b3-fleet.sh teardown <task>    # tmux kill + worktree remove + branch delete
```

Every launch is four roles — **partition** (pick N tasks; ≤1 touches the
framework seam) → **provision** → **spawn** → **integrate** (on `master`, gated
on `make test`). Keep `/workspaces/teppan` on `master` throughout; `integrate`
only *advances* master (it never `checkout`s), using the override internally.

> **Two `integrate` nuances not visible from its one-line description** (both in
> `scripts/b3-fleet.sh`, worth knowing before you trust the gate):
>
> - **It self-heals a bad merge.** If the *post-merge* `make test` on `master`
>   fails, `integrate` rolls the merge back automatically
>   (`TEPPAN_MAIN_HEAD_OK=1 git reset --hard ORIG_HEAD`) and aborts — you are
>   left on a clean `master`, not a broken one. A *conflicting* merge likewise
>   stops with nothing torn down.
> - **The gate is `make test` only — macro-level, not a build.** `make test`
>   exercises `generator.m4` macros; it does **not** render HTML/CSS. So a change
>   touching build *inputs* (`layout.html`, `configure.m4`, `*.in.html`, CSS) can
>   pass the gate while still breaking `make build`. Run `make build` yourself in
>   the worktree **before** `integrate` for any such change — the gate won't catch
>   a broken render.

Two other launch models exist (see the design note) for later: **Model B** — a
parent Claude session orchestrating subagents via the Agent/Workflow tools
(worktree-isolated); **Model C** — a headless `devcontainer exec … claude -p`
script for unattended fleets.

## C. Guard cheat-sheet (what's blocked, and the escape hatch)

Inside the container, on `/workspaces/teppan` only (worktrees and the host are
unaffected):

| You run… | Plain terminal (you) | Via a Claude session |
|---|---|---|
| edit / `make …` | ✅ | ✅ |
| `git commit` / `reset --hard` / `merge` on master | ❌ blocked (hook) | ❌ blocked |
| `git checkout`/`switch <branch>` | ⚠️ allowed, warns | ❌ denied (PreToolUse) |
| the same, in your **own worktree** | ✅ | ✅ |

Escape hatch for a sanctioned trunk move: prefix `TEPPAN_MAIN_HEAD_OK=1`
(inline, never `export` it — an exported value would also wave through an
*accidental* command in the same shell).

## D. Recovery / housekeeping

- **Leftover branch after a failed provision** (`fatal: a branch named
  'agent/<task>' already exists`): `git -C /workspaces/teppan branch -D agent/<task> && git -C /workspaces/teppan worktree prune`.
- **Rebuild the container anytime** — committed work is safe (host `.git` +
  named volumes survive); only *uncommitted* worktree state is lost, so commit
  often. `postcreate.sh` re-installs the guard hooks and re-chowns `/workspaces`
  idempotently.
- **Verify guards after a rebuild:** re-run the checks in *Prerequisites* plus
  `scripts/b3-fleet.sh provision smoke && scripts/b3-fleet.sh teardown smoke`.

See also: [Parallel development — branch workflow, worktrees & multi-agent
setup](parallel-agent-worktrees.md) (the design rationale + the guard coverage
table), [Build & test commands](../build/commands.md),
[dev container setup](devcontainer-setup.md).
