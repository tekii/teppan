## STOP — Input Quality Check (MANDATORY)

**DO NOT respond to any task until both checks below have passed.**

Before processing any prompt, detect the language of the input.

- If the language is **not English**: skip this check entirely and proceed normally.
- If the language **is English**: run both checks below before doing anything else.
  - **Grammar and spelling**: if errors are found, respond ONLY with:
    1. A list of the specific errors found (e.g. "❌ 'provede' → 'provide'", "❌ Missing comma after 'case'")
    2. A corrected version of the full prompt under the heading **"Suggested revision:"**
    3. Use `AskUserQuestion` with two options: **"Proceed"** (use the corrected version) and **"I meant something different"** (user will clarify). Do not ask as plain text.
  - **Ambiguous references**: if the prompt contains a vague pronoun or noun (`it`, `this`, `that`, `the thing`, etc.) whose referent cannot be determined from the prompt itself — only from prior conversation context — flag each one and ask what it refers to before proceeding. Do not flag when the antecedent is clear within the same message.
  - If neither check finds anything: proceed normally without any mention of this check.

Do not silently fix and proceed — always surface errors explicitly so the user stays in control.

# TEKii static site

*(Content below is loaded from `knowledge/` — see that directory for the
browsable, OKF-formatted source.)*

@knowledge/index.md
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
@knowledge/conventions/git-commit-attribution.md
@knowledge/conventions/m4-conditional-formatting.md
@knowledge/conventions/m4-comment-style.md
