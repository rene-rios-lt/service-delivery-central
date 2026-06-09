#!/usr/bin/env bash
# Fired by a PostToolUse hook after 'gh pr merge' succeeds.
# Extracts the story ID from the merged PR's head branch and crosses it out
# in docs/stories/execution-plan.md in the central repo.

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

# Fallback: try each working repo
if [ -z "$branch" ] && [ -n "$pr_num" ]; then
  for repo_dir in \
    "$CENTRAL_REPO/service-delivery-backend" \
    "$CENTRAL_REPO/service-delivery-frontend" \
    "$CENTRAL_REPO/service-delivery-simulator"; do
    if [ -d "$repo_dir" ]; then
      branch=$(cd "$repo_dir" && gh pr view "$pr_num" --json headRefName -q '.headRefName' 2>/dev/null || true)
      [ -n "$branch" ] && break
    fi
  done
fi

[ -z "$branch" ] && exit 0

# Extract story ID: feature/BE-025-... -> BE-025
story_id=$(echo "$branch" | grep -oE '(BE|FE|SIM)-[0-9]+' || true)
[ -z "$story_id" ] && exit 0

# Apply strikethrough to the matching row in execution-plan.md
python3 - "$story_id" "$PLAN" <<'PYEOF'
import re, sys

story_id = sys.argv[1]
plan_file = sys.argv[2]

with open(plan_file, 'r') as f:
    content = f.read()

# Match a table row that contains the story ID and is NOT already struck through
pattern = r'\| (' + re.escape(story_id) + r') \| ([^|~\n]+?) \| ([^|~\n]+?) \|'

def strike(m):
    return '| ~~' + m.group(1) + '~~ | ~~' + m.group(2).strip() + '~~ | ~~' + m.group(3).strip() + '~~ |'

new_content = re.sub(pattern, strike, content)

if content != new_content:
    with open(plan_file, 'w') as f:
        f.write(new_content)
    print('Crossed out ' + story_id + ' in execution-plan.md')
PYEOF
