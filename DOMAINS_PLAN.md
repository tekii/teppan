# Domains Plan

Branch: `domains-plan`. Scope: add new domains to the site and change which
existing domains serve full multi-locale content vs. which are
redirect-only, while preserving the existing per-page domain-registration
mechanism (no central domain registry to touch).

## Current domain inventory (today, on `master`)

- `www.tekii.com.ar` — full content, `en`/`es`/`br` locale subdirs. Wired in
  `srl-default.in.html` via `__WITH_DOMAIN([www.tekii.com.ar], [...])`
  wrapping `__WITH_STEM([index], [...])` + `__WITH_LANG(...)` +
  `__MAKE_PAGE([__LOCALIZE_URL_NULL | __LOCALIZE_URL_PATH])` per language
  (`es` uses `__LOCALIZE_URL_NULL`, `en`/`br` use `__LOCALIZE_URL_PATH`).
  Other content stems (`contact.in.html`, `news.in.html`, `jobs.in.html`,
  `404.in.html`) also target this domain.
- `tekii.ar` — redirect-only (ES). Wired in `redirect.in.html` via
  `__WITH_DOMAIN([tekii.ar], [__WITH_LANG([__ES__], [__MAKE_PAGE([__LOCALIZE_URL_NULL])])])`,
  using `layout-redirect.html` instead of `layout.html`.
- `tekii.us` — redirect-only (EN). Same pattern as `tekii.ar`, in the same
  `redirect.in.html`, with `__WITH_LANG([__EN__], ...)`.

## Mechanism (what to preserve)

There is **no central domain list** in `Makefile`/`Rules.mk`. Domains are
registered dynamically wherever a `*.in.html` source calls
`__WITH_DOMAIN([domain], [...])` (`generator.m4:133-140` —
`m4_set_add([__ROOTS__], __DOC__/__DOMAIN__)` and similar `m4_set_add`s for
build targets/alternates). `publish`/`gsutil` rules in `Makefile` are
generic and not domain-specific. This means:

- **Add a redirect-only domain** → add a new `__WITH_DOMAIN([new-domain],
  [__WITH_LANG([__XX__], [__MAKE_PAGE([__LOCALIZE_URL_NULL])])])` block to
  `redirect.in.html` (or a new redirect source, if it needs different target
  content than the existing two).
- **Add a full-content domain** → new `__WITH_DOMAIN([new-domain], [...])`
  wrapping real `__WITH_LANG`/`__MAKE_PAGE` content, following the
  `srl-default.in.html` pattern — either in a new `*.in.html` stem or an
  existing one, depending on whether it shares pages with
  `www.tekii.com.ar`.
- **Convert a domain between redirect-only ↔ full-content** → move its
  `__WITH_DOMAIN` block out of `redirect.in.html` into a real content page
  source (or vice versa), and switch `__SRC__/layout.html` ↔
  `__SRC__/layout-redirect.html` accordingly.
- No `Makefile`/`Rules.mk`/`generator.m4` changes are expected for adding or
  recategorizing domains — only `*.in.html` edits. Flag this explicitly so a
  reviewer doesn't go looking for a domain list to update.

## Target state — open questions (need input)

This is where the plan is incomplete and needs the actual target domain
list and category changes:

- Which new domain(s) are being added, and are they full-content or
  redirect-only?
- Which existing domain(s), if any, change category (e.g. does
  `tekii.ar`/`tekii.us` become full-content instead of redirect-only, or
  does `www.tekii.com.ar` shed a locale to a dedicated domain)?
- For any new full-content domain: does it reuse existing page stems
  (`srl-default.in.html`, `contact.in.html`, etc.) and `fragment-*.html`
  content, or does it need its own?
- Cross-domain linking/navigation: out of scope here per the same
  reasoning as the CSS plan — covered separately whenever the
  `NAVIGATION_PHASE` internals are worked on, not as part of this plan.

## Verification (once target state is filled in and implemented)

- `make build` should produce the new/changed domain(s) under
  `BUILD/DOC/<domain>/` with the expected redirect vs. full-locale
  structure.
- `make test` should still pass (`generator_test.m4` / `__ASSERT_EQ`).
- Use the `build-preview` skill to serve `BUILD/DOC` and manually check the
  new/changed domain's pages in a browser.
- Once implemented, update `knowledge/architecture/domains.md` to describe
  the new shipped state (do not edit it as part of this proposal).
