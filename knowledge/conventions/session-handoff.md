---
type: Convention
title: Outer↔inner session handoff (the handoff/ channel)
description: How a host/outer Claude session and a container/inner Claude session collaborate on repo-content work through the untracked handoff/ folder — outer drafts, inner verifies-and-commits — with the verify-at-apply, hygiene, attribution, cleanup, and push rules learned in practice.
tags: [conventions, workflow, handoff, devcontainer, agents]
timestamp: 2026-07-05
---

# Outer↔inner session handoff (the `handoff/` channel)

The **host/outer** Claude session and the **container/inner** session split
repo work by the [host = infrastructure, container = deliverable
convention](../notes/parallel-agent-worktrees.md): the outer can *research and
draft* but cannot commit repo-content (its tooling and guards don't apply — see
"Why not just let the outer commit?" below); the inner *verifies, applies, and
commits*. The **`handoff/` folder** is the channel between them.

## The channel: `handoff/`

- **Untracked scratch on the host bind-mount**, so both sessions read the *same*
  files (host and container share `/workspaces/teppan`). **Gitignored** — these
  artifacts are ephemeral and must never enter history. (It is a *dedicated*
  channel; do not reuse `wip/`, which exists for other purposes.)
- **Artifact naming:**
  - `draft-<topic>.md` — **outer → inner**: a package to apply.
  - `findings-<topic>.md` — **inner → outer**: a hand-back (verification
    results, refutations, revision requests).
- Every artifact opens with a **provenance header**: the authoring model, the
  date, and "content-authoritative, but re-verify anchors against the tree."

## Draft anatomy (outer authors)

- Provenance header + a **package map** (`PKG1..N`).
- Each package: the **target file**, the **verbatim anchor**, and the exact
  replacement/insert text.
- **Label unverified claims** explicitly (e.g. "confirm on first launch") and
  keep those labels through application.
- An **"out of scope"** list (things to surface to the user, not do unasked)
  and, optionally, a paste-in prompt for the inner session.

## Inner apply rules (hard-won — follow every time)

1. **Re-read the draft file itself at apply time** as the source of truth —
   never a cached copy from an earlier read. The outer may have revised it since
   (a stale cached `PKG4` was applied once for exactly this reason).
2. **Re-verify every anchor** against the current tree before editing. Watch
   **line-wrapping** — a phrase may span two lines and not match a single-line
   `grep`; read the region.
3. **Verify checkable claims** against the tree/code; keep "unverified /
   confirm-later" labels intact — never silently upgrade them.
4. **Hygiene precondition:** `findmnt -R /workspaces/teppan` must show the
   `TEPPAN_BUILD` volume mount before any `make` on the main checkout, or the
   [baked-root trap](../notes/realclean-recursive.md) aborts/re-poisons. If
   missing, **STOP and hand back**.
5. **Apply via the sanctioned flow:** `scripts/b3-fleet.sh provision` → edits in
   the worktree → `make test` gate (30 PASS / 0 FAIL) → `integrate` →
   `teardown`.
6. **Attribution:** dual `Assisted-By` lines — the **drafting** model *and* the
   **applying** model; never `Co-Authored-By` (see
   [git commit attribution](git-commit-attribution.md)).
7. **Cleanup:** after a successful `integrate`, `rm` the consumed `handoff/`
   artifacts (the draft's own cleanup section lists which).
8. **Push is user-authorized:** never `git push` without an explicit ask — even
   after `integrate`. Whether to push-after-integrate is itself an open workflow
   question (see [cloud environments](../notes/cloud-environments.md)).

## When the inner refutes a draft

If verification refutes a claim or an anchor is stale, **do not apply the bad
part.** Write `findings-<topic>.md` — a hand-back stating what is verified vs.
wrong, with the corrected mechanism. The outer revises the draft; the inner
re-applies the revised version. (Observed live: the baked-root `PKG1`
refutation, and the stale-`PKG4` catch.)

## Why not just let the outer commit?

The outer/host **cannot** use the sanctioned path: `scripts/b3-fleet.sh` is
container-gated (`require_container` dies unless `TEPPAN_IN_CONTAINER=1`), and
the accidental-HEAD-move guards **fail open on the host** — a host commit to
`master` has no rails and risks the shared-HEAD trap. So repo-content lands
**only** through the inner. See
[parallel development](../notes/parallel-agent-worktrees.md),
[dev container setup](../notes/devcontainer-setup.md).

See also: [Knowledge base index](../index.md),
[trace notes on removal](trace-notes-on-removal.md).
