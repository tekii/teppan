---
type: Design Note
title: Deferred / open work register (infrastructure & process)
description: Repo-visible register of known-but-unimplemented infra/process work items and pending decisions, so no pending task lives only in a session's private memory (per the session-memory-hygiene rules in the handoff constitution). The project-deliverable register lives in knowledge/notes/deferred-work.md.
tags: [design-note, deferred, workflow, infra]
timestamp: 2026-07-06
---

# Deferred / open work register (infrastructure & process)

Per the [session-memory-hygiene rules](../conventions/session-handoff.md),
pending work lives **here** — visible to every session and the user, auditable
and re-prioritizable — not in a session's private auto-memory. This register
holds the **infra/process side**; project-deliverable items live in
[the project register](../../knowledge/notes/deferred-work.md).

## Revise the integration gate for change type (decision needed)

`scripts/b3-fleet.sh integrate` gates every merge on `make test` only, which
exercises `generator.m4` macros — **unnecessary for doc-only changes** and
**insufficient for build-input changes** (it doesn't cover `make build`, which
catches HTML/CSS breakage). Consider a **change-type-aware gate**: docs →
light/none; code or build inputs → `make test` **and** `make build`. Related: the
`$(PWD)`-stamp hardening's design analysis lives in
[realclean-recursive.md](../../knowledge/notes/realclean-recursive.md), and the
gate this would revise is documented in the [Teppan integration profile's Gate
section](../../knowledge/conventions/handoff-integration-profile.md).

## Wayland display-forwarding decision (host/infra lane — decision needed)

VS Code auto-bind-mounts the host Wayland socket into the dev container
(`/run/user/1000/wayland-0` → `/tmp/vscode-wayland-*.sock`; not declared in
`devcontainer.json`; re-verified present 2026-07-05). Unused in this
workflow (Playwright is headless) and low-risk (Wayland isolates clients),
but a hole in the hardened-container posture. There is **no clean
`devcontainer.json` opt-out** — it's VS Code client behavior. Decide:
find/disable the client setting, or accept and document. This is
**outer/user-lane** (infrastructure); it sits in this register for
visibility, per the memory-hygiene rules.

See also: [handoff constitution](../conventions/session-handoff.md),
[Teppan integration profile](../../knowledge/conventions/handoff-integration-profile.md),
[infrastructure knowledge index](../index.md).
