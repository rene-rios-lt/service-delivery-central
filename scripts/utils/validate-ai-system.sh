#!/usr/bin/env bash
# Validates the AI system (.claude/agents + .claude/skills) for the kind of drift
# that produces NO runtime error but silently degrades a story run: a broken path,
# a stale cross-reference, an agent whose native registration won't load, or a
# registry table that no longer matches the files on disk.
#
# Single source of truth for both `/validate-ai-system` (the skill runs this) and
# the PostToolUse hook that fires after a .claude file is edited.
#
# Two severities:
#   BLOCKING — would break a story run. Exit 1. Must be fixed before /master.
#   WARNING  — drift worth fixing (doc/tool mismatch) but won't break a run. Exit 0.
#
# Flags:
#   --quiet   Hook mode: print nothing when fully clean; still report any finding.
#
# Idempotent and strictly read-only. macOS bash 3.2 compatible (no associative
# arrays, no bash-4 features, guarded empty-array expansion).
set -eo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1

# Example typos that live inside the governance skills ON PURPOSE, illustrating
# what a broken reference looks like. They are not live references — the
# cross-reference scan must never flag them. Keep this list tiny and exact.
EXAMPLE_IGNORE="ac-coverge ac-overage"

# Recognised Claude Code tool names. An entry in `tools:` outside this set is most
# likely a typo (e.g. `Reed`) that silently grants nothing — flagged as a WARNING
# rather than BLOCKING, since the tool roster evolves.
KNOWN_TOOLS="Read Write Edit MultiEdit NotebookEdit Bash BashOutput KillBash KillShell Glob Grep LS WebFetch WebSearch Task Agent TodoWrite ExitPlanMode EnterPlanMode SlashCommand Skill"

# agent name : expected audit file (stage numbering)
AGENT_AUDIT="story-evaluator:01-evaluation.md
story-planner:02-plan.md
story-implementor:03-implementation.md
story-ai-reviewer:04-ai-review.md
story-pr:05-pr.md"

MASTER="./.claude/skills/master/SKILL.md"
CLAUDEMD="./CLAUDE.md"

blocking=()
warnings=()
block() { blocking+=("$1"); }
warn()  { warnings+=("$1"); }

# --- small helpers ---------------------------------------------------------
contains_word() { case " $1 " in *" $2 "*) return 0;; *) return 1;; esac; }

frontmatter() { # print the YAML block between the first two `---` fences
  awk 'NR==1 && $0=="---"{infm=1;next} infm && $0=="---"{exit} infm{print}' "$1"
}
fm_value() { # value of a frontmatter field, trimmed
  frontmatter "$1" | sed -nE "s/^$2:[[:space:]]*(.*)$/\1/p" | head -1 \
    | sed -E 's/[[:space:]]+$//'
}
has_fm_field() { [ -n "$(fm_value "$1" "$2")" ]; }
has_header()   { grep -qxF "$2" "$1"; }
section() { # body of a `## Header` section up to the next `## `
  awk -v h="$1" '$0==h{flag=1;next} /^## /{flag=0} flag' "$2"
}

# ===========================================================================
# 1. Every agent/skill folder must contain its definition file
# ===========================================================================
for d in .claude/agents/*/; do
  [ -d "$d" ] || continue
  [ -f "${d}AGENT.md" ] || block "${d} — no AGENT.md in folder"
done
for d in .claude/skills/*/; do
  [ -d "$d" ] || continue
  [ -f "${d}SKILL.md" ] || block "${d} — no SKILL.md in folder"
done

# ===========================================================================
# 2. AGENT.md — frontmatter, native-registration validity, sections,
#    Required Reading resolution, tool declaration vs use
# ===========================================================================
seen_names=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  folder="$(basename "$(dirname "$f")")"

  for field in name description tools; do
    has_fm_field "$f" "$field" || block "$f — missing frontmatter field: $field"
  done

  # native registration: name must match folder and be unique
  name="$(fm_value "$f" name)"
  if [ -n "$name" ] && [ "$name" != "$folder" ]; then
    block "$f — name '$name' does not match folder '$folder' (subagent registers under name)"
  fi
  if [ -n "$name" ]; then
    contains_word "$seen_names" "$name" && block "duplicate agent name '$name' across two AGENT.md files"
    seen_names="$seen_names $name"
  fi

  # tool names: warn on anything outside the known roster
  tools="$(fm_value "$f" tools | tr ',' ' ')"
  for t in $tools; do
    contains_word "$KNOWN_TOOLS" "$t" || warn "$f — unrecognised tool in tools: '$t' (typo?)"
  done

  # structure
  grep -qE '^# ' "$f" || block "$f — missing top-level heading / persona"
  for h in "## Required Reading" "## Inputs" "## Audit Output" "## Process" "## Output Format"; do
    has_header "$f" "$h" || block "$f — missing section: $h"
  done

  # an agent that declares an audit file MUST be able to write it
  audit_sec="$(section "## Audit Output" "$f")"
  if echo "$audit_sec" | grep -qE '0[1-5]-[a-z-]+\.md'; then
    contains_word "$tools" "Write" || block "$f — declares an audit file but 'Write' is not in tools"
  fi

  # an agent whose body runs shell needs Bash
  if grep -qE '^```(bash|sh)$' "$f"; then
    contains_word "$tools" "Bash" || warn "$f — body contains a shell block but 'Bash' is not in tools"
  fi

  # Required Reading paths resolve
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    [ -f "${p#../}" ] || block "$f — Required Reading ${p} → NOT FOUND"
  done < <(section "## Required Reading" "$f" \
             | grep -oE '\.\./\.claude/skills/[a-z-]+/SKILL\.md' | sort -u)
done < <(find .claude/agents -name AGENT.md | sort)

# ===========================================================================
# 3. SKILL.md — frontmatter + required sections
# ===========================================================================
while IFS= read -r f; do
  [ -z "$f" ] && continue
  has_fm_field "$f" "description" || block "$f — missing frontmatter field: description"
  for h in "## Purpose" "## Repo Adaptations"; do
    has_header "$f" "$h" || block "$f — missing section: $h"
  done
done < <(find .claude/skills -name SKILL.md | sort)

# ===========================================================================
# 4. SKILL cross-references (skip fenced code blocks + documented example typos)
# ===========================================================================
while IFS= read -r f; do
  [ -z "$f" ] && continue
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    contains_word "$EXAMPLE_IGNORE" "$name" && continue
    [ -f ".claude/skills/$name/SKILL.md" ] || block "$f — cross-reference skills/$name/SKILL.md → NOT FOUND"
  done < <(awk '/^```/{fence=!fence;next} !fence' "$f" \
             | grep -oE 'skills/[a-z-]+/SKILL\.md' \
             | sed -E 's#skills/([a-z-]+)/SKILL\.md#\1#' | sort -u)
done < <(find .claude/skills -name SKILL.md | sort)

# ===========================================================================
# 5. Audit-file numbering — each agent declares its expected stage file
# ===========================================================================
while IFS= read -r line; do
  [ -z "$line" ] && continue
  agent="${line%%:*}"; expected="${line##*:}"
  f=".claude/agents/$agent/AGENT.md"
  [ -f "$f" ] || continue
  section "## Audit Output" "$f" | grep -qF "$expected" \
    || block "$agent/AGENT.md — Audit Output does not declare expected $expected"
done <<EOF
$AGENT_AUDIT
EOF

# ===========================================================================
# 6. Registry consistency — master/SKILL.md must reference every agent, and
#    every agent it references must exist (bidirectional)
# ===========================================================================
if [ -f "$MASTER" ]; then
  # forward: every path master names must exist on disk
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    [ -f "$ref" ] || block "master/SKILL.md references $ref which does not exist"
  done < <(grep -oE '\.claude/agents/[a-z-]+/AGENT\.md' "$MASTER" | sort -u)
  # reverse: every agent on disk must be wired into master
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    a="$(basename "$(dirname "$f")")"
    grep -qE "agents/$a/AGENT\.md" "$MASTER" \
      || block "agent '$a' exists but is not referenced in master/SKILL.md (orphan stage)"
  done < <(find .claude/agents -name AGENT.md | sort)
else
  block "master/SKILL.md not found — pipeline orchestrator missing"
fi

# ===========================================================================
# 7. Documentation drift (WARNING) — every agent/skill folder should be listed
#    in the CLAUDE.md registry tables
# ===========================================================================
if [ -f "$CLAUDEMD" ]; then
  for d in .claude/agents/*/ .claude/skills/*/; do
    [ -d "$d" ] || continue
    n="$(basename "$d")"
    grep -qF "$n" "$CLAUDEMD" || warn "CLAUDE.md does not document '$n/' in its registry tables"
  done
fi

# ===========================================================================
# Report
# ===========================================================================
nb=${#blocking[@]}; nw=${#warnings[@]}

if [ "$nb" -eq 0 ] && [ "$nw" -eq 0 ]; then
  [ "$QUIET" -eq 1 ] || echo "Ai System validation passed — no blocking findings, no warnings."
  exit 0
fi

if [ "$nb" -gt 0 ]; then
  echo "AI SYSTEM VALIDATION FAILED"
else
  echo "AI SYSTEM VALIDATION — warnings only (non-blocking)"
fi
echo

if [ "$nb" -gt 0 ]; then
  echo "Blocking ($nb):"
  for item in ${blocking[@]+"${blocking[@]}"}; do echo "  ✗ $item"; done
  echo
fi
if [ "$nw" -gt 0 ]; then
  echo "Warnings ($nw):"
  for item in ${warnings[@]+"${warnings[@]}"}; do echo "  ! $item"; done
  echo
fi

echo "Summary: $nb blocking · $nw warning(s)"
if [ "$nb" -gt 0 ]; then
  echo "Blocking findings must be resolved before running /master."
  exit 1
fi
exit 0
