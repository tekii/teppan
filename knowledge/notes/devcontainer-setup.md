---
type: Design Note
title: Dev container — Claude Code + Playwright MCP, three coexisting scenarios
description: The .devcontainer/ moves development into a hardened VS Code dev container that replaces the host's chrome-devtools MCP with Microsoft's Playwright MCP — registered at local scope inside the container only, so the host-IDE and Claude-Code-web scenarios are left untouched. Records why each choice was made.
tags: [design-note, devcontainer, mcp, browser, firewall, playwright, node]
timestamp: 2026-07-02
---

# Dev container setup

`.devcontainer/` runs development inside a VS Code dev container for
isolation, reproducibility, and safe use of `--dangerously-skip-permissions`.
Inside it, Google's [`chrome-devtools` MCP](chrome-devtools-mcp-setup.md) is
replaced by Microsoft's official Playwright MCP (`@playwright/mcp`). Three
environments must keep working, and the container must not disturb the other
two:

1. **Host + IDE** — everything installed on the host; `chrome-devtools` MCP at
   Claude's `local` scope in the host's `~/.claude.json` (never committed),
   with project-local `.claude/node/` + `.claude/chrome-profile/`.
2. **Dev container** — this note (the primary environment going forward).
3. **Claude Code web** — provisioned by `scripts/install_pkgs.sh`, gated on
   `CLAUDE_CODE_REMOTE=true` (only adds `autoconf` to a base image).

## Files

- `Dockerfile` — `mcr.microsoft.com/devcontainers/base:ubuntu` + the m4 build
  toolchain, a pinned Node, the Playwright MCP + its Chromium, and the firewall.
- `devcontainer.json` — features, non-root user, volumes, `containerEnv`, and
  the firewall / MCP-registration lifecycle hooks.
- `init-firewall.sh` — egress-allowlist script adapted from Anthropic's
  reference; installed as `/usr/local/bin/tekii-init-firewall.sh` (see the
  firewall section for why the `tekii-` name matters).
- `postcreate.sh` — claims the build volume and registers the Playwright MCP.

## Why these choices

### MCP scoping is the crux — local scope, not a committed `.mcp.json`
The generic advice ("put MCP servers in a project-scope `.mcp.json`") is
**wrong here**: project scope is inherited unconditionally by *all three*
environments, so it would push Playwright onto the host (no browsers →
launch-fail) and web (no Node), breaking scenarios 1 and 3. Instead
`postcreate.sh` registers Playwright at **`local` scope inside the container
only** (`claude mcp add … --scope local`). The host keeps `chrome-devtools`;
`install_pkgs.sh` and web are untouched. Registration is **idempotent**
(remove-then-add): with `CLAUDE_CONFIG_DIR` pointing at the persistent
`~/.claude` volume, the local-scope entry is written to
`${CLAUDE_CONFIG_DIR}/.claude.json` and survives rebuilds, so re-adding is a
harmless no-op.

**Volume-ownership gotcha (bit us on first launch):** a fresh named volume
mounts **root-owned**, and `vscode` can't write into it. When `~/.claude` was
root-owned, `claude mcp add` printed `Added …` and exited 0 but **silently
failed to write the file** — `claude mcp list` then showed nothing. Fix:
`postcreate.sh` `chown -R vscode:vscode` **both** volumes (`TEKII_BUILD` and
`~/.claude`) before registering, and the Dockerfile pre-creates `~/.claude`
vscode-owned so fresh volumes initialise correctly.

### Browser baked at build time; Playwright MCP pinned to match
`@playwright/mcp` is pinned, and its Chromium is installed **at image-build
time** using the package's *own* bundled `playwright` (resolved from its dep
tree, not a fresh `npx playwright@latest`) so the baked browser revision is
exactly the one the server launches. All fetching happens in the Dockerfile,
*before* the firewall exists (the firewall only runs at container start), so
the runtime allowlist needs no browser/npm additions. `PLAYWRIGHT_BROWSERS_PATH`
is set identically at build and runtime.

Two doc-vs-reality facts, both verified against upstream (don't trust the
plan's guesses):
- The MCP binary is **`playwright-mcp`**, not `mcp-server-playwright`.
- `--browser chromium` **is** accepted (upstream's own containerized example
  uses `--headless --browser chromium --no-sandbox`), even though the README
  options *table* lists only channels (`chrome/firefox/webkit/msedge`). So the
  bundled Chromium engine is selectable straight from the CLI — no config file
  needed. `--isolated` keeps the profile in memory (see next point).

### Bind-mount hygiene — the container ignores host browser state
The workspace bind-mount exposes the host's gitignored `.claude/node/` and
`.claude/chrome-profile/` inside the container. The container uses **neither**:
its own Node in `/usr/local`, its own baked browser, and Playwright MCP runs
`--isolated` (ephemeral in-memory profile). This sidesteps the stale
`SingletonLock` failure mode documented in
[chrome-devtools MCP setup](chrome-devtools-mcp-setup.md) — there is no
persistent on-disk profile to lock.

### Workspace path & a container-private build tree
The workspace bind-mounts to `/workspaces/www` (pinned via `workspaceFolder`).
Because the build bakes **absolute** paths (`BUILD_ROOT := $(PWD)/TEKII_BUILD`
plus m4 `realpath`), the container's paths (`/workspaces/www/…`) differ from the
host's (`$HOME/www/…`). Since `TEKII_BUILD/` is inside the workspace, host and
container would otherwise share one tree with conflicting absolute paths and
`.mode-<domain>` stamps → rebuild churn and wrong `file://` links (see
[`file://`-relative preview](file-relative-preview.md)). Fix: a **named volume
over `/workspaces/www/TEKII_BUILD`** gives the container its own private,
gitignored build tree (also faster than bind-mount I/O). It mounts root-owned,
so `postcreate.sh` `chown`s it to `vscode`.

### Node provenance
Node is installed from the canonical `nodejs.org` tarball (pinned +
`SHASUMS256.txt`-verified), matching the provenance of the project's existing
`.claude/node` runtime and the "official sources only" rule — not NodeSource or
apt (apt's Node was too old for the browser MCP tooling anyway).

### Hardened firewall + non-root — for safe `--dangerously-skip-permissions`
Default-deny egress; allowlist = a small domain set + dynamic GitHub CIDRs +
host subnet + DNS/localhost/established. Needs `NET_ADMIN`/`NET_RAW` (`runArgs`)
and runs at `postStartCommand` (with `waitFor`, so a session never starts with
egress open). Non-root `vscode` is mandatory regardless — the CLI refuses
`--dangerously-skip-permissions` as root.

Two non-obvious facts, both learned by a failed first launch:
- **The `claude-code` feature ships its *own* `init-firewall.sh`** and installs
  it to `/usr/local/bin/init-firewall.sh`, layering *after* the Dockerfile — so
  it would silently clobber ours at that path. Our copy is therefore installed
  as **`tekii-init-firewall.sh`** and `postStartCommand` invokes that name.
- **The reference allowlist does a hard `exit 1` on any domain it can't
  resolve**, and `statsig.anthropic.com` currently has **no A record** — so it
  aborted the whole container start. Our adapted script (a) omits the telemetry
  domains (`sentry.io`/`statsig.*`), which `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`
  already blocks, and (b) treats an unresolvable domain as a skippable warning,
  so one dead host can never brick the container again.

**Secret hygiene:** the Dev Containers extension logs the full `docker run …`
line — including `-e GH_TOKEN=…` — at debug level into
`~/.config/Code/logs/.../ms-vscode-remote.remote-containers/`. Redact or rotate
the PAT before sharing those logs. The fine-grained, short-expiry, repo-scoped
token keeps that exposure low-risk.

### `gh` authentication — host env token, never in repo or image
`gh` reads `GH_TOKEN` from the environment (fully authenticates, no
`gh auth login`). `devcontainer.json` carries
`"GH_TOKEN": "${localEnv:GH_TOKEN}"`, substituted from the **host** environment
at create/rebuild — keep the real token in an untracked file *outside* the repo.
Use a **fine-grained PAT scoped to `tekii/www`** with a short expiry (bounds the
blast radius under skip-perms). Never a Docker build `ARG` (baked into image
history). Do **not** mount host `~/.config/gh` or `~/.ssh`. For HTTPS `git push`,
run `gh auth setup-git` once. Web/Codespaces uses the same contract via a
Codespaces secret named `GH_TOKEN`; the host keeps its own `gh auth login`.

## Memory is not shared across scenarios
Host-Claude and container-Claude do **not** share auto-memory: the container's
`~/.claude` is a separate named volume, and the project-path key differs
(`-workspaces-www` vs the host's `-home-<user>-www`). Web is a third store.
Durable, cross-scenario knowledge therefore belongs in this `knowledge/` tree
(bind-mounted, shared) — this note is an example of that channel.

See also: [`chrome-devtools` MCP setup](chrome-devtools-mcp-setup.md),
[`file://`-relative preview](file-relative-preview.md),
[Build & test commands](../build/commands.md).
