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

## The new domain structure (what I'm planning to do, this is input)

The new collection of sites will be composed of two related sites (`tekii.ar` and `tekii.us`); the first will mostly contain the legacy traceability business stuff and will still be i18n through the `en`/`es`/`br` locale subdirs. Actually, the Spanish branch of the site will most likely lose the `es` in favor of being the default lang.
The second one (`tekii.us`) will be the new and "international" part of the business, it will be English only (at least for now); there is some small possibility of some cross-site links with `tekii.ar` if necessary.
The rest of the domain properties are mostly redirects: `tekii.com.ar` (currently the main Spanish site) will become a redirect to `tekii.ar`'s Spanish branch, also `teky.com.ar`, `teky.ar`, `teki.com.ar` (this list needs to be revised and completed).
The `tekii.com` will redirect to `tekii.us`.
Also loosely related to this plan (but complex enough to deserve its own plan) is the need to convert the current hosting environment/mechanism (not documented yet) to support HTTPS; this has an impact on the domains plan.
A mechanism (I need a better synonym for this context) to update the DNS zones (currently managed in a mix of Google and Squarespace DNS, depending on the registrar) for each new domain would constitute a major improvement.
As you correctly state, the cross-domain linking will be addressed in the `NAVIGATION_PHASE`.

This is incomplete, more input is coming. I will consider the future of the current page stems.

## Finding: the current redirect mechanism doesn't support cross-domain redirects

`redirect.in.html` + `layout-redirect.html` is the only existing
redirect-only-domain mechanism, and as built today it can only redirect a
domain to *itself*, not to another domain. `layout-redirect.html:6` embeds
`<meta http-equiv="refresh" content="0;URL=http://__DOMAIN__">`, and
`__DOMAIN__` is always the domain the page is being generated for (set via
`-D __DOMAIN__=...` per `__WITH_DOMAIN` block in `redirect.in.html`). So the
generated `tekii.ar/redirect.html` today redirects to `http://tekii.ar`
(itself) and `tekii.us/redirect.html` to `http://tekii.us` (itself) — these
look like placeholders, not working cross-domain redirects.

None of the redirects this plan calls for (`tekii.com.ar` → `tekii.ar`,
`teky.com.ar`/`teky.ar`/`teki.com.ar` → `tekii.ar`, `tekii.com` →
`tekii.us`) can be expressed with the mechanism as it exists today — it
needs a way to specify a redirect *target* domain that's distinct from the
page's own `__DOMAIN__`. This is a real gap, not just "add more
`__WITH_DOMAIN` blocks following the existing pattern."

**Scoping decision:** fixing this is out of scope for this plan. Like
cross-domain linking/navigation above, it will be addressed as part of the
`NAVIGATION_PHASE` work — that's where domain-to-domain relationships in
general are meant to live, so the redirect-target mechanism belongs there
too rather than as a one-off fix here.

**Alternative avenue:** a DNS-level redirect (e.g. registrar/DNS-provider
URL forwarding, or a CNAME/ALIAS plus redirect rule at the DNS/hosting
layer) could replace some or all of this app-level mechanism entirely,
*if* this project ever gains DNS-update capabilities (see the
DNS-zone-update mechanism mentioned above, currently split across Google and
Squarespace DNS). Worth exploring once that capability exists, rather than
building out a more elaborate `__WITH_DOMAIN`-based cross-domain redirect
mechanism that DNS-level redirects might make unnecessary.

## Verification (once target state is filled in and implemented)

- `make build` should produce the new/changed domain(s) under
  `BUILD/DOC/<domain>/` with the expected redirect vs. full-locale
  structure.
- `make test` should still pass (`generator_test.m4` / `__ASSERT_EQ`).
- Use the `build-preview` skill to serve `BUILD/DOC` and manually check the
  new/changed domain's pages in a browser.
- Once implemented, update `knowledge/architecture/domains.md` to describe
  the new shipped state (do not edit it as part of this proposal).
