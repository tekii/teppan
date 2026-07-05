# Antigravity Workspace Rules — TEKii (`AGENTS.md`)

This file contains workspace-scoped rules and style guidelines for Antigravity agents operating in the TEKii (`tekii/teppan`) codebase. All agent actions, file modifications, and commands executed within this workspace must adhere to these directives.

---

## 1. Local Workspace Overview

The TEKii codebase is a static site generator utilizing GNU `m4` (with `m4sugar`) and GNU `make`. There is no node/npm build process; everything is processed via local macros and the Makefile into `TEPPAN_BUILD/DOC`.

Before performing any code modifications, agents **MUST** read and familiarize themselves with:
- **[CLAUDE.md](../CLAUDE.md)**: Entry point for knowledge base index references.
- **[GEMINI.md](../GEMINI.md)**: Detailed tech stack, build commands, and m4 macro principles.
- **[knowledge/](../knowledge)** directory: Contains specific guidelines for architecture, testing, and reviews (starting with [index.md](../knowledge/index.md)).

---

## 2. Core Agent Constraints & Rules

### A. Environment and Sandbox
- Do not run complex shell scripts, python scripts, or install software globally unless absolutely required and approved.
- All builds and site compilations should be initiated using `make build`.
- Never bypass the `Makefile` when compiling pages or checking outputs.

### B. Coding and Compilation Standards
- **Keep macros clean**: Avoid introducing custom javascript or node libraries. Keep layout structures focused entirely on the GNU `m4` generator design.
- **No AMP**: The site no longer uses AMP (removed in the Water.css migration); HTML/CSS is plain WHATWG-standard markup, and stylesheets are delivered via external `<link>` (Water.css + `custom.css`). Flag any new `<amp-*>` element/attribute or `<style amp-custom>` block as a regression. JavaScript is still avoided — no longer for AMP compliance, but by the project's static m4-generator design (see "Keep macros clean" above).
- **CSS Modularity**: Style changes go in `custom.css` (renamed from `amp-custom.css`).

### C. Testing and Safety
- Always run `make test` after modifying `generator.m4` or route files.
- Ensure that no assertion failures (yielding `FAIL` output) occur in `generator_test.m4`.
- Never submit or finish a task if `make test` fails or contains errors.
- Preserve existing comments, docstrings, and headers unless explicitly instructed otherwise.

### D. Workspace Setup & Dependencies (Antigravity-Specific)
> [!NOTE]
> This section applies **only** to Antigravity (Gemini) agents. Claude Code / Claude agents should ignore these guidelines, as they rely on the automated `SessionStart` hooks in `.claude/settings.json`.
- **No Startup Hooks**: Antigravity does not natively execute automated background session hooks (like those in `.claude/settings.json`).
- **Manual Dependency Handling**: If `make test` or `make build` fails because `autoconf` or `m4sugar` is missing, Antigravity agents must manually run `./scripts/install_pkgs.sh` or request permission to install the necessary packages.

---

## 3. Communication and Reporting
- When presenting build and compile statuses to the user, keep explanations clear and concise.
- Focus on describing what was verified by `make test`.
