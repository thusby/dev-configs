#!/bin/bash
# Sync Check Script
# Verifies sync status across dotfiles, dev-configs, and chezmoi
# Called by sync-check skill
# Returns JSON with status

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Initialize result
declare -A results
issues_found=0

# Check dotfiles
check_dotfiles() {
    local status="clean"
    local details=""

    if [ -d ~/dotfiles/.git ]; then
        cd ~/dotfiles

        # Check for uncommitted changes
        if [ -n "$(git status --porcelain)" ]; then
            status="uncommitted"
            details=$(git status --short | head -5)
            issues_found=$((issues_found + 1))
        fi

        # Check if behind origin
        git fetch origin main --quiet 2>/dev/null || true
        if git status | grep -q 'behind'; then
            status="behind"
            issues_found=$((issues_found + 1))
        fi

        # Check if ahead
        if git status | grep -q 'ahead'; then
            status="ahead"
        fi
    else
        status="error"
        details="Not a git repository"
        issues_found=$((issues_found + 1))
    fi

    results[dotfiles_status]="$status"
    results[dotfiles_details]="$details"
}

# Check dev-configs
check_dev_configs() {
    local status="clean"
    local details=""

    if [ -d ~/Development/dev-configs/.git ]; then
        cd ~/Development/dev-configs

        if [ -n "$(git status --porcelain)" ]; then
            status="uncommitted"
            details=$(git status --short | head -5)
            issues_found=$((issues_found + 1))
        fi

        git fetch origin main --quiet 2>/dev/null || true
        if git status | grep -q 'behind'; then
            status="behind"
            issues_found=$((issues_found + 1))
        fi
    else
        status="error"
        details="Not found"
        issues_found=$((issues_found + 1))
    fi

    results[dev_configs_status]="$status"
    results[dev_configs_details]="$details"
}

# Check chezmoi
check_chezmoi() {
    local status="clean"
    local details=""

    if command -v chezmoi &> /dev/null; then
        # Check for unapplied changes (suppress YubiKey errors over SSH)
        local chezmoi_status=$(chezmoi status 2>&1 | grep -v "age: warning\|age: error\|yubikey plugin" || true)

        if [ -n "$chezmoi_status" ]; then
            status="unapplied"
            details=$(echo "$chezmoi_status" | head -3)
            issues_found=$((issues_found + 1))
        fi
    else
        status="not_installed"
        issues_found=$((issues_found + 1))
    fi

    results[chezmoi_status]="$status"
    results[chezmoi_details]="$details"
}

# Check secrets
check_secrets() {
    local status="ok"
    local count=0

    if [ -d ~/dotfiles/secrets ]; then
        count=$(find ~/dotfiles/secrets -type f 2>/dev/null | wc -l)

        if [ "$count" -eq 0 ]; then
            status="empty"
            issues_found=$((issues_found + 1))
        fi
    else
        status="missing"
        issues_found=$((issues_found + 1))
    fi

    results[secrets_status]="$status"
    results[secrets_count]="$count"
}

# Main execution
main() {
    check_dotfiles
    check_dev_configs
    check_chezmoi
    check_secrets

    # Output JSON
    cat <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "issues_found": $issues_found,
  "dotfiles": {
    "status": "${results[dotfiles_status]}",
    "details": "${results[dotfiles_details]}"
  },
  "dev_configs": {
    "status": "${results[dev_configs_status]}",
    "details": "${results[dev_configs_details]}"
  },
  "chezmoi": {
    "status": "${results[chezmoi_status]}",
    "details": "${results[chezmoi_details]}"
  },
  "secrets": {
    "status": "${results[secrets_status]}",
    "count": ${results[secrets_count]}
  }
}
EOF
}

main "$@"
