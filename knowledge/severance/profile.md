---
type: Convention
title: Severance consumer profile — Teppan (STUB, mock phase)
description: Placeholder for Teppan's answers to the SEVERANCE.md profile contract (gate, hygiene preconditions, sanctioned flow). During the mock phase the real answers remain in knowledge/conventions/handoff-integration-profile.md; this stub proves the spec+profile co-location mechanism only.
tags: [conventions, severance, profile, stub]
timestamp: 2026-07-09
---

# Severance consumer profile — Teppan (STUB)

> **STUB — mock phase.** The vendored [`SEVERANCE.md`](SEVERANCE.md)
> beside this file is a v0.0.x mock, so this profile is a placeholder
> proving the spec+profile co-location. Teppan's real answers live, for
> now, in the
> [integration profile](../conventions/handoff-integration-profile.md)
> and move here as a named migration step.

## Gate

See the [integration profile](../conventions/handoff-integration-profile.md):
`make test` — 30 `__ASSERT_EQ` assertions, 0 FAIL.

## Hygiene preconditions

See the [integration profile](../conventions/handoff-integration-profile.md):
`findmnt` must show the `TEPPAN_BUILD` volume mount before any `make`
on the main checkout.

## Sanctioned flow

See the [integration profile](../conventions/handoff-integration-profile.md):
`scripts/b3-fleet.sh provision` → edits in the worktree → gate →
`integrate` → `teardown`.
