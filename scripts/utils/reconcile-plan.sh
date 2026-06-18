#!/usr/bin/env bash
# reconcile-plan.sh — cross out every merged story/bug in execution-plan.md.
#
# A backstop for the mark-story-complete.sh PostToolUse hook. That hook fires on
# `gh pr merge` and works from the central checkout, but it does NOT fire when a
# PR is merged from a worktree session: the worktree (.worktrees/<ID>) is a
# separate, freshly-added project directory, so central's project-scoped hook in
# .claude/settings.json is not active there. Merges done from worktrees therefore
# leave the plan stale.
#
# This script reconciles the plan against ground truth: it lists merged PRs across
# all working repos + central, extracts each story/bug ID from the PR head branch,
# and crosses it out via mark-story-complete.sh.
#
# Idempotent — already-struck rows are left untouched.
#
# Usage: reconcile-plan.sh
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CENTRAL="$(cd "$HERE/../.." && pwd)"
MARK="$HERE/mark-story-complete.sh"

command -v gh >/dev/null 2>&1 || { echo "reconcile-plan: gh CLI not found on PATH" >&2; exit 1; }
[ -x "$MARK" ] || { echo "reconcile-plan: $MARK not executable" >&2; exit 1; }

repos=(
  "$CENTRAL"
  "$CENTRAL/service-delivery-backend"
  "$CENTRAL/service-delivery-frontend"
  "$CENTRAL/service-delivery-simulator"
)

# Collect every story/bug ID that has a merged PR.
ids=""
for repo in "${repos[@]}"; do
  [ -d "$repo/.git" ] || continue
  branches="$(cd "$repo" && gh pr list --state merged --limit 300 \
                --json headRefName -q '.[].headRefName' 2>/dev/null || true)"
  for b in $branches; do
    id="$(printf '%s' "$b" | grep -oE '(BE|FE|SIM|BUG)-[0-9]+' || true)"
    [ -n "$id" ] && ids="$ids $id"
  done
done

# De-dup and cross each out (mark-story-complete.sh only prints on a real change).
crossed=0
for id in $(printf '%s\n' $ids | sort -u); do
  out="$("$MARK" "$id" || true)"
  if [ -n "$out" ]; then
    echo "$out"
    crossed=$((crossed + 1))
  fi
done

if [ "$crossed" -eq 0 ]; then
  echo "reconcile-plan: execution plan already up to date"
else
  echo "reconcile-plan: crossed out $crossed merged story/bug row(s)"
fi
