# Skills Integration med Eksisterande Rutiner

**Dato:** 2025-11-13
**Formål:** Integrere Claude Code skills med morning/evening, taskwarrior, og andre etablerte workflows

---

## 📋 Eksisterande Rutiner (frå AI-INSTRUCTIONS.md)

### Morning Routine
```bash
morning
```
**Viser:**
- Pending tasks (taskwarrior)
- Overdue tasks warning
- Ready tasks (top 5 by urgency)
- Dotfiles uncommitted changes

### Evening Routine
```bash
evening
```
**Gjer:**
- Taskwarrior summary (completed today)
- Scans ~/Development for uncommitted changes
- **Auto-commits task-data to git** ← Viktig!
- Shows dotfiles status

### Task Management (Taskwarrior)
**Version:** 3.4.2 (SQLite format)
**Data:** `~/dotfiles/task-data/` (synced via git)
**Config:** `~/dotfiles/taskwarrior/taskrc`

**Tag-basert organisering:**
```bash
task add "Mac-only thing" +mac
task add "Linux-only thing" +linux
task add "Works everywhere"  # No tag

# Context switching
task context mac
task context linux
task context shared
```

---

## 🎯 Event-Driven Skill Triggers

### Filosofi: "Observe, Don't Interrupt"

Skills skal vere **reaktive** til eksisterande workflows, ikkje erstatte dei.

```
User Workflow → Generates Events → Skills Observe → Skills Act Autonomously
      ↓                                   ↓                    ↓
   morning()                      Uncommitted changes?    Offer to commit
   evening()                      Secrets outdated?       Re-encrypt
   task add                       New project task?       Setup project
   cd projects/                   Missing .claude/?       Offer setup
```

---

## 🔄 Integration Points

### 1. Morning Routine → Skills Kickoff

**Noverande morning():**
```bash
morning
├── task ready urgency
├── task overdue
└── git status ~/dotfiles
```

**Med Skills Integration:**
```bash
morning
├── task ready urgency
├── task overdue
├── git status ~/dotfiles
└── ✨ CLAUDE SKILLS TRIGGERED:
    ├── sync-check skill
    │   ├── Verifiser dotfiles sync
    │   ├── Verifiser dev-configs sync
    │   ├── Sjekk chezmoi status
    │   └── Valider secrets dekryptert
    │
    ├── task-analyzer skill (ny!)
    │   ├── Sjekk for "setup" eller "new project" tasks
    │   ├── Foreslå: "Eg ser du har task 'Setup X' - vil du eg skal hjelpe?"
    │   └── Prioriter dagens tasks basert på urgency
    │
    └── docs-reminder skill (ny!)
        └── Vis tips basert på aktive tasks
```

**Implementasjon:**
```bash
# ~/dotfiles/shell/functions.sh

morning() {
    # Existing morning routine
    echo "🌅 Good morning!"
    task ready urgency
    task overdue

    # Git status
    cd ~/dotfiles && git status --short

    # NEW: Trigger Claude Code skills
    # Creates a marker file that skills can detect
    echo "$(date +%Y-%m-%d)" > ~/.cache/morning-triggered

    # Skills observerer denne fila og tek action
}
```

---

### 2. Evening Routine → Cleanup & Sync

**Noverande evening():**
```bash
evening
├── task completed today
├── Scan ~/Development for uncommitted changes
├── Auto-commit task-data
└── Show dotfiles status
```

**Med Skills Integration:**
```bash
evening
├── task completed today
├── Scan ~/Development for uncommitted changes
├── Auto-commit task-data
└── ✨ CLAUDE SKILLS TRIGGERED:
    ├── sync-orchestrator skill (ny!)
    │   ├── Commit dotfiles (if changes)
    │   ├── Commit dev-configs (if changes)
    │   ├── Push all repos
    │   └── Verifiser sync successful
    │
    ├── secrets-check skill
    │   ├── Sjekk om secrets er endra
    │   ├── Tilby re-encrypt + commit
    │   └── Verifiser YubiKey tilgjengeleg
    │
    └── project-summary skill (ny!)
        ├── Oppsummer dagens kodeendringar
        ├── Foreslå TODO-items for i morgon
        └── Oppdater TECH-STACK.md (if relevant)
```

**Implementasjon:**
```bash
# ~/dotfiles/shell/functions.sh

evening() {
    # Existing evening routine
    echo "🌙 Evening summary..."
    task completed today

    # Scan for uncommitted changes
    for dir in ~/Development/projects/*/; do
        cd "$dir"
        if [[ -n $(git status --porcelain) ]]; then
            echo "⚠️  Uncommitted: $(basename $dir)"
        fi
    done

    # Auto-commit task-data
    cd ~/dotfiles
    git add task-data/
    git commit -m "task: evening sync $(date +%Y-%m-%d)" 2>/dev/null

    # NEW: Trigger Claude Code skills
    echo "$(date +%Y-%m-%d)" > ~/.cache/evening-triggered

    # Skills observerer og tek action
}
```

---

## 📝 Taskwarrior Hooks → Skill Triggers

### Taskwarrior Hook System

Taskwarrior støttar hooks som køyrer på events:
```
~/.task/hooks/
├── on-add.sh       # Når task vert lagt til
├── on-modify.sh    # Når task vert endra
└── on-exit.sh      # Når taskwarrior avsluttar
```

### Hook Integration med Claude Skills

**Scenario 1: Ny "setup" eller "project" task**
```bash
# ~/.task/hooks/on-add.sh

#!/bin/bash
# Taskwarrior on-add hook

# Read task JSON from stdin
read input

# Check if task contains keywords: setup, new project, initialize
if echo "$input" | jq -r '.description' | grep -iq 'setup\|new project\|initialize'; then
    # Create marker for Claude skill
    echo "$input" > ~/.cache/task-setup-detected.json
fi

# Pass through unchanged (required by taskwarrior)
echo "$input"
```

**Claude skill responderer:**
```
dev-setup skill (observerer ~/.cache/task-setup-detected.json)
    ↓
"Eg ser du har lagt til task om prosjekt-setup. Vil du eg skal hjelpe?"
    ↓
Autonomt: Detekter prosjekt-type, køyr setup, marker task som started
```

**Scenario 2: Task fullført → Cleanup**
```bash
# ~/.task/hooks/on-modify.sh

#!/bin/bash
read input

# Check if task was marked as completed
if echo "$input" | jq -r '.status' | grep -q 'completed'; then
    desc=$(echo "$input" | jq -r '.description')

    # If it was a dev task, trigger cleanup
    if echo "$desc" | grep -iq 'dev\|code\|implement'; then
        echo "$input" > ~/.cache/task-completed-dev.json
    fi
fi

echo "$input"
```

**Claude skill responderer:**
```
project-cleanup skill
    ↓
Sjekkar: Uncommitted changes? Missing tests? Documentation updated?
    ↓
Foreslår: "Task fullført! Vil du eg skal commit endringane?"
```

---

## 🎨 Skill Design: Event-Driven Architecture

### Core Principle: Observer Pattern

```
Event Source          Signal File               Claude Skill
    ↓                     ↓                         ↓
morning()      →  ~/.cache/morning-triggered  →  sync-check
evening()      →  ~/.cache/evening-triggered  →  sync-orchestrator
task add       →  ~/.cache/task-setup.json    →  dev-setup
cd projects/X  →  ~/.cache/pwd-change         →  project-detector
git commit     →  ~/.cache/git-event          →  commit-helper
```

### Signal File Convention

**Location:** `~/.cache/claude-events/`

**Format:**
```json
{
  "event": "morning_routine",
  "timestamp": "2025-11-13T08:00:00Z",
  "context": {
    "tasks_overdue": 2,
    "uncommitted_repos": ["dev-configs", "dotfiles"]
  }
}
```

**Cleanup:** Skills slettar signal-filer etter prosessering

---

## 🛠️ Skill Implementations

### 1. `sync-check` skill (Morning trigger)

```markdown
---
name: sync-check
description: |
  Autonomously verifies sync status across dotfiles, dev-configs, and chezmoi.
  Triggered by morning() routine. Detects uncommitted changes, outdated secrets,
  and sync issues. Offers to fix automatically.
  Observes: ~/.cache/claude-events/morning-triggered
allowed-tools:
  - Bash
  - Read
---

# Sync Check Skill

## Trigger Detection

```bash
# Sjekk om morning() har køyrt
if [ -f ~/.cache/claude-events/morning-triggered ]; then
    # Køyr sync checks
    # Slett signal file når ferdig
fi
```

## Checks

1. **Dotfiles sync:**
   - `cd ~/dotfiles && git status`
   - Uncommitted task-data? → Offer commit
   - Behind origin? → Offer pull

2. **Dev-configs sync:**
   - `cd ~/Development/dev-configs && git status`
   - Uncommitted changes? → Show diff, offer commit

3. **Chezmoi status:**
   - `chezmoi status`
   - Unmanaged files? → Offer to add
   - Changes not applied? → Offer apply

4. **Secrets check:**
   - `ls -la ~/dotfiles/secrets/`
   - Empty dir? → Offer to decrypt (chezmoi apply)
   - Old timestamp? → Suggest re-decrypt

## Output

```
✅ Sync Status Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ dotfiles: Clean, up-to-date
⚠️  dev-configs: 2 uncommitted files
   └─ AUTOMATION-ANALYSIS.md
   └─ SKILL-INTEGRATION-PLAN.md

   Commit desse? (ja/nei)

✅ chezmoi: All managed files applied
✅ secrets: 14 files dekryptert
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
```

---

### 2. `task-analyzer` skill (Morning + Task events)

```markdown
---
name: task-analyzer
description: |
  Analyzes taskwarrior tasks and offers autonomous help.
  Detects setup/project tasks and offers to run dev-setup skill.
  Prioritizes tasks based on urgency and context.
  Observes: ~/.cache/claude-events/morning-triggered,
            ~/.cache/claude-events/task-setup.json
allowed-tools:
  - Bash
---

# Task Analyzer Skill

## Morning Analysis

```bash
# Hent ready tasks
tasks=$(task ready urgency export)

# Analyser kvar task
for task in $tasks; do
    desc=$(echo "$task" | jq -r '.description')
    tags=$(echo "$task" | jq -r '.tags[]')

    # Setup/project tasks?
    if [[ "$desc" =~ setup|project|initialize ]]; then
        # Trigger dev-setup skill
        echo "Eg ser task: $desc - Vil du eg skal hjelpe med setup?"
    fi

    # Missing context?
    if [[ -z "$tags" ]]; then
        echo "Task '$desc' har ingen tags - Vil du legge til +mac/+linux?"
    fi
done
```

## Task Hook Analysis

```bash
# Observerer ~/.cache/claude-events/task-setup.json
# Når taskwarrior on-add hook detekterer "setup" task

{
  "event": "task_added",
  "description": "Setup new Django project",
  "tags": ["dev", "django"],
  "uuid": "abc123"
}

# Skill responderer:
# "Eg ser du skal sette opp Django-prosjekt. Vil du eg skal køyre dev-setup?"
```

## Proaktiv Hjelp

**Scenario:**
```
User: task add "Initialize localfarm v2 with Vue 3"
      ↓
on-add hook detekterer "Initialize" + "Vue"
      ↓
task-analyzer skill:
  "Eg ser du skal sette opp Vue-prosjekt. Eg kan:
   1. Køyre dev-configs/setup.sh
   2. Setup Claude settings
   3. Lag .env.example
   4. Git init med første commit

   Vil du eg skal gjere dette no?"
```
```

---

### 3. `sync-orchestrator` skill (Evening trigger)

```markdown
---
name: sync-orchestrator
description: |
  Orchestrates evening sync workflow across all repos.
  Auto-commits task-data, dotfiles, dev-configs.
  Re-encrypts secrets if changed.
  Pushes all repos to remote.
  Observes: ~/.cache/claude-events/evening-triggered
allowed-tools:
  - Bash
  - Edit
---

# Sync Orchestrator Skill

## Evening Workflow

```bash
# 1. Task-data (allereie gjort av evening())
cd ~/dotfiles
git add task-data/
git commit -m "task: evening sync $(date)" 2>/dev/null

# 2. Dotfiles changes
if [[ -n $(git status --porcelain) ]]; then
    echo "Dotfiles har endringar:"
    git status --short
    read -p "Commit? (ja/nei) " answer
    if [[ "$answer" == "ja" ]]; then
        git add -A
        read -p "Commit message: " msg
        git commit -m "$msg"
    fi
fi

# 3. Dev-configs changes
cd ~/Development/dev-configs
if [[ -n $(git status --porcelain) ]]; then
    echo "dev-configs har endringar:"
    git status --short
    # Autonomous commit or ask?
fi

# 4. Secrets check
if [[ -n $(git -C ~/dotfiles diff ~/dotfiles/secrets/) ]]; then
    echo "Secrets har endra seg. Re-krypter og commit?"
    # Trigger secrets-mgmt skill
fi

# 5. Push all
git -C ~/dotfiles push
git -C ~/Development/dev-configs push
git -C ~/.local/share/chezmoi push
```

## Output

```
🌙 Evening Sync Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ task-data: Committed & pushed
✅ dotfiles: No changes
⚠️  dev-configs: 2 files committed & pushed
✅ secrets: No changes
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
```

---

### 4. `dev-setup` skill (Task + Directory triggers)

```markdown
---
name: dev-setup
description: |
  Autonomously sets up new projects when detected.
  Triggered by: task with "setup/initialize" keywords,
                cd to empty project directory,
                explicit user request.
  Observes: ~/.cache/claude-events/task-setup.json,
            ~/.cache/claude-events/pwd-change
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
---

# Dev Setup Skill

## Trigger 1: Task-based

```bash
# User: task add "Setup new Python project: mcp-slack"
#   ↓
# Taskwarrior on-add hook → ~/.cache/claude-events/task-setup.json
#   ↓
# dev-setup skill observerer:

{
  "event": "task_added",
  "description": "Setup new Python project: mcp-slack",
  "tags": ["dev", "python"],
  "project_name": "mcp-slack"  # Extracted
}

# Skill responderer:
"Skal eg sette opp mcp-slack som Python-prosjekt?"
  ↓
User: "ja"
  ↓
1. mkdir ~/Development/projects/mcp-slack
2. cd ~/Development/projects/mcp-slack
3. ../../dev-configs/setup.sh python .
4. ../../dev-configs/setup-new-project.sh $(pwd)
5. cp .env.example (if exists)
6. git init && git commit -m "Initial setup"
7. task start <uuid>  # Mark task as started
```

## Trigger 2: Directory-based

```bash
# User: cd ~/Development/projects/new-project
#   ↓
# PROMPT_COMMAND / chpwd hook → ~/.cache/claude-events/pwd-change
#   ↓
# dev-setup skill observerer:

if [[ -d .git ]]; then
    # Existing repo, skip
elif [[ -z "$(ls -A)" ]]; then
    # Empty directory!
    echo "Tomt prosjekt detektert. Vil du eg skal sette det opp?"
fi
```

## Proaktiv Deteksjon

**Patterns som trigger:**
- Task description: `setup`, `initialize`, `create project`, `new`
- Directory: Empty dir under `~/Development/projects/`
- Git: `git init` i ny mappe
```

---

## 🔗 Integration Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    USER WORKFLOWS                            │
│  morning() │ evening() │ task add │ cd projects/ │ git ...  │
└──────┬───────────┬──────────┬─────────┬──────────┬──────────┘
       │           │          │         │          │
       ▼           ▼          ▼         ▼          ▼
┌─────────────────────────────────────────────────────────────┐
│               EVENT SIGNAL LAYER                             │
│     ~/.cache/claude-events/                                  │
│     ├── morning-triggered                                    │
│     ├── evening-triggered                                    │
│     ├── task-setup.json                                      │
│     ├── pwd-change                                           │
│     └── git-event.json                                       │
└──────┬───────────┬──────────┬─────────┬──────────┬──────────┘
       │           │          │         │          │
       ▼           ▼          ▼         ▼          ▼
┌─────────────────────────────────────────────────────────────┐
│                  CLAUDE SKILLS                               │
│  sync-check │ sync-orchestrator │ task-analyzer │ dev-setup │
│  secrets-mgmt │ docs-navigator │ project-cleanup │ ...      │
└──────┬───────────┬──────────┬─────────┬──────────┬──────────┘
       │           │          │         │          │
       ▼           ▼          ▼         ▼          ▼
┌─────────────────────────────────────────────────────────────┐
│               AUTONOMOUS ACTIONS                             │
│  Commit │ Sync │ Setup │ Encrypt │ Document │ Cleanup       │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 Implementation Checklist

### Fase 1: Signal Layer (Foundation)
- [ ] Opprett `~/.cache/claude-events/` dir
- [ ] Oppdater `morning()` til å lage signal file
- [ ] Oppdater `evening()` til å lage signal file
- [ ] Test: Køyr morning/evening, verifiser signal files

### Fase 2: Taskwarrior Hooks
- [ ] Opprett `~/.task/hooks/` dir
- [ ] Lag `on-add.sh` hook (detekter setup-tasks)
- [ ] Lag `on-modify.sh` hook (detekter completion)
- [ ] Test: `task add "Setup X"` → sjekk signal file

### Fase 3: Core Skills
- [ ] Implementer `sync-check` skill
- [ ] Implementer `task-analyzer` skill
- [ ] Implementer `sync-orchestrator` skill
- [ ] Implementer `dev-setup` skill

### Fase 4: Integration Testing
- [ ] Test morning → sync-check flow
- [ ] Test evening → sync-orchestrator flow
- [ ] Test task add → dev-setup flow
- [ ] Test på tvers av Mac + Linux

### Fase 5: Advanced Skills
- [ ] `secrets-mgmt` skill (evening trigger for re-encrypt)
- [ ] `project-cleanup` skill (task completion trigger)
- [ ] `docs-navigator` skill (context-aware help)

---

## 🎯 Success Metrics

### Før Integration
**Morning routine:**
- User køyrer `morning`
- Ser task list
- Manuelt sjekkar dotfiles sync
- Manuelt sjekkar secrets

**Evening routine:**
- User køyrer `evening`
- Ser completed tasks
- Manuelt commit dev-configs
- Manuelt push repos

**Tidsbruk:** ~5 minutt (+ manuell innsats)

### Etter Integration
**Morning routine:**
- User køyrer `morning`
- `sync-check` skill kjører autonomt
- Får rapport om sync-status
- Skills tilbyr fix om naudsynt

**Evening routine:**
- User køyrer `evening`
- `sync-orchestrator` skill kjører autonomt
- Auto-commit task-data ✅
- Auto-commit dev-configs (if changes)
- Auto-push alle repos
- Rapport om status

**Tidsbruk:** ~1 minutt (skills gjer resten)

**Benefit:** 80% tidsbesparelse + færre gløymde steg

---

## 💭 Design Philosophy

### 1. "Amplify, Don't Replace"
Skills skal **forsterke** eksisterande workflows, ikkje erstatte dei.
- ✅ morning/evening beheld sin form
- ✅ taskwarrior fungerer som før
- ✅ Skills legg til intelligens på toppen

### 2. "Observe, Don't Interrupt"
Skills skal vere **reaktive**, ikkje påtrengande.
- ✅ Observerer signal files
- ✅ Tilbyr hjelp når relevant
- ✅ Brukar bestemmer om dei aksepterer

### 3. "Autonomous, But Transparent"
Skills skal vere **autonome**, men forklarande.
- ✅ Viser kva dei gjer
- ✅ Spør om kritiske endringar
- ✅ Logger actions for transparency

---

## 🚀 Next Steps

1. **Start med signal layer** (15 min)
   - Opprett ~/.cache/claude-events/
   - Oppdater morning/evening functions

2. **Implementer sync-check skill** (30 min)
   - Test morning trigger
   - Verifiser sync-checks fungerer

3. **Implementer task-analyzer skill** (45 min)
   - Lag taskwarrior hooks
   - Test task-based triggers

4. **Rollout i faser**
   - Test på Linux først
   - Deretter Mac
   - Finjuster basert på feedback

---

**Laga av:** Claude Code
**Dato:** 2025-11-13
**Basert på:** AI-INSTRUCTIONS.md, ECOSYSTEM.md, + eksisterande workflows
