# New `Preview build` functionality proposal

I plan to implement a new preview build seperate from the actual "to be published..." build, with his own `preview` or `preview-build` target on the makefile and posible a separate SKILL to invoque it and a `PREVIEW` directory under the project root at the same level of the current `BUILD`. The objective is to generate all files in all domain with the links all relative to the PREVIEW root (the equivalent of the current BUILD directory) instead of the domain subdirectory or also could be absolute paths in the current filesystem, this hopefully allows cross domain links in the preview using the `file://xxx` or `file:///xxx` schema without the need to spawn multiples local preview http servers per domain an also eliminate the need of some mock domain resolver tweek (hardcoding the domains in the `/etc/hosts` or something similar).

## Preliminary analysis

### The two stated motivations above are already solved

`.claude/skills/build-preview/SKILL.md` already serves every domain from a
single `python3 -m http.server --directory BUILD/DOC` process, with each
domain as a subpath (`BUILD/DOC/<domain>/...`). No per-domain servers, no
`/etc/hosts` tweak needed today.

### The actual unsolved problem: two places hardcode production scheme+host

- `__ABSOLUTE` (`generator.m4:74`):
  `m4_define([__ABSOLUTE],[http://__HREF([$1],__DOC__)])dnl`
  Computes a path relative to `__DOC__`, which strips down to
  `<domain>/<rest>` (e.g. `www.tekii.com.ar/en/index.html` — verified with
  `realpath --relative-to`), then glues a literal `http://` onto it. Used
  only for `<link rel="alternate" hreflang>` / `<link rel="canonical">` in
  `layout.html:9,11`.
- The redirect template (`layout-redirect.html:6`) hardcodes
  `<meta http-equiv="refresh" content="0;URL=http://__DOMAIN__">` directly,
  not even routed through `__HREF`/`__ABSOLUTE` — a *second*, independent
  hardcoded-scheme spot that should be unified to call `__ABSOLUTE` instead,
  so only one macro needs preview-mode awareness. (Separately, and
  unrelated to preview: the currently rendered output redirects `tekii.us`
  to itself — `URL=http://tekii.us` — rather than to the real main site, so
  this looks unfinished regardless of the preview work.)

Everything else (nav, images, fonts, favicons) is already pure relative
paths via `__HREF`, which work unchanged under `file://` or any server.

### No currently visible/clickable cross-domain link exists

The `__ABSOLUTE` URLs only ever land in non-visible `<head>` metadata; the
redirect domains bounce via meta-refresh, not a clickable link. A human
browsing the preview today would never actually click a cross-domain link.
The feature's value is latent — useful for verifying hreflang/canonical
correctness, or for a *future* visible cross-domain nav (e.g. a
country/region switcher) — not a fix for an existing browsing pain.

### Why the `http://` (not the path math) is what breaks local preview nav

`__HREF`'s path computation is scheme-agnostic and already correct for
cross-domain targets: from `www.tekii.com.ar/en/index.html` to
`tekii.ar/index.html`, plain `__HREF($1)` (default, relative to `__TDIR__`,
no `__DOC__` override) computes `../../tekii.ar/index.html` — verified with
`realpath`. That works under `file://` or `http://` identically, because it
carries no scheme/authority.

It's `__ABSOLUTE` gluing a literal `http://` onto the `__DOC__`-relative
path that defeats local navigation — once an `href` carries an explicit
scheme+authority, the browser resolves it as a fully-qualified URL via real
DNS, ignoring the local context entirely. This is true today even under the
existing local `http.server` preview, not just under `file://`: clicking a
hreflang/canonical link already escapes to the live production site instead
of looping back to `localhost:8080/<domain>/...`.

### Design rule: `__HREF` is same-origin only; `__ABSOLUTE` is the sole cross-domain chokepoint

Relative references (everything `__HREF` produces) resolve per RFC 3986
against the *current document's own origin* — there is no way for a
relative path to specify a different scheme/host. In production each domain
ships to its own GCS bucket/origin (`Makefile:154-157`, `do-publish` →
`gs://$@`), so a relative path that happens to spell another domain's name
as a path segment (`../../tekii.ar/index.html`) would just 404 against the
*current* domain's own bucket — it only ever "means" cross-domain inside the
artificially colocated build/preview tree.

Rule going forward: **`__HREF` (bare) is for same-origin computation only**
— intra-domain in production, intra-preview-tree in preview. **Any
reference that must stay valid across the real domain boundary — explicit
cross-domain links (if/when added), `hreflang`/canonical alternates, and
redirects — must go through `__ABSOLUTE`**, the one macro that needs to know
the build mode (production: literal `http://` + domain-as-directory;
preview: bare `__HREF` or `file://` + absolute path). No other macro should
grow its own hardcoded scheme/host logic — that's what created the second,
unsynced spot in the redirect template above.

### Implied hard constraint

Production output must keep real absolute `__ABSOLUTE`/redirect URLs for
SEO/redirect correctness. Any preview link-rewrite must be a separate,
explicitly-invoked build mode — never change default `make build` output.

### Fix surface is small — no tree restructure needed

Keep domain subdirectories as-is in the preview root (`PREVIEW/<domain>/...`,
mirroring today's `BUILD/DOC/<domain>/...`) — flattening them would collide
`index.html`/`favicon.ico` across `www.tekii.com.ar`, `tekii.us`,
`tekii.ar`. The only things that need a preview-mode branch:

1. `__ABSOLUTE` — fall back to plain `__HREF($1)` (`__TDIR__`-relative,
   matches "relative to the PREVIEW root ... instead of the domain
   subdirectory" above), or build a `file://` + canonicalized absolute
   filesystem path (matches "absolute paths in the current filesystem"
   above).
2. The redirect template — route through `__ABSOLUTE` instead of its own
   hardcoded `http://__DOMAIN__`, so the preview-mode branch lives in one
   place only (and so fixing the self-redirect gap naturally inherits
   preview-awareness instead of needing a third hardcoded spot).

### `file://` marginal benefit is small

Intra-domain links already work under `file://` with zero server, and the
existing single `http.server` already covers all domains from one process.
The only thing `file://` adds over the status quo is "no server process at
all" — traded against things like the AMP CDN `<script src=...>` tags'
behavior under `file://` (mixed-content/CORS quirks), though that risk is
shrinking since AMP removal is already in progress on this repo.

### Follow-up: code-review rule for `__HREF`/`__ABSOLUTE` usage

Once this lands, the HTML/CSS code-review guidelines
(`knowledge/code-review/html.md`, `knowledge/code-review/css.md`) need a new
check enforcing the design rule above: flag any `__HREF` call whose target
crosses domains, and flag any cross-domain reference (link, redirect,
alternate/canonical) that doesn't go through `__ABSOLUTE`. Without that
check, a future page/feature can silently reintroduce the same mistake — a
relative path that looks fine in preview but 404s once published.

### Open questions

1. Is the goal eventually a *visible* cross-domain nav (e.g. region/country
   switcher), or is this purely about previewing the existing SEO
   tags/redirect correctness?
2. Is the existing single-server preview (`build-preview` skill) acceptable
   as the serving mechanism, with only `__ABSOLUTE`/redirect link-generation
   needing a preview-mode variant — or is true zero-server `file://` access
   a hard requirement?
3. Should redirect-domain pages (`tekii.us`, `tekii.ar`'s historical
   redirect) become preview-aware too (bounce to the local preview root
   instead of the real production host), or is escaping to production
   acceptable/expected in preview?

