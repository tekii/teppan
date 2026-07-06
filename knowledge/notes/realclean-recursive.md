---
type: Design Note
title: make realclean — recursive TEPPAN_BUILD deletion
description: realclean uses rm -rf on the literal, project-namespaced TEPPAN_BUILD directory name to wipe the build tree, safely handling stale output from dropped domain/stem/lang registrations that clean cannot remove.
tags: [makefile, build]
timestamp: 2026-06-30
---

# `make realclean` — recursive `TEPPAN_BUILD` deletion

`realclean` runs `clean` first (removing all files whose rules are still
registered in the current source tree), then executes `@rm -rf TEPPAN_BUILD`
to wipe the build tree entirely: `TEPPAN_BUILD/DOC`, `TEPPAN_BUILD/NAV`,
`TEPPAN_BUILD/DEP`, `TEPPAN_BUILD/ZIP`, and `TEPPAN_BUILD/.mode` (the build-mode
stamp — see the "BUILD MODE STAMP" block in `Makefile`). `build` and
`make preview` (`make PREVIEW=1`) write into this single shared root; there
is no longer a separate `TEKII_PREVIEW` tree.

## Why `rm -rf` and not `rmdir`

`clean`'s removal recipes (`clean-build`, `clean-navigation`, etc.) are
generated dynamically per `*.in.html` source by the `__MAKE_PAGE` macro in
`generator.m4`. Once a `__WITH_DOMAIN`/`__WITH_STEM`/
`__WITH_LANG` call is removed from a source file, the matching `clean`
rule for its old output disappears too — there is nothing left in the
current source tree to declare "go remove this file." Those orphaned
outputs survive `make clean`. A non-recursive `rmdir` would also fail
because `TEPPAN_BUILD/DOC` is never empty after a build. Only a recursive
delete is reliable.

## Why `TEPPAN_BUILD` (literal) and not `$(__BUILD_ROOT__)` (variable)

The [GNU Makefile code review guidelines](../code-review/makefile.md)
forbid `rm -rf $(VARIABLE)` in build recipes — if a variable expands to
an empty string or an unexpected path, the command silently deletes an
arbitrary directory tree. Using the project-namespaced literal
`TEPPAN_BUILD` sidesteps this entirely: no variable expansion, and the
name is unique enough that `rm -rf TEPPAN_BUILD` is a no-op if Make is
accidentally invoked from a directory where `TEPPAN_BUILD/` doesn't exist.

## The baked-root trap — stale `.mk` files can poison `realclean` itself

The generated per-stem `TEPPAN_BUILD/DEP/*.mk` files bake **absolute** source
paths (`$(PWD)` plus m4 `realpath`, captured at generation time). Whenever
`make` runs against a `TEPPAN_BUILD` whose `.mk` files were generated under a
**different absolute source root**, those baked prerequisites dangle. Two
ways to get there — one historical, one live:

- **The checkout moved or was renamed** (e.g. the 2026-07-04 `www` → `teppan`
  repo rename): the sources' mtimes never changed, so the stale `.mk` files
  look up to date and are `-include`d as-is — the same mtime-blindness the
  "BUILD MODE STAMP" block in `Makefile` fixes for `build`↔`preview`, but for
  the tree's *location* rather than its mode.
- **Two environments with different roots share one `TEPPAN_BUILD`**: the
  host (`/home/<user>/teppan`) and the container (`/workspaces/teppan`) share
  the bind-mounted tree whenever the container-private `TEPPAN_BUILD` volume
  declared in `devcontainer.json` is **not actually mounted** in the running
  container (see the "declared ≠ mounted" caveat in
  [dev container setup](devcontainer-setup.md)). Then every `make` on one
  side re-bakes that side's root into `DEP/*.mk` and traps the other —
  cross-poisoning, observed live in *both* directions on 2026-07-05.

The failure is worse than a broken `build`: GNU Make reads and remakes all
`-include`d makefiles **before running any goal**, so one dangling
prerequisite (`No rule to make target '/other/root/<page>.in.html'`) aborts
**every** invocation — `build`, `test`, `clean`, and `realclean` alike. The
recovery target is poisoned by exactly the state it exists to clear.

**Recovery:** delete the build tree by hand — `rm -rf TEPPAN_BUILD` from the
checkout root (the same well-known literal `realclean` itself uses; never a
variable) — then rebuild. In the shared-tree case this is only a **stopgap**:
the next `make` from the other side re-poisons it (even `make test` — the
makefile-remake phase regenerates `DEP/*.mk` with the invoking side's root).
The real fix is restoring the volume isolation (rebuild the container so the
declared volume actually mounts), or strict temporal separation until then.

**Possible hardening (unimplemented; deferred 2026-07-05, user decision —
inner-lane task when picked up):** stamp the generation-time source root the
way build/preview mode is stamped, and force `DEP` regeneration when `$(PWD)`
no longer matches the stamp — same blindness, same cure. Design analysis
(outer session, 2026-07-05):

- **Implement as a parse-time guard at the top of `Makefile`, *before* the
  `-include`** — e.g. `ifneq ($(strip $(file <TEPPAN_BUILD/.source-root)),$(PWD))`
  → `$(warning source root changed -- dropping stale generated makefiles)` +
  `$(shell rm -rf TEPPAN_BUILD/DEP)` + rewrite the stamp. Deleting the
  poisoned files before Make reads them sidesteps the remake phase entirely.
- **Not as a `.source-root` prerequisite on `DEP/%.mk` rules** (the
  mode-stamp style): GNU Make loads all `-include`d makefiles *before* its
  makefile-remake phase, so stale in-memory rules can still abort before a
  stamp-triggered regeneration wins — the observed failure fired in exactly
  that phase.
- **`rm -rf` on the literal path only** (`TEPPAN_BUILD/DEP`), never a
  variable — per this repo's own
  [Makefile review guideline](../code-review/makefile.md).
- **Keep the `$(warning ...)`:** in a shared-tree scenario the guard would
  otherwise mask a broken volume isolation as silent alternating full
  rebuilds; the loud line preserves the symptom.
- **Testing is fully in-container:** worktrees provide distinct source roots
  (share one `TEPPAN_BUILD` between two, or `mv` a worktree) — no host
  involvement. Gate with a manual `make build`, not just `make test` (it's a
  build-input change).

Note the guard would also soften the shared-tree case from a hard abort into
silently alternating full rebuilds; better, but the volume isolation remains
the intended design.

See also: [Build & test commands](../build/commands.md),
[GNU Makefile code review guidelines](../code-review/makefile.md),
[Domains](../architecture/domains.md).
