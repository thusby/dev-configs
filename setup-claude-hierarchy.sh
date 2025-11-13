#!/bin/bash
# Setup Claude Code 3-level permissions hierarchy
# Based on CLAUDE-PERMISSIONS.md

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_DIR="$HOME/Development"

echo "🔧 Setting up Claude Code permissions hierarchy..."

# ============================================================================
# LEVEL 1: Global (via dotfiles symlink)
# ============================================================================
echo ""
echo "📋 Level 1: Global settings (via dotfiles)"

if [ -L "$HOME/.claude/CLAUDE.md" ]; then
    echo "✅ Global CLAUDE.md symlink exists"
    ls -l "$HOME/.claude/CLAUDE.md"
else
    echo "⚠️  Global CLAUDE.md not symlinked - run dotfiles setup first"
fi

# ============================================================================
# LEVEL 2: Development System
# ============================================================================
echo ""
echo "🛠️  Level 2: Development system settings"

mkdir -p "$DEV_DIR/.claude"

DEV_SETTINGS="$DEV_DIR/.claude/settings.local.json"
if [ -f "$DEV_SETTINGS" ]; then
    echo "✅ Development settings exist at $DEV_SETTINGS"
else
    echo "📝 Creating development settings..."
    cp "$SCRIPT_DIR/development-template-settings.local.json" "$DEV_SETTINGS"
    echo "✅ Development settings created"
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Claude Code hierarchy setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📦 Structure:"
echo "   1️⃣  Global:      ~/.claude/CLAUDE.md → dotfiles/claude/"
echo "   2️⃣  Development: $DEV_SETTINGS"
echo "   3️⃣  Project:     [project]/.claude/settings.local.json"
echo ""
echo "🚀 Next steps:"
echo "   • New project:    ./setup-new-project.sh ~/Development/projects/my-project"
echo "   • Update project: ./update-project-settings.sh ~/Development/projects/existing"
echo "   • Update all:     ./update-all-projects.sh"
