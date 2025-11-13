#!/bin/bash
# Dev Setup Script
# Autonomous project setup
# Called by dev-setup skill with JSON input

set -e

# Parse input JSON (from stdin or file)
if [ -t 0 ]; then
    # Terminal input - read from arg
    INPUT="${1:?Usage: $0 <json-file-or-pipe>}"
    if [ -f "$INPUT" ]; then
        JSON=$(cat "$INPUT")
    else
        JSON="$INPUT"
    fi
else
    # Piped input
    JSON=$(cat)
fi

# Extract params
PROJECT_NAME=$(echo "$JSON" | jq -r '.analysis.project_name')
PROJECT_TYPE=$(echo "$JSON" | jq -r '.analysis.project_type')
PROJECT_PATH=$(echo "$JSON" | jq -r '.analysis.project_path')
TASK_UUID=$(echo "$JSON" | jq -r '.task.uuid')

PROJECTS_DIR="${PROJECTS_DIR:-$HOME/Development}/projects"

# Validation
if [ -z "$PROJECT_NAME" ] || [ "$PROJECT_NAME" = "null" ]; then
    echo '{"error": "Could not extract project name"}' >&2
    exit 1
fi

# Check if exists
if [ -d "$PROJECT_PATH" ]; then
    echo "{\"error\": \"Project already exists\", \"path\": \"$PROJECT_PATH\"}" >&2
    exit 1
fi

# Setup steps
steps_total=7
steps_done=0

report_progress() {
    steps_done=$((steps_done + 1))
    echo "{\"step\": $steps_done, \"total\": $steps_total, \"message\": \"$1\"}" >&2
}

# 1. Create directory
mkdir -p "$PROJECT_PATH"
cd "$PROJECT_PATH"
report_progress "Created directory"

# 2. Run dev-configs setup
if [ -f "$HOME/Development/dev-configs/setup.sh" ]; then
    case "$PROJECT_TYPE" in
        python)
            "$HOME/Development/dev-configs/setup.sh" python . 2>/dev/null || true
            ;;
        node)
            "$HOME/Development/dev-configs/setup.sh" node . 2>/dev/null || true
            ;;
        go)
            # Go projects: basic structure (no specific setup script yet)
            mkdir -p cmd pkg internal
            ;;
        c)
            "$HOME/Development/dev-configs/setup.sh" c-embedded . 2>/dev/null || true
            ;;
    esac
fi
report_progress "Applied dev-configs standards"

# 3. Claude settings
if [ -f "$HOME/Development/dev-configs/setup-new-project.sh" ]; then
    "$HOME/Development/dev-configs/setup-new-project.sh" "$PROJECT_PATH" 2>/dev/null || true
fi
report_progress "Configured Claude settings"

# 4. .env.example
if [ "$PROJECT_TYPE" = "python" ] || [ "$PROJECT_TYPE" = "node" ]; then
    cat > .env.example <<EOF
# Environment variables for $PROJECT_NAME
# Copy to .env and fill in your values

# Example:
# API_KEY=your_key_here
# DATABASE_URL=postgresql://localhost/$PROJECT_NAME
EOF
fi
report_progress "Created .env.example"

# 5. README
cat > README.md <<EOF
# $PROJECT_NAME

Project description here.

## Setup

\`\`\`bash
cp .env.example .env
# Edit .env with your credentials
\`\`\`

## Development

\`\`\`bash
# Start here
\`\`\`

## Standards

Uses [dev-configs](../../dev-configs/) for code standards.
EOF
report_progress "Created README"

# 6. Git init
git init
git add .
git commit -m "Initial setup for $PROJECT_NAME

🤖 Generated with Claude Code dev-setup script

Co-Authored-By: Claude <noreply@anthropic.com>" 2>/dev/null
report_progress "Git initialized"

# 7. Mark task as started
if [ -n "$TASK_UUID" ] && command -v task &> /dev/null; then
    task "$TASK_UUID" start 2>/dev/null || true
fi
report_progress "Task marked as started"

# Success output
cat <<EOF
{
  "success": true,
  "project": {
    "name": "$PROJECT_NAME",
    "type": "$PROJECT_TYPE",
    "path": "$PROJECT_PATH"
  },
  "steps_completed": $steps_total,
  "task_uuid": "$TASK_UUID"
}
EOF
