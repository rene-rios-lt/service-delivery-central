#!/usr/bin/env bash
# worktree.sh — create or remove per-story git worktrees and launch a Claude
# session for each, for fast parallel story work.
#
# Worktrees live INSIDE the central repo at .worktrees/<STORY-ID> — gitignored
# and excluded from all AI analysis via .claude/settings.json (permissions.deny).
# Each `create` symlinks central's .claude into the worktree (so /master + the
# story-* agents are discoverable there), opens a new Terminal.app window with
# Claude running in the worktree, and sends the `/master <STORY-ID>` command as
# text once the session is up. (It is sent as typed text, not a launch argument:
# a slash-command passed as the startup prompt resolves before project skills
# register and fails with "Unknown command".)
#
# Usage:
#   worktree.sh create <STORY-ID> [<STORY-ID> ...]
#   worktree.sh remove <STORY-ID> [<STORY-ID> ...]
#   worktree.sh remove --merged          # sweep every merged story worktree
#   worktree.sh <STORY-ID> [...]         # bare ids default to `create`
#
# Story ids: BE-### / FE-### / SIM-### / BUG-### / QUAL-### (BUG and QUAL
# resolve their repo from the "Repo / Area" line in docs/stories/bug.md /
# quality.md; a QUAL story with no such line is central-only governance work —
# refused here, it ships via /ship-it).
#
# Env:
#   SD_WORKTREES_DIR        override worktree root (default: <central>/.worktrees)
#   SD_WORKTREE_NO_LAUNCH=1 skip opening Terminal (print the command instead)
#   SD_WORKTREE_LAUNCH_DELAY seconds to wait before sending /master (default 6)
#   SD_WORKTREE_FORCE=1     allow removing a worktree with uncommitted changes
#
# Idempotent. macOS bash 3.2 compatible.
set -euo pipefail

CENTRAL="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKTREES_DIR="${SD_WORKTREES_DIR:-$CENTRAL/.worktrees}"
STORIES_DIR="$CENTRAL/docs/stories"

die()  { echo "worktree: $*" >&2; exit 1; }
info() { echo "worktree: $*"; }

# --- resolution helpers ----------------------------------------------------

# absolute working-repo path for a story id
repo_for_id() {
  local id="$1" repo area
  case "${id%%-*}" in
    BE)  repo="service-delivery-backend" ;;
    FE)  repo="service-delivery-frontend" ;;
    SIM) repo="service-delivery-simulator" ;;
    BUG)
      area="$(area_from_repo_line "$id" bug.md)"
      [ -n "$area" ] || die "$id: could not resolve Repo / Area from bug.md"
      repo="service-delivery-$area" ;;
    QUAL)
      area="$(area_from_repo_line "$id" quality.md)"
      [ -n "$area" ] || die "$id: no Repo / Area line in quality.md — central-only QUAL story; it ships via /ship-it, not /worktree + /master (see docs/stories/quality.md)"
      repo="service-delivery-$area" ;;
    *)   die "unrecognised prefix in '$id' (expected BE-/FE-/SIM-/BUG-/QUAL-)" ;;
  esac
  echo "$CENTRAL/$repo"
}

# backend|frontend|simulator from a story's "- **Repo / Area:**" line in
# docs/stories/<file>. Scans only the story's own section — stops at the next
# H2 heading — so a story with no line never picks up the next story's (that
# absence is meaningful for QUAL: it means central-only). Prints empty when
# absent; callers decide whether that is fatal and with what message.
area_from_repo_line() {
  local id="$1" file="$2" area
  area="$(awk -v id="$id" '
    $0 ~ "^## "id" "    {f=1; next}
    f && /^## /         {exit}
    f && /Repo \/ Area/ {print; exit}
  ' "$STORIES_DIR/$file" 2>/dev/null \
    | grep -oiE 'backend|frontend|simulator' | head -1 | tr '[:upper:]' '[:lower:]' || true)"
  printf '%s\n' "$area"
}

story_file_for_id() {
  case "${1%%-*}" in
    BE)  echo "$STORIES_DIR/backend.md" ;;
    FE)  echo "$STORIES_DIR/frontend.md" ;;
    SIM) echo "$STORIES_DIR/simulator.md" ;;
    BUG) echo "$STORIES_DIR/bug.md" ;;
    QUAL) echo "$STORIES_DIR/quality.md" ;;
  esac
}

# branch name derived from the story heading: feature/<id>-<kebab-title>
# (fix/ for BUG-, feat/ for QUAL- — matching /ship-it's QUAL branch shape so
# the post-merge hook strikes the plan row from either entry point). Errors
# out if the id is not in the backlog (typo guard).
branch_for_id() {
  local id="$1" file title slug kind
  file="$(story_file_for_id "$id")"
  # stories: '### BE-001 — Title'  bugs: '## BUG-001 — Title'
  title="$(grep -m1 -E "^#{2,3} ${id} " "$file" 2>/dev/null \
            | sed -E "s/^#{2,3} ${id} (—|-)[[:space:]]*//")" || true
  [ -n "$title" ] || die "$id: not found in $(basename "$file") — check the id"
  slug="$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' \
            | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
  case "${id%%-*}" in BUG) kind="fix" ;; QUAL) kind="feat" ;; *) kind="feature" ;; esac
  echo "$kind/$id-$slug"
}

# normalise an argument to a bare story id, or fail
require_id() {
  local id
  id="$(printf '%s' "$1" | grep -oE '(BE|FE|SIM|BUG|QUAL)-[0-9]+' || true)"
  [ -n "$id" ] || die "'$1' is not a story id (expected e.g. BE-030)"
  echo "$id"
}

# --- create ----------------------------------------------------------------

do_create() {
  local arg id repo branch path
  for arg in "$@"; do
    id="$(require_id "$arg")"
    repo="$(repo_for_id "$id")"
    [ -d "$repo/.git" ] || die "$id: working repo not found at $repo"
    branch="$(branch_for_id "$id")"
    path="$WORKTREES_DIR/$id"
    mkdir -p "$WORKTREES_DIR"

    if [ -d "$path" ]; then
      info "$id: worktree already exists at $path — reusing"
    else
      info "$id: fetching origin in $(basename "$repo")…"
      git -C "$repo" fetch origin --quiet
      if git -C "$repo" show-ref --verify --quiet "refs/heads/$branch"; then
        info "$id: branch $branch exists — adding worktree on it"
        git -C "$repo" worktree add "$path" "$branch"
      else
        info "$id: creating $branch off origin/main"
        git -C "$repo" worktree add -b "$branch" "$path" origin/main
      fi
    fi

    link_central_claude "$path"
    launch_session "$id" "$path"
  done
}

# Symlink central's .claude into the worktree so its slash-command skills
# (/master) and subagents (story-*) are discoverable from inside the worktree.
# A worktree's git root is the working repo, which has no .claude, and discovery
# does not walk out to the central repo — without this the worktree session has
# no /master. Kept out of the worktree's git status via its local exclude.
link_central_claude() {
  local path="$1" excl
  ln -snf "$CENTRAL/.claude" "$path/.claude"
  excl="$(git -C "$path" rev-parse --git-path info/exclude 2>/dev/null || true)"
  if [ -n "$excl" ] && [ -f "$excl" ] && ! grep -qxF ".claude" "$excl" 2>/dev/null; then
    printf '.claude\n' >> "$excl"
  fi
}

launch_session() {
  local id="$1" path="$2" open_cmd type_cmd esc_open esc_type delay
  # Open Claude BARE in the worktree, then send the /master command as text once
  # the session is up. We do NOT pass "/master <id>" as a launch argument: a
  # project slash-command given as the startup prompt is resolved before project
  # skills register and fails with "Unknown command".
  open_cmd="cd \"$path\" && claude"
  type_cmd="/master $id"
  delay="${SD_WORKTREE_LAUNCH_DELAY:-6}"
  if [ "${SD_WORKTREE_NO_LAUNCH:-0}" = "1" ]; then
    info "$id: (no-launch) would open Terminal at $path and send: $type_cmd"
    return 0
  fi
  esc_open="${open_cmd//\\/\\\\}"; esc_open="${esc_open//\"/\\\"}"
  esc_type="${type_cmd//\\/\\\\}"; esc_type="${esc_type//\"/\\\"}"
  if osascript \
       -e 'tell application "Terminal"' \
       -e 'activate' \
       -e "set t to do script \"$esc_open\"" \
       -e "delay $delay" \
       -e "do script \"$esc_type\" in t" \
       -e 'end tell' >/dev/null 2>&1; then
    info "$id: opened Terminal at $path and sent: $type_cmd"
    info "$id: (if a trust prompt appeared first, just type '$type_cmd' yourself)"
  else
    die "$id: could not open Terminal.app (macOS only). Worktree ready at $path — run 'claude' there, then: $type_cmd"
  fi
}

# --- remove ----------------------------------------------------------------

do_remove() {
  if [ "${1:-}" = "--merged" ]; then
    remove_merged
    return
  fi
  local arg id repo branch
  for arg in "$@"; do
    id="$(require_id "$arg")"
    repo="$(repo_for_id "$id")"
    branch="$(branch_for_id "$id")"
    remove_one "$repo" "$branch" "$WORKTREES_DIR/$id" "$id"
  done
  cleanup_worktrees_dir
}

remove_one() {
  local repo="$1" branch="$2" path="$3" id="$4" force=()
  [ "${SD_WORKTREE_FORCE:-0}" = "1" ] && force=(--force)
  if [ -d "$path" ]; then
    git -C "$repo" worktree remove ${force[@]+"${force[@]}"} "$path" \
      && info "$id: removed worktree $path" \
      || die "$id: worktree has uncommitted changes — push them or re-run with SD_WORKTREE_FORCE=1"
  else
    info "$id: no worktree at $path"
  fi
  git -C "$repo" worktree prune
  if git -C "$repo" show-ref --verify --quiet "refs/heads/$branch"; then
    if git -C "$repo" branch -d "$branch" 2>/dev/null; then
      info "$id: deleted merged branch $branch"
    else
      info "$id: kept branch $branch — not fully merged (delete with: git -C $(basename "$repo") branch -D $branch)"
    fi
  fi
}

remove_merged() {
  [ -d "$WORKTREES_DIR" ] || { info "no $WORKTREES_DIR — nothing to sweep"; return; }
  local d id repo branch
  for d in "$WORKTREES_DIR"/*/; do
    [ -d "$d" ] || continue
    id="$(printf '%s' "$(basename "$d")" | grep -oE '(BE|FE|SIM|BUG|QUAL)-[0-9]+' || true)"
    [ -n "$id" ] || { info "skip $(basename "$d") — not a story worktree"; continue; }
    repo="$(repo_for_id "$id")"
    branch="$(branch_for_id "$id")"
    git -C "$repo" fetch origin --quiet || true
    if git -C "$repo" branch --merged origin/main 2>/dev/null | grep -qE "^[* ]*${branch}$"; then
      remove_one "$repo" "$branch" "$WORKTREES_DIR/$id" "$id"
    else
      info "$id: $branch not merged to origin/main — keeping"
    fi
  done
  cleanup_worktrees_dir
}

cleanup_worktrees_dir() {
  [ -d "$WORKTREES_DIR" ] || return 0
  rmdir "$WORKTREES_DIR" 2>/dev/null && info "removed empty $WORKTREES_DIR" || true
}

# Cross out any merged stories the worktree-merge hook missed. Worktree sessions
# merge PRs from a separate project dir where central's PostToolUse hook does not
# fire, so the plan drifts; this reconciles it against the merged-PR ground truth.
reconcile_plan() {
  local script="$CENTRAL/scripts/utils/reconcile-plan.sh"
  [ -x "$script" ] || return 0
  info "reconciling execution plan with merged PRs…"
  "$script" || true
}

# --- dispatch --------------------------------------------------------------

[ $# -ge 1 ] || die "usage: worktree.sh {create|remove} <STORY-ID>... | remove --merged | <STORY-ID>..."

case "$1" in
  create) shift; [ $# -ge 1 ] || die "create needs at least one story id"; do_create "$@" ;;
  remove) shift; [ $# -ge 1 ] || die "remove needs a story id or --merged"; do_remove "$@"; reconcile_plan ;;
  *)      do_create "$@" ;;
esac
