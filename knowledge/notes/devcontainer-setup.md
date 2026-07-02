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

### Playwright MCP blocks `file://` by default — preview needs `--allow-unrestricted-file-access`
Playwright MCP **refuses to navigate to `file://` URLs** out of the box
(`Error: Access to "file:" protocol is blocked`), unlike the host's
`chrome-devtools` MCP which allowed them. This directly collides with this
project's `file://`-based `make preview` (see
[`file://`-relative preview](file-relative-preview.md)): there is no HTTP
server to point a browser at — the whole design is "open the generated file
off disk." So to screenshot/inspect the preview in the container, the server
must be registered with **`--allow-unrestricted-file-access`** (the *only*
flag that lifts the block — `--allowed-origins`/`--allowed-hosts` do **not**;
confirmed via `playwright-mcp --help`). It's now baked into `postcreate.sh`'s
`claude mcp add` line. Safe here specifically because the container is
hardened, isolated, and non-root — granting the headless browser local-file
read is exactly its job in this environment, nothing more.

**Restart gotcha:** changing the registration (via `claude mcp add` or by
editing `postcreate.sh`) updates `${CLAUDE_CONFIG_DIR}/.claude.json`, but the
**already-running** MCP server process keeps its old args — `file://` stays
blocked for the rest of the current session. The new flag only takes effect
when the server is re-spawned, i.e. on the **next Claude Code session**. So
after adding the flag: restart the session, *then* navigate to
`file:///workspaces/www/TEKII_BUILD/DOC/<domain>/index.html`. (Same caveat for
any later flag change, e.g. `--output-dir` below.) Mid-session workaround
without a restart: pass an **absolute** path where the flag's effect would
otherwise apply — e.g. `browser_take_screenshot`'s `filename` as an absolute
path under the desired output dir.

**Output location — `--output-dir` into `TEKII_BUILD/ARTIFACTS/`.** By default
Playwright MCP writes screenshots (relative `filename`s) to its working dir —
the workspace root — and its console/snapshot logs to a `.playwright-mcp/`
folder there. **Neither is gitignored**, so both pollute the checkout as
untracked files. `postcreate.sh` therefore adds
`--output-dir "${WORKSPACE}/TEKII_BUILD/ARTIFACTS"`, which redirects *both*
into the `TEKII_BUILD` tree — already gitignored (`.gitignore`'s `TEKII_BUILD`
line), container-private (named volume, no host bind-mount leak), and wiped by
`make realclean`. That makes captures genuinely disposable dev artifacts with
zero repo-pollution risk and no extra `.gitignore` entry — preferred over
`/tmp` (which is off-workspace and invisible in the file tree).

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

### Side effect: the `/model` picker shows fewer models than the host (no Fable)
The container's `/model` list is a **subset** of the host's — notably it omits
newer models like **Fable 5** — even though both run the **same Claude Code
version** and authenticate as the **same account** (`api.anthropic.com` is
allowlisted; there is no entitlement difference). The cause is a direct
consequence of two firewall/telemetry choices above: which models the picker
advertises is **feature-gated via Statsig** (`statsig.anthropic.com`), and this
container cannot reach that gate — `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`
tells the CLI not to contact Statsig, and the firewall omits
`statsig.anthropic.com` from the allowlist anyway. With the gate unresolvable,
Claude Code falls back to the **static model list baked into the CLI build**,
which excludes models still being rolled out behind gates. So it is *not* a
version or account problem; it is the hardened setup deliberately severing the
feature-gate channel. Restoring the full list would mean allowlisting
`statsig.anthropic.com` **and** dropping `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`
— i.e. re-enabling the non-essential/telemetry traffic this setup exists to cut,
a real trade-off, not a free toggle. Left as-is by design.

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

## 📌 Pinned limitation: permission grants leak host ↔ container (unsolved)
`.claude/settings.local.json` (the per-checkout permission allowlist +
`enabledPlugins`) is **bind-mounted**, so an "always allow, don't ask again in
this project" granted in one environment appears in the other. Note "local"
means *uncommitted / per-working-copy*, **not** per-runtime-environment — the
two environments share one working copy, hence one file. This is worrisome
because grants made in the (looser) container bleed into the host. Candidate
fixes, all non-trivial (deferred until primary work moves into the container):
- steer container "always allow" into **user scope** (`$CLAUDE_CONFIG_DIR`, the
  container-only volume) instead of project scope — but that's a manual,
  per-decision choice;
- give the container its **own** `settings.local.json` by overlaying that path
  with a container-private mount (like `TEKII_BUILD`) — fiddly, since a Docker
  volume mounts as a directory, not a file (needs a bind-mounted file or a
  postCreate symlink);
- keep the shared baseline allowlist in committed `.claude/settings.json` and
  treat `settings.local.json` as disposable per environment.

See also: [`chrome-devtools` MCP setup](chrome-devtools-mcp-setup.md),
[`file://`-relative preview](file-relative-preview.md),
[Build & test commands](../build/commands.md).
