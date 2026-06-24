# Antigravity Workspace Rules — TEKii (`AGENTS.md`)

This file contains workspace-scoped rules and style guidelines for Antigravity agents operating in the TEKii (`tekii/www`) codebase. All agent actions, file modifications, and commands executed within this workspace must adhere to these directives.

---

## 1. Local Workspace Overview

The TEKii codebase is a static site generator utilizing GNU `m4` (with `m4sugar`) and GNU `make`. There is no node/npm build process; everything is processed via local macros and the Makefile into `BUILD/DOC`.

Before performing any code modifications, agents **MUST** read and familiarize themselves with:
- **[CLAUDE.md](file:///home/rodablo/www/CLAUDE.md)**: Entry point for knowledge base index references.
- **[GEMINI.md](file:///home/rodablo/www/GEMINI.md)**: Detailed tech stack, build commands, and m4 macro principles.
- **[knowledge/](file:///home/rodablo/www/knowledge)** directory: Contains specific guidelines for architecture, testing, and reviews (starting with [index.md](file:///home/rodablo/www/knowledge/index.md)).

---

## 2. Core Agent Constraints & Rules

### A. Environment and Sandbox
- Do not run complex shell scripts, python scripts, or install software globally unless absolutely required and approved.
- All builds and site compilations should be initiated using `make build`.
- Never bypass the `Makefile` when compiling pages or checking outputs.

### B. Coding and Compilation Standards
- **Keep macros clean**: Avoid introducing custom javascript or node libraries. Keep layout structures focused entirely on the GNU `m4` generator design.
- **AMP Compliance**: Since the site uses Accelerated Mobile Pages (AMP) standards, ensure that any HTML/CSS alterations comply strictly with AMP validation rules. No arbitrary `<script>` tags are permitted unless they are authorized AMP components.
- **CSS Modularity**: All style changes must be planned via `css/` files or updating `amp-custom.css`.

### C. Testing and Safety
- Always run `make test` after modifying `generator.m4` or route files.
- Ensure that no assertion failures (yielding `FAIL` output) occur in `generator_test.m4`.
- Never submit or finish a task if `make test` fails or contains errors.
- Preserve existing comments, docstrings, and headers unless explicitly instructed otherwise.

---

## 3. Communication and Reporting
- When presenting build and compile statuses to the user, keep explanations clear and concise.
- Focus on describing what was verified by `make test`.
