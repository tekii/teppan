---
type: Architecture Concept
title: Diversion/phase model
description: How generator.m4 routes content through named m4 diversions and dispatches output by __PHASE__.
tags: [architecture, m4, diversion]
timestamp: 2026-06-17
---

# Diversion/phase model

`generator.m4` writes content into named m4 diversions (`MAKEFILE`, `HEAD`,
`MAIN`, `NAVIGATION`, `HTML`, `DEFERRED_MK`, `TESTS`, ...) and a final
`m4_case(__PHASE__, ...)` dispatch picks which diversion gets emitted to
`DEFAULT` (stdout) for a given run: `GENERATE_MAKEFILE_PHASE`,
`GENERATE_NAVIGATION_PHASE`, `GENERATE_HTML_PHASE`, `GENERATE_DEFERRED_MK_PHASE`,
`MAKEPUB_PHASE`, `TEST_PHASE`. An unmatched `__PHASE__` is a hard `m4_fatal`.

See also: [Page source conventions](page-source-conventions.md) (the
producers that push into these diversions) and
[Testing conventions](../testing/conventions.md) (the `TESTS` diversion /
`TEST_PHASE`).
