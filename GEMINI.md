# TEKii Static Site — AI Developer Rules & Context (`GEMINI.md`)

Welcome to the TEKii Static Site codebase! This project is a multi-domain, multi-language static website generator built with **GNU `m4`** and **GNU Makefile**. This document provides the core instructions, commands, architectural principles, and styling conventions for any Gemini assistant working on this workspace.

---

## 1. Project Overview & Architecture

TEKii is built without an application server or complex JS build tools. Instead, it uses GNU `m4` with autoconf's `m4sugar.m4f` macro library (standalone) to render pages ahead of time into standard, highly optimized HTML, CSS, and assets under `BUILD/DOC`.

### Key Components:
- **`generator.m4`**: The core template and macro processor that handles routing, layout inclusion, diversions, asset mapping, and localization.
- **`layout.html`**: The main page layout containing structure, navigation, footer, and placeholder slots filled by diversions.
- **Source pages (`*.in.html`)**: Source templates (e.g., `contact.in.html`, `news.in.html`) that contain actual page contents wrapped in `m4` macro calls.
- **[knowledge/](knowledge)**: The local knowledge base containing deep explanations of the architecture, build conventions, testing practices, and styling rules (starting with [index.md](knowledge/index.md)).

---

## 2. Standard Commands Reference

Always use these standard GNU `make` commands to build, test, and clean the codebase:

```bash
# Generate the full static site into BUILD/DOC
make build

# Run the m4 generator assertions (fails if __ASSERT_EQ outputs FAIL)
make test

# Remove generated build output and temp files
make clean
```

> [!TIP]
> Use the `build-preview` skill to serve the contents of `BUILD/DOC` locally in a browser for manual testing and visual layout inspections.

---

## 3. Development & Styling Conventions

When editing or creating files in this project, you **MUST** follow these specific conventions:

### A. M4 Macros & Commenting
- **Comment Style**: Use `dnl` (delete through newline) or `m4_dnl` for standard m4-only comments. Avoid leaving raw m4 macros or unbalanced parentheses in normal HTML comments, as it can break parsing.
- **Conditional Formatting**: Format m4 conditionals (`m4_if`, `m4_ifdef`, etc.) cleanly with consistent indentation. Keep bracket pairings `[` and `]` balanced to prevent macro expansion issues.

### B. CSS & HTML (including AMP)
- The site uses AMP (Accelerated Mobile Pages) conventions. Make sure any CSS updates are compatible with AMP constraints (e.g., inlining CSS in `<style amp-custom>` and keeping size under 75KB, avoiding disallowed JS).
- Custom styles are maintaned in `css/` and consolidated in `amp-custom.css`.

### C. Git Commit Messages
- Ensure commit messages have proper attribution where required by project guidelines. See `knowledge/conventions/git-commit-attribution.md` for specific formatting details.

---

## 4. Testing Conventions
- All macro changes and route rules must be covered by assertions in `generator_test.m4`.
- Run assertions via `make test`. If any assertion fails, it prints `FAIL` and aborts the make process. Always run tests before completing changes.
