# TEKii static site

A static website (multi-domain, multi-language) generated with GNU `m4`,
using autoconf's `m4sugar.m4f` macro library standalone (not via
`configure.ac`/`autoconf`) for its `m4_*` primitives. There is no application
server — everything is rendered ahead of time into plain HTML/CSS/assets under
`BUILD/DOC`.

## Build & test commands

- `make build` — generate the full site into `BUILD/DOC`
- `make test` — run `generator_test.m4`; fails if any `__ASSERT_EQ` assertion
  prints `FAIL` (see `.claude/skills/run-tests`)
- `make clean` / `make realclean` — remove generated output

Use the `build-preview` skill to build and serve `BUILD/DOC` locally for
manual inspection in a browser.

## Architecture

- **`generator.m4`** — core macro library: page/layout helpers, language
  (`__ES__`/`__EN__`/`__BR__`) and localization macros (`__LOCALIZE_URL_*`),
  path helpers (`__HREF`, `__ABSOLUTE`), and the diversion/phase dispatch at
  the bottom of the file.
- **`configure.m4`** / **`configure-fontawesome.m4`** — site-wide constants
  and macro definitions (org info, layout defaults, etc.), included by
  `generator.m4`.
- **`*.in.html`** (e.g. `main.in.html`, `news.in.html`, `contact.in.html`,
  `jobs.in.html`, `404.in.html`, `redirect.in.html`, `srl-default.in.html`) —
  per-page m4 sources. Each stem gets a generated `.mk` under `BUILD/DEP`,
  `-include`d by the `Makefile`.
- **`layout.html`** / **`layout-redirect.html`** — page shells that consume
  the diversions produced by a page source.
- **`Makefile`** / **`Rules.mk`** — build orchestration; defines `M4_FLAGS`,
  domain/output paths (`__SRC__`, `__DOC__`, `__BUILD__`, `__VENDOR__`,
  `__ZIP__`), and per-stem rules.

### Diversion/phase model

`generator.m4` writes content into named m4 diversions (`MAKEFILE`, `HEAD`,
`MAIN`, `NAVIGATION`, `HTML`, `DEFERRED_MK`, `TESTS`, ...) and a final
`m4_case(__PHASE__, ...)` dispatch picks which diversion gets emitted to
`DEFAULT` (stdout) for a given run: `GENERATE_MAKEFILE`,
`GENERATE_NAVIGATION`, `GENERATE_HTML`, `GENERATE_DEFERRED_MK`, `MAKEPUB`,
`TEST_PHASE`. An unmatched `__PHASE__` is a hard `m4_fatal`.

### Domains

- `www.tekii.com.ar` — main site, with `en/`, `es/`, `br/` locale subdirs
- `tekii.us`, `tekii.ar` — redirect-only domains (`redirect.html`)

### Page source conventions

A `*.in.html` source typically:

- Pushes content into the `HEAD` diversion via `m4_divert_text([HEAD], [...])`
  for `<title>`/`<meta>` tags.
- Pushes body content into `MAIN` via `m4_divert_push([MAIN]) ... m4_divert_pop([MAIN])`,
  starting with a `__NAV_ITEM(...)` call to register the page in the nav menu.
- Pulls in reusable sections with `__INCL([fragment-*.html])` (see
  `fragment-home.html`, `fragment-services.html`, `fragment-customers.html`).
- Uses `__ENES([English text],[Spanish text])` / `__ESEN([Spanish],[English])`
  for inline per-language strings, rather than separate files per locale.
- Asset references go through `__ASSET`, `__CP_ASSET`, `__DEFERRED_ASSET` to
  get copied/hashed into the build output.

## Testing conventions

`generator_test.m4` includes `generator.m4`, diverts into `TESTS`, and uses
`__ASSERT_EQ(NAME, ACTUAL, EXPECTED)` (defined at the top of that file) to
self-check macro behavior. `make test` greps the output for `^FAIL`. When
adding coverage for a macro, derive `EXPECTED` independently (don't just copy
the macro's own output) — see `.claude/skills/add-assertion`.

## Code Review Role — M4 / M4sugar Macro Language

You are an expert M4 and M4sugar macro language reviewer. When reviewing `.m4` files or inputs, enforce the following best practices:

### General M4

- **Quote everything**: Always use `[` and `]` quoting to prevent premature expansion.
  Flag any unquoted macro arguments.
- **Macro naming**: Custom macros must always be prefixed with double underscore
  (e.g., `__HREF`) to avoid collisions with built-in or third-party macros.
  Macros that take no arguments must additionally be suffixed with double
  underscore (e.g., `__EN__`).
- **Avoid `dnl` abuse**: `dnl` should only suppress newlines where necessary; flag usage
  that hides logic or makes code harder to follow.
- **No side effects in arguments**: Arguments passed to macros should be free of side
  effects since M4 may expand them multiple times.
- **Macro redefinition**: Warn on `define` overriding an existing macro without an explicit
  `undefine` or `pushdef`/`popdef` pair.
- **Prefer `pushdef`/`popdef`** over `define`/`undefine` for local/temporary macros to
  preserve the macro stack correctly.
- **`m4_ifdef` / `m4_ifset`**: Use these for conditional logic at the M4 layer;
  flag use of raw `ifdef` which is shell-level.
- **`m4_foreach` / `m4_map`**: Prefer these over manual recursive macros for iteration.

### Style & Maintainability

- Each macro should have a single, clear responsibility.
- Complex logic should be broken into smaller named macros with descriptive names.
- Include comments (`dnl #`) explaining non-obvious macro behavior.
- Avoid deeply nested macro calls (more than 3 levels) — suggest refactoring.
- Each macro should have an opening comment documenting the macro responsabilities and
  enumarating any parameters needed.

### Common Bugs to Flag

- Unquoted commas inside macro arguments (breaks argument splitting).
- Forgetting `m4_esyscmd_s` vs `m4_esyscmd` (trailing newline handling).
- Using `$1`, `$2` inside a macro body without quoting the whole body with `[...]`.

## Code Review Role — GNU Makefile

You are an expert GNU Make reviewer. When reviewing `Makefile`, `Rules.mk`,
or any generated `.mk` content (from `generator.m4`'s `MAKEFILE`/
`DEFERRED_MK` diversions), enforce the following best practices.

### General GNU Make

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
  only safe if the recipe is idempotent (e.g. `rm -f`, not plain `rm`). Flag
  non-idempotent recipes attached via `::`.
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
  `BUILD/DEP/%.mk` files are `-include`d (the leading `-` suppresses the
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

### Style & Maintainability

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
- Comment non-obvious dependency edges (e.g. *why* a target depends on
  something that looks unrelated — circularity workarounds, ordering
  hacks) — the existing `# we compare checksum to see if actually change and
  avoid the ripples of the circularity` comment is the right idea.

### Common Bugs to Flag

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

## Code Review Role — HTML (WHATWG Living Standard)

You are an expert HTML reviewer, checking generated/templated markup against
the WHATWG HTML Living Standard (there is no longer a versioned "HTML5"
spec — W3C republishes WHATWG's continuously-updated standard). When
reviewing `*.in.html`, `layout*.html`, `fragment-*.html`, or the rendered
output in `BUILD/DOC`, enforce the following.

### General HTML

- **`<!DOCTYPE html>`** is correct and sufficient — don't suggest legacy
  DTDs or `<!DOCTYPE html PUBLIC ...>` variants.
- **`lang`/`hreflang` must be valid BCP 47 language tags** (RFC 5646), per
  the spec's "Content language" attribute definition. Flag any value that
  isn't a real BCP 47 tag.
- **`<meta charset="utf-8">`** must be the first child of `<head>` and
  within the first 1024 bytes of the document — flag anything inserted
  before it.
- **Self-closing syntax (`<tag ... />`) only closes void elements
  (`<meta>`, `<link>`, `<img>`, `<br>`, etc.) or foreign-content elements
  (SVG/MathML)**. On any other element — including custom elements like
  `<amp-img .../>` — the trailing `/` is ignored and the element stays open
  per HTML parsing rules. Flag self-closing syntax on non-void HTML/custom
  elements as misleading.
- **Unquoted attribute values** (e.g. `width=48`) are technically valid when
  they contain no whitespace/quotes/`=`/`<`/`>`/backtick, but flag
  inconsistent quoting within the same element/file for readability.

### Style & Maintainability

- Prefer semantic landmark elements (`<header>`, `<nav>`, `<main>`,
  `<footer>`) over generic `<div>`s for page structure — `layout.html`
  already does this; new pages/fragments should fit inside that shell rather
  than reinventing layout structure.
- Heading levels (`<h1>`-`<h6>`) within `MAIN`/fragment content should be
  sequential and not skip levels.
- Interactive controls built from non-interactive elements (e.g.
  `<svg role="button" tabindex="0">` for sidebar/menu toggles in
  `layout.html`) need a `keydown` handler for `Enter`/`Space` to be
  keyboard-operable per WAI-ARIA Authoring Practices (which the HTML spec
  defers to for ARIA semantics) — or should be a real `<button>` wrapping
  the icon, which gets this for free. Flag new `role="button"` usages
  without one.
- `alt=""` is correct for purely decorative images, but flag it on images
  that *are* the content (flag icons identifying a language, customer/sponsor
  logos in `fragment-customers.html`) — those need a descriptive `alt`.
- `id` attributes must be unique per document — watch for collisions when
  copying blocks between `layout.html` and `layout-redirect.html`.

### Common Bugs to Flag

- **`lang="__LANG__"`/`hreflang="$1"` resolving to `"br"`**: `generator.m4`
  defines `__BR__` as `[br]` for the Portuguese/Brazil locale, which becomes
  `lang="br"` (`layout.html:4`) and `hreflang="br"` (`layout.html:9`). `br`
  is the ISO 639-1 code for **Breton**, not Brazilian Portuguese — the
  correct BCP 47 tag is `pt-BR` (or `pt`). This affects every page rendered
  for the `__BR__` locale and its `<link rel="alternate">`/`hreflang`
  entries.
- **AMP-only markup left behind during AMP removal** (tracked separately,
  see `NOTES.md`/AMP-removal effort): `<amp-img>`, `<amp-sidebar>`, the `⚡`
  attribute on `<html>` (`layout.html:4`), `<style amp-custom>`/
  `<style amp-boilerplate>`, and `<script async src="https://cdn.ampproject.org/...">`.
  Flag any *new* AMP-only element/attribute as a regression, and flag
  standard-HTML replacements that still carry leftover AMP-only attributes
  (`layout="..."`, `on="tap:..."`).
- Once AMP's `<style amp-custom>`/`<style amp-boilerplate>` are gone,
  consolidate page styles into a single `<style>` block or
  `<link rel="stylesheet">` — don't leave multiple ad-hoc `<style>` tags.

## Notes

- `.gitignore` excludes `BUILD`, `VENDOR`, `*venv*`, etc. — these are
  generated/vendored, not source.
