---
type: Convention
title: M4 conditional formatting — one branch per line
description: Split multi-branch m4_if/m4_case calls one branch per line; GNU m4 strips newlines after commas in argument lists, so only a single trailing dnl after the closing paren is needed.
tags: [m4, conventions, style]
timestamp: 2026-06-23
---

# M4 conditional formatting — one branch per line

When a conditional macro call (`m4_if`, `m4_case`, or any similar
comma-separated multi-branch macro) has more than one branch, write each
branch on its own line rather than packing every `(condition, value,
action)` triple (or `m4_case` label/action pair) onto a single line.
`m4_case(__PHASE__, ...)` (`generator.m4:381-390`) is the model to follow.

## Why this is safe without a `dnl` on every line

GNU m4 strips leading whitespace — including newlines — immediately
following a comma (or an opening parenthesis) while collecting a macro
call's arguments. Splitting an argument list across multiple source lines
therefore never leaks a stray blank line or whitespace into the generated
output. Confirmed empirically: building `BUILD/DOC` from variants with and
without `dnl` on each internal line of a multi-line `m4_if`/`m4_case`
produced byte-identical output both ways.

Only **one** `dnl` is ever needed for a multi-line conditional call: the one
*after* the closing `)`, suppressing that line's own trailing newline — the
same idiom already used for top-level statements throughout `generator.m4`
(e.g. `m4_include([./configure.m4])dnl`). A `dnl` on every internal line is
not incorrect, just redundant — remove it when found, and don't add it when
writing new multi-branch conditionals.

See also: [M4 code review guidelines](../code-review/m4.md).