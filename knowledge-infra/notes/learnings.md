---
type: Design Note
title: Learnings register — what each step of the experiment taught
description: Chronological register of what each design-bearing step taught about coding with LLMs — facts separated from interpretation, lessons attributed as Claude findings or user-verified (via comprehension interview). Governed by the learnings-register convention; backfill from git/knowledge archaeology pending.
tags: [design-note, learnings, experiment, register]
timestamp: 2026-07-06
---

# Learnings register

What each step of the experiment taught — governed by the
[learnings-register convention](../conventions/learnings-register.md)
(entry format, thresholds, and the comprehension interview are defined
there). Newest entries last.

## 2026-07-06 — Entry 1: this register was created late

- **Step:** the register itself was proposed during the Severance-conceit
  naming session, months into the project.
- **Fact:** no per-step learning record existed before this date; the
  project's history is reconstructible only because commit messages,
  knowledge notes, and the constitution's "observed live" annotations
  happen to be unusually thorough.
- **Interpretation:** in an LLM-assisted project, decide at the start
  what the experiment must record — the collaboration moves fast enough
  that the record won't keep itself. Thorough incidental documentation
  made the lateness recoverable *this time*; that was luck elevated to
  method only in hindsight.
- **Attribution:** Claude finding; user-verified (the lesson was stated
  by Devon himself — the interview requirement in the convention is, in
  fact, Devon's own addition from the same session).

## 2026-07-06 — Entry 2: the author skipped a check the constitution never wrote down

- **Step:** the first tape of the Severance-conceit fold was drafted;
  its edit-package anchors were verified against files read from disk,
  without proving contemporaneously that the disk state was authoritative
  `master` (clean tree, expected HEAD). Devon asked "did Claude check
  that the disk version was at HEAD?"; a retroactive probe confirmed no
  drift had occurred.
- **Fact:** the constitution held the principle (Rule 3: the outer
  anchors to the state that ships) and the consumer-side procedure
  (inner apply rule 2), but no author-side procedure; every procedural
  checklist had accumulated on the Innie side, where the failures had
  happened. The gap was closed by amending the draft-anatomy section in
  the same change as this entry.
- **Interpretation:** LLMs follow written checklists reliably and
  first-principles hygiene unreliably — a rule that exists as principle
  but not procedure will eventually be skipped, and redundant
  verification layers exist precisely because each layer individually
  gets skipped. The human auditing the process caught what both the
  author session and the written rules missed: the reviewer role is
  load-bearing, not ceremonial.
- **Attribution:** user-originated (Devon caught it and drove the rule);
  Claude finding for the audit details (no prior norm existed; the split
  lost nothing — verified against the split commits' diffs).

## 2026-07-07 — Entry 3: the audit of the formerly-public history

- **Step:** Devon disclosed that the repo (as `tekii/www`) was once
  public; the Outie swept all 526 `master` commits for secrets, identity
  leaks, and content liabilities (read-only, `master` scope per Rule 3).
- **Fact:** two Google Maps API keys were found — one still in HEAD
  inside a commented-out iframe on the contact page, removed by the same
  change that adds this entry; committed user-home paths appeared in
  three historical eras (SVG export metadata 2015/2018, m4 comments
  2020, doc links 2026 — the last already purged when the
  no-user-paths convention was created); a 2014 commit imported a
  third-party marketing site wholesale as a design base and was cleaned
  up weeks later; no other secret patterns, sensitive filenames, or
  personal data surfaced.
- **Interpretation:** *public once is public forever* — privatization is
  not retraction (forks, archives, caches), so the audit's value was
  knowing the exposure, not preventing it. "Nothing embarrassing on it
  (I hope)" and a verified inventory are different artifacts, and the
  sweep cost minutes of model time; the human's irreplaceable
  contribution was disclosing the fact that made it necessary. For the
  planned infra extraction, everything found strengthens a fresh-start
  founding commit over carried-over history.
- **Attribution:** user-originated (Devon disclosed the prior publicity
  and triggered the audit); Claude finding for the inventory itself.

## Backfill (pending)

A reconstruction pass over git history and both knowledge trees —
proposing a dated timeline of design-bearing steps and their lessons for
Devon's correction (and comprehension interviews where applicable) — is
registered in the [deferred-work register](deferred-work.md). Candidate
epochs already visible from the tree: the AMP removal / Water.css
migration, the repo rename, the build-volume isolation, the B3 fleet and
its guards, the handoff constitution, the knowledge-tree split, the IQC
hook.

See also: [learnings-register convention](../conventions/learnings-register.md),
[the Severance conceit](severance-conceit.md).
