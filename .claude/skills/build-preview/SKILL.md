---
name: build-preview
description: Build the site in preview mode (relative URLs, no server needed) and open it in a browser for manual inspection. See knowledge/notes/file-relative-preview.md for why preview is filesystem-relative.
allowed-tools: Bash(make preview), Bash(make realclean), Bash(find:*), Bash(realpath:*)
---

# Build & preview the site in a browser

Goal: build the site with relative URLs and open it directly off disk —
no local HTTP server, no deploy step. See
[`file://`-relative preview](../../../knowledge/notes/file-relative-preview.md)
for why this works (the `__PREVIEW__` branch in `__ABSOLUTE`, `generator.m4`)
and [Build & test commands](../../../knowledge/build/commands.md) for the
full `make` reference, including scoping a preview to one domain.

## 1. Build in preview mode

```
make preview
```

This writes into `TEPPAN_BUILD/DOC` with relative `href`s (e.g. `en/index.html`,
not `http://host/en/index.html`). It shares the same `TEPPAN_BUILD` tree as
`make build` — switching back and forth is safe and only rebuilds the pages
whose mode actually changed (see the "BUILD MODE STAMP" section of
`Makefile`).

To preview just one domain instead of the whole site:
```
make PREVIEW=1 <domain>-build   # e.g. make PREVIEW=1 tekii-ar-build
```

## 2. Decide whether you actually need a browser

The browser is slow and expensive — reach for it only when something
genuinely visual is being verified (rendered layout, CSS, screenshots,
console/network output for a real bug). For anything else — does a link
point where it should, is the right text/title present, did a macro expand
correctly — read the generated HTML directly (`Read`/`grep` on
`TEPPAN_BUILD/DOC/<domain>/...`) or trace the source macro in `generator.m4`.
That's cheaper and just as authoritative; a full browser navigation adds
nothing for a question that's really "what does this file contain."

If a browser genuinely is warranted, **which MCP server is available depends
on which of the three environments you're in** (see
[dev container setup](../../../knowledge/notes/devcontainer-setup.md)) —
they are mutually exclusive, never both at once, so check rather than assume:

- **Host + IDE** → Google's `chrome-devtools` MCP (`mcp__chrome-devtools__*`).
- **Dev container** → Microsoft's Playwright MCP (`mcp__playwright__*`) —
  `chrome-devtools` is not registered in-container at all, it's replaced.
- **Claude Code web** → neither; fall straight to manual/no-browser.

Confirm with `ToolSearch` for whichever prefix applies before picking a path.

**A1. `chrome-devtools` MCP** (`mcp__chrome-devtools__*` — `navigate_page`,
`new_page`, `take_screenshot`, `take_snapshot`, `list_console_messages`,
`list_network_requests`, etc.). Open the target page with `new_page`/
`navigate_page` (`file:///$(pwd)/TEPPAN_BUILD/DOC/<domain>/index.html`), then
use `take_screenshot`/`take_snapshot`/console/network tools as needed. It's
already configured (local scope, project-local profile and Node — see
[`chrome-devtools` MCP setup](../../../knowledge/notes/chrome-devtools-mcp-setup.md))
to run against `.claude/chrome-profile/` and the real `google-chrome`
binary. No extra permission dance needed beyond the tool's own call.

**A2. Playwright MCP** (`mcp__playwright__*` — `browser_navigate`,
`browser_take_screenshot`, `browser_snapshot`, `browser_console_messages`,
etc.), inside the dev container only. Navigate with `browser_navigate` to
`file:///$(pwd)/TEPPAN_BUILD/DOC/<domain>/index.html`. Three
container-specific gotchas, all detailed in
[dev container setup](../../../knowledge/notes/devcontainer-setup.md):
- `file://` needs `--allow-unrestricted-file-access` — already baked into
  `postcreate.sh`, but only takes effect from the *next* session after that
  flag was added (mid-session, `file://` may still be blocked).
- The generated pages still carry AMP boilerplate CSS that hides `<body>`
  for up to 8 seconds regardless of whether the AMP runtime loads (it never
  does here — no network egress to `cdn.ampproject.org`) — a screenshot
  taken immediately after navigation comes back blank white. Call
  `browser_wait_for({time: 9})` before screenshotting.
- `browser_take_screenshot`'s `filename` parameter bypasses `--output-dir`
  entirely and resolves relative to the workspace root instead — omit
  `filename` (auto-generated name, lands correctly in
  `TEPPAN_BUILD/ARTIFACTS/`) or pass an absolute `TEPPAN_BUILD/ARTIFACTS/...`
  path; never a bare relative name, or it leaks an untracked `.png` into
  the repo root.

**B. Manual launch**, only if neither MCP server is connected and the user
still wants eyes-on inspection (not a scripted screenshot/DOM check):

```
google-chrome --user-data-dir="$(pwd)/.claude/chrome-profile" --no-first-run "$(realpath TEPPAN_BUILD/DOC/<domain>/index.html)"
```

This is **not** in this skill's `allowed-tools` — launching a GUI browser
window is a visible, unannounced action, so it must go through the normal
Bash permission prompt every time, even though the build step above runs
without asking. If the user denies it, just report the absolute
`file://...` path instead so they can open it themselves. Don't fall back
to `xdg-open`/the default browser/global profile — the project-local
profile is the point, not a nice-to-have.

## 3. Tell the user

State what was checked (and how — file read, MCP browser, or manual open)
and the result. If a browser was opened (either way), remind them that
links on the page are relative — clicking around the site works directly
from the opened file, no server required.
