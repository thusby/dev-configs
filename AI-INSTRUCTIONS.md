# AI Assistant Instructions

**Target Audience:** Claude Code, GitHub Copilot, and other AI coding assistants working in Terje Husby's development environment.

**Purpose:** Navigate the complex ecosystem of dotfiles, dev-configs, chezmoi, and cross-platform configuration management.

---

## 🎯 Core Principle

> **"Personal goes in dotfiles, Standards go in dev-configs, Templates go in chezmoi"**

Before making changes, always ask: **Is this personal preference or team standard?**

---

## 📍 Quick Reference: Where Does It Go?

| What | Where | Why | Example |
|------|-------|-----|---------|
| **Personal shell config** | `~/dotfiles/shell/` | User-specific preferences | aliases, functions, prompts |
| **Personal productivity** | `~/dotfiles/` | Individual workflow tools | taskwarrior config, habits |
| **Team code standards** | `~/Development/dev-configs/` | Shared across projects | Python/C formatting rules |
| **Templated configs** | `chezmoi-source/` | Cross-platform with variables | Claude settings with OS detection |
| **Secrets (active)** | `~/dotfiles/secrets/` | git-crypt encrypted | API keys, OAuth tokens |
| **Secrets (future)** | `chezmoi-source/` | Age + YubiKey encrypted | Migration in progress |
| **Project code** | `~/Development/projects/` | Actual development work | Django, Vue, embedded, etc. |

---

## 🗺️ The Ecosystem

```
┌─────────────────────────────────────────────────────┐
│                    USER'S MACHINE                    │
│                   (Mac or Linux)                     │
└──────────────────┬──────────────────────────────────┘
                   │
    ┌──────────────┼──────────────┐
    │              │              │
    ▼              ▼              ▼
┌────────┐   ┌──────────┐   ┌─────────────┐
│dotfiles│   │dev-configs│  │  chezmoi    │
│(git)   │   │  (git)    │  │  (git)      │
└───┬────┘   └─────┬─────┘  └──────┬──────┘
    │              │               │
    │              │               ├─→ Templates
    │              │               ├─→ Secrets (Age)
    │              │               └─→ Applies to ~
    │              │
    │              └─→ Team standards
    │                  (python/, c-embedded/, etc)
    │
    └─→ Personal config + secrets (git-crypt)
        ├─→ shell/
        ├─→ taskwarrior/
        ├─→ task-data/ (synced via git)
        └─→ secrets/ (git-crypt)
```

**See also:** `ECOSYSTEM.md` for detailed architecture diagram.

---

## 🔐 Secrets Management (Dual-Mode Status)

**IMPORTANT:** Two systems are currently active!

### Active System (Primary): git-crypt
- **Location:** `~/dotfiles/secrets/`
- **Encryption:** git-crypt + GPG
- **Status:** ✅ **Currently in use** - This is the source of truth
- **Unlock:** `cd ~/dotfiles && git-crypt unlock`
- **Lock:** Automatic at shutdown via systemd/launchd

### Migration Target: Age + YubiKey (via Chezmoi)
- **Location:** `chezmoi-source/dotfiles/secrets/*.age`
- **Status:** 🔄 Partial migration
- **DO NOT** assume Age is primary yet

**When adding new secrets:**
1. Add to `~/dotfiles/secrets/` (git-crypt) ← **Current method**
2. Optionally mirror to chezmoi (Age) for future
3. Do NOT remove git-crypt versions yet

---

## 🖥️ Cross-Platform Considerations

### Paths
- **Consistent:** `~/Development` on BOTH Mac and Linux (migrated 2025-11)
- **Old:** Mac used `~/Developer` (deprecated)

### Tools Installation
- **Linux:** `apt install` or build from source
- **Mac:** `brew install`

### Automation
- **Linux:** systemd user services (`~/.config/systemd/user/`)
- **Mac:** launchd agents (`~/Library/LaunchAgents/`)

### Shell
- **Linux:** bash (default)
- **Mac:** zsh (default)
- Both supported via dotfiles

---

## 📋 Task Management (Taskwarrior)

### Setup (as of 2025-11-12)
- **Version:** 3.4.2 on both Mac and Linux
- **Format:** SQLite (`taskchampion.sqlite3`)
- **Data location:** `~/dotfiles/task-data/` (synced via git)
- **Config:** `~/dotfiles/taskwarrior/taskrc`

### Tag-Based Organization
```bash
# Machine-specific tasks
task add "Mac-only thing" +mac
task add "Linux-only thing" +linux

# Shared tasks (no tag)
task add "Works everywhere"

# Context switching
task context mac      # Show only Mac tasks
task context linux    # Show only Linux tasks
task context shared   # Show only untagged
task context none     # Show all
```

### Auto-Commit Workflow
1. User works with tasks: `task add`, `task done`
2. User runs `evening` function (or manually)
3. Script auto-commits `task-data/` to git
4. Other machine pulls changes
5. Tasks sync across machines

**DO NOT** manually sync task-data between machines outside of git.

---

## 🛠️ Common Workflows

### Adding Personal Tool Config
```bash
# 1. Add config to dotfiles
~/dotfiles/newtool/config

# 2. Create symlink
ln -s ~/dotfiles/newtool/config ~/.newtoolrc

# 3. Update install.sh to create symlink
# Add to dotfiles/install.sh

# 4. Commit to dotfiles repo
cd ~/dotfiles
git add newtool/ install.sh
git commit -m "Add newtool config"
git push
```

### Adding Team Standard
```bash
# 1. Add to dev-configs
~/Development/dev-configs/newtool/standard-config.yml

# 2. Document in dev-configs/README.md

# 3. Commit to dev-configs repo
cd ~/Development/dev-configs
git add newtool/ README.md
git commit -m "Add newtool standards"
git push
```

### Adding Secret
```bash
# 1. Add to git-crypt protected area
echo "API_KEY=secret" > ~/dotfiles/secrets/.env.newservice

# 2. Symlink to project (via script)
ln -s ~/dotfiles/secrets/.env.newservice ~/Development/projects/myproject/.env

# 3. Add to setup-secrets-symlinks.sh
# Edit ~/dotfiles/scripts/setup-secrets-symlinks.sh

# 4. Commit (git-crypt will encrypt)
cd ~/dotfiles
git add secrets/.env.newservice scripts/setup-secrets-symlinks.sh
git commit -m "Add newservice secrets"
git push
```

---

## 🚨 Common Pitfalls

### ❌ DON'T: Put personal preferences in dev-configs
```bash
# WRONG:
~/Development/dev-configs/shell/my-aliases.sh  # Personal!

# RIGHT:
~/dotfiles/shell/aliases.sh
```

### ❌ DON'T: Put team standards in dotfiles
```bash
# WRONG:
~/dotfiles/python/pyproject.toml  # Should be shared!

# RIGHT:
~/Development/dev-configs/python/pyproject-base.toml
```

### ❌ DON'T: Assume Age encryption is active
```bash
# WRONG:
chezmoi apply  # Expecting secrets to unlock

# RIGHT (for now):
cd ~/dotfiles && git-crypt unlock
```

### ❌ DON'T: Manually edit task-data SQLite
```bash
# WRONG:
sqlite3 ~/dotfiles/task-data/taskchampion.sqlite3

# RIGHT:
task add "Use the CLI"
```

### ❌ DON'T: Commit unencrypted secrets
```bash
# WRONG:
echo "API_KEY=secret" > ~/dotfiles/.env
git add .env

# RIGHT:
echo "API_KEY=secret" > ~/dotfiles/secrets/.env.service
git add secrets/.env.service  # git-crypt will encrypt
```

---

## 🔍 Decision Tree: Making Changes

```
Is it a SECRET?
├─ YES → ~/dotfiles/secrets/ (git-crypt encrypted)
└─ NO  → Continue...

Is it PERSONAL PREFERENCE?
├─ YES → ~/dotfiles/
│        (shell config, taskwarrior, etc.)
└─ NO  → Continue...

Is it a TEAM STANDARD?
├─ YES → ~/Development/dev-configs/
│        (Python rules, C formatting, etc.)
└─ NO  → Continue...

Does it need CROSS-PLATFORM TEMPLATING?
├─ YES → chezmoi-source/
│        (OS detection, variable substitution)
└─ NO  → It's probably PROJECT CODE
         → ~/Development/projects/myproject/
```

---

## 📚 Daily Functions

### Morning Routine
```bash
morning
```
**Shows:**
- Harsh habits to log
- Pending tasks (taskwarrior)
- Overdue tasks warning
- Ready tasks (top 5 by urgency)
- Dotfiles uncommitted changes

### Evening Routine
```bash
evening
```
**Does:**
- Shows harsh habit completion
- Shows consistency graphs
- Taskwarrior summary (completed today)
- Scans ~/Development for uncommitted changes
- **Auto-commits task-data to git** ← Important!
- Shows dotfiles status

### Health Check
```bash
dotdoctor
```
**Verifies:**
- Dotfiles directory exists
- Chezmoi installed
- Pet installed
- fzf installed
- Config symlinks created
- Secrets symlinks created
- Chezmoi session unlocked

---

## 🔄 Sync Workflows

### Dotfiles Sync (Manual)
```bash
cd ~/dotfiles
git pull
source ~/.bashrc  # or ~/.zshrc on Mac
```

### Task Sync (Automatic via evening)
```bash
# On Machine A:
task add "New task"
evening  # Auto-commits task-data

# On Machine B:
cd ~/dotfiles && git pull
task list  # Sees new task
```

### Dev-Configs Sync (Manual)
```bash
cd ~/Development/dev-configs
git pull
```

### Chezmoi Sync (Manual)
```bash
chezmoi update
```

---

## 🐛 Troubleshooting

### "Function not found: morning/evening"
```bash
# Reload shell config
source ~/.bashrc  # Linux
source ~/.zshrc   # Mac

# Or restart terminal
```

### "git-crypt: secrets not decrypted"
```bash
cd ~/dotfiles
git-crypt unlock

# If that fails, check GPG keys:
gpg --list-keys
```

### "Taskwarrior format mismatch"
This happened when we had v2.6 (Linux) and v3.4 (Mac).
**Solution:** Both machines now run v3.4.2 with SQLite format.

### "Chezmoi session locked"
```bash
unlock-session  # Prompts for YubiKey PIN
```

### "Task data conflicts"
If you get git merge conflicts in `taskchampion.sqlite3`:
```bash
# Accept one version:
git checkout --ours task-data/taskchampion.sqlite3
# or
git checkout --theirs task-data/taskchampion.sqlite3

# Then manually reconcile tasks
```

---

## 📖 Further Reading

- **ECOSYSTEM.md** - Detailed architecture and component relationships
- **ARCHITECTURE.md** - Technical design decisions
- **SYNC-OVERVIEW.md** - How configuration sync works
- **CHEZMOI-SETUP.md** - Chezmoi-specific instructions
- **MIGRATION.md** - Developer → Development path migration
- **TECH-STACK.md** - Technologies and versions in use

---

## 🤖 AI Assistant Guidelines

### When User Asks to "Add Config"
1. **Ask:** "Is this personal or team standard?"
2. **Determine location** using decision tree above
3. **Check cross-platform** needs (Mac + Linux)
4. **Create appropriate files** in correct repo
5. **Update install scripts** if needed
6. **Commit to correct repo**

### When User Says "It's Not Working"
1. **Check which machine** (Mac or Linux)
2. **Verify tools installed** (task --version, harsh --version)
3. **Check symlinks** (ls -la ~/.taskrc, ls -la ~/.task)
4. **Run dotdoctor** to verify setup
5. **Check secrets unlocked** (git-crypt status)

### When User Wants to Sync Something
1. **Identify what** (configs, secrets, tasks, code)
2. **Determine method:**
   - Configs: git (dotfiles or dev-configs)
   - Tasks: git (via evening function)
   - Secrets: git-crypt (currently) or Age (future)
   - Code: git (project-specific)
3. **Verify both machines** have compatible versions
4. **Test sync** by checking on other machine

### When Making Changes
1. **Read relevant docs first** (ECOSYSTEM.md, this file)
2. **Understand the boundary** between personal/team/template
3. **Make changes in correct location**
4. **Update related documentation**
5. **Test on both Mac and Linux** if cross-platform
6. **Commit with clear message** explaining rationale

---

## ✅ Verification Checklist

### Automated Verification

**ALWAYS run `dotdoctor` after making changes** to verify setup compliance:

```bash
dotdoctor
```

This automated health check verifies:
- ✅ All required tools installed (chezmoi, pet, fzf, taskwarrior, harsh)
- ✅ Config symlinks exist (.gitconfig, .profile, .taskrc, .task, etc.)
- ✅ Secrets symlinks exist (Claude, Ansible, Conda, etc.)
- ✅ Bootstrap automation enabled (systemd/launchd)
- ✅ Shell functions available (morning, evening)
- ✅ Chezmoi session unlocked

**When adding new tools:**
1. Install the tool
2. Add config to correct location (dotfiles/dev-configs/chezmoi)
3. Create symlinks in install.sh
4. **Update dotdoctor** to verify the new tool and symlinks
5. Run dotdoctor to confirm all checks pass

### Manual Verification Checklist

Before considering a change "complete":

- [ ] Files in correct repository (dotfiles/dev-configs/chezmoi)
- [ ] Symlinks created if needed
- [ ] install.sh updated if needed
- [ ] **dotdoctor updated** to verify new tool/symlinks
- [ ] Cross-platform tested (Mac + Linux)
- [ ] Documentation updated (README.md at minimum)
- [ ] Secrets properly encrypted (if applicable)
- [ ] Changes committed to git
- [ ] Changes pushed to remote
- [ ] Verified on other machine (if sync needed)
- [ ] **dotdoctor passes** on both machines

---

## 🎯 Success Criteria

A well-integrated change should:
1. ✅ Work on both Mac and Linux (unless explicitly machine-specific)
2. ✅ Be in the correct repository (dotfiles vs dev-configs)
3. ✅ Have appropriate documentation
4. ✅ Not break existing functionality (run dotdoctor)
5. ✅ Sync correctly (if shared config/data)
6. ✅ Follow existing patterns and conventions

---

**Last Updated:** 2025-11-12
**Maintained By:** Terje Husby (@thusby)
**AI Assistants:** Please keep this document updated when making significant ecosystem changes.
