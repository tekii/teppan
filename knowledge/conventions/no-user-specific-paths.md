---
type: Convention
title: No user-specific or hardcoded absolute paths
description: Two standing rules for this repo — never commit a user-specific absolute path or username (e.g. /home/<login>/…), and never hardcode the workspace/checkout path; derive it (the build is already $(PWD)-relative; the container plumbing reads devcontainer variables / WORKSPACE_ROOT). Keeps the repo portable across clone locations and folder names, and free of leaked usernames.
tags: [convention, paths, portability, privacy, devcontainer, hardcoding]
timestamp: 2026-07-04
---

# No user-specific or hardcoded absolute paths

Two rules, both about keeping the repo decoupled from *where* and *by whom* it
happens to be checked out.

## Rule 1 — never commit a username or user-home path

No tracked file may contain a **user-specific absolute path** — a real login
name or a `/home/<login>/…` (or `/Users/<login>/…`, `C:\Users\…`) path.

- **Docs/links:** use **repo-relative** paths — `[CLAUDE.md](../CLAUDE.md)`,
  `[knowledge/](knowledge)` — never `file:///home/<login>/teppan/CLAUDE.md`.
- **Prose that must illustrate a home path:** use the `<user>` placeholder
  (`/home/<user>/…`), never a real login. The docs already do this
  consistently (e.g. the isolation matrix in
  [parallel development](../../knowledge-infra/notes/parallel-agent-worktrees.md)).
- **Applies even to `dnl`/comment/disabled scratch code.** A committed username
  changes *no behavior* there, but it still ships in every clone and is
  `git grep`-visible — a privacy leak and a needless personalization of the
  tree. Strip the path (make it relative) or delete the dead line.
- **Not covered:** the dev container's **fixed** non-root user `vscode`
  (`/home/vscode/…`, e.g. `CLAUDE_CONFIG_DIR`) is *not* a personal login — it's
  the same on every machine, portable, and intentional. Only *personal* logins
  and host-home paths are forbidden.
- **Check before committing:**
  ```sh
  git grep -iE '/(home|Users)/[A-Za-z0-9_.-]+/' | grep -vE '/home/vscode/'  # → empty
  git grep -i '<your-login>'                                                 # → empty
  ```

## Rule 2 — never hardcode the workspace/checkout path; derive it

The location and folder name of the checkout must not be baked into tracked
files. Two facets, mirroring the
[Make vs m4 variable-naming split](make-m4-variable-naming.md):

- **Build (Make):** already correct — `SRC`/`BUILD_ROOT`/`VENDOR` are
  `$(PWD)/…` plus `realpath`, so `make build`/`test` run from **any** path
  (verified in ephemeral worktrees). Keep it that way; never introduce an
  absolute build path.
- **Container plumbing:** derive from **devcontainer variables**, not a literal
  `/workspaces/<name>`:
  - `devcontainer.json`: `"workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}"`,
    mounts `target=${containerWorkspaceFolder}/…`, and expose
    `"WORKSPACE_ROOT": "${containerWorkspaceFolder}"` in `containerEnv`.
  - Scripts/guards (`postcreate.sh`, `scripts/b3-fleet.sh`,
    `scripts/guard-main-head.sh`) read **`$WORKSPACE_ROOT`** — never a literal
    path. Worktree parents derive as `$(dirname "$WORKSPACE_ROOT")`. The
    `reference-transaction`/`post-checkout` git hooks stay path-free by design
    (`git rev-parse --absolute-git-dir == --git-common-dir`).

## Why

- **Portability:** clone anywhere, name the folder anything (`www`, `teppan`,
  a throwaway), and the container + build + B3 guards work unchanged — a repo
  rename needs **zero** code edits.
- **Privacy:** no contributor's login ships to everyone who clones.
- **Reproducibility:** no hidden dependency on one machine's directory layout.

See also: [Make vs m4 variable naming](make-m4-variable-naming.md),
[parallel development — B3 guards read `WORKSPACE_ROOT`](../../knowledge-infra/notes/parallel-agent-worktrees.md),
[glossary](../glossary.md).
