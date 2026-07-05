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
(smoke-tested 2026-07-03 — see [Validation](#validation-smoke-tested)). The
**B3 launcher + the three accidental-HEAD-move guards are now implemented** on
`feat/b3-multi-agent` (`scripts/b3-fleet.sh`, `scripts/git-hooks/`,
`scripts/guard-main-head.sh`) and empirically validated end-to-end in the
rebuilt container (2026-07-04, git 2.55 — provision → 30-PASS `make test` in a
fresh worktree → teardown, plus every guard path) — see
[Guarding the shared main checkout](#guarding-the-shared-main-checkout-against-accidental-head-moves).
The **per-agent B2 container infrastructure** (distinct named volumes) remains a
**sketch to build if/when needed**, for the compromised-agent threat model only.

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

**Caveat — browser MCP only, not build/test.** A fresh worktree is a new path,
so it does **not** inherit the gitignored per-project tooling (`.claude/node/`,
`.claude/chrome-profile/`, `.claude/settings.local.json`, or the path-keyed
local-scope MCP registration in `~/.claude.json`). But this bites the **browser
MCP only**: `make test`/`make build` need **zero** per-worktree setup —
*verified* (30 PASS in a fresh worktree that lacked `VENDOR`), because
`m4sugar.m4f` loads from a **system path**
(`-R /usr/share/autoconf/m4sugar/m4sugar.m4f`) and the tests use only tracked
files (`generator_test.m4` + `tests/fixtures/MOCK_VENDOR`), never the gitignored
`VENDOR`.

## Isolation matrix — host vs. container vs. worktree

"`.claude`" is two different things that fall on opposite sides of the
container boundary:

| Thing | Host | Container | Shared? |
|---|---|---|---|
| **`~/.claude`** (user scope: MCP registrations, auto-memory, user settings) | host home | separate **named volume** | **No** |
| **MCP server** | `chrome-devtools` (host local scope) | `@playwright/mcp` (container volume local scope) | **No** |
| **Auto-memory** | `-home-<user>-teppan` key | `-workspaces-teppan` key, container volume | **No** |
| **`./.claude/`** (repo subtree: `settings.local.json`, `skills/`, committed `settings.json`) | \<— workspace bind-mount —> | same files | **Yes** |
| **source tree + `.git`/HEAD** (all tracked files, the branch pointer) | `/home/<user>/teppan` | `/workspaces/teppan` (bind-mount) | **Yes — ONE HEAD** |

So host↔container do **not** share the MCP or user-scope `~/.claude`
(including memory) — that isolation is the container's *volume* setup, not
worktrees. They **do** share the repo's own `./.claude/`, which is exactly the
`settings.local.json` permission-grant leak the
[dev container note](devcontainer-setup.md) documents (mitigated by defaulting
the container to `bypassPermissions`). **Most consequentially, they share the
source tree *and* `.git`/HEAD** — the container bind-mounts the host checkout,
so the two are one repo on one branch pointer. That is the sharpest coupling of
all, and it caused a real incident — see
[the shared-HEAD trap](#hostcontainer-the-shared-head-trap) below.

**Worktrees are a third, independent axis.** A host worktree at a new path
doesn't inherit the main checkout's path-keyed MCP or its gitignored tooling,
and a host worktree created as a sibling of the repo lives **outside**
`/workspaces/teppan`, so it is not mounted into the container. Worktrees enable
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

1. **Worktrees as siblings *outside* `/workspaces/teppan`** (e.g.
   `/workspaces/wt-<task>`), not under it — because `/workspaces/teppan` carries
   both the bind-mount and the named volume over `TEPPAN_BUILD`. Outside, the
   worktree's **working files are container-local/ephemeral**, while its
   `.git` pointer resolves to `/workspaces/teppan/.git/worktrees/<task>` — so
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
   worktree, gated on `make test` → `git worktree remove`. Implemented as
   `scripts/b3-fleet.sh` (`provision`/`spawn`/`up`/`integrate`/`teardown`/`list`);
   `integrate` keeps the main checkout *on* `master` and only advances it via
   `merge --no-ff` (never `checkout`), so it stays clear of the HEAD-move guards
   below (using the inline `TEPPAN_MAIN_HEAD_OK=1` override for the merge itself).

   `integrate` is not fire-and-forget — it has three failure modes, each
   leaving a different state behind: a *pre-merge* test failure in the
   worktree aborts before `master` is touched at all; a *merge conflict*
   stops mid-merge with nothing torn down (resolve or abort manually); and a
   *post-merge* test failure **self-heals** — the script rolls the merge back
   (`TEPPAN_MAIN_HEAD_OK=1 git reset --hard ORIG_HEAD`) and aborts, leaving
   `master` clean at its pre-merge commit with the worktree and branch intact
   for diagnosis. That last case is the semantic-drift scenario this note's
   "clean merge that no longer builds" warning describes — the gate catching
   it is the design working as intended. Remember the gate is `make test`
   only (macro-level, no HTML/CSS render): changes touching build inputs need
   a manual `make build` in the worktree first. Operator steps for each
   failure mode are in the
   [runbook's recovery section](b3-fleet-runbook.md).

Gotchas: N Playwright MCP = N headless Chromium (all `--isolated`, so no
`SingletonLock` clash — see [chrome-devtools MCP setup](chrome-devtools-mcp-setup.md));
the firewall is fleet-wide (can't loosen it per agent — that's the B2 signal);
gitignored tooling doesn't follow worktrees (mostly moot inside the container,
where Node is system-wide and the browser is baked).

### VS Code interaction

VS Code Dev Containers is **one window : one container : one folder**
(`workspaceFolder = /workspaces/${localWorkspaceFolderBasename}`, i.e.
`$WORKSPACE_ROOT`; `/workspaces/teppan` in the current checkout). This sorts the topologies:

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
`master`, gated on `make test` (with automatic rollback if the post-merge run
fails — see the failure modes in the B3-delta list above) — and it is where the
"one agent owns the framework seam" partition rule is enforced. **Recommendation:** Model B inside
Claude Code (least to build); Model C (`devcontainer exec` + `claude -p` +
`tmux`) only for an unattended, GUI-less fleet; Model A as the two-agent
manual fallback.

## Container rebuild safety

The container is designed to be rebuilt as the recovery path. "Rebuild loses
nothing" is true **only for what lives in the bind-mount or a named volume** —
the container's own overlay filesystem is discarded. The ledger:

| Where it lives | Survives a rebuild? |
|---|---|
| `/workspaces/teppan` (**bind-mount** = host repo) — committed work, tracked files, `.git` | ✅ Safe (it's on the host) |
| `TEPPAN_BUILD`, `~/.claude` (**named volumes**) — build tree, MCP registration, auto-memory | ✅ Survive a normal rebuild (incl. "Rebuild Without Cache"); lost **only** if you explicitly `docker volume rm` / delete volumes |
| **Container overlay** — ephemeral worktrees at `/workspaces/wt-*`, ad-hoc installs, `tmux` sessions, processes | ❌ Lost on rebuild |

The one real data-loss surface: **uncommitted work in an ephemeral worktree**
(overlay, not bind-mount). Its **commits** survive — they were written into the
bind-mounted `/workspaces/teppan/.git` (the "durable spine") — but uncommitted
working-tree state does not. So "just rebuild, nothing lost" holds **precisely
if the work is committed**, which is why the design leans on committing often.

**A broken `.devcontainer/` experiment can make the container fail to start**
(see the firewall/statsig abort modes in
[dev container setup](devcontainer-setup.md)), but you are never bricked: the
config is on the bind-mounted repo, so recover with
`git checkout master -- .devcontainer/` (or switch branch) and rebuild. Note
the running container reflects whichever `.devcontainer/` was checked out **at
build time**, so keep experimental config on its own branch.

## Host↔container: the shared-HEAD trap

The devcontainer isolates user-scope `~/.claude` (memory/MCP) and the
`TEPPAN_BUILD` volume, but it does **not** isolate the **source tree or
`.git`/HEAD** — those are bind-mounted. So the host checkout (`/home/<user>/teppan`)
and the container's `/workspaces/teppan` are **one repo on one branch pointer**.
Two git-active sessions on that shared checkout is *negative* isolation — the
opposite of what worktrees/B2 give. The clash condition is **agent-agnostic**:
it's any two git-active sessions on one shared tree+HEAD (agent-agent,
user-agent, user-user alike).

**Real incident (2026-07-03, resolved benign).** A host-side session ran
`git checkout master` (to commit an unrelated `knowledge/` doc) while a
container session was live on `css-water-migration`. Because HEAD is shared, the
checkout **reverted the container's in-context files** (`layout.html`,
`configure.m4`, …) to their `master` content *underneath* the live session. The
container harness then emitted its standard **external-file-change
notifications** — *"Note: <file> was modified… don't tell the user, they are
already aware…"* — one per reverted file, batched onto the session's next tool
result. The container instance briefly suspected **prompt injection**. It was a
**false alarm**: no data loss (the migration commit was intact — HEAD simply
moved and moved back), the "don't tell the user" wording is *standard harness
phrasing*, and the tell was that the notes matched the **reverted files**, not
the file being read. Correct posture (surface, don't silently obey) but wrong
classification, for lack of cross-session visibility.

**Prevention — ranked (for "user/agent outside + agent inside, concurrent"):**

1. Current bind-mount, both working in `/workspaces/teppan` → ❌ shared HEAD (the incident).
2. **B3** — the container actor works in its **own** container-local worktree
   (own HEAD) and **never `git checkout` in `/workspaces/teppan`** → ✅ *if
   disciplined* (the agent can still wander into the shared checkout — which is
   exactly what happened).
3. **B2** — give the container its **own clone** (no host source bind-mount) →
   ✅✅ no shared HEAD exists; **foolproof by construction**.
4. Temporal separation (never both git-active at once) → ✅ operational, not structural.

**Takeaway (scope by threat model):** B3 is sufficient *if the discipline is
followed*. B2's structural clash-immunity **is** genuinely more robust — but
that robustness only *pays off against an untrusted/compromised agent*; for
*cooperating* agents the cost (next section) outweighs it. So the default is
**B3 + a guard** (the accidental-mishap hooks below), with B2 reserved for the
compromised-agent threat model — as the **Decision of record** below (end of the
guarding section) states. See
[dev container setup](devcontainer-setup.md) for the volume/bind-mount layout
this rests on.

### B2's cost — it *moves* durability, merging, and integration onto you

B2 removes the clash by construction, but it **relocates** onto you several
things the shared bind-mount / shared object store gave for free:

1. **Commit durability moves *into* the container.** The bind-mount's "durable
   spine" (commits land in the host's `.git`, so they survive a container
   crash — see [Container rebuild safety](#container-rebuild-safety)) is
   **gone**: B2's clone has its **own** `.git` *inside* the container, so a
   crash/destroy loses committed work too **unless** the clone is on a
   **persistent volume** or **pushed**. Durability is no longer free — you must
   re-provide it.
2. **Merging goes from local to remote-mediated — the biggest change.** In B3
   all worktrees share **one `.git` object store**, so `git merge agent/b` is
   **local and instant** (the commits are already present — no network). In B2
   each clone has its **own** object store, so agent B's commits are physically
   **absent** from the integrator until **transferred**: a merge becomes
   *push/fetch, **then** merge*. That forces a shared-remote topology and
   reintroduces classic collaboration friction — non-fast-forward rejections and
   `pull → rebase → push` loops that the single object store eliminates.
3. **Integration is forced through `origin` (firewall-specific).** B2 containers
   can't see each other's filesystems, and the egress allowlist blocks arbitrary
   container-to-container / host-to-container git transport — but **`origin`
   (GitHub) is allowlisted**. So every agent must push its WIP branch to GitHub
   and the integrator pulls from there: WIP noise on the shared remote, network
   round-trips per integration, and a **push credential (`GH_TOKEN`/PAT) in
   *every* hardened container** — N× secret distribution / blast radius, against
   the [devcontainer note](devcontainer-setup.md)'s minimal-PAT posture.
4. **Further friction:** *stale base* (a clone integrates against the `master` it
   last `fetch`ed, not the live one → more conflicts; B3 worktrees see refs
   instantly); loss of git's *"same branch can't be checked out in two
   worktrees"* guard (two clones can diverge their own `master`); and *N× disk +
   provisioning* (a full clone **and** a full container each, vs one container +
   a cheap `git worktree add`).

| | Bind-mount (current / B3) | B2 (own clone) |
|---|---|---|
| Working tree | shared → clash risk (needs discipline) | isolated → clash impossible |
| Commit durability | **free** (host `.git`) | **your job** (persistent volume or push) |
| Merge / integration | **local `git merge`** (shared object store) | **remote-mediated** (push/fetch via `origin`) + non-ff reconciliation |
| Base freshness | live shared refs | stale until `fetch` → more conflicts |
| Push credentials | not required to merge | PAT in **every** container |
| Crash blast radius | host tree can be disturbed | host tree untouched |

**Net:** B2 doesn't merely risk "work until pushed" — it **converts a
single-repo operation into a distributed-VCS workflow** (shared remote,
credentials everywhere, stale-base conflicts, non-ff reconciliation). That
multi-repo collaboration tax is why, for *cooperating* agents, the default stays
**B3 + a guard** (next section) and B2 is reserved for the untrusted/compromised
case.

## Guarding the shared main checkout against *accidental* HEAD moves

If you keep the bind-mount (B3-style) instead of isolating the tree (B2), you
can still catch the **accidental** violation — a trusted in-container agent, or
a script it runs, that forgets the rule and does `git checkout`/`switch`/`reset`
in the shared checkout. **Scope: accidental only.** A *compromised/injected*
agent is **out of scope of this protection**: deliberate evasion (routes the
guard doesn't match, a direct `.git/HEAD` file-write) or disabling the guard
would need **capability removal** (RO-mount / own clone), not the hooks below.

**Three complementary guards** (implemented on `feat/b3-multi-agent`), each of
which also **injects the rule** into the agent's view so it self-corrects for
the rest of the session:

- **`PreToolUse` deny (harness layer) — the clean front door.**
  (`scripts/guard-main-head.sh`, wired in `.claude/settings.json`.) Fires
  *before* the Bash command runs, so a denied `git checkout|switch|reset …` on
  the main checkout **never executes** → nothing touched, no partial state.
  Blind spot: it matches the **command string** + the session `cwd`, so a
  checkout nested in a `script`/`make`, or one run from a *worktree* session via
  `cd /workspaces/teppan && …` beyond the literal-path heuristic, slips past.
- **`reference-transaction` git hook — the ref-move backstop.**
  (`scripts/git-hooks/reference-transaction`.) Runs *inside* git's ref
  machinery, so it catches the **scripted/plumbing** routes `PreToolUse` can't
  see — but **only for operations that change a ref's object id**: `reset`,
  `commit`, `merge`, detached checkout, branch force-move/delete, `update-ref`
  (all surface as `HEAD` or `refs/heads/<current>`). It **aborts** those.
- **`post-checkout` git hook — the branch-switch detective.**
  (`scripts/git-hooks/post-checkout`.) Covers the one route the other two miss
  (see the correction below). git has no `pre-checkout` hook, so it fires
  *after* the switch: it loudly warns + injects the rule, but does **not**
  auto-undo (the tree is already switched; a blind restore could clobber real
  uncommitted work).

**Empirical correction (git 2.43, validated 2026-07-04 — supersedes an earlier
claim here that `reference-transaction` "catches every git-path HEAD move"):**

- **`git checkout|switch <branch>` emits NO `reference-transaction` at all.**
  Retargeting the `HEAD` *symref* is not a ref-object-id update, so the hook
  never fires for a branch switch — which is *the exact incident operation*
  (`git checkout master`). Neither mandated guard catches a **scripted/nested**
  branch checkout from a worktree; that gap is precisely why `post-checkout`
  (detective) was added.
- **An aborted `git reset --hard` still clobbers the working tree.** `reset`
  updates the index+worktree *before* the ref transaction fires, so aborting at
  `prepared` leaves the tree reverted with `HEAD` intact — a half-applied state
  (recover with `git restore --source=HEAD --staged --worktree .`). The hook
  *prevents the ref move* (so the damage is recoverable from the untouched
  HEAD), it does not prevent the file touch. (The note's old worry about a
  half-applied *checkout* was moot — checkout never reaches the hook.)

Corrected coverage (accidental, in the shared main checkout):

| Route | PreToolUse | reference-transaction | post-checkout |
|---|---|---|---|
| **typed** `checkout`/`switch <branch>` | ✅ deny (prevents) | ❌ invisible | ⚠️ detect-after |
| **scripted/nested** `checkout <branch>` | ❌ (cwd is worktree) | ❌ invisible | ✅ **only catch** (detect-after) |
| `reset --hard` (typed / scripted) | ✅ deny / — | ⚠️ aborts ref; tree already touched (HEAD safe) | — |
| commit/merge on master (integrator) | allow (override) | allow (override) | — |
| branch force-move / delete / `update-ref` | ✅ (if typed) | ✅ **aborts cleanly** (pure-ref) | — |
| linked worktree moving its **own** HEAD | allow | allow (early-exit) | allow (early-exit) |
| **host** actor on `/home/<user>/teppan` | allow | allow (fail-open) | allow (fail-open) |

**Actor discrimination (empirically validated).** All three self-gate with:
(1) **container vs. host** — a `TEPPAN_IN_CONTAINER=1` image `ENV` (Dockerfile),
the guards' *first* line, chosen over VS Code's `REMOTE_CONTAINERS` because image
`ENV` is inherited by both `docker run` children and headless `devcontainer exec`
processes (so it reaches git-hook subprocesses); host has no marker → **fail-open
with no git call**, so a hook bug can never disrupt host git; (2) **main vs.
linked worktree** — `git rev-parse --absolute-git-dir == --git-common-dir` (a
linked worktree moving its *own* HEAD is always allowed); (3) **op type** — the
transaction ref name (`HEAD`/current branch vs. an unrelated `refs/heads/*`),
*skipping symref writes* (`new = ref:…`): those never revert the working tree,
and git **2.55**'s `git worktree add` initializes the new worktree's HEAD as a
`ref:` write **in the main git-dir** — without the skip, the guard would block
its own `provision` step (git 2.43 didn't do this; caught only by in-container
validation); and
(4) the **sanctioned-integrator escape hatch** — an *inline* (never `export`ed)
`TEPPAN_MAIN_HEAD_OK=1` on the launcher's merge/rollback step, since the
integrator's `git merge` on master *is* a `refs/heads/master` update the
ref-transaction guard would otherwise block.

**Name-agnostic — no hardcoded path.** None of the guards bake in `/workspaces/teppan`:
`guard-main-head.sh`'s `cwd` check and the launcher (`scripts/b3-fleet.sh`) read
**`$WORKSPACE_ROOT`** (= the devcontainer's `${containerWorkspaceFolder}`, exported
via `containerEnv`), and the two git hooks discriminate purely via
`git rev-parse --absolute-git-dir == --git-common-dir`. So the concrete
`/workspaces/teppan` path throughout this note is just *the current example* — rename
the repo/folder to anything and the guards, launcher, and build work unchanged.
See [no user-specific or hardcoded absolute paths](../conventions/no-user-specific-paths.md).

**Installation.** `PreToolUse` lives in the repo's shared `.claude/settings.json`.
The two git hooks are **copied** (`scripts/install-git-hooks.sh`, run from
`.devcontainer/postcreate.sh`, idempotent) from tracked sources in
`scripts/git-hooks/` into the shared common `.git/hooks/` — *not*
`core.hooksPath` and *not* a symlink: the single `.git` is bind-mount-shared, so
an absolute `core.hooksPath` can't be valid on both the container checkout path
(`$WORKSPACE_ROOT`) and the host's (`/home/<user>/…`), and the worktrees live
outside the repo so a relative one wouldn't resolve there. Copying into the shared common dir covers host,
container, and every worktree uniformly; the `TEPPAN_IN_CONTAINER` gate makes the
shared install safe (inert on the host). (`reference-transaction`/`post-checkout`
are the right hooks — **not** `pre-commit`; a HEAD move isn't a commit, and they
aren't skipped by `--no-verify`.)

**Mental model:** `PreToolUse` = preventive front door (typed); the two git hooks
= the net for what comes scripted/nested — `reference-transaction` aborts ref
moves, `post-checkout` warns on the branch switch that no git hook can prevent.

**Decision of record (2026-07-03; guards implemented + coverage corrected
2026-07-04):** for concurrent host↔container work, keep **B3** (bind-mount,
agents confined to their own worktrees) plus the `PreToolUse` +
`reference-transaction` + `post-checkout` guards above — **scoped to accidental
mishaps**. **B2** (separate clone) is reserved for a threat model that includes
a **compromised/injected** agent, which these guards deliberately do **not**
cover. Primary mechanism is still the discipline ("agent works only in its own
worktree"); the hooks are the safety net for a slip.

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

See also: [B3 fleet runbook — working in the container & launching agents
(operator-facing)](b3-fleet-runbook.md) (the operational checklist on top of
this design note), [dev container setup](devcontainer-setup.md),
[`chrome-devtools` MCP setup](chrome-devtools-mcp-setup.md),
[`file://`-relative preview](file-relative-preview.md),
[Build & test commands](../build/commands.md),
[Make vs m4 variable naming](../conventions/make-m4-variable-naming.md).
