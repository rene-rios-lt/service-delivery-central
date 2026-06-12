#!/usr/bin/env bash
# Fired by a PostToolUse hook after 'gh pr merge' succeeds.
# Extracts the story/bug ID from the merged PR's head branch and crosses it out
# in docs/stories/execution-plan.md in the central repo.
#
# Handles both story IDs (BE-/FE-/SIM-) and bug IDs (BUG-), and matches the ID
# whether the row's first cell is a bare ID (`| BE-014 |`) or a markdown link
# (`| [BE-014](backend.md) |`, `| [**BUG-001**](bug.md) |`).

PLAN="/Users/rrios/dev/ServiceDelivery/docs/stories/execution-plan.md"
CENTRAL_REPO="/Users/rrios/dev/ServiceDelivery"

input=$(cat)

# Extract PR number from the command: "gh pr merge 15 --merge ..."
cmd=$(echo "$input" | jq -r '.tool_input.command // ""')
pr_num=$(echo "$cmd" | grep -oE '\bgh pr merge [0-9]+' | grep -oE '[0-9]+$' || true)

# Extract GitHub remote URL from the git pull output embedded in the response
response=$(echo "$input" | jq -r '
  .tool_response |
  if type == "string" then .
  elif type == "object" then (.output // .stdout // .result // "")
  else ""
  end // ""
' 2>/dev/null || true)

repo=$(echo "$response" | grep -oE 'github\.com/[^/]+/service-delivery-[a-z]+' | head -1 | sed 's|github.com/||' || true)

# Resolve head branch
branch=""
if [ -n "$pr_num" ] && [ -n "$repo" ]; then
  branch=$(gh pr view "$pr_num" --repo "$repo" --json headRefName -q '.headRefName' 2>/dev/null || true)
fi

# Fallback: try each repo — only accept if branch contains a story/bug ID
if [ -z "$branch" ] && [ -n "$pr_num" ]; then
  for repo_dir in \
    "$CENTRAL_REPO" \
    "$CENTRAL_REPO/service-delivery-backend" \
    "$CENTRAL_REPO/service-delivery-frontend" \
    "$CENTRAL_REPO/service-delivery-simulator"; do
    if [ -d "$repo_dir" ]; then
      candidate=$(cd "$repo_dir" && gh pr view "$pr_num" --json headRefName -q '.headRefName' 2>/dev/null || true)
      if echo "$candidate" | grep -qE '(BE|FE|SIM|BUG)-[0-9]+'; then
        branch="$candidate"
        break
      fi
    fi
  done
fi

[ -z "$branch" ] && exit 0

# Extract ID: feature/BE-025-... -> BE-025 ; fix/BUG-001-... -> BUG-001
story_id=$(echo "$branch" | grep -oE '(BE|FE|SIM|BUG)-[0-9]+' || true)
[ -z "$story_id" ] && exit 0

# Apply strikethrough to the matching row in execution-plan.md.
# Link-aware: matches the ID inside a markdown link or as a bare token, in the
# first table cell only; preserves the link markup inside the ~~ ~~.
python3 - "$story_id" "$PLAN" <<'PYEOF'
import re, sys

story_id = sys.argv[1]
plan_file = sys.argv[2]

with open(plan_file) as f:
    lines = f.readlines()

# Match the ID as a whole token (bare, or inside [..](..) / [**..**](..)),
# not as a prefix of a longer ID (BE-1 must not match BE-14).
id_re = re.compile(r'(?<![A-Za-z0-9-])' + re.escape(story_id) + r'(?![0-9])')

changed = False
out = []
for line in lines:
    stripped = line.rstrip('\n')
    is_row = stripped.startswith('|') and stripped.count('|') >= 4
    cells = stripped.split('|') if is_row else []
    # cells[1] is the first (Story) column; only strike if the ID is there
    # and the row is not already struck through.
    if is_row and len(cells) >= 4 and id_re.search(cells[1]) and '~~' not in stripped:
        new = []
        for i, c in enumerate(cells):
            if i == 0 or i == len(cells) - 1:
                new.append(c)              # outer empties around the row
            else:
                inner = c.strip()
                new.append(f' ~~{inner}~~ ' if inner else c)
        line = '|'.join(new) + '\n'
        changed = True
    out.append(line)

if changed:
    with open(plan_file, 'w') as f:
        f.writelines(out)
    print('Crossed out ' + story_id + ' in execution-plan.md')
PYEOF
