---
type: Design Note
title: Firebase Hosting publish pipeline (firebase.json generation + deploy targets)
description: The live publish design — a generated multi-site firebase.json (one hosting entry per content domain, emitted via GENERATE_PUBLISH_PHASE from a guillemet template file), env-required FIREBASE_PROJECT, refuse-only publish guards, and console-level domain redirects verified by publish-verify. Replaces the retired gsutil/ZIP flow and the redirect-HTML machinery.
tags: [design-note, makefile, publish, firebase, m4]
timestamp: 2026-07-23
---

# Firebase Hosting publish pipeline

Publishing moved from the stubbed gsutil-per-file flow (see the
[gsutil trace note](publish-target.md)) to **Firebase Hosting** on 2026-07-23.
The build now generates a single multi-domain `TEPPAN_BUILD/firebase.json`, and
`publish` / `<domain>-publish` targets run `firebase deploy`. The nine
redirect-only domains no longer ship HTML — they are Firebase-console
domain-level redirects, verified live by `make publish-verify`.

## Config pipeline (how `firebase.json` is generated)

Each **landing** stem (`__AS_LANDING`, one per content domain) drives one
`firebase.json` "hosting" entry:

1. `__MAKE_PAGE`'s landing block (`generator.m4`) emits, into the `MAKEFILE`
   diversion, a rule building `$(BUILD_ROOT)/PUB/<domain>.json` via
   `$(do-generate-publish)` — an m4 run with `__PHASE__=GENERATE_PUBLISH_PHASE`.
2. That phase undiverts the `PUBLISH` diversion, into which the same landing
   block pushed the entry (see "the template" below).
3. The `Makefile` assembly rule `cat`s the per-domain `PUB/*.json` fragments,
   wrapping them in `{ "hosting": [ … ] }`, awk joining with commas
   (`awk 'FNR==1 && NR>1 {print ","} NF'` — `NF` skips blank lines so there is
   no stray blank before an inter-entry comma), into
   `$(BUILD_ROOT)/firebase.json`.
4. `build` depends on `firebase.json`, so a normal `make build` produces it —
   **4 entries** (`tekii.ar`, `tekii.us`, `tekii.srl`, `tekii.llc`), each with
   `"public": "DOC/<domain>"`.

`TEPPAN_BUILD/PUB/` holds the intermediate per-domain fragments; only
`firebase.json` (at `TEPPAN_BUILD/` root, outside `DOC/`) is the deploy config.

### The entry template — `firebase-entry.json.m4` (guillemet idiom)

The hosting entry is **not** a macro. It is a file-scope template,
`firebase-entry.json.m4`, `m4_include`d directly at the call site inside the
`PUBLISH` diversion push. It uses the **`meta.json` guillemet idiom** (Devon's
prior art, `meta.json`): `m4_changequote(«,»)` switches the quote characters to
`«»` so that literal JSON `[` `]` pass through as plain bytes, restored with
`m4_changequote([,])` on the last line.

Why a **file-scope template** rather than a macro body: at file scope the JSON
text never transits an m4 **argument collector**, so it carries **no
bracket-balance constraint** — even a lone `[` inside a string is safe. This is
the fix for the failure that a macro-based approach hit (below).

- **Site ID:** `m4_bpatsubst(__DOMAIN__-teppan-site,«\.»,«-»)` — `__DOMAIN__` (in
  scope from the enclosing `__WITH_DOMAIN`) dash-substituted, with a
  `-teppan-site` suffix, e.g. `tekii.ar` → `tekii-ar-teppan-site`. The site ID is
  the project's own naming convention (it also forms Firebase's default
  `<site-id>.web.app` subdomain); it is **not** derived from `.firebaserc`.
  **Why the suffix exists (Devon, 2026-07-24):** the first console setup was
  deleted, and Firebase **retired its site IDs — deleted IDs are not reusable**
  (e.g. `tekii-us-site`, permanently gone), forcing a fresh namespace on the
  second attempt. Do not "simplify" the IDs to match the bare dashed-domain
  convention: site IDs are **immutable**, so renaming means delete-and-recreate
  — which hits the same retention behavior again, plus custom-domain
  re-attachment and certificate re-provisioning on live sites.
- **Load-bearing caveat:** the first `m4_bpatsubst` argument is **unquoted on
  purpose** so `__DOMAIN__` expands *before* substitution. Quoting it would dash
  nothing and re-expand late, silently emitting a dotted (invalid) site ID. Do
  not "fix" it.
- **Include only at top level / inside a diversion push** — never nest the
  include in another macro's argument list (that would re-impose the collector
  constraint the file-scope approach exists to avoid).

The Makefile's per-domain deploy derives the same ID:
`--only hosting:$(patsubst %-publish,%,$@)-teppan-site` — so `make
tekii-ar-publish` targets `hosting:tekii-ar-teppan-site`, matching the config.
**These two must stay in lockstep**; a unit assertion in `generator_test.m4`
pins the transformation
(`m4_bpatsubst([tekii.com.ar-teppan-site],[\.],[-])` → `tekii-com-ar-teppan-site`).

#### Trace: the retired quadrigraph entry macro (design-bearing, never shipped)

The first cut (base tape PKG2) emitted the entry from a macro
`__FIREBASE_HOSTING_ENTRY` that wrote JSON brackets as autoconf **quadrigraphs**
`@<:@` / `@:>@`. That failed: quadrigraphs are converted to `[` / `]` only by
**autom4te's** output post-processing, which Teppan (standalone `m4sugar.m4f`,
no autoconf) never runs — so they reached `firebase.json` verbatim, producing
invalid JSON. It never reached `master`; the guillemet template replaced it the
same day. **Revisit trigger:** only if the project adopts autom4te (then
quadrigraphs would become viable and the changequote dance unnecessary).

## Publish semantics

- **`make publish`** → `firebase deploy … --only hosting` (all sites).
- **`make <dashed-domain>-publish`** → `--only hosting:<dashed-domain>-teppan-site`.
- **Refuse-only mode guards.** Each `<dashed-domain>-publish` depends on a
  `<dashed-domain>-mode-guard` that reads the `.mode-<domain>` stamp and refuses
  unless it is `build`. **Publish never builds** (Devon, 2026-07-23) — it
  deploys whatever is on disk, refusing if that is preview output or absent.
- **Parse-time PREVIEW refusal.** `PREVIEW=1` combined with a publish goal is a
  parse-time `$(error)` (preview output has `file://`-relative URLs — see
  [`file://`-relative preview](file-relative-preview.md)). This is a **separate**
  block from the `FIREBASE_PROJECT` guard below; either firing first is fine.
- **Host-side only.** Deploys run on the host (Devon/Gemini); the container
  network is firewalled. Auth is **ambient** (`firebase login` /
  `GOOGLE_APPLICATION_CREDENTIALS`) — never in Make.

### `FIREBASE_PROJECT` is environment-required (no tracked default)

The Firebase project binding has **no tracked default anywhere in the tree** —
the project ID appears in no committed file (not `.firebaserc` — there is none —
nor a Make default). It is supplied by the environment where the deploy runs
(`export FIREBASE_PROJECT=…` or `FIREBASE_PROJECT=… make publish`). Publish
goals **fail fast** with a named parse-time error when it is unset; every other
goal ignores it. `publish-verify` is deliberately **exempt** (it probes live
domains with `curl` only — no firebase CLI, no project). Rationale: the
**ownership seam** — the repo carries content and config *shape*; the project
binding, sites, domains, redirects, and auth live entirely on Gemini's / the
environment's side. This also means the repo carries **zero**
Firebase-project-scoped identity.

## Console-level domain redirects

The nine redirect-only domains are **not** hosting sites and ship **no HTML**.
Each redirects at the Firebase console's domain-attach level (301,
path-preserving) to a content domain. The map is declared in-repo at the target
domain's landing page via `__AS_REDIRECT_DOMAINS([aliases…],[ … landing … ])`
(`generator.m4`), which pushes `__REDIRECT_DOMAINS_CONTEXT__` around the landing
so `__MAKE_PAGE` can emit per-alias `check-redirect` rules:

- `tekii.com.ar`, `www.tekii.com.ar`, `teky.com.ar`, `teky.ar` → `tekii.ar`
- `tekii.com`, `tekii.info`, `tekii.biz`, `tekii.co`, `tekii.net` → `tekii.us`

**`make publish-verify`** probes each alias (`curl`, reads the 301 + `Location`,
never follows) and asserts a path-preserving redirect to the expected target —
the drift probe for the console configuration. It is the seam between
repo-declared intent and console-owned reality: creating the sites, attaching
domains, and configuring the redirects are **console operations (Gemini's
lane)**; the repo only declares what *should* be true and verifies it.

### Trace: the retired redirect-HTML machinery (design-bearing removal)

Redirect domains previously shipped a real HTML page: `redirect-to-*.in.html`
sources under `layout-redirect.html`, whose `<meta http-equiv="refresh">`
target came from `__REDIRECT_URL(DOMAIN)` → `__ABSOLUTE` (the build-mode-aware
cross-domain chokepoint), resolving the target's registered
`__LANDING_<DOMAIN>_URL__`. It was **root-only** (a single meta-refresh page per
domain). **Why it lost (on the merits):** console redirects are real,
path-preserving **301s** with **zero build footprint** (no page, no asset, no
DEP rule), whereas meta-refresh is a client-side bounce that loses the deep
path. `layout-redirect.html`, `redirect-to-tekii-ar.in.html`,
`redirect-to-tekii-us.in.html`, and `__REDIRECT_URL` were all removed
2026-07-23. **Revisit trigger:** leaving Firebase, or moving to a host without
domain-level redirects — then the meta-refresh page (or a
`__FIREBASE_REDIRECT_ENTRY` grown from the same `__AS_REDIRECT_DOMAINS`
declarations) would need to return. Git history preserves the removed bytes;
this note preserves the why.

## Legacy cutover contract — `www.tekii.com.ar` (constraints on the final tekii.ar layout)

`www.tekii.com.ar` is the one redirect alias with a **past**: it serves the
pre-redesign production site today (probed 2026-07-24), so its cutover carries
preservation duties none of the other eight aliases have. This section is that
contract — binding on the final `tekii.ar` layout until honored some other way.

### The live legacy surface (verified 2026-07-24: crawl == sitemap.xml, five pages)

| Legacy path (HTTP 200 today) | Post-301 lands on tekii.ar | Status in the new tree |
|---|---|---|
| `/`, `/index.html` | `/index.html` | exists (ES landing) — survives as-is |
| `/en/contact.html` | `/en/contact.html` | exists — survives as-is |
| `/es/about.html` | `/es/about.html` | missing (no `es/` dir; ES at root) — needs a rule → `/index.html` |
| `/es/contact.html` | `/es/contact.html` | missing (same) — needs a rule → `/contact.html` |
| `/en/about.html` | `/en/about.html` | missing — needs a rule → `/en/index.html` (the landing IS the about content) |

The `es/` cases are one prefix collapse (`/es/:path*` → `/:path`); `en/about` is
one explicit rule. **No duty beyond these five**: everything else 404s on the
legacy site today (extensionless/cleanUrls-style paths included — verified: the
legacy host serves exact filenames only), so the cutover owes them nothing.

### DNS / hosting facts (probed 2026-07-24)

- Zone: Google Cloud DNS (`ns-cloud*.googledomains.com`).
- **Apex `tekii.com.ar`: zero records** — resolves to nothing today. No
  preservation duty; attaching it as a console redirect is a pure improvement
  and can happen **any time** (nothing that works today breaks).
- **`www.tekii.com.ar`: `CNAME c.storage.googleapis.com`** — a Google Cloud
  Storage bucket website: the still-running deployment of the retired gsutil
  flow (see [the gsutil trace](publish-target.md)). HTTP-only by construction
  (CNAME-to-GCS has no custom-domain TLS — HTTPS fails certificate validation),
  so all legacy inbound links are `http://` and upgrade cleanly via Firebase's
  automatic HTTP→HTTPS after cutover.
- **Sequencing:** `www`'s DNS flip is the real production cutover — only after
  `tekii.ar` content first deploys. The other three `tekii.ar` aliases
  (`tekii.com.ar`, `teky.com.ar`, `teky.ar`) have no DNS today and may be
  attached whenever convenient.

### Post-cutover acceptance

`make publish-verify` (all nine aliases green), plus: curl the five legacy URLs
above — each must answer 200 or single-301-to-200; zero 404s. Bonus (no duty):
`/en`, `/en/` start serving via Firebase directory-index handling — legacy
404'd them.

### OPEN DECISION — where the three fixup rules live (Devon to rule; blocks
nothing until the `www` cutover itself)

- **Option A — rules on `tekii.ar`'s hosting entry** (console redirect for
  `www` as for the other aliases): two `redirects` rules in the content site's
  entry. Cheapest; but legacy deep links take **two-hop 301 chains**
  (domain-301 then site-rule-301), and `tekii.ar`'s future layout must honor
  legacy URL shapes forever (coupling).
- **Option B — a dedicated redirects-only Firebase site for
  `www.tekii.com.ar`** (Devon's proposal, 2026-07-24): the domain attaches as a
  *serving* domain on its own site whose entry is only a redirect table — the
  five paths mapped explicitly to absolute current destinations, plus a
  path-preserving catch-all `/:path*` → `https://tekii.ar/:path`. Pros:
  **single-hop 301s** (better SEO equity transfer, half the latency on exactly
  the URLs that matter), legacy semantics quarantined on the legacy hostname
  (`tekii.ar`'s entry stays pure; future restructuring edits one mapping
  table), the whole contract versioned in generated `firebase.json`. Cons:
  reintroduces for one domain what the console decision avoided — a fifth
  site/entry (global ID claim), a second entry-template shape + an in-repo
  declaration for the map (the `__FIREBASE_REDIRECT_ENTRY` seat), and the
  `public`-dir-must-exist wart (stub dir, or point at `DOC/tekii.ar`,
  unreachable behind the catch-all). Outie's recommendation (2026-07-24):
  **Option B**, catch-all path-preserving — one-time machinery beats a
  permanent constraint on the content site's layout.

## Accepted risks / known limits

- **No `.firebaserc`, no staging parameterization.** A staging project would
  need `FIREBASE_PROJECT` set to a different value (already supported — it is
  env-supplied) but there is no per-environment site-ID map; a site-ID
  namespace collision would force an explicit exception map.
- **The gate does not validate `firebase.json`.** `make test` (the sanctioned
  gate) never builds `firebase.json`, so an invalid config passes the gate — the
  quadrigraph defect above passed `make test` and was caught only by a manual
  `make build` + JSON-validity check. See the
  [infra gate-revision entry](../infra/deferred-work.md). **Validate in-container
  with `jq -e . TEPPAN_BUILD/firebase.json`** (the container lacks `python3`; jq
  is available — Devon, 2026-07-23).
- **`cleanUrls: false`** — the generator emits explicit `.html` links, so there
  are no sitewide 301 bounces. Pretty/extensionless URLs are deferred (see the
  [project register](deferred-work.md)).
- **Absolute URLs are `https://`** (`__ABSOLUTE`, flipped 2026-07-24, before
  first publish): every generated canonical, `hreflang` alternate, and
  cross-domain link names the final TLS URL — matching the console redirects'
  `https://` targets, keeping canonicals from pointing at the http→https 301,
  and anchoring the `<site-id>.web.app` duplicate-content mitigation. Preview
  output is unaffected (relative URLs).

See also: [gsutil publish trace note](publish-target.md),
[Build & test commands](../build/commands.md),
[Domains](../architecture/domains.md),
[`file://`-relative preview](file-relative-preview.md),
[M4 comment style](../conventions/m4-comment-style.md).
