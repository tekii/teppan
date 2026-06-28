---
type: Reference
title: Open Knowledge Format (OKF)
description: The knowledge/ tree is authored in the Open Knowledge Format — a directory of markdown files with YAML frontmatter, readable by humans and AI agents. Links to the OKF specification overview.
resource: https://cloud.google.com/blog/products/data-analytics/how-the-open-knowledge-format-can-improve-data-sharing
tags: [reference, okf, documentation]
timestamp: 2026-06-28
---

# Open Knowledge Format (OKF)

The files under `knowledge/` are authored in the **Open Knowledge Format
(OKF)** — an open, vendor-neutral specification that represents a body of
knowledge as a *directory of markdown files with YAML frontmatter*, designed
to be consumable by both humans and AI agents without a proprietary SDK or
runtime. `CLAUDE.md` loads this tree as its "OKF-formatted source."

Specification overview / announcement:
<https://cloud.google.com/blog/products/data-analytics/how-the-open-knowledge-format-can-improve-data-sharing>

## How this repo applies OKF

- **File path = concept identity.** Each `.md` file is one concept and its
  path is its identifier (e.g. `code-review/makefile.md`).
- **Frontmatter fields.** `type` is the only field OKF requires; every file
  in this tree also fills in `title`, `description`, `tags`, and `timestamp`.
  `resource` (used in this file's frontmatter) is the OKF field for an
  external URL.
- **Reserved `index.md`.** Per-directory overview / progressive disclosure —
  see [`index.md`](index.md), [`architecture/index.md`](architecture/index.md),
  and [`code-review/index.md`](code-review/index.md).
- **Standard markdown links** between files form the concept graph — e.g. the
  "See also" footers throughout this tree.

See also: [Knowledge base index](index.md).
