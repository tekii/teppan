---
type: Reference
title: Project glossary & naming
description: Canonical names for this repository — TEKii (the company), Teppan (the project, and since 2026-07-04 the repo name `tekii/teppan`), www (the FORMER repo name, historical only), and the "TEKii static multidomain sites" (the deliverable bundle the project produces). Single source of truth for terms the docs historically conflated.
tags: [reference, naming, glossary, teppan, tekii]
timestamp: 2026-07-02
---

# Project glossary & naming

Canonical terms for this repository. The docs historically conflated the
company, the project, the repo, and the output — this file is the single
source of truth. (Reconciliation across the docs is largely complete —
including the 2026-07-04 `www`→`teppan` repo rename; remaining surfaces get
updated one at a time.)

| Term | What it is |
|---|---|
| **TEKii** | The **company**. Brand casing is `TEKii` — capital `TEK`, lowercase `ii`. Not the project, not the site. |
| **Teppan** | The **project** — the m4/make-based static-site generation system that lives in this repo. This is the project's *actual* name, and (since 2026-07-04) the **repository** name too: `github.com/tekii/teppan`. |
| **www** | The **former** repository name (`github.com/tekii/www`, until 2026-07-04 → now `tekii/teppan`). **Historical only** — carries no meaning beyond it; survives just in old commits and GitHub's URL redirect. |
| **TEKii static multidomain sites** | The **deliverable** — the *bundle* of generated static sites the project produces: multi-domain and multi-language (e.g. `tekii.ar`, `tekii.us`, plus the redirect-only domains). It is a **bundle of sites, not a single site**. (Current working label — refine here if it changes.) |

## Casing & code identifiers
- **Prose / brand:** `TEKii`, `Teppan`.
- **Domains / paths:** lowercase, e.g. `tekii.ar`, `tekii/teppan`.
- **Code identifiers — split by what they name:**
  - Identifiers naming the **project's build/output** use **`TEPPAN_*`**, e.g.
    **`TEPPAN_BUILD`** (formerly `TEKII_BUILD` — the output tree is the
    project's, not the company's).
  - Identifiers naming the **company or its domains/entity** keep **`TEKII`**,
    e.g. the m4 macros `__TEKII__` (renders "TEKii"), `__TEKII_SRL__`
    ("TEKii SRL"), `__TEKII_AR_URL__` (the `tekii.ar` URL). These are literally
    the company name in the rendered pages — **do not** rebrand them.

## Don't conflate
- The **project** is **Teppan**; the "TEKii static multidomain sites" is what it
  *produces*, not the project itself.
- **TEKii** is the **company**, not the project and not the output.
- **www** was the old repo folder name (renamed to `teppan` on 2026-07-04) —
  historical, not a name to build meaning on.

See also: [Knowledge base index](index.md).
