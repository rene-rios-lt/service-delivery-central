#!/usr/bin/env bash
# worktree.sh — create or remove per-story git worktrees and launch a Claude
# session for each, for fast parallel story work.
#
# Worktrees live INSIDE the central repo at .worktrees/<STORY-ID> — gitignored
# and excluded from all AI analysis via .claude/settings.json (permissions.deny).
# Each `create` opens a new Terminal.app window already running `claude
# "/master <STORY-ID>"`, so a story goes from idea to running pipeline in one
# command.
#
# Usage:
#   worktree.sh create <STORY-ID> [<STORY-ID> ...]
#   worktree.sh remove <STORY-ID> [<STORY-ID> ...]
#   worktree.sh remove --merged          # sweep every merged story worktree
#   worktree.sh <STORY-ID> [...]         # bare ids default to `create`
#
# Story ids: BE-### / FE-### / SIM-### / BUG-### (BUG resolves its repo from
# the "Repo / Area" line in docs/stories/bug.md).
#
# Env:
#   SD_WORKTREES_DIR        override worktree root (default: <central>/.worktrees)
#   SD_WORKTREE_NO_LAUNCH=1 skip opening Terminal (print the command instead)
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
  local id="$1" repo
  case "${id%%-*}" in
    BE)  repo="service-delivery-backend" ;;
    FE)  repo="service-delivery-frontend" ;;
    SIM) repo="service-delivery-simulator" ;;
    BUG) repo="service-delivery-$(area_for_bug "$id")" ;;
    *)   die "unrecognised prefix in '$id' (expected BE-/FE-/SIM-/BUG-)" ;;
  esac
  echo "$CENTRAL/$repo"
}

# backend|frontend|simulator from a bug's "Repo / Area" line
area_for_bug() {
  local id="$1" area
  area="$(awk -v id="$id" '
    $0 ~ "^## "id" " {f=1}
    f && /Repo \/ Area/ {print; exit}
  ' "$STORIES_DIR/bug.md" 2>/dev/null \
    | grep -oiE 'backend|frontend|simulator' | head -1 | tr '[:upper:]' '[:lower:]')"
  [ -n "$area" ] || die "$id: could not resolve Repo / Area from bug.md"
  echo "$area"
}

story_file_for_id() {
  case "${1%%-*}" in
    BE)  echo "$STORIES_DIR/backend.md" ;;
    FE)  echo "$STORIES_DIR/frontend.md" ;;
    SIM) echo "$STORIES_DIR/simulator.md" ;;
    BUG) echo "$STORIES_DIR/bug.md" ;;
  esac
}

# branch name derived from the story heading: feature/<id>-<kebab-title>
# (fix/ for BUG-). Errors out if the id is not in the backlog (typo guard).
branch_for_id() {
  local id="$1" file title slug kind
  file="$(story_file_for_id "$id")"
  # stories: '### BE-001 — Title'  bugs: '## BUG-001 — Title'
  title="$(grep -m1 -E "^#{2,3} ${id} " "$file" 2>/dev/null \
            | sed -E "s/^#{2,3} ${id} (—|-)[[:space:]]*//")" || true
  [ -n "$title" ] || die "$id: not found in $(basename "$file") — check the id"
  slug="$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' \
            | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
  case "${id%%-*}" in BUG) kind="fix" ;; *) kind="feature" ;; esac
  echo "$kind/$id-$slug"
}

# normalise an argument to a bare story id, or fail
require_id() {
  local id
  id="$(printf '%s' "$1" | grep -oE '(BE|FE|SIM|BUG)-[0-9]+' || true)"
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

    launch_session "$id" "$path"
  done
}

launch_session() {
  local id="$1" path="$2" inner esc ascript
  inner="cd \"$path\" && claude \"/master $id\""
  if [ "${SD_WORKTREE_NO_LAUNCH:-0}" = "1" ]; then
    info "$id: (no-launch) would run: $inner"
    return 0
  fi
  # escape backslashes then double-quotes for embedding in an AppleScript string
  esc="${inner//\\/\\\\}"; esc="${esc//\"/\\\"}"
  ascript="tell application \"Terminal\" to do script \"$esc\""
  if osascript -e "$ascript" >/dev/null 2>&1; then
    info "$id: opened Terminal window → /master $id"
  else
    die "$id: could not open Terminal.app (macOS only). Worktree is ready at $path"
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
    id="$(printf '%s' "$(basename "$d")" | grep -oE '(BE|FE|SIM|BUG)-[0-9]+' || true)"
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

# --- dispatch --------------------------------------------------------------

[ $# -ge 1 ] || die "usage: worktree.sh {create|remove} <STORY-ID>... | remove --merged | <STORY-ID>..."

case "$1" in
  create) shift; [ $# -ge 1 ] || die "create needs at least one story id"; do_create "$@" ;;
  remove) shift; [ $# -ge 1 ] || die "remove needs a story id or --merged"; do_remove "$@" ;;
  *)      do_create "$@" ;;
esac
