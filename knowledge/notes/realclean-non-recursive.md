---
type: Known Issue
title: make realclean doesn't actually clean BUILD/DOC
description: RMDIR (Makefile:16) is a non-recursive rmdir with errors ignored, so realclean silently no-ops on BUILD/DOC, BUILD/DEP, BUILD/ZIP whenever they aren't empty — which they never are after a build.
tags: [known-issue, makefile, build]
timestamp: 2026-06-19
---

# `make realclean` doesn't actually clean `BUILD/DOC`

`Makefile:16` defines `RMDIR:= @-rmdir`. The leading `-` tells Make to
ignore the recipe's exit code, and `rmdir` itself only removes a directory
when it's already empty — it doesn't recurse. `realclean` (`Makefile:174-178`)
calls `$(RMDIR) $(__DEP__)`, `$(RMDIR) $(__DOC__)`, `$(RMDIR) $(__ZIP__)`
after running `clean`. Since `BUILD/DOC` always still contains per-domain
subdirectories/files at that point, the `rmdir` call fails — visibly, as
`make: [Makefile:177: realclean] Error 1 (ignored)` — and `realclean`
reports `[[[ DONE realclean ]]]` having removed nothing beyond what `clean`
already removed.

## Compounding factor: stale output from dropped domain/stem/lang registrations

`clean`'s own removal recipes (`clean-build`, `clean-navigation`, etc., see
`__MAKE_PAGE` in `generator.m4:173-246`) are generated dynamically per
`*.in.html` source during the `GENERATE_MAKEFILE_PHASE`, the same mechanism
that generates the build rules themselves (see
[Domains](../architecture/domains.md) on the lack of a central domain
registry). So once a `__WITH_DOMAIN`/`__WITH_STEM`/`__WITH_LANG` call is
removed from a source file, the matching `clean` rule for its *old* output
disappears too — there's nothing left in the current source tree to declare
"go remove this file." The old generated file becomes orphaned: neither
`make clean` nor `make realclean` will ever remove it.

Concretely hit this after dropping the `tekii.ar` `__WITH_DOMAIN` block from
`redirect.in.html` (now that `tekii-ar-default.in.html` gives `tekii.ar` real
content instead of a redirect): `BUILD/DOC/tekii.ar/redirect.html` and
`redirect.m4` survived `make clean`, `make realclean`, and a fresh
`make build` on top, because no current source declares a clean rule for
them anymore.

## Practical workaround

`rm -rf BUILD` is the only reliable way to get a truly clean generated tree.
Don't trust `make realclean` to remove stale per-domain output left over
from a source change that dropped a domain/stem/lang registration — verify
with a manual `rm -rf BUILD && make build` instead when in doubt.

See also: [Build & test commands](../build/commands.md),
[GNU Makefile code review guidelines](../code-review/makefile.md),
[Domains](../architecture/domains.md).
