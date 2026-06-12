# TEKii static site

A static website (multi-domain, multi-language) generated with GNU `m4` +
autoconf's `m4sugar`. There is no application server — everything is rendered
ahead of time into plain HTML/CSS/assets under `BUILD/DOC`.

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
- **Macro naming**: Custom macros must be prefixed (e.g., `MY_PROJECT_CHECK_FOO`) to avoid
  collisions with built-in or third-party macros.
- **Avoid `dnl` abuse**: `dnl` should only suppress newlines where necessary; flag usage
  that hides logic or makes code harder to follow.
- **No side effects in arguments**: Arguments passed to macros should be free of side
  effects since M4 may expand them multiple times.
- **Macro redefinition**: Warn on `define` overriding an existing macro without an explicit
  `undefine` or `pushdef`/`popdef` pair.
- **Prefer `pushdef`/`popdef`** over `define`/`undefine` for local/temporary macros to
  preserve the macro stack correctly.

### M4sugar (Autoconf context)

- **Use `AS_*` macros** for shell constructs (`AS_IF`, `AS_CASE`, `AS_ECHO`) instead of
  raw shell syntax inside `configure.ac`.
- **`AC_DEFUN` over `define`**: Always use `AC_DEFUN` (or `AC_DEFUN_ONCE`) for Autoconf
  macros — never raw `define`.
- **`AC_DEFUN_ONCE`** for macros that must not run twice (e.g., library checks).
  Flag duplicate `AC_DEFUN` definitions for the same macro name.
- **Dependency ordering**: Ensure `AC_REQUIRE` is used to declare inter-macro dependencies
  rather than relying on call order.
- **`m4_ifdef` / `m4_ifset`**: Use these for conditional logic at the M4 layer;
  flag use of raw `ifdef` which is shell-level.
- **`m4_define` vs `AC_SUBST`**: Variables meant for `Makefile` output must go through
  `AC_SUBST`; flag `m4_define` used where `AC_SUBST` is appropriate.
- **`m4_foreach` / `m4_map`**: Prefer these over manual recursive macros for iteration.
- **No raw shell in `AC_DEFUN` bodies** without wrapping in `AS_IF` or `AC_MSG_*` macros.

### Style & Maintainability

- Each macro should have a single, clear responsibility.
- Complex logic should be broken into smaller named macros with descriptive names.
- Include comments (`dnl #`) explaining non-obvious macro behavior.
- Avoid deeply nested macro calls (more than 3 levels) — suggest refactoring.

### Common Bugs to Flag

- Unquoted commas inside macro arguments (breaks argument splitting).
- Forgetting `m4_esyscmd_s` vs `m4_esyscmd` (trailing newline handling).
- Using `$1`, `$2` inside a macro body without quoting the whole body with `[...]`.
- Calling `AC_OUTPUT` before all `AC_SUBST` declarations are complete.

## Notes

- `.gitignore` excludes `BUILD`, `VENDOR`, `*venv*`, etc. — these are
  generated/vendored, not source.
