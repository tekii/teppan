---
type: Reference
title: Project glossary & naming
description: Canonical names for this repository — TEKii (the company), Teppan (the project), www (the legacy repo name), and the "TEKii static multidomain sites" (the deliverable bundle the project produces). Single source of truth for terms the docs historically conflated.
tags: [reference, naming, glossary, teppan, tekii]
timestamp: 2026-07-02
---

# Project glossary & naming

Canonical terms for this repository. The docs historically conflated the
company, the project, the repo, and the output — this file is the single
source of truth. (Reconciliation across the rest of the docs is in progress,
one surface at a time.)

| Term | What it is |
|---|---|
| **TEKii** | The **company**. Brand casing is `TEKii` — capital `TEK`, lowercase `ii`. Not the project, not the site. |
| **Teppan** | The **project** — the m4/make-based static-site generation system that lives in this repo. This is the project's *actual* name. |
| **www** | The **repository** name (`github.com/tekii/www`). **Legacy**; it carries no meaning beyond history. |
| **TEKii static multidomain sites** | The **deliverable** — the *bundle* of generated static sites the project produces: multi-domain and multi-language (e.g. `tekii.ar`, `tekii.us`, plus the redirect-only domains). It is a **bundle of sites, not a single site**. (Current working label — refine here if it changes.) |

## Casing & code identifiers
- **Prose / brand:** `TEKii`, `Teppan`.
- **Domains / paths:** lowercase, e.g. `tekii.ar`, `tekii/www`.
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
- **www** is just the repo folder — legacy, not a name to build meaning on.

See also: [Knowledge base index](index.md).
