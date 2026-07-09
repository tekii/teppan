#!/usr/bin/env bash
# install-git-hooks.sh -- copy the tracked MDR guard hooks into this repo's shared
# hooks dir (the common .git/hooks, which the host, the container, and every
# linked worktree all resolve hooks from).
#
# Idempotent: re-run safely from .devcontainer/postcreate.sh on every rebuild,
# and once by hand on the host (`scripts/install-git-hooks.sh`).
#
# We COPY (not symlink, not core.hooksPath) on purpose: the single .git is
# bind-mount-shared between the host and container checkouts, which sit at
# different paths, so an absolute core.hooksPath can't be valid on both, and the
# worktrees live OUTSIDE the repo so a relative one wouldn't resolve there.
# Copying into the shared common .git/hooks covers all three uniformly; each hook
# self-gates to the container via TEPPAN_IN_CONTAINER, so a shared install is safe
# (it fails open on the host).
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
src="$here/git-hooks"
dest="$(git -C "$here" rev-parse --path-format=absolute --git-common-dir)/hooks"
mkdir -p "$dest"
for hook in reference-transaction post-checkout; do
  install -m 0755 "$src/$hook" "$dest/$hook"
  echo "install-git-hooks: installed $dest/$hook"
done
