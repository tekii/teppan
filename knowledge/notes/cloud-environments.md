---
type: Design Note
title: Cloud environments — Claude Code web & GitHub Codespaces (readiness, auth, integration workflow)
description: Readiness survey (2026-07-05) for running Teppan sessions in Claude Code web and GitHub Codespaces — what transfers from the devcontainer, the firewall/permissions and volume gaps in Codespaces, where Claude's own credential lives per environment, and the (undecided) integration-workflow question these environments raise.
tags: [design-note, codespaces, claude-code-web, devcontainer, credentials, workflow]
timestamp: 2026-07-05
---

# Cloud environments — Claude Code web & GitHub Codespaces

Forward-looking survey (2026-07-05): the user plans to use **Claude Code
web** and (primarily) **GitHub Codespaces** alongside the host and the local
dev container. Nothing here is blocking today; this note records what
transfers, what breaks, and which decisions are still open, so the first
real cloud session starts from analysis instead of surprises.

## Claude Code web (scenario 3 — already designed for)

- **No Docker in the sandbox** — and none needed: web does not use
  `.devcontainer/` at all. Provisioning is `scripts/install_pkgs.sh`, gated
  on `CLAUDE_CODE_REMOTE=true` (installs `autoconf`; the base image already
  carries `m4`/`make`). The sandbox replaces the container: isolation,
  egress limits, and non-root come from Anthropic's platform.
- `make test`/`make build` work because they need only tracked files plus
  the system `m4sugar.m4f` — the same property that makes fresh worktrees
  zero-setup (see [parallel development](parallel-agent-worktrees.md)).
- The HEAD-move guards are inert there (`TEPPAN_IN_CONTAINER` unset → they
  fail open) and harmlessly so: each web session works on its own fresh
  clone; the shared-checkout hazard they exist for cannot occur.
- **Claude's auth never enters the sandbox** — platform-managed via scoped
  proxies (git credentials and API auth stay outside; per official
  `claude-code-on-the-web` docs). Delivery back to the repo is push/PR via
  the platform's scoped GitHub credential.

## GitHub Codespaces (a fourth scenario — devcontainer-based)

Codespaces consumes the same `devcontainer.json`/`Dockerfile`/
`postcreate.sh`, so most of the local container transfers as-is: the m4
toolchain, pinned Node, Playwright MCP + baked Chromium, guard-hook install,
`WORKSPACE_ROOT` derivation, `TEPPAN_IN_CONTAINER` (image `ENV` → guards
active, harmless — no shared checkout there either). The no-hardcoded-paths
convention pays off: nothing assumes a folder name or a `/home/<user>` path.

**Gap 1 — firewall + permissions coupling (decision needed, unimplemented).**
`tekii-init-firewall.sh` needs `NET_ADMIN`/`NET_RAW` from `runArgs`, and
Codespaces does not honor `runArgs` *(platform limitation — from general
platform knowledge, confirm on first launch)*. Expect `iptables` to fail at
`postStartCommand`: best case the codespace runs with **open egress**, worst
case the failing hook blocks startup. Meanwhile the image bakes
`managed-settings.json` defaulting to `bypassPermissions` — a default that
was **justified by** the egress firewall. A codespace would inherit the
permissive half without the protective half. Before serious Codespaces use:
gate the firewall script to skip-with-loud-warning when `$CODESPACES` is
set, and decide whether the managed `bypassPermissions` default should also
be conditional there. (When control A is justified by control B, the config
should encode the dependency, not just the two settings.)

**Gap 2 — no named volumes** *(same confirm-on-first-launch caveat)*: the
`mounts:` volumes likely don't apply. `TEPPAN_BUILD` falling back to the
workspace directory is harmless — a codespace is a single environment with
one absolute root, so the [baked-root trap](realclean-recursive.md) has no
second environment to cross-poison with. But `~/.claude` not being a volume
means the codespace Claude's **memory and login live on the container
filesystem**: they survive stop/start but are wiped by a rebuild inside the
codespace (and by deletion). This `knowledge/` tree — bind-independent,
committed — remains the only durable cross-environment memory channel, now
across *four* silos.

**Credentials in a codespace** follow the already-documented `GH_TOKEN`
contract (a Codespaces secret; see the `gh` authentication section in
[dev container setup](devcontainer-setup.md)) — note Codespaces also
auto-injects its own repo-scoped `GITHUB_TOKEN`, so `gh` may partially work
even without the secret. The `/model` picker: if
`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` is baked in the image env, a
codespace inherits the static model list too (see the "fewer models"
section in [dev container setup](devcontainer-setup.md)).

## Where Claude's own credential lives, per environment

Verified against official Claude Code docs (`authentication.md`,
`headless.md`, `claude-code-on-the-web.md`), 2026-07-05:

| Environment | Claude's auth | Survives rebuild? |
|---|---|---|
| Host | `~/.claude/.credentials.json` (0600), written by `/login` | n/a |
| Local container | same file under `CLAUDE_CONFIG_DIR=/home/vscode/.claude` → on the `teppan-claude-config-*` **named volume** | ✅ (why the container never re-asks for login) |
| Claude Code web | never in the sandbox — platform-managed scoped proxies | n/a |
| Codespaces | ⚠️ container filesystem → **wiped per rebuild** → interactive `/login` each time, unless the token pattern below | ❌ by default |

**Codespaces fix — same shape as `GH_TOKEN`:** run `claude setup-token`
once (browser flow; produces a **one-year subscription OAuth token**) and
store it as a Codespaces secret named **`CLAUDE_CODE_OAUTH_TOKEN`** — a
first-class auth env var for Claude Code. Caveats:

- The pattern follows the documented auth-precedence model but is **not
  explicitly endorsed** for Codespaces by official docs.
- **Precedence gotcha:** `ANTHROPIC_API_KEY` *outranks* the OAuth token —
  if an API key appears in the env, Claude Code silently switches from the
  subscription to **API billing**. Keep API keys out of Codespaces secrets
  unless deliberate.
- **Lifetime asymmetry:** the one-year token is the opposite of the
  short-expiry PAT posture — revocable, but a long-lived secret in GitHub's
  store; weigh it accordingly.
- **Structural asymmetry with the kill-switch:** `GH_TOKEN` is
  *absent-able* (that is its value as a control); Claude's own credential
  is not — no token, no Claude. In every self-managed environment the
  Claude credential must coexist with the agent; the design lever is only
  its durability and scope.

## Integration workflow — OPEN QUESTION (no decision yet)

Topologically, a web session or codespace is a **B2 actor** — own clone,
own object store, origin-mediated — so the B2 cost model in
[parallel development](parallel-agent-worktrees.md) applies wholesale:
remote-mediated merges, stale bases, everything through `origin`. The
PR-to-merge workflow these platforms promote collides with two local
habits: `master` is kept **local and long-unpushed** (a web session would
fork from a stale base; a remote merge would diverge from the local
authority), and the **merge gate lives in `b3-fleet.sh integrate`**
(`make test` + auto-rollback) — GitHub's merge button has no equivalent and
the repo has **no CI** (no `.github/workflows/`).

Two coherent reconciliations, both documented here *without a decision*
(the user is deliberating; revisit at the first real web/Codespaces work
session):

1. **PR as transport, local integrate as authority** (minimal delta):
   cloud sessions push `agent/<task>` branches and open PRs; nobody merges
   on GitHub. The in-container session fetches the branch and runs the
   normal worktree → `make test` → `integrate` flow; pushing the resulting
   `master` closes the PR as merged. Requires one habit change: **push
   `master` after every integrate** so cloud sessions always fork from
   truth.
2. **Shift merge authority to GitHub** (native model): add a `make test`
   Actions workflow + branch protection, merge PRs remotely, demote local
   `master` to a mirror. Conventional, but inverts the local-authority
   posture and the auto-rollback gate would need rebuilding as CI.

Either way, a **branch-protection rule on `master`** is worth having: in
model 1 it enforces "only the local authority pushes master" against
accident — the GitHub-side analog of the HEAD-move guards.

See also: [dev container setup](devcontainer-setup.md),
[parallel development — B2 cost model](parallel-agent-worktrees.md),
[baked-root trap](realclean-recursive.md),
[Build & test commands](../build/commands.md).
