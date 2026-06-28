---
type: Design Note
title: make realclean — recursive TEKII_BUILD deletion
description: realclean uses rm -rf on the literal, project-namespaced TEKII_BUILD and TEKII_PREVIEW directory names to wipe both build trees, safely handling stale output from dropped domain/stem/lang registrations that clean cannot remove.
tags: [makefile, build]
timestamp: 2026-06-28
---

# `make realclean` — recursive `TEKII_BUILD` deletion

`realclean` runs `clean` first (removing all files whose rules are still
registered in the current source tree), then executes `@rm -rf TEKII_BUILD`
and `@rm -rf TEKII_PREVIEW` to wipe both build trees entirely:
`TEKII_BUILD/DOC`, `TEKII_BUILD/NAV`, `TEKII_BUILD/DEP`, `TEKII_BUILD/ZIP`,
and the parallel `TEKII_PREVIEW` tree produced by `make PREVIEW=1`.

## Why `rm -rf` and not `rmdir`

`clean`'s removal recipes (`clean-build`, `clean-navigation`, etc.) are
generated dynamically per `*.in.html` source by the `__MAKE_PAGE` macro in
`generator.m4`. Once a `__WITH_DOMAIN`/`__WITH_STEM`/
`__WITH_LANG` call is removed from a source file, the matching `clean`
rule for its old output disappears too — there is nothing left in the
current source tree to declare "go remove this file." Those orphaned
outputs survive `make clean`. A non-recursive `rmdir` would also fail
because `TEKII_BUILD/DOC` is never empty after a build. Only a recursive
delete is reliable.

## Why `TEKII_BUILD` (literal) and not `$(__BUILD_ROOT__)` (variable)

The [GNU Makefile code review guidelines](../code-review/makefile.md)
forbid `rm -rf $(VARIABLE)` in build recipes — if a variable expands to
an empty string or an unexpected path, the command silently deletes an
arbitrary directory tree. Using the project-namespaced literal
`TEKII_BUILD` sidesteps this entirely: no variable expansion, and the
name is unique enough that `rm -rf TEKII_BUILD` is a no-op if Make is
accidentally invoked from a directory where `TEKII_BUILD/` doesn't exist.

See also: [Build & test commands](../build/commands.md),
[GNU Makefile code review guidelines](../code-review/makefile.md),
[Domains](../architecture/domains.md).
