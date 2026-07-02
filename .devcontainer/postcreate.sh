#!/usr/bin/env bash
# Runs once per container create/rebuild, as the `vscode` user
# (devcontainer.json: postCreateCommand). Two jobs:
#   1. Claim the container-private TEKII_BUILD volume (mounts root-owned).
#   2. Register the Playwright MCP at *local* scope — container-only, so the
#      host and web sessions are never touched (they keep chrome-devtools / no
#      browser MCP respectively).
set -euo pipefail

WORKSPACE="/workspaces/www"

# 1. A freshly-created named volume mounts as root:root; hand it to the
#    workspace user so `make build`/`preview` can write generated output.
sudo chown vscode:vscode "${WORKSPACE}/TEKII_BUILD"

# 2. Register Playwright MCP (Microsoft, @playwright/mcp — baked into the image
#    at build time, so no npx/network here). local scope writes ~/.claude.json,
#    which lives OUTSIDE the mounted ~/.claude volume and is recreated on every
#    rebuild — hence remove-then-add to stay idempotent.
#    Flags mirror upstream's own containerized example:
#      --browser chromium  bundled Chromium engine (matches PLAYWRIGHT_BROWSERS_PATH)
#      --headless          no display in the container
#      --isolated          in-memory profile (no on-disk SingletonLock)
#      --no-sandbox        required for Chromium in a container
claude mcp remove playwright --scope local >/dev/null 2>&1 || true
claude mcp add playwright --scope local -- \
  playwright-mcp --headless --browser chromium --isolated --no-sandbox

echo "postcreate: TEKII_BUILD owned by vscode; Playwright MCP registered (local scope)."
