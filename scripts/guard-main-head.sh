#!/usr/bin/env bash
# guard-main-head.sh -- Claude Code PreToolUse deny (harness layer).
#
# The PREVENTIVE front door: denies typed branch-moving git commands
# (checkout/switch/reset) issued from the SHARED main checkout ($WORKSPACE_ROOT)
# BEFORE they run, so nothing is touched. Reads the PreToolUse JSON on stdin and
# emits a deny decision as JSON on stdout.
#
# Scope: ACCIDENTAL, typed only. It matches the command STRING, so git nested in
# a script/make target slips past -- the reference-transaction + post-checkout
# git hooks are the net for those routes. Loaded on host + container (shared
# .claude/settings.json) but gated to the container by TEPPAN_IN_CONTAINER; on
# the host it exits without a decision (allow).
set -uo pipefail
input=$(cat)

# Container-only + Bash-only. WORKSPACE_ROOT (the main checkout path, set in
# devcontainer.json containerEnv) is required; absent => host/misconfig => allow.
[ "${TEPPAN_IN_CONTAINER:-}" = 1 ] || exit 0
[ -n "${WORKSPACE_ROOT:-}" ] || exit 0
[ "$(jq -r '.tool_name // empty' <<<"$input")" = Bash ] || exit 0
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")

# Sanctioned integrator override (inline env prefix on the command).
case "$cmd" in *TEPPAN_MAIN_HEAD_OK=1*) exit 0 ;; esac

# Does the command move a branch/HEAD? switch/reset always; checkout unless it is
# a file-restore form (`git checkout ... -- <path>`). `git restore` is never a
# HEAD move, so it is intentionally not matched.
moves=0
grep -Eq '(^|[;&|(){}[:space:]])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+(switch|reset)([[:space:]]|$)' <<<"$cmd" && moves=1
if grep -Eq '(^|[;&|(){}[:space:]])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+checkout([[:space:]]|$)' <<<"$cmd" \
   && ! grep -Eq 'checkout([[:space:]]+[^[:space:]]+)*[[:space:]]+--([[:space:]]|$)' <<<"$cmd"; then moves=1; fi
[ "$moves" = 1 ] || exit 0

# Aimed at the SHARED main checkout: session cwd is $WORKSPACE_ROOT (NOT a
# sibling wt-* worktree), or the command names it (typed nested `cd &&` route).
aimed=0
case "$cwd" in "$WORKSPACE_ROOT"|"$WORKSPACE_ROOT"/*) aimed=1 ;; esac
case "$cmd" in *"$WORKSPACE_ROOT"*) aimed=1 ;; esac
[ "$aimed" = 1 ] || exit 0

# Name-agnostic message (single quotes, not backticks, so the string is inert);
# $WORKSPACE_ROOT interpolates the real path.
reason="B3 guard: do not run git checkout/switch/reset in the SHARED main checkout ${WORKSPACE_ROOT} -- it moves the one shared HEAD and reverts files under any other session on this checkout (the shared-HEAD trap). Work in your OWN sibling worktree, never in ${WORKSPACE_ROOT}; use 'git restore <file>' for file restores. Sanctioned integrator override: prefix the command with TEPPAN_MAIN_HEAD_OK=1."
jq -n --arg r "$reason" \
  '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
exit 0
