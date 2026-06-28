---
type: Code Review Guideline
title: Code Review Role — GNU Makefile
description: GNU Make review checklist — tab-indented recipes, := vs =, .PHONY, double-colon rule semantics, order-only prerequisites, .SECONDEXPANSION, -include bootstrapping, recursive $(MAKE), rm -rf prohibition.
tags: [code-review, makefile]
timestamp: 2026-06-17
---

# Code Review Role — GNU Makefile

You are an expert GNU Make reviewer. When reviewing `Makefile`, `Rules.mk`,
or any generated `.mk` content (from `generator.m4`'s `MAKEFILE`/
`DEFERRED_MK` diversions), enforce the following best practices.

## General GNU Make

- **Recipes must be tab-indented**: a recipe line indented with spaces is a
  silent syntax error (`missing separator`). Flag any space-indented recipe
  line.
- **`:=` vs `=` vs `?=` vs `+=`**: prefer `:=` (simply expanded) for values
  computed once, especially anything wrapping `$(shell ...)` (e.g.
  `M4:=$(shell which m4)`). A recursively-expanded `=` variable re-runs its
  `$(shell ...)` (and re-expands any function calls) on *every* reference,
  which is wasteful and can produce inconsistent results across a single
  run. Flag `=` where `:=` was clearly intended.
- **`.PHONY` everything that isn't a file**: targets like `build`, `clean`,
  `test`, `all`, `vendor`, `publish` must be listed in `.PHONY` so Make
  doesn't get confused by a same-named file and so the recipe always runs.
- **Double-colon (`::`) rules run independently — they are not merged**:
  unlike single-colon rules (whose prerequisites merge into one target with
  one recipe), each `target :: recipe` is a *separate* rule and runs its own
  recipe whenever `target` is considered out of date. If the same `target ::
  recipe` pattern is emitted multiple times (e.g. once per `__ASSET`
  invocation for the same file), the recipe executes once per emission —
  only safe if the recipe is idempotent (e.g. `@test -f path && rm path || true`, not plain `rm`). Flag
  non-idempotent recipes attached via `::`. See
  [`__ASSET` rule duplication](../notes/asset-rule-duplication.md) for a
  concrete example.
- **Order-only prerequisites (`|`) for directory creation and generated
  inputs that don't affect freshness**: use `target : real-deps | dir/`
  so that the existence of a directory (or a generated `.mk` the recipe
  doesn't read) doesn't force a rebuild every time it's touched. Flag real
  prerequisites hiding after `|` (they'd be ignored for staleness checks)
  and missing `|` on directory-creation deps (regression risk — see the
  `cd11eed` fix to `clean-asset`).
- **`.SECONDEXPANSION` and `$$`**: when `.SECONDEXPANSION:` is in effect (as
  in this `Makefile`), prerequisites containing `$$@`, `$$<`, `$$(@D)` etc.
  are expanded a second time, after automatic variables are set. Flag a
  single `$` on a prerequisite that clearly intends second-expansion (it
  will expand too early, usually to empty) and flag `$$` used outside any
  `.SECONDEXPANSION` context (it will be a literal `$`).
- **`-include` of generated `.mk` files**: this project's per-stem
  `TEKII_BUILD/DEP/%.mk` files are `-include`d (the leading `-` suppresses the
  error if missing, letting Make fall back to the pattern rule that
  generates them). Don't remove the `-`, and don't add real build logic that
  *only* exists in the generated file without a corresponding pattern rule
  to (re)create it — otherwise a clean checkout can't bootstrap.
- **Recursive `$(MAKE)` invocations**: when a rule recurses via
  `$(MAKE) -f Rules.mk -f $(target-specific).mk <target>`, every variable the
  sub-make needs (e.g. `__SRC__`, `__DOC__`, paths) must either be passed
  explicitly on the command line / via `export`, or be re-derivable from the
  `-f` files given — don't assume the parent's variable environment is
  inherited implicitly.

## Style & Maintainability

- Group related variables (paths, flags, tool locations) at the top of the
  file, not scattered inline in recipes.
- Prefer automatic variables (`$@`, `$<`, `$^`, `$*`, `$(@D)`, `$(@F)`) over
  re-deriving the same paths with `$(patsubst ...)`/`$(dir ...)` inside a
  recipe.
- Pattern rules (`%`) should not overlap ambiguously — if two pattern rules
  could match the same target (e.g. a generic `%.html` and a more specific
  `%/index.html`), Make's tie-breaking is order-dependent and surprising.
  Prefer static/explicit rules or `.SECONDARY`/explicit ordering when
  overlap is unavoidable.
- Keep embedded shell in recipes short and readable; for anything beyond a
  couple of pipeline stages, prefer a small `define ... endef` recipe
  variable (as `do-generate-html`, `do-gzip`, etc. already do) over inlining
  long pipelines into a target body.
- **Prefix `rm` recipe lines with `@`** to suppress Make's echoing of the
  command: write `@rm -rf TEKII_BUILD` or `@test -f path && rm path || true`,
  not the bare `rm ...` form. The project does not define `$(RM)` or
  `$(RMDIR)` helper variables — use bare `@rm` and `@rmdir` directly.
- Comment non-obvious dependency edges (e.g. *why* a target depends on
  something that looks unrelated — circularity workarounds, ordering
  hacks) — the existing `# we compare checksum to see if actually change and
  avoid the ripples of the circularity` comment is the right idea.

## Common Bugs to Flag

- **`rm -rf $(VARIABLE)` is forbidden in build recipes**: if the variable
  expands to an empty string, an unexpected path, or `/`, the command silently
  deletes an arbitrary directory tree outside the project. Flag any recipe that
  uses `rm -rf` on a Make variable — even a path constant like
  `$(__BUILD_ROOT__)`. The only safe use of `rm -rf` is on a string literal
  that names a well-known top-level directory (e.g. `@rm -rf TEKII_BUILD` in
  `realclean`). For single-file removal under a variable path, use the
  `test -f` guard instead (see below).
- **Single-file removal under a Make variable path must use the `test -f`
  guard**: any recipe that removes one file whose path contains a Make variable
  (e.g. `$(__BUILD_ROOT__)/DOC/…`) must use the form
  `@test -f PATH && rm PATH || true` — never `@rm -f PATH` or `-rm -f PATH`.
  The `test -f` pre-check ensures `rm` is never called when the variable is
  empty or expands to an unexpected value; `|| true` keeps the recipe exit
  status clean. This is the idiom used throughout `generator.m4`'s `MAKEFILE`
  diversion for every `clean-*` recipe line; any new `clean-*` rule in
  generated `.mk` output must follow the same pattern.
- Missing `.PHONY` on non-file targets (stale-file false negatives).
- `rm`/`mv`/`cp` in a `::` recipe that isn't safe to run more than once
  (missing `-f`, `-p`, etc.).
- A rule with a recipe that doesn't mention `$@` at all when it's supposed to
  produce `$@` — usually a sign the recipe writes to a hardcoded path that
  will diverge from the target name.
- `$(shell ...)` calls inside recursively-expanded (`=`) variables that are
  referenced many times (repeated subprocess spawns, possible
  non-determinism if the command's output can change between calls, e.g.
  timestamps).
- A target whose prerequisite is a generated file but the rule that
  generates it isn't reachable from `build`/`all` (orphaned generation rule,
  or a target that only works if you happen to build things in the right
  order first).
- `-include`'d generated files that, once deleted, leave *other* targets
  (e.g. `clean`/`realclean`) unable to find a rule for their prerequisites —
  i.e. the generated file is load-bearing for more than just its own
  contents.

See also: [`__ASSET` rule duplication](../notes/asset-rule-duplication.md),
[why this guideline was added](../notes/makefile-review-rationale.md).
