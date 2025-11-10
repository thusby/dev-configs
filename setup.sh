#!/bin/bash
# Setup script for linking dev-configs into a project
# Usage: ./setup.sh <project-type> <target-dir>
#
# Example:
#   ./setup.sh python ../mcp-common
#   ./setup.sh c-embedded ../zephyr-meta

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_TYPE=$1
TARGET_DIR=$2

if [ -z "$PROJECT_TYPE" ] || [ -z "$TARGET_DIR" ]; then
    echo "Usage: $0 <project-type> <target-dir>"
    echo ""
    echo "Available project types:"
    echo "  python       - Link Python configs (ruff, mypy, pytest)"
    echo "  c-embedded   - Link C/C++ configs (.clang-format, .editorconfig)"
    echo "  node         - Link Node.js configs (future)"
    echo ""
    echo "Example:"
    echo "  $0 python ../mcp-common"
    exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Target directory '$TARGET_DIR' does not exist"
    exit 1
fi

cd "$TARGET_DIR"
TARGET_ABS="$(pwd)"

echo "Setting up $PROJECT_TYPE configs in: $TARGET_ABS"
echo ""

case "$PROJECT_TYPE" in
    python)
        echo "Linking Python configs..."

        # Option: Just document, don't actually symlink pyproject.toml
        # since projects usually need custom [project] section
        echo "  ℹ️  Add to your pyproject.toml:"
        echo ""
        echo "  [tool.ruff]"
        echo "  extend = \"$SCRIPT_DIR/python/pyproject-base.toml\""
        echo ""

        # Create .gitignore if it doesn't exist
        if [ ! -f .gitignore ]; then
            ln -s "$SCRIPT_DIR/git/python.gitignore" .gitignore
            echo "  ✓ Linked .gitignore"
        else
            echo "  ⊘ .gitignore already exists"
        fi
        ;;

    c-embedded)
        echo "Linking C/C++ embedded configs..."

        if [ ! -f .clang-format ]; then
            ln -s "$SCRIPT_DIR/c-embedded/.clang-format" .clang-format
            echo "  ✓ Linked .clang-format"
        else
            echo "  ⊘ .clang-format already exists"
        fi

        if [ ! -f .editorconfig ]; then
            ln -s "$SCRIPT_DIR/c-embedded/.editorconfig" .editorconfig
            echo "  ✓ Linked .editorconfig"
        else
            echo "  ⊘ .editorconfig already exists"
        fi
        ;;

    node)
        echo "Linking Node.js configs..."

        if [ ! -f .gitignore ]; then
            ln -s "$SCRIPT_DIR/git/node.gitignore" .gitignore
            echo "  ✓ Linked .gitignore"
        else
            echo "  ⊘ .gitignore already exists"
        fi

        echo "  ⚠️  ESLint/Prettier configs not yet implemented"
        ;;

    *)
        echo "Error: Unknown project type '$PROJECT_TYPE'"
        exit 1
        ;;
esac

echo ""
echo "✅ Setup complete!"
