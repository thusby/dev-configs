#!/bin/bash
# migrate-mac.sh - Migrate ~/Developer to ~/Development on Mac
# Run this script on your Mac to unify paths across platforms

set -e

echo "🔄 Mac Migration: Developer → Development"
echo "=========================================="
echo ""

# Check if running on Mac
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: This script is for Mac only"
    echo "   Current OS: $OSTYPE"
    exit 1
fi

# Check if Developer exists
if [ ! -d "$HOME/Developer" ]; then
    echo "✅ ~/Developer doesn't exist - nothing to migrate"
    echo "   (or already migrated)"
    exit 0
fi

# Check if Development already exists
if [ -d "$HOME/Development" ]; then
    echo "⚠️  Warning: ~/Development already exists!"
    echo "   This script will NOT overwrite it."
    echo ""
    echo "   Options:"
    echo "   1. Backup and remove ~/Development first"
    echo "   2. Manually merge directories"
    exit 1
fi

echo "📦 Step 1: Creating backup..."
BACKUP_FILE="$HOME/Desktop/Developer-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf "$BACKUP_FILE" -C "$HOME" Developer/
echo "   ✓ Backup saved to: $BACKUP_FILE"
echo ""

echo "📁 Step 2: Renaming ~/Developer to ~/Development..."
mv "$HOME/Developer" "$HOME/Development"
echo "   ✓ Directory renamed"
echo ""

echo "🔧 Step 3: Updating dotfiles/shell/env.sh..."
if [ -f "$HOME/dotfiles/shell/env.sh" ]; then
    # Backup original
    cp "$HOME/dotfiles/shell/env.sh" "$HOME/dotfiles/shell/env.sh.backup"

    # Update to use consistent path
    cat > "$HOME/dotfiles/shell/env.sh" << 'EOF'
# Platform detection and environment setup
# Consistent path across all platforms (Mac + Linux)

export PROJECTS_DIR="$HOME/Development"

# OS-specific settings
case "$OSTYPE" in
    darwin*)
        export OS_TYPE="macos"
        ;;
    linux*)
        export OS_TYPE="linux"
        ;;
    *)
        export OS_TYPE="unknown"
        ;;
esac

export DOTFILES="$HOME/dotfiles"
EOF

    echo "   ✓ Updated env.sh (backup saved to env.sh.backup)"
else
    echo "   ⚠️  Warning: ~/dotfiles/shell/env.sh not found"
    echo "      You may need to update it manually"
fi
echo ""

echo "🔄 Step 4: Updating chezmoi..."
if command -v chezmoi &> /dev/null; then
    CHEZMOI_DIR="$HOME/.local/share/chezmoi"

    if [ -d "$CHEZMOI_DIR" ]; then
        cd "$CHEZMOI_DIR"

        # Check if Developer directory exists in chezmoi
        if [ -d "Developer" ]; then
            mv Developer Development
            echo "   ✓ Renamed Developer to Development in chezmoi"
        fi

        # Update any references in chezmoi files
        if command -v rg &> /dev/null; then
            rg -l "Developer" . 2>/dev/null | grep -v ".git" | while read file; do
                sed -i '' 's|Developer|Development|g' "$file"
                echo "   ✓ Updated: $file"
            done
        fi

        # Commit changes if it's a git repo
        if [ -d ".git" ]; then
            git add -A
            if git diff --staged --quiet; then
                echo "   ℹ️  No chezmoi changes to commit"
            else
                git commit -m "mac: Rename Developer to Development for consistency"
                echo "   ✓ Changes committed to chezmoi"
            fi
        fi

        cd - > /dev/null
    else
        echo "   ⚠️  Warning: chezmoi directory not found at $CHEZMOI_DIR"
    fi
else
    echo "   ⚠️  Warning: chezmoi not installed"
fi
echo ""

echo "🔗 Step 5: Cloning dev-configs..."
if [ ! -d "$HOME/Development/dev-configs" ]; then
    cd "$HOME/Development"
    git clone git@github.com:thusby/dev-configs.git
    echo "   ✓ dev-configs cloned"
else
    echo "   ℹ️  dev-configs already exists"
fi
echo ""

echo "🧪 Step 6: Verification..."
echo ""

# Test PROJECTS_DIR
source "$HOME/dotfiles/shell/env.sh" 2>/dev/null || true
echo "   PROJECTS_DIR=$PROJECTS_DIR"
if [ "$PROJECTS_DIR" = "$HOME/Development" ]; then
    echo "   ✓ PROJECTS_DIR is correct"
else
    echo "   ⚠️  PROJECTS_DIR may need manual check"
fi
echo ""

# Test directory structure
if [ -d "$HOME/Development/projects" ]; then
    echo "   ✓ ~/Development/projects exists"
    echo "     Projects found:"
    ls -1 "$HOME/Development/projects" | head -5 | sed 's/^/       - /'
else
    echo "   ⚠️  ~/Development/projects not found"
fi
echo ""

if [ -d "$HOME/Development/dev-configs" ]; then
    echo "   ✓ ~/Development/dev-configs exists"
else
    echo "   ⚠️  ~/Development/dev-configs not found"
fi
echo ""

# Test symlinks to secrets
echo "   Checking symlinks to secrets:"
BROKEN_LINKS=0
find "$HOME/Development/projects" -maxdepth 3 -type l 2>/dev/null | while read link; do
    if [ ! -e "$link" ]; then
        echo "     ⚠️  Broken: $link"
        BROKEN_LINKS=$((BROKEN_LINKS + 1))
    fi
done

if [ $BROKEN_LINKS -eq 0 ]; then
    echo "     ✓ All symlinks are valid (or none found)"
fi
echo ""

echo "=========================================="
echo "✅ Migration Complete!"
echo ""
echo "Summary:"
echo "  - Renamed: ~/Developer → ~/Development"
echo "  - Updated: dotfiles/shell/env.sh"
echo "  - Updated: chezmoi (if installed)"
echo "  - Cloned: dev-configs"
echo "  - Backup: $BACKUP_FILE"
echo ""
echo "Next steps:"
echo "  1. Open a new terminal to load updated env.sh"
echo "  2. Test: echo \$PROJECTS_DIR"
echo "  3. Test: cd \$PROJECTS_DIR/projects/mcp-common"
echo "  4. Check symlinks: ls -la \$PROJECTS_DIR/projects/*/\.env"
echo ""
echo "If everything works:"
echo "  - You can delete the backup: rm $BACKUP_FILE"
echo "  - Push chezmoi changes: cd ~/.local/share/chezmoi && git push"
echo ""
echo "If something breaks:"
echo "  - Restore: tar -xzf $BACKUP_FILE -C ~"
echo "  - Restore env.sh: cp ~/dotfiles/shell/env.sh.backup ~/dotfiles/shell/env.sh"
echo ""
