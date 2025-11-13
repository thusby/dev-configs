#!/bin/bash
# Setup Claude Code settings for a new project
# Usage: ./setup-new-project.sh /path/to/project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:?Usage: $0 /path/to/project}"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Project directory does not exist: $PROJECT_DIR"
    exit 1
fi

PROJECT_NAME=$(basename "$PROJECT_DIR")

echo "🎯 Setting up Claude Code for: $PROJECT_NAME"
echo "   Path: $PROJECT_DIR"
echo ""

# Create .claude directory
mkdir -p "$PROJECT_DIR/.claude"

# Copy template
SETTINGS_FILE="$PROJECT_DIR/.claude/settings.local.json"

if [ -f "$SETTINGS_FILE" ]; then
    echo "⚠️  Settings already exist: $SETTINGS_FILE"
    read -p "   Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted"
        exit 1
    fi
fi

echo "📝 Creating project settings from template..."
cp "$SCRIPT_DIR/project-template-settings.local.json" "$SETTINGS_FILE"

echo "✅ Project settings created!"
echo ""
echo "📝 Next steps:"
echo "   1. Edit $SETTINGS_FILE"
echo "   2. Remove placeholder: Bash(echo PROJECT_PLACEHOLDER:*)"
echo "   3. Add project-specific permissions only"
echo "   4. Commit to git: git add .claude/settings.local.json"
echo ""
echo "💡 See CLAUDE-PERMISSIONS.md for examples"
