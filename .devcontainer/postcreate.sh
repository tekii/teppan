#!/usr/bin/env bash
# Runs once per container create/rebuild, as the `vscode` user
# (devcontainer.json: postCreateCommand). Two jobs:
#   1. Claim the container-private TEPPAN_BUILD volume (mounts root-owned).
#   2. Register the Playwright MCP at *local* scope — container-only, so the
#      host and web sessions are never touched (they keep chrome-devtools / no
#      browser MCP respectively).
set -euo pipefail

# The main checkout path, derived (not hardcoded) from the devcontainer's
# ${containerWorkspaceFolder} via WORKSPACE_ROOT -- so this is name-agnostic.
WORKSPACE="${WORKSPACE_ROOT:?WORKSPACE_ROOT not set (define it in devcontainer.json containerEnv)}"

# 1. Fresh named volumes mount root-owned; hand them to the workspace user.
#    - TEPPAN_BUILD: so `make build`/`preview` can write generated output.
#    - ~/.claude (CLAUDE_CONFIG_DIR): so `claude mcp add` below can actually
#      persist ~/.claude/.claude.json. If this volume stays root-owned, the CLI
#      prints "Added ..."/exit 0 but SILENTLY fails to write, and no MCP is
#      registered (the symptom that first bit us).
sudo chown -R vscode:vscode "${WORKSPACE}/TEPPAN_BUILD" "${HOME}/.claude"

# 1b. Make /workspaces itself writable by the workspace user so the MDR launcher
#     (scripts/mdr.sh) can create sibling worktrees next to the main
#     checkout -- OUTSIDE the "$WORKSPACE" bind-mount, so they are container-local
#     and ephemeral. The runtime creates /workspaces root-owned; chown just the
#     dir (not -R -- the workspace bind-mount is separate and stays as-is).
sudo chown vscode:vscode /workspaces

# 2. Register Playwright MCP (Microsoft, @playwright/mcp — baked into the image
#    at build time, so no npx/network here). Local scope writes the project
#    entry in ${CLAUDE_CONFIG_DIR}/.claude.json, which is on the persistent
#    ~/.claude volume — remove-then-add keeps this idempotent across rebuilds.
#    Flags mirror upstream's own containerized example:
#      --browser chromium  bundled Chromium engine (matches PLAYWRIGHT_BROWSERS_PATH)
#      --headless          no display in the container
#      --isolated          in-memory profile (no on-disk SingletonLock)
#      --no-sandbox        required for Chromium in a container
#      --allow-unrestricted-file-access
#                          lift Playwright MCP's default block on file:// URLs,
#                          so it can screenshot the file://-based `make preview`
#                          output (see knowledge/notes/file-relative-preview.md).
#                          Safe here: hardened, isolated, non-root container.
#      --output-dir        write screenshots + console/snapshot logs into the
#                          gitignored, container-private, realclean-wiped
#                          TEPPAN_BUILD tree instead of the workspace root (whose
#                          default .playwright-mcp/ and *.png are NOT gitignored
#                          and would pollute the repo).
claude mcp remove playwright --scope local >/dev/null 2>&1 || true
mkdir -p "${WORKSPACE}/TEPPAN_BUILD/ARTIFACTS"
claude mcp add playwright --scope local -- \
  playwright-mcp --headless --browser chromium --isolated --no-sandbox \
    --allow-unrestricted-file-access \
    --output-dir "${WORKSPACE}/TEPPAN_BUILD/ARTIFACTS"

# 3. Install the MDR accidental-HEAD-move git hooks into the shared common
#    .git/hooks (reference-transaction + post-checkout). Idempotent; copies the
#    tracked sources from scripts/git-hooks. The hooks self-gate to the container
#    via TEPPAN_IN_CONTAINER, so they fail open when the same .git is used on the
#    host. See knowledge/notes/parallel-agent-worktrees.md (the guard section).
"${WORKSPACE}/scripts/install-git-hooks.sh"

echo "postcreate: TEPPAN_BUILD owned by vscode; Playwright MCP registered (local scope); MDR git hooks installed."
