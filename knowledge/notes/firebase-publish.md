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

See also: [gsutil publish trace note](publish-target.md),
[Build & test commands](../build/commands.md),
[Domains](../architecture/domains.md),
[`file://`-relative preview](file-relative-preview.md),
[M4 comment style](../conventions/m4-comment-style.md).
