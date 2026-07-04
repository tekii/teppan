#!/usr/bin/env bash
# b3-fleet.sh -- B3 multi-agent launcher/integrator.
# See knowledge/notes/parallel-agent-worktrees.md ("The B3 delta", "Who launches
# the agents").
#
# One hardened container, N git worktrees, N `claude` processes under tmux.
# Worktrees are provisioned as siblings OUTSIDE /workspaces/www (container-local,
# ephemeral working tree); their commits land in the bind-mounted, host-persisted
# .git (the "durable spine"). The integrator merges each agent/<task> into master
# on the main checkout, gated on `make test`, then removes the worktree.
#
# Subcommands:
#   provision <task> [base]   git worktree add /workspaces/wt-<task> -b agent/<task> [base=master]
#   spawn     <task>          launch `claude` in that worktree under tmux (shared CLAUDE_CONFIG_DIR)
#   up        <task> [base]   provision + spawn
#   integrate <task>          make test (worktree) -> merge --no-ff to master -> make test (master)
#   teardown  <task>          kill tmux, worktree remove --force, branch -D, worktree prune
#   list                      worktrees + agent tmux sessions
set -euo pipefail

MAIN=/workspaces/www
WT_DIR=/workspaces                 # worktrees at $WT_DIR/wt-<task>, OUTSIDE $MAIN
BASE_BRANCH=${BASE_BRANCH:-master}

die(){ echo "b3-fleet: $*" >&2; exit 1; }
wt_path(){ echo "$WT_DIR/wt-$1"; }
br(){ echo "agent/$1"; }

require_container(){
  [ "${TEPPAN_IN_CONTAINER:-}" = 1 ] || die "run inside the dev container (TEPPAN_IN_CONTAINER unset)."
}

provision(){
  local task=${1:?task name required} base=${2:-$BASE_BRANCH} p; p=$(wt_path "$task")
  case "$p" in "$MAIN"|"$MAIN"/*) die "worktree path must be OUTSIDE $MAIN (got $p)";; esac
  [ -e "$p" ] && die "$p already exists"
  # Creates a NEW branch ref (agent/<task>) + a linked worktree HEAD -- neither is
  # the main checkout's HEAD/current branch, so the reference-transaction guard
  # does not fire here.
  git -C "$MAIN" worktree add "$p" -b "$(br "$task")" "$base"
  echo "provisioned $p on $(br "$task") (base $base)"
}

spawn(){
  local task=${1:?task name required} p; p=$(wt_path "$task")
  [ -d "$p" ] || die "no worktree for '$task' -- run: $0 provision $task"
  command -v tmux >/dev/null || die "tmux not found"
  tmux has-session -t "agent-$task" 2>/dev/null && die "tmux session agent-$task already running"
  # CLAUDE_CONFIG_DIR is left at the container default (shared ~/.claude) on
  # purpose: all agents share memory + the once-registered Playwright MCP; grants
  # don't collide (settings.local.json is path-keyed, bypassPermissions uniform).
  tmux new-session -d -s "agent-$task" -c "$p" "claude ${CLAUDE_ARGS:-}"
  echo "spawned tmux 'agent-$task' in $p   (attach: tmux attach -t agent-$task)"
}

up(){ provision "$@"; spawn "$1"; }

integrate(){
  local task=${1:?task name required} b p; b=$(br "$task"); p=$(wt_path "$task")
  [ -d "$p" ] || die "no worktree for '$task'"
  # Integrator invariant: the main checkout stays ON $BASE_BRANCH; we never
  # checkout here (that shared-HEAD move is exactly what the guards forbid) -- we
  # only ADVANCE the branch via merge, which the reference-transaction guard
  # allows through the inline TEPPAN_MAIN_HEAD_OK=1 override.
  local on; on=$(git -C "$MAIN" symbolic-ref --quiet --short HEAD || true)
  [ "$on" = "$BASE_BRANCH" ] || die "main checkout is on '$on', expected '$BASE_BRANCH' -- fix before integrating"
  echo ">> gate: make test in $p"
  ( cd "$p" && make test ) || die "worktree tests FAILED -- not merging $b"
  echo ">> merge --no-ff $b into $BASE_BRANCH"
  TEPPAN_MAIN_HEAD_OK=1 git -C "$MAIN" merge --no-ff "$b" -m "integrate $b" \
    || die "merge failed (conflict?) -- resolve manually; nothing torn down"
  echo ">> gate: make test on $MAIN (post-merge)"
  if ! ( cd "$MAIN" && make test ); then
    echo "!! post-merge tests FAILED -- rolling back the merge" >&2
    TEPPAN_MAIN_HEAD_OK=1 git -C "$MAIN" reset --hard ORIG_HEAD
    die "integration of $b reverted"
  fi
  echo "integrated $b (OK)  ->  run: $0 teardown $task"
}

teardown(){
  local task=${1:?task name required} b p; b=$(br "$task"); p=$(wt_path "$task")
  tmux kill-session -t "agent-$task" 2>/dev/null || true
  git -C "$MAIN" worktree remove --force "$p" 2>/dev/null || true
  git -C "$MAIN" branch -D "$b" 2>/dev/null || true
  git -C "$MAIN" worktree prune
  echo "torn down $task"
}

list(){
  echo "== worktrees =="; git -C "$MAIN" worktree list
  echo "== agent tmux sessions =="; tmux ls 2>/dev/null | grep '^agent-' || echo "(none)"
}

require_container
cmd=${1:-}; [ $# -gt 0 ] && shift
case "$cmd" in
  provision) provision "$@";;
  spawn)     spawn "$@";;
  up)        up "$@";;
  integrate) integrate "$@";;
  teardown)  teardown "$@";;
  list)      list "$@";;
  *) die "usage: $0 {provision|spawn|up|integrate|teardown|list} <task> [base]";;
esac
