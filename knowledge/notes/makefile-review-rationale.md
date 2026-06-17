---
type: Design Note
title: GNU Makefile code review role — rationale
description: Rationale for adding the GNU Makefile code-review role to the project's guidelines, with sources.
tags: [design-note, makefile]
timestamp: 2026-06-17
---

# Code Review Role — GNU Makefile (CLAUDE.md addition)

It's tailored to patterns already present in this project's
`Makefile`/`Rules.mk`/generated `.mk` files: `:=` vs `=` (esp.
`$(shell which m4)`), `.PHONY`, double-colon `::` rule semantics (ties back
to the `logo.png`/`clean-asset` finding in
[`asset-rule-duplication.md`](asset-rule-duplication.md)), order-only `|`
prerequisites (ties to the `cd11eed` fix), `.SECONDEXPANSION`/`$$`
expansion, `-include`'d generated `.mk` bootstrapping, and recursive
`$(MAKE)` variable propagation — plus style and common-bugs checklists in
the same format as the M4 section.

Sources:
- [Recursive Make Considered Harmful (Peter Miller)](https://aegis.sourceforge.net/auug97.pdf)
- [Makefile Conventions — GNU Coding Standards](https://www.gnu.org/prep/standards/html_node/Makefile-Conventions.html)
- [Makefile Tutorial by Example](https://makefiletutorial.com/)
- [GNU Makefiles - best practices](http://rahul.gopinath.org/post/2025/10/17/makefiles/)
- [Makefile Best Practices — Cloud Posse](https://docs.cloudposse.com/best-practices/developer/makefile/)

See also: [GNU Makefile code review guidelines](../code-review/makefile.md).
