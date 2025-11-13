#!/bin/bash
# Update Claude Code settings for all projects
# Usage: ./update-all-projects.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_DIR="$HOME/Development"

echo "🔄 Updating Claude Code settings for all projects"
echo ""

# Find all projects with .claude/settings.local.json
PROJECTS=()
while IFS= read -r -d '' settings_file; do
    project_dir=$(dirname "$(dirname "$settings_file")")
    PROJECTS+=("$project_dir")
done < <(find "$DEV_DIR/projects" -name "settings.local.json" -path "*/.claude/*" -print0 2>/dev/null)

if [ ${#PROJECTS[@]} -eq 0 ]; then
    echo "❌ No projects found with .claude/settings.local.json"
    exit 1
fi

echo "📦 Found ${#PROJECTS[@]} projects:"
for project in "${PROJECTS[@]}"; do
    echo "   • $(basename "$project")"
done
echo ""

read -p "Update all these projects? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Aborted"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SUCCESS=0
SKIPPED=0
FAILED=0

for project in "${PROJECTS[@]}"; do
    echo ""
    echo "📂 $(basename "$project")"
    if "$SCRIPT_DIR/update-project-settings.sh" "$project"; then
        ((SUCCESS++))
    else
        echo "⚠️  Failed to update $(basename "$project")"
        ((FAILED++))
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
done

echo ""
echo "📊 Summary:"
echo "   ✅ Updated: $SUCCESS"
echo "   ⚠️  Failed:  $FAILED"
echo ""
echo "💡 Review changes and commit when ready"
