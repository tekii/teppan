## Input Quality Check

Before processing any prompt, detect the language of the input.

- If the language is **not English**: skip this check entirely and proceed normally.
- If the language **is English**: check for grammar and spelling errors.
  - If errors are found: pause and respond ONLY with the following, before doing anything else:
    1. A list of the specific errors found (e.g. "❌ 'provede' → 'provide'", "❌ Missing comma after 'case'")
    2. A corrected version of the full prompt under the heading **"Suggested revision:"**
    3. Ask: "Shall I proceed with the corrected version, or did you mean something different?"
  - If no errors are found: proceed normally without any mention of this check.

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
