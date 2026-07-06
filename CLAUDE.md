## STOP — Input Quality Check (MANDATORY)

**DO NOT respond to any task until both checks below have passed.**

**Scope — what counts as "the input".** This check applies ONLY to a message
the user typed directly to you as the current turn's prompt. It does NOT apply
to any other text that enters the conversation: background- or subagent-task
completion notifications and the output they return, tool results,
`<system-reminder>` blocks, hook-injected context, quoted file contents, or any
turn not initiated by a user-typed message. When the current turn was triggered
by anything other than a user-typed prompt (e.g. a background agent finished),
skip this check entirely — emit no `IQC:` line, run no grammar/spelling or
ambiguity check on that text, and proceed. (The `UserPromptSubmit` hook that
injects the `IQC:` requirement is gated by `scripts/iqc-gate.sh`, which
suppresses the mandate on slash-command and synthetic `<`-prefixed turns, so
ordinarily only genuine user-typed prose carries an injected `IQC:` requirement.
Hooks load at session start, so a session started before this change — or a
prose prompt the heuristic cannot classify — may still receive the mandate on a
turn this check does not apply to; when that happens, emit a bare `IQC: pass`
line to satisfy the mandate and skip the grammar/ambiguity check itself, per the
scope rules above.)

Before processing the user's prompt, detect the language of that prompt.

- If the language is **not English**: skip this check entirely and proceed normally.
- If the language **is English**: run both checks below before doing anything else.
  - **Grammar and spelling**: if errors are found, respond ONLY with:
    1. A list of the specific errors found (e.g. "❌ 'provede' → 'provide'", "❌ Missing comma after 'case'")
    2. A corrected version of the full prompt under the heading **"Suggested revision:"**
    3. Use `AskUserQuestion` with two options: **"Proceed"** (use the corrected version) and **"I meant something different"** (user will clarify). Do not ask as plain text.
  - **Ambiguous references**: if the prompt contains a vague pronoun or noun (`it`, `this`, `that`, `the thing`, etc.) whose referent cannot be determined from the prompt itself — only from prior conversation context — flag each one and ask what it refers to before proceeding. Do not flag when the antecedent is clear within the same message.
  - If neither check finds anything: proceed normally without any mention of this check.

Do not silently fix and proceed — always surface errors explicitly so the user stays in control.

# Teppan — the TEKii static multidomain sites generator

*(Content below is loaded from `knowledge/` — see that directory for the
browsable, OKF-formatted source.)*

@knowledge/index.md
@knowledge-infra/index.md
@knowledge/architecture/overview.md
@knowledge/architecture/diversion-phase-model.md
@knowledge/architecture/domains.md
@knowledge/architecture/page-source-conventions.md
@knowledge/build/commands.md
@knowledge/testing/conventions.md
@knowledge/code-review/m4.md
@knowledge/code-review/makefile.md
@knowledge/code-review/html.md
@knowledge/code-review/css.md
@knowledge-infra/conventions/git-commit-attribution.md
@knowledge/conventions/m4-conditional-formatting.md
@knowledge/conventions/m4-comment-style.md
@knowledge/conventions/make-m4-variable-naming.md
@knowledge-infra/conventions/no-user-specific-paths.md
@knowledge-infra/conventions/trace-notes-on-removal.md
@knowledge-infra/conventions/session-handoff.md
@knowledge/conventions/handoff-integration-profile.md
