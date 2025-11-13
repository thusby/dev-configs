#!/bin/bash
# Update Claude Code settings for an existing project
# Migrates to 3-level hierarchy by removing duplicate permissions
# Usage: ./update-project-settings.sh /path/to/project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:?Usage: $0 /path/to/project}"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Project directory does not exist: $PROJECT_DIR"
    exit 1
fi

PROJECT_NAME=$(basename "$PROJECT_DIR")
SETTINGS_FILE="$PROJECT_DIR/.claude/settings.local.json"

echo "🔄 Updating Claude Code settings for: $PROJECT_NAME"
echo "   Path: $PROJECT_DIR"
echo ""

if [ ! -f "$SETTINGS_FILE" ]; then
    echo "❌ No settings file found at: $SETTINGS_FILE"
    echo "💡 Use ./setup-new-project.sh instead"
    exit 1
fi

# Create backup
BACKUP_FILE="$SETTINGS_FILE.backup-$(date +%Y%m%d-%H%M%S)"
echo "💾 Creating backup: $(basename "$BACKUP_FILE")"
cp "$SETTINGS_FILE" "$BACKUP_FILE"

echo ""
echo "📊 Current settings:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
grep -E '^\s+"Bash\(|^\s+"WebFetch\(|^\s+"Read\(' "$SETTINGS_FILE" | head -20
TOTAL_PERMS=$(grep -c -E '^\s+"(Bash|WebFetch|Read)\(' "$SETTINGS_FILE" || true)
echo "   ... (total: $TOTAL_PERMS permissions)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check for global duplicates (read-only commands)
GLOBAL_DUPES=$(grep -c -E 'Bash\((cat|ls|pwd|grep|git status|git log|git diff|echo):' "$SETTINGS_FILE" || true)

# Check for development duplicates (write operations)
DEV_DUPES=$(grep -c -E 'Bash\((git add|git commit|git push|docker|npm|pip|mkdir|touch|cp|mv):' "$SETTINGS_FILE" || true)

TOTAL_DUPES=$((GLOBAL_DUPES + DEV_DUPES))

if [ $TOTAL_DUPES -gt 0 ]; then
    echo "⚠️  Found $TOTAL_DUPES potential duplicate permissions:"
    echo "   • $GLOBAL_DUPES global-level (read-only)"
    echo "   • $DEV_DUPES development-level (infrastructure)"
    echo ""
    echo "💡 These should be removed as they're covered by:"
    echo "   • Global: ~/Development/dev-configs/claude-global-settings.json"
    echo "   • Development: ~/Development/.claude/settings.local.json"
    echo ""

    read -p "Show recommended changes? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "🔍 Recommended removals (covered by global):"
        grep -E 'Bash\((cat|ls|pwd|grep|git status|git log|git diff|echo):' "$SETTINGS_FILE" || echo "   (none)"
        echo ""
        echo "🔍 Recommended removals (covered by development):"
        grep -E 'Bash\((git add|git commit|git push|docker|npm|pip|mkdir|touch|cp|mv):' "$SETTINGS_FILE" || echo "   (none)"
        echo ""
    fi

    echo "⚙️  Apply automatic cleanup? This will:"
    echo "   1. Remove common global permissions (cat, ls, git status, etc.)"
    echo "   2. Remove common development permissions (git commit, docker, npm, etc.)"
    echo "   3. Keep project-specific permissions"
    read -p "   Proceed? (y/N) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Create cleaned version
        python3 <<'PYTHON_SCRIPT' "$SETTINGS_FILE"
import sys
import json
import re

settings_file = sys.argv[1]

# Permissions that should be at global level
GLOBAL_PERMS = [
    r'Bash\(cat:',
    r'Bash\(ls:',
    r'Bash\(pwd:',
    r'Bash\(cd:',
    r'Bash\(grep:',
    r'Bash\(find:',
    r'Bash\(echo:',
    r'Bash\(git status:',
    r'Bash\(git log:',
    r'Bash\(git diff:',
    r'Bash\(git show:',
    r'Bash\(git branch:',
    r'Bash\(head:',
    r'Bash\(tail:',
    r'Bash\(wc:',
    r'Bash\(which:',
    r'Bash\(whoami:',
    r'Bash\(env:',
    r'Bash\(df:',
    r'Bash\(ps:',
    r'WebSearch',
    r'WebFetch\(domain:github\.com\)',
    r'WebFetch\(domain:docs\.python\.org\)',
    r'WebFetch\(domain:docs\.anthropic\.com\)',
]

# Permissions that should be at development level
DEV_PERMS = [
    r'Bash\(git add:',
    r'Bash\(git commit:',
    r'Bash\(git push:',
    r'Bash\(git pull:',
    r'Bash\(gh:',
    r'Bash\(mkdir:',
    r'Bash\(touch:',
    r'Bash\(cp:',
    r'Bash\(mv:',
    r'Bash\(docker:',
    r'Bash\(docker compose:',
    r'Bash\(npm:',
    r'Bash\(pip:',
    r'Bash\(python:',
    r'Bash\(node:',
    r'Bash\(systemctl:',
]

ALL_REMOVE = GLOBAL_PERMS + DEV_PERMS

with open(settings_file, 'r') as f:
    content = f.read()

lines = content.split('\n')
filtered_lines = []
removed_count = 0

for line in lines:
    should_remove = False
    for pattern in ALL_REMOVE:
        if re.search(pattern, line):
            should_remove = True
            removed_count += 1
            break

    if not should_remove:
        filtered_lines.append(line)

with open(settings_file, 'w') as f:
    f.write('\n'.join(filtered_lines))

print(f"✅ Removed {removed_count} duplicate permissions")
PYTHON_SCRIPT

        echo "✅ Settings updated!"
    else
        echo "❌ Cleanup skipped"
    fi
else
    echo "✅ No obvious duplicates found!"
    echo "   This project appears to have minimal settings already."
fi

echo ""
echo "📝 Manual review recommended:"
echo "   1. Check: $SETTINGS_FILE"
echo "   2. Ensure only project-specific permissions remain"
echo "   3. Backup available at: $(basename "$BACKUP_FILE")"
echo ""
echo "💡 See CLAUDE-PERMISSIONS.md for examples"
