---
type: Convention
title: M4 comment style — `#` for documentation, `dnl` for diversion hygiene
description: Use bare `#` for top-level documentation comments; reserve `dnl` for newline-suppression plus any comment or disabled code sitting inside an active diversion push, since `#` content is passed through, not discarded.
tags: [m4, conventions, style]
timestamp: 2026-06-23
---

# M4 comment style

`generator.m4` has two comment mechanisms available: `dnl` (discard to the
next newline) and `#` (m4's traditional comment-to-end-of-line, where the
text is passed through *unexpanded* but **not discarded**). Use them for
different purposes:

- **`#` for documentation comments** — macro header docs, parameter lists,
  TODOs, and any other prose meant only for readers of the m4 source —
  whenever the comment sits at a point where the active diversion is
  `KILL`. That's the default at the top of the file, and it's restored
  after every balanced `m4_divert_push`/`m4_divert_pop` pair. At such a
  point the comment text is harmless: m4 skips macro-expansion inside a
  `#...` comment, and `KILL` (diversion -1) discards anything written to it
  regardless.
- **`dnl` for diversion hygiene** — the trailing `dnl` after a real
  statement (suppressing that line's own newline) and any comment or
  disabled ("commented-out") code that sits *inside* an open
  `m4_divert_push(...) ... m4_divert_pop(...)` span.

## Why the diversion context matters

`#` comments are not discarded the way `dnl` ones are — m4 just skips
expansion within them and copies the text through to whatever diversion
happens to be active at that point. Confirmed empirically: temporarily
replacing the `dnl`-commented TODO inside `__MAKE_PAGE`'s `MAKEFILE`
diversion span (`generator.m4:207`, between `m4_divert_push([MAKEFILE])` at
line 196 and `m4_divert_pop([MAKEFILE])` at line 247) with a bare `#`
comment leaked that TODO text verbatim into the generated `Makefile`
output, because the active diversion there is `MAKEFILE`, not `KILL`. The
same risk applies to disabled/commented-out code sitting inside a diversion
span (e.g. `generator.m4:252`, inside the `NAVIGATION` span) — keeping it
`dnl`-prefixed is what keeps it inert.

So a documentation comment is only safe as `#` where it's provably in
`KILL` context — i.e. outside any open diversion push, or after a balanced
pop. Anywhere a comment (or disabled code) sits between a
`m4_divert_push` and its matching `m4_divert_pop`, keep it as `dnl`.

## Box multi-line header comments only — not single-line ones

A **multi-line** macro/section/test header comment is bookended by a bare
`#` line immediately before and immediately after it:

```
#
# WITH_LAYOUT(LAYOUT,BODY,[EXTRA...]) MACRO
# $1 path to an alternate layout file -- required...
# $2 body to expand under the alternate __LAYOUT__
#
m4_define([__WITH_LAYOUT],[...])
```

A **single-line** comment — a one-line macro header (`# WITH_LANG MACRO`),
an inline TODO, a casual aside — does **not** get the box. Bookending a
one-liner with blank `#` lines is noise, not signal: it makes a passing
remark look as weighty as a multi-paragraph doc block. Write it bare:

```
# WITH_LANG MACRO
m4_define([__WITH_LANG],[...])
```

`generator.m4:100-113` (`WITH_LAYOUT` doc, multi-line, boxed) and
`generator.m4:126` (`WITH_LANG MACRO`, single-line, bare) are the models for
each case. When two distinct single-line notes sit back to back (e.g. a
macro-name header followed by a one-line parameter note), stack them as
plain consecutive `#` lines with no blank between — don't box each
individually and don't merge them into one box.

## Spelling: "diversion", not "divertion"

The correct term — matching GNU m4's own manual and this project's
`_m4_divert`/`m4_divert_push`/`m4_divert_pop`/`m4_undivert`/`m4_cleardivert`
macro names — is **diversion**. "Divertion" is not a word.

See also: [M4 code review guidelines](../code-review/m4.md).
