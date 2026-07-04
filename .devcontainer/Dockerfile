# Teppan dev container (repo: teppan).
#
# Layered on Microsoft's devcontainers base (non-root `vscode` user + sudo).
# The Claude Code and GitHub CLI features are added on top in devcontainer.json;
# they run *after* this Dockerfile, so Node (installed here) is already on PATH
# for the feature that installs the Claude Code CLI.
#
# Everything the runtime firewall would otherwise have to fetch (Node, the
# Playwright browser, the Playwright MCP server) is installed HERE, at image
# build time, before any egress restriction exists.
FROM mcr.microsoft.com/devcontainers/base:ubuntu

# --- Container identity marker -----------------------------------------------
# A reliable "am I inside this container" signal for the B3 tree guards
# (scripts/guard-main-head.sh + the reference-transaction/post-checkout git
# hooks). Image ENV is inherited by BOTH `docker run` children AND `docker exec`d
# processes, so it survives the headless `devcontainer exec` fleet path and
# reaches git-hook subprocesses -- unlike VS Code's REMOTE_CONTAINERS, which is
# set only in attached terminals. The shared .git/hooks run host-side too; this
# marker is absent on the host, so the guards fail open there.
ENV TEPPAN_IN_CONTAINER=1

# --- Project build toolchain + firewall deps + tarball extraction ------------
#   m4/autoconf/make          -> the Teppan m4 site generator (Makefile)
#   iptables..aggregate,jq    -> .devcontainer/init-firewall.sh
#   xz-utils                  -> extract the Node .tar.xz below
#   tmux                      -> B3 fleet: scripts/b3-fleet.sh runs each agent's
#                                claude under tmux so it survives a VS Code
#                                reload/reconnect/window-close (see
#                                knowledge/notes/b3-fleet-runbook.md)
# (coreutils/realpath, git, curl come with the base image.)
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      m4 autoconf make \
      iptables ipset iproute2 dnsutils aggregate jq \
      ca-certificates curl xz-utils \
      tmux \
 && rm -rf /var/lib/apt/lists/*

# --- Node.js: canonical nodejs.org tarball, pinned + checksum-verified --------
# Matches the provenance of the project's existing .claude/node runtime
# (nodejs.org release tarball, not NodeSource/apt) per the "official sources
# only" rule. Extracted into /usr/local so `node`/`npm`/`npx` land on PATH.
ARG NODE_VERSION=22.23.1
RUN set -eux; \
    arch=x64; \
    f="node-v${NODE_VERSION}-linux-${arch}.tar.xz"; \
    curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/${f}"; \
    curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt"; \
    grep " ${f}\$" SHASUMS256.txt | sha256sum -c -; \
    tar -xJf "${f}" -C /usr/local --strip-components=1 --no-same-owner; \
    rm "${f}" SHASUMS256.txt; \
    node --version; npm --version

# --- Playwright MCP + its matching Chromium, baked at build time --------------
# Pin @playwright/mcp; install the browser with the SAME playwright it bundles
# (resolved from the package's own dep tree, not a fresh `npx playwright@latest`)
# so the baked Chromium revision is exactly the one the server launches.
# --with-deps pulls the browser's OS libraries via apt (root, build-time only).
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers
ARG PLAYWRIGHT_MCP_VERSION=0.0.77
RUN set -eux; \
    npm install -g "@playwright/mcp@${PLAYWRIGHT_MCP_VERSION}"; \
    ( cd "$(npm root -g)/@playwright/mcp" \
        && npx playwright install --with-deps chromium ); \
    chmod -R a+rX /opt/pw-browsers

# --- Config dir owned by the non-root user ----------------------------------
# A fresh named volume inherits the ownership of the image directory it mounts
# over. Pre-create ~/.claude as vscode so the CLAUDE_CONFIG_DIR volume starts
# vscode-owned; otherwise it mounts root-owned and `claude mcp add` silently
# fails to write. (postcreate.sh also chowns it, to fix pre-existing volumes.)
RUN mkdir -p /home/vscode/.claude && chown vscode:vscode /home/vscode/.claude

# --- Managed settings: container defaults to bypassPermissions ----------------
# Container-only Claude Code policy (highest-precedence managed scope, baked into
# the image — NOT the shared repo `.claude/`). The container is hardened
# (firewall + non-root + isolated), so it defaults to skip-permissions: with no
# interactive prompts, Claude writes NO permission grants to the bind-mounted
# `.claude/settings.local.json`, so none leak to the host. (Per-file isolation
# isn't viable — Claude writes settings.local.json via atomic temp+rename, which
# fails with EBUSY over a single-file bind-mount; see knowledge/notes.)
RUN mkdir -p /etc/claude-code
COPY managed-settings.json /etc/claude-code/managed-settings.json

# --- Hardened egress firewall (run from postStartCommand via passwordless sudo)
# Installed under a tekii-* name on purpose: the claude-code feature ships its
# OWN /usr/local/bin/init-firewall.sh and layers AFTER this Dockerfile, so it
# would clobber ours at that path. postStartCommand invokes this copy.
COPY init-firewall.sh /usr/local/bin/tekii-init-firewall.sh
RUN chmod +x /usr/local/bin/tekii-init-firewall.sh \
 && echo 'vscode ALL=(root) NOPASSWD: /usr/local/bin/tekii-init-firewall.sh' \
      > /etc/sudoers.d/vscode-firewall \
 && chmod 0440 /etc/sudoers.d/vscode-firewall
