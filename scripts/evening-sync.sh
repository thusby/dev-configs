#!/bin/bash
# Evening Sync Script
# Multi-repo sync orchestration
# Called by sync-orchestrator skill with signal trigger

set -e

# Configuration
REPOS=(
    "$HOME/dotfiles"
    "$HOME/Development/dev-configs"
)

# Output structure
declare -A repo_status

# Check repo for uncommitted changes
check_repo() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")

    if [ ! -d "$repo_path/.git" ]; then
        repo_status["$repo_name"]='{"status":"not_a_repo","path":"'"$repo_path"'"}'
        return
    fi

    cd "$repo_path"

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        local files_changed=$(git status --short | wc -l)
        local summary=$(git status --short | head -5 | sed 's/"/\\"/g')
        repo_status["$repo_name"]="{
            \"status\": \"uncommitted\",
            \"path\": \"$repo_path\",
            \"files_changed\": $files_changed,
            \"summary\": \"$summary\"
        }"
        return
    fi

    # Check for unpushed commits
    local unpushed=$(git log @{u}.. --oneline 2>/dev/null | wc -l || echo 0)
    if [ "$unpushed" -gt 0 ]; then
        local commits=$(git log @{u}.. --oneline | head -3 | sed 's/"/\\"/g')
        repo_status["$repo_name"]="{
            \"status\": \"unpushed\",
            \"path\": \"$repo_path\",
            \"commits_ahead\": $unpushed,
            \"commits\": \"$commits\"
        }"
        return
    fi

    # Check if pull needed
    git fetch --quiet 2>/dev/null || true
    local behind=$(git log ..@{u} --oneline 2>/dev/null | wc -l || echo 0)
    if [ "$behind" -gt 0 ]; then
        repo_status["$repo_name"]="{
            \"status\": \"behind\",
            \"path\": \"$repo_path\",
            \"commits_behind\": $behind
        }"
        return
    fi

    # All clean
    repo_status["$repo_name"]="{
        \"status\": \"clean\",
        \"path\": \"$repo_path\"
    }"
}

# Check for secrets that need re-encryption
check_secrets() {
    local secrets_dir="$HOME/Development/dev-configs/secrets"

    if [ ! -d "$secrets_dir" ]; then
        echo '{"status":"no_secrets_dir"}'
        return
    fi

    # Count .age files
    local age_count=$(find "$secrets_dir" -name "*.age" 2>/dev/null | wc -l)

    # Check if any secrets have been modified but not re-encrypted
    # (This would be indicated by .dec files existing without matching .age)
    local needs_reencrypt=false
    if [ -d "$secrets_dir" ]; then
        while IFS= read -r dec_file; do
            local base=$(basename "$dec_file" .dec)
            local age_file="${dec_file%.dec}.age"
            if [ ! -f "$age_file" ] || [ "$dec_file" -nt "$age_file" ]; then
                needs_reencrypt=true
                break
            fi
        done < <(find "$secrets_dir" -name "*.dec" 2>/dev/null)
    fi

    if [ "$needs_reencrypt" = true ]; then
        echo "{\"status\":\"needs_reencrypt\",\"count\":$age_count}"
    else
        echo "{\"status\":\"ok\",\"count\":$age_count}"
    fi
}

# Main execution
main() {
    # Check all repos
    for repo in "${REPOS[@]}"; do
        check_repo "$repo"
    done

    # Check secrets
    secrets_status=$(check_secrets)

    # Build JSON output
    local repos_json=""
    for repo_name in "${!repo_status[@]}"; do
        repos_json+="\"$repo_name\": ${repo_status[$repo_name]},"
    done
    repos_json=${repos_json%,}  # Remove trailing comma

    # Count issues
    local issues=0
    for status in "${repo_status[@]}"; do
        if echo "$status" | grep -q '"uncommitted"' || \
           echo "$status" | grep -q '"unpushed"' || \
           echo "$status" | grep -q '"behind"'; then
            issues=$((issues + 1))
        fi
    done

    # Check if secrets need attention
    if echo "$secrets_status" | grep -q '"needs_reencrypt"'; then
        issues=$((issues + 1))
    fi

    # Output final JSON
    cat <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "issues_found": $issues,
  "repos": {
    $repos_json
  },
  "secrets": $secrets_status
}
EOF
}

# Run
main
