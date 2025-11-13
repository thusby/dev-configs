#!/bin/bash
# Task Analyzer Script
# Analyzes taskwarrior tasks for setup/project keywords
# Called by task-analyzer skill
# Returns JSON with task details and suggestions

set -e

SIGNAL_FILE="${1:-$HOME/.cache/claude-events/task-setup-detected.json}"

# Check if signal file exists
if [ ! -f "$SIGNAL_FILE" ]; then
    echo '{"error": "No signal file found"}' >&2
    exit 1
fi

# Read signal file
TASK_UUID=$(jq -r '.task.uuid' "$SIGNAL_FILE")
TASK_DESC=$(jq -r '.task.description' "$SIGNAL_FILE")
TASK_TAGS=$(jq -r '.task.tags' "$SIGNAL_FILE")

# Extract project name
extract_project_name() {
    local desc="$1"

    # Try various patterns
    if echo "$desc" | grep -qiE ':\s*\S+'; then
        # "Setup new X project: NAME"
        echo "$desc" | sed -E 's/.*:\s*(\S+).*/\1/'
    elif echo "$desc" | grep -qiE '^(initialize|create)\s+\S+'; then
        # "Initialize NAME" or "Create NAME"
        echo "$desc" | sed -E 's/^(initialize|create)\s+(\S+).*/\2/i'
    else
        # Fallback: last word
        echo "$desc" | awk '{print $NF}'
    fi
}

# Detect project type
detect_project_type() {
    local text="$1 $2"  # description + tags
    text=$(echo "$text" | tr '[:upper:]' '[:lower:]')

    if echo "$text" | grep -qE 'python|django|flask|fastapi|mcp'; then
        echo "python"
    elif echo "$text" | grep -qE 'node|javascript|typescript|vue|react|npm'; then
        echo "node"
    elif echo "$text" | grep -qE '\bgo\b|golang'; then
        echo "go"
    elif echo "$text" | grep -qE '\bc\b|embedded|stm32|zephyr|arduino'; then
        echo "c"
    elif echo "$text" | grep -qE 'rust|cargo'; then
        echo "rust"
    else
        echo "python"  # default
    fi
}

# Check if project directory already exists
check_project_exists() {
    local name="$1"
    local projects_dir="${PROJECTS_DIR:-$HOME/Development}/projects"

    if [ -d "$projects_dir/$name" ]; then
        echo "true"
    else
        echo "false"
    fi
}

# Main
PROJECT_NAME=$(extract_project_name "$TASK_DESC")
PROJECT_TYPE=$(detect_project_type "$TASK_DESC" "$TASK_TAGS")
PROJECT_EXISTS=$(check_project_exists "$PROJECT_NAME")
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/Development}/projects"

# Output JSON
cat <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "task": {
    "uuid": "$TASK_UUID",
    "description": "$TASK_DESC",
    "tags": "$TASK_TAGS"
  },
  "analysis": {
    "project_name": "$PROJECT_NAME",
    "project_type": "$PROJECT_TYPE",
    "project_exists": $PROJECT_EXISTS,
    "project_path": "$PROJECTS_DIR/$PROJECT_NAME"
  },
  "recommendations": {
    "action": "setup",
    "script": "~/Development/dev-configs/scripts/dev-setup.sh"
  }
}
EOF
