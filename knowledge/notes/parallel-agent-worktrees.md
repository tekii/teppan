---
type: Design Note
title: Parallel development — branch workflow, git worktrees, and multi-agent setup
description: Why Teppan keeps a single-trunk workflow (short goal-scoped branches merged to master) rather than long-lived framework/content branches; how git worktrees give each branch its own absolute-path TEPPAN_BUILD; the host/container/worktree isolation matrix; and how to run two or more agents in parallel (B1/B2/B3 topologies, the B3 delta on the existing devcontainer, VS Code interaction, and who/how launches the agents).
tags: [design-note, git, workflow, worktree, devcontainer, agents, build]
timestamp: 2026-07-03
---

# Parallel development — branch workflow, worktrees, and multi-agent setup

This note records a design discussion. The conclusions are
decisions-of-record; the **manual worktree flow is empirically validated**
(smoke-tested 2026-07-03 — see [Validation](#validation-smoke-tested)); the
**committed B3 infrastructure** (distinct named volumes, launcher scripts)
remains a **sketch to build if/when needed**, not yet implemented.

## The premise that started it

Proposal: split work into two long-lived branches — a **framework** branch
(new macros, build/publish infrastructure, dev container) and a **content**
branch (the prose in `*.in.html`, `layout.html`, CSS) — on the theory that
the two concerns are isolated enough to merge cleanly.

**Verdict: a sound instinct that holds for ~80% of the tree but breaks at one
seam — so it is incomplete, not wrong.**

- **Where it holds:** the concern boundary coincides with a **file boundary**
  for `generator.m4`/`configure*.m4`/`Makefile`/`Rules.mk`, `.devcontainer/`,
  `.claude/`, `knowledge/`, `fragment-*.html`, `amp-custom.css`, assets. Git
  merges at file/line granularity; disjoint file sets never conflict.
- **Where it breaks:** the fault line runs *through* `*.in.html` and
  `layout.html`, not between files. `tekii-ar-default.in.html` interleaves
  framework scaffolding (`__WITH_DOMAIN`/`__WITH_LANG`/`__MAKE_PAGE`/
  `__NAV_ITEM`, the `m4_divert_push`/`pop` structure), the actual prose
  content, **and** per-page CSS (the `CUSTOM_STYLES` diversion). Git cannot
  branch a line-range.

### Why the strong (long-lived-branch) form fails

1. **The danger is silent, not loud.** Content edits and framework edits
   usually touch *different lines* of the same `.in.html` (prose vs. the
   macro-scaffold lines), so git merges the hunks **cleanly** — textual
   conflicts are the benign, loud case. The real hazard is the **clean merge
   that no longer builds**: the framework branch changes a macro signature
   (e.g. `__NAV_ITEM`), the content branch adds a page using the old
   signature, the merge succeeds textually, and the tree is broken with no
   warning.
2. **A two-branch model can't hold a cross-cutting commit.** A macro rename
   *must* update its call sites in the **same commit** to keep the tree
   buildable and `make test` green. History proves it: `c8495a6`
   (`__DEFERRED_ASSET2`→`__DASSET`) touched `generator.m4` **+**
   `contact.in.html` **+** `layout.html`; `32fe4aa` (`__MAKE_PAGE`'s
   `[landing]` → `__AS_LANDING`) touched `generator.m4` + tests +
   `mock-page.in.html`. There is no branch to put such a commit on — it is
   inherently both concerns. (Caveat on counting: ~70 historical commits
   touch both a framework and a content file, but much of that is the repo's
   pre-discipline `wip` genesis; the *mechanism* plus these two clean-era
   examples is the real evidence, not the count.)

## Decision of record: single trunk + short goal-scoped branches

Keep `master` as the single trunk; use **short, goal-scoped branches merged
back to master**. Concern separation already comes for free from the
conventional-commit scopes in use (`feat(devcontainer)`, `build(...)`,
`refactor(...)`, `docs`). Two standing rules:

1. **Cross-cutting refactors stay atomic on one branch** — a macro rename and
   its call-site updates land together (the `c8495a6`/`32fe4aa` pattern),
   never split across branches/agents.
2. **`make test` is the merge guard, not git** — gate merges on build + test
   passing, because a clean textual merge cannot catch the "builds-green-then-
   broken" semantic-drift case.

The *goal* the premise wanted (real isolation) is legitimate, but its leverage
is **architectural, not git-topological**: extract content out of `*.in.html`
into pure include/data files so the seam becomes a file boundary. Until that
refactor is judged worth it, single trunk + short branches + the test suite is
the low-overhead answer. (The extraction itself is unscheduled.)

## Git worktrees — orthogonal to merge semantics, but a good fit here

A worktree (`git worktree add`) is a second checkout of a *different branch*
at a *different path*, sharing one `.git`. It changes **nothing** about merge
semantics — same conflicts, same silent-drift risk — so it does **not** make
long-lived framework/content branches any safer. It is a workspace-management
tool, not a branching-model tool.

It pairs unusually well with **this** repo for a build-mechanics reason: the
build bakes **absolute** paths (`BUILD_ROOT := $(PWD)/TEPPAN_BUILD` plus m4
`realpath`) and stamps `TEPPAN_BUILD/.mode-<domain>` per domain. Each worktree
has a distinct `$(PWD)` → its **own** `TEPPAN_BUILD` → zero build-tree/stamp
collision. So a worktree per branch lets you build two branches concurrently
with no `make realclean` churn between switches — see
[`file://`-relative preview](file-relative-preview.md) and
[Build & test commands](../build/commands.md) for the stamp mechanism.

**Caveat:** a fresh worktree is a new path, so it does **not** inherit the
gitignored per-project tooling — `.claude/node/`, `.claude/chrome-profile/`,
`.claude/settings.local.json`, or the path-keyed local-scope MCP registration
in `~/.claude.json`. Harmless if the agent only edits m4/HTML/CSS and runs
`make test`/`make build`; needs per-worktree re-setup if it needs the browser
MCP.

**Verified — `make test`/`make build` need *zero* per-worktree setup.** A fresh
worktree lacks the gitignored `VENDOR`, yet `make test` runs green in it because
(a) `m4sugar.m4f` is loaded from a **system path**
(`-R /usr/share/autoconf/m4sugar/m4sugar.m4f`), not `VENDOR`, and (b) `make
test` needs only tracked files — `generator_test.m4` plus the tracked
`tests/fixtures/MOCK_VENDOR` — not the real (gitignored, currently absent)
`VENDOR`. So the "gitignored tooling doesn't follow a worktree" caveat bites the
**browser MCP only**, never the build/test path.

## Isolation matrix — host vs. container vs. worktree

"`.claude`" is two different things that fall on opposite sides of the
container boundary:

| Thing | Host | Container | Shared? |
|---|---|---|---|
| **`~/.claude`** (user scope: MCP registrations, auto-memory, user settings) | host home | separate **named volume** | **No** |
| **MCP server** | `chrome-devtools` (host local scope) | `@playwright/mcp` (container volume local scope) | **No** |
| **Auto-memory** | `-home-<user>-www` key | `-workspaces-www` key, container volume | **No** |
| **`./.claude/`** (repo subtree: `settings.local.json`, `skills/`, committed `settings.json`) | \<— workspace bind-mount —> | same files | **Yes** |

So host↔container do **not** share the MCP or user-scope `~/.claude`
(including memory) — that isolation is the container's *volume* setup, not
worktrees. They **do** share the repo's own `./.claude/`, which is exactly the
`settings.local.json` permission-grant leak the
[dev container note](devcontainer-setup.md) documents (mitigated by defaulting
the container to `bypassPermissions`).

**Worktrees are a third, independent axis.** A host worktree at a new path
doesn't inherit the main checkout's path-keyed MCP or its gitignored tooling,
and a host worktree created as a sibling of the repo lives **outside**
`/workspaces/www`, so it is not mounted into the container. Worktrees enable
parallel *branches* (host-side); the container volumes enable simultaneous
*host-vs-container* work. Two separate tools, two separate problems.

## Running two or more agents in parallel

Two independent axes:

- **Axis A — code/build isolation:** clones vs. worktrees.
- **Axis B — runtime/security isolation:** processes on one host vs. one
  container per agent.

### Axis A — one clone + worktrees beats N clones (here)

Worktrees: N branches, N directories, one shared `.git`, trivial local merges
(no remote). Plus the per-worktree `TEPPAN_BUILD` win above. Reserve **full
clones** for agents on *different machines* or an *untrusted* agent you don't
want sharing a `.git` object store.

### Axis B — three topologies, pick by trust level

| | What | Isolation | Cost |
|---|---|---|---|
| **B1** — N processes on the host, no container | each `claude` in its own worktree | weakest — shared OS/network; shared `~/.claude` unless per-process `CLAUDE_CONFIG_DIR` | cheapest |
| **B2** — one container per agent | N instances of the hardened devcontainer, one worktree each | strongest — per-agent firewall, non-root, own `~/.claude` + MCP | N× overhead; needs **distinct named volumes** (the `teppan-*` volumes would otherwise collide) |
| **B3** — one container, N worktrees, N processes | one hardened sandbox around the fleet | medium — agents share the container kernel/network + see each other's files, but the fleet is firewalled + non-root as a unit | one container's overhead |

The container boundary is a **trust boundary**: B2 puts it *between* agents
(mutually untrusted); B3 puts it *around* the fleet (cooperating agents you
trust on one project); B1 has none. **Default to B3** for trusted cooperating
agents; graduate to B2 only when you need per-agent network/trust boundaries;
use clones only across machines.

### The B3 delta on the existing single-container devcontainer

Everything that makes the container a trust boundary is **reused unchanged**
(firewall, non-root, `bypassPermissions` managed settings, toolchain,
`workspaceFolder` pin, the repo bind-mount incl. `.git`). The delta:

1. **Worktrees as siblings *outside* `/workspaces/www`** (e.g.
   `/workspaces/wt-<task>`), not under it — because `/workspaces/www` carries
   both the bind-mount and the named volume over `TEPPAN_BUILD`. Outside, the
   worktree's **working files are container-local/ephemeral**, while its
   `.git` pointer resolves to `/workspaces/www/.git/worktrees/<task>` — so
   **every commit lands in the bind-mounted, host-persisted object store.**
   *Ephemeral body, durable spine:* killing the container loses only
   uncommitted working-tree state, never committed work. (The host can even
   `git worktree list` the entry — pointing at a path it can't reach; clean up
   with `git worktree prune`/`remove`.)
2. **Build isolation is free** — distinct `$(PWD)` per worktree → own
   `TEPPAN_BUILD`, no `.mode-<domain>` collision, no extra volumes.
3. **`CLAUDE_CONFIG_DIR` decision** — shared (recommended: all agents share the
   `~/.claude` volume, hence memory + the once-registered Playwright MCP;
   grants don't collide because `settings.local.json` is path-keyed and
   `bypassPermissions` is uniform) vs. isolated (per-agent
   `CLAUDE_CONFIG_DIR`, but then re-register the MCP per dir).
4. **Launcher + integration** — `git worktree add` per task → `claude` per
   worktree (under `tmux`) → merge each `agent/<task>` to `master` on the main
   worktree, gated on `make test` → `git worktree remove`.

Gotchas: N Playwright MCP = N headless Chromium (all `--isolated`, so no
`SingletonLock` clash — see [chrome-devtools MCP setup](chrome-devtools-mcp-setup.md));
the firewall is fleet-wide (can't loosen it per agent — that's the B2 signal);
gitignored tooling doesn't follow worktrees (mostly moot inside the container,
where Node is system-wide and the browser is baked).

### VS Code interaction

VS Code Dev Containers is **one window : one container : one folder**
(`workspaceFolder = /workspaces/www`). This sorts the topologies:

- **B3 plays well** — still one container; VS Code attaches normally, agents
  are terminal processes, worktrees outside the folder are simply not shown in
  the UI (add via "Add Folder to Workspace" only when a human wants to look,
  at the cost of extra watchers/LSPs per root).
- **B2 fights the GUI** — needs N windows (one per container) or headless
  running; a single window can't multiplex containers.

Gotchas: agent processes in an integrated terminal die on window
close/detach — run them under **`tmux`**; lifecycle hooks (firewall/MCP/chown)
and `${localEnv:GH_TOKEN}` substitution are extension-driven at attach. **The
escape hatch:** you are not bound to the GUI — the **`devcontainer` CLI**
(`devcontainer up`/`exec`) runs the same config and hooks headless, which is
the better driver for an actual fleet, with the VS Code GUI as an *optional
human-oversight attach*.

## Who launches the agents, and how

Every launch has four roles: **partition** (pick N tasks; ≤1 touches the
framework seam) → **provision** (`git worktree add`) → **spawn** (one `claude`
per worktree) → **integrate** (merge to `master`, gated on `make test`,
`git worktree remove`). "Who launches the agents" = who sits in the
orchestrator seat. Three models:

- **A — Human, manually.** You do all four by hand; interactive `claude` in
  `tmux`/terminals. Fit: 2–3 agents, ad hoc.
- **B — A parent Claude Code session (built-in; the natural fit inside Claude
  Code).** The session orchestrates via the **Agent tool** (subagents,
  `isolation: "worktree"`) or the **Workflow tool** (`parallel()`/`pipeline()`
  with worktree-isolated agents); the harness auto-provisions the worktree,
  runs the subagent, returns the result, tears it down; the parent integrates.
  No manual git/CLI. Caveat: subagents are transient task-runners under one
  orchestrating session, not long-lived independent services.
- **C — A script or the Agent SDK, headless (unattended fleets).** A shell
  driver or SDK program loops tasks → `git worktree add` →
  `devcontainer exec … claude -p "<task>"` (headless print mode) under `tmux`
  → collect → merge. No GUI, no human in the loop.

The integrator is always the orchestrator (human/parent-session/script), on
`master`, gated on `make test` — and it is where the "one agent owns the
framework seam" partition rule is enforced. **Recommendation:** Model B inside
Claude Code (least to build); Model C (`devcontainer exec` + `claude -p` +
`tmux`) only for an unattended, GUI-less fleet; Model A as the two-agent
manual fallback.

## Container rebuild safety

The container is designed to be rebuilt as the recovery path. "Rebuild loses
nothing" is true **only for what lives in the bind-mount or a named volume** —
the container's own overlay filesystem is discarded. The ledger:

| Where it lives | Survives a rebuild? |
|---|---|
| `/workspaces/www` (**bind-mount** = host repo) — committed work, tracked files, `.git` | ✅ Safe (it's on the host) |
| `TEPPAN_BUILD`, `~/.claude` (**named volumes**) — build tree, MCP registration, auto-memory | ✅ Survive a normal rebuild (incl. "Rebuild Without Cache"); lost **only** if you explicitly `docker volume rm` / delete volumes |
| **Container overlay** — ephemeral worktrees at `/workspaces/wt-*`, ad-hoc installs, `tmux` sessions, processes | ❌ Lost on rebuild |

The one real data-loss surface: **uncommitted work in an ephemeral worktree**
(overlay, not bind-mount). Its **commits** survive — they were written into the
bind-mounted `/workspaces/www/.git` (the "durable spine") — but uncommitted
working-tree state does not. So "just rebuild, nothing lost" holds **precisely
if the work is committed**, which is why the design leans on committing often.

**A broken `.devcontainer/` experiment can make the container fail to start**
(see the firewall/statsig abort modes in
[dev container setup](devcontainer-setup.md)), but you are never bricked: the
config is on the bind-mounted repo, so recover with
`git checkout master -- .devcontainer/` (or switch branch) and rebuild. Note
the running container reflects whichever `.devcontainer/` was checked out **at
build time**, so keep experimental config on its own branch.

## Validation (smoke-tested)

The **manual worktree flow** was smoke-tested end-to-end on the real repo
(2026-07-03, host-side; the git/build mechanics are identical in the
container). Two sibling worktrees on throwaway `agent/*` branches off `master`,
each a distinct fake task, then:

- **`make test` run in both worktrees *in parallel*** → both exited 0, **30
  PASS / 0 FAIL** each, each building into its **own** `$(PWD)/TEPPAN_BUILD`
  with no `.mode-<domain>` collision and no write to the main tree — confirming
  the absolute-path build-isolation property.
- **Both branches merged into a throwaway integration branch** (disjoint files)
  → clean merge, post-merge `make test` still 0 FAIL — the "~80% file-boundary"
  case in practice.

**Verified teardown — leaves zero trace** (throwaway commits become unreachable,
then GC-pruned; `master` and keeper branches untouched):

```sh
git worktree remove --force <path>        # --force only if the worktree is dirty
git branch -D agent/<task>                # -D (force): the branch is unmerged by design
git worktree prune
# optional hard reclaim of the now-dangling objects:
git reflog expire --expire=now --all && git gc --prune=now
```

The **only** way a test run leaves residue is if you deliberately merge a
throwaway branch into a keeper branch — which the partition/integration
discipline says you don't.

See also: [dev container setup](devcontainer-setup.md),
[`chrome-devtools` MCP setup](chrome-devtools-mcp-setup.md),
[`file://`-relative preview](file-relative-preview.md),
[Build & test commands](../build/commands.md),
[Make vs m4 variable naming](../conventions/make-m4-variable-naming.md).
