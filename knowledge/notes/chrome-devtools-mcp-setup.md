---
type: Design Note
title: chrome-devtools MCP setup — project-local Node.js and Chrome profile
description: Google's official chrome-devtools MCP server is registered at local scope for this project, using a project-local Node.js runtime and Chrome profile instead of any system-wide install, plus the stale-SingletonLock failure mode hit while setting it up.
tags: [design-note, mcp, browser, node]
timestamp: 2026-07-01
---

# `chrome-devtools` MCP setup

This project has Google's official [`chrome-devtools-mcp`](https://github.com/ChromeDevTools/chrome-devtools-mcp)
server registered, giving Claude direct browser tools (`navigate_page`,
`take_screenshot`, `take_snapshot`, `list_console_messages`,
`list_network_requests`, `evaluate_script`, etc. — 30 tools total) for
inspecting real rendered output. Per [`file://`-relative preview](file-relative-preview.md)
and the `build-preview` skill, this is reserved for genuinely visual/runtime
checks (rendering, CSS, screenshots, console/network) — content/structure
questions (does a link point where it should, is the title text correct)
should read the generated HTML or trace `generator.m4` directly instead;
the browser is comparatively slow and heavyweight.

**None of this configuration lives in the repo** — it's registered at
Claude Code's `local` MCP scope (`~/.claude.json`, keyed to this project's
path, never committed) specifically so it stays private to whoever set it
up and isn't inherited by anyone who clones this repo. The only in-repo
trace is two gitignored directories.

## Why project-local Node.js and Chrome profile, not system-wide

- **`.claude/node/`** — a Node.js runtime extracted directly from a
  `nodejs.org` release tarball (not `apt`, not NodeSource, not `nvm`),
  checksum-verified against the release's own `SHASUMS256.txt` before
  extracting. No `sudo`, no system package manager involved.
- **`.claude/chrome-profile/`** — a Chrome profile directory passed via
  `--user-data-dir`, kept separate from any real personal Chrome profile.

Both choices were deliberate, not incidental: keeping tooling scoped inside
the project directory means restricting an agent's filesystem access to
this project doesn't break the MCP server, and avoids touching global
system state (installed packages, the user's real browser profiles) for
something that's purely a development aid.

`chrome-devtools-mcp` requires Node **≥20.19.0** — confirmed by actually
running it against this machine's apt-repo Node.js (18.19.1), which failed
immediately with an explicit version-floor error. Don't assume a README's
stated minimum version without testing; the project-local Node.js
(currently v24.18.0, current LTS at setup time) satisfies this comfortably.

## The exact registration

```
claude mcp add chrome-devtools --scope local \
  --env PATH="<project>/.claude/node/bin:$PATH" \
  -- <project>/.claude/node/bin/npx -y chrome-devtools-mcp@latest \
     --executable-path=/usr/bin/google-chrome \
     --user-data-dir=<project>/.claude/chrome-profile \
     --no-performance-crux --no-usage-statistics
```

- `--executable-path` points at the real, already-installed `google-chrome`
  binary (a normal `.deb` package here, not a snap) rather than a bundled
  Chromium.
- The explicit `--env PATH=...` is required because `npm`/`npx` are shell
  scripts with a `#!/usr/bin/env node` shebang — they fail to even start
  ("`/usr/bin/env: 'node': No such file or directory`") if `node` isn't on
  `PATH` *for that spawned process specifically*, independent of whether
  it's on the caller's own shell `PATH`.
- `--no-performance-crux --no-usage-statistics` opt out of the server's
  default telemetry (sending performance-trace URLs to Google's CrUX API,
  collecting usage statistics) — not required for the server to function,
  added on request once the defaults were noticed in its startup banner.

## Known failure mode: stale `SingletonLock`

Chrome's own single-instance lock (`SingletonLock`, a symlink named
`<hostname>-<pid>`, plus `SingletonSocket`/`SingletonCookie`) can go stale
inside `.claude/chrome-profile/` if the MCP server process is killed
abruptly (`kill`/`pkill`) instead of shutting down cleanly — which is
exactly what happens if you interrupt a manual test invocation. Symptom:
`claude mcp list`/`claude mcp get` report `✔ Connected` (the JSON-RPC
handshake alone succeeds), but the server never actually launches Chrome
and exposes **zero tools** — `ToolSearch` for `mcp__chrome-devtools__*`
finds nothing even after a full session restart, because tool discovery
happens once at session start and a broken-but-"connected" server just
silently advertises no tools.

**Diagnosis:** send a real MCP `initialize` + `tools/list` handshake to the
server directly (bypassing Claude Code) and watch for it to hang/timeout
rather than return a tool list — that's what surfaced this, not the
`Connected` status.

**Fix:**
```sh
LOCK_PID=$(readlink .claude/chrome-profile/SingletonLock | grep -oE '[0-9]+$')
ps -p "$LOCK_PID" || rm -f .claude/chrome-profile/SingletonLock \
                           .claude/chrome-profile/SingletonSocket \
                           .claude/chrome-profile/SingletonCookie
```
Only remove the lock files if the referenced PID is confirmed dead — never
remove a lock for a still-running process.

See also: [`file://`-relative preview](file-relative-preview.md),
[`make publish` — post-publish verification with the browser](publish-target.md).
