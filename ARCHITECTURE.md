# Architecture Diagram

Visuell oversikt over Terje Husby sitt development ecosystem.

---

## Heilskapsarkitektur

```
╔═══════════════════════════════════════════════════════════════╗
║                    CHEZMOI v2.67.0                            ║
║              Master Configuration Manager                     ║
║            ~/.local/share/chezmoi/ (git repo)                 ║
╚═══════════════════════════════════════════════════════════════╝
                              │
                              │ manages & syncs
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌─────────────────┐   ┌─────────────────┐
│   dotfiles    │   │  Development/   │   │   .claude/      │
│   (privat)    │   │   projects/     │   │   .config/      │
│               │   │                 │   │                 │
│  ~/dotfiles/  │   │ ~/Development/  │   │ Claude configs  │
└───────┬───────┘   └────────┬────────┘   └─────────────────┘
        │                    │
        │                    │
        ▼                    ▼
┌───────────────┐   ┌─────────────────┐
│   secrets/    │   │  dev-configs/   │
│ (Age+YubiKey) │   │   (shared)      │
│               │   │                 │
│  API tokens   │   │  Team standards │
│  OAuth creds  │   │  Linting rules  │
│  .env files   │   │  Formatting     │
└───────┬───────┘   └────────┬────────┘
        │                    │
        │                    │
        │          ┌─────────┴──────────┬──────────┐
        │          │                    │          │
        ▼          ▼                    ▼          ▼
   ┌────────┐  ┌─────────┐  ┌─────────────┐  ┌─────────┐
   │Project │  │ Project │  │   Project   │  │ Project │
   │   A    │  │    B    │  │      C      │  │    D    │
   │        │  │         │  │             │  │         │
   │mcp-*   │  │coord.   │  │  localfarm  │  │ zephyr  │
   └────────┘  └─────────┘  └─────────────┘  └─────────┘
        │          │                │              │
        └──────────┴────────────────┴──────────────┘
                         │
                         ▼
                ┌─────────────────┐
                │ tech-stack.md   │
                │ (dokumentasjon) │
                └─────────────────┘
```

---

## Dataflyt & Avhengigheiter

### Secrets Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    MAINTAINER WORKFLOW                       │
└─────────────────────────────────────────────────────────────┘

1. Encrypt and store in chezmoi:
   ~/.local/share/chezmoi/dotfiles/secrets/encrypted_dot_env.readwise.age
              │
              │ Age + YubiKey encrypt
              │
              ▼
   Commit til git (kryptert)

2. Decrypt locally:
   chezmoi apply (YubiKey touch)
              │
              ▼
   ~/dotfiles/secrets/.env.readwise

3. Link til prosjekt:
   ~/Development/projects/mcp-readwise/.env
              │
              │ symlink
              │
              ▼
   ~/dotfiles/secrets/.env.readwise

3. Prosjekt bruker .env:
   Python: load_dotenv()
   Node: process.env.API_KEY


┌─────────────────────────────────────────────────────────────┐
│                   CONTRIBUTOR WORKFLOW                       │
└─────────────────────────────────────────────────────────────┘

1. Les template:
   ~/Development/projects/mcp-readwise/.env.example
              │
              │ copy
              │
              ▼
   ~/Development/projects/mcp-readwise/.env

2. Fyll inn eigne credentials:
   vim .env

3. Prosjekt bruker .env:
   Python: load_dotenv()
   Node: process.env.API_KEY
```

### dev-configs Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                   SHARED STANDARDS FLOW                      │
└─────────────────────────────────────────────────────────────┘

1. Define standards:
   dev-configs/python/pyproject-base.toml
              │
              │ extend/import
              │
              ▼
   mcp-common/pyproject.toml
   coordinator/pyproject.toml
   localfarm/backend/pyproject.toml

2. Update standards:
   cd dev-configs/
   vim python/pyproject-base.toml
   git commit -m "ruff: enable new rule"
              │
              │ automatic via extend
              │
              ▼
   All projects using it get updates

3. Project-specific overrides:
   [tool.ruff]
   extend = "../../dev-configs/python/pyproject-base.toml"

   # Override specific settings
   line-length = 100  # Override default 88
```

---

## Synkronisering mellom Maskiner

```
╔═══════════════════════════════════════════════════════════╗
║                    MASKIN 1 (Linux)                       ║
╚═══════════════════════════════════════════════════════════╝

~/.local/share/chezmoi/
    │
    │ git push
    │
    ▼
┌───────────────────────────────────────────────────────────┐
│              GitHub (Private Repo)                        │
│       github.com/thusby/dotfiles (chezmoi)                │
└───────────────────────────────────────────────────────────┘
    │
    │ git pull
    │
    ▼
╔═══════════════════════════════════════════════════════════╗
║                    MASKIN 2 (Mac)                         ║
╚═══════════════════════════════════════════════════════════╝

~/.local/share/chezmoi/
    │
    │ chezmoi apply
    │
    ▼
~/Development/projects/     (Mac path)
~/dotfiles/
~/.claude/


PLATTFORM-DETEKSJON:
┌────────────────────────────────────────┐
│ dotfiles/shell/env.sh                  │
├────────────────────────────────────────┤
│ if [[ "$OSTYPE" == "darwin"* ]]; then  │
│   PROJECTS_DIR="$HOME/Development"       │
│ elif [[ "$OSTYPE" == "linux"* ]]; then │
│   PROJECTS_DIR="$HOME/Development"     │
│ fi                                     │
└────────────────────────────────────────┘
```

---

## Lag-struktur

```
┌─────────────────────────────────────────────────────────────┐
│ LAG 1: SYSTEM (chezmoi)                                     │
│ - Master configuration manager                              │
│ - Cross-platform sync                                       │
│ - Template engine (.tmpl files)                             │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ LAG 2: PERSONLEG (dotfiles)                                 │
│ - Shell configs                                             │
│ - Git global settings                                       │
│ - SSH keys                                                  │
│ - Secrets (decrypted from chezmoi Age+YubiKey)             │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ LAG 3: TEAM (dev-configs)                                   │
│ - Linting/formatting rules                                  │
│ - Test configuration                                        │
│ - Code standards                                            │
│ - Editor configs                                            │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ LAG 4: PROSJEKT (kvar repo)                                 │
│ - Business logic                                            │
│ - Dependencies                                              │
│ - .env.example templates                                    │
│ - README documentation                                      │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ LAG 5: DOKUMENTASJON (tech-stack.md)                        │
│ - Technology overview                                       │
│ - Framework versions                                        │
│ - Architecture decisions                                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Sikkerheits-modell

```
PUBLIC (GitHub)
├── dev-configs/          ✅ Open source
│   ├── python/
│   ├── c-embedded/
│   └── git/
├── prosjekt/code/        ✅ Open source
│   └── src/
└── prosjekt/.env.example ✅ Template (safe)


PRIVATE (GitHub, ukryptert)
└── chezmoi repo (repo structure)


ENCRYPTED (Age + YubiKey in chezmoi source)
└── ~/.local/share/chezmoi/dotfiles/secrets/     🔒 Age encrypted
    ├── encrypted_dot_env.*.age
    ├── gmail/
    │   ├── encrypted_credentials.json.age
    │   └── encrypted_token.json.age
    └── tana/encrypted_token.txt.age

    ↓ chezmoi apply (YubiKey touch) ↓

DECRYPTED (Local, gitignored)
└── ~/dotfiles/secrets/     🔓 Decrypted locally
    ├── .env.*
    ├── gmail/
    │   ├── credentials.json
    │   └── token.json
    └── tana/token.txt


LOCAL ONLY (.gitignore)
└── prosjekt/.env         🚫 Aldri i Git
```

---

## Component Responsibility Matrix

| Component | Config | Secrets | Code | Sync | Share |
|-----------|--------|---------|------|------|-------|
| **chezmoi** | ✅ Master | 🔒 Encrypted | ❌ | ✅ Git | ❌ Private |
| **dotfiles** | ✅ Personal | ✅ Owns | ❌ | via chezmoi | ❌ Private |
| **dev-configs** | ✅ Standards | ❌ | ❌ | ✅ Git | ✅ Public |
| **projects/** | 🔧 Import | 🔗 Symlink | ✅ | ✅ Git | ✅ Public |
| **tech-stack.md** | ❌ | ❌ | 📚 Docs | ✅ Git | ✅ Public |

---

## Decision Tree: "Kor skal denne fila ligge?"

```
START: Eg har ei fil som skal lagres
    │
    ├─► Er det ein SECRET? (API key, password, token)
    │   ├─► JA → ~/.local/share/chezmoi/dotfiles/secrets/*.age (Age+YubiKey)
    │   │        Then: chezmoi apply → ~/dotfiles/secrets/ (decrypted)
    │   └─► NEI → fortsett
    │
    ├─► Er det PERSONLEG CONFIG? (shell alias, git global)
    │   ├─► JA → dotfiles/ (chezmoi managed)
    │   └─► NEI → fortsett
    │
    ├─► Er det TEAM STANDARD? (linting rule, formatter config)
    │   ├─► JA → dev-configs/ (git, shared)
    │   └─► NEI → fortsett
    │
    ├─► Er det PROSJEKT-KODE? (source files, tests)
    │   ├─► JA → projects/PROSJEKT/ (git, shared)
    │   └─► NEI → fortsett
    │
    └─► Er det DOKUMENTASJON? (tech overview, architecture)
        ├─► Prosjekt-spesifikk → projects/PROSJEKT/docs/
        └─► Cross-project → ~/Development/tech-stack.md
```

---

## Quick Reference

### Eg vil...

**...legge til ein ny API key:**
```bash
cd ~/dotfiles/secrets/
echo "API_KEY=xyz" > .env.service
git add .env.service
git commit -m "Add service API key"
cd ~/Development/projects/service/
ln -s ~/dotfiles/secrets/.env.service .env
```

**...endre linting-regler for alle Python-prosjekt:**
```bash
cd ~/Development/dev-configs/
vim python/pyproject-base.toml
git commit -m "ruff: enable rule XYZ"
git push
# Alle prosjekt med extend får automatisk oppdatering
```

**...starte nytt prosjekt:**
```bash
cd ~/Development/projects/
mkdir nytt-prosjekt
cd nytt-prosjekt
../../dev-configs/setup.sh python .
cp .env.example .env.example
ln -s ~/dotfiles/secrets/.env.nytt .env
```

**...synke til ny maskin:**
```bash
chezmoi init https://github.com/thusby/chezmoi-source
chezmoi apply  # Touch YubiKey to decrypt secrets
```

**...dokumentere ny teknologi:**
```bash
vim ~/Development/tech-stack.md
# Legg til i riktig prosjekt-seksjon
git commit -m "docs: add XYZ to tech stack"
```

---

## Summary

**5 hovudkomponentar:**
1. **chezmoi** - Synkroniserer alt
2. **dotfiles** - Personleg + secrets
3. **dev-configs** - Team standards
4. **projects/** - Kode og funksjonalitet
5. **tech-stack.md** - Dokumentasjon

**3 sikkerheitslag:**
1. Public (dev-configs, prosjekt-kode)
2. Private (chezmoi repo-struktur)
3. Encrypted (secrets via Age + YubiKey)

**1 workflow:**
chezmoi → dotfiles → dev-configs → projects → tech-stack.md

## Git History Cleanup (2025-11-12)

**Dotfiles repository history was reset to remove old git-crypt secrets.**

### What Changed
- Old history: 56 commits (with git-crypt encrypted secrets)
- New history: Fresh start with 1 initial commit
- No secrets in new history (secrets never were, and never will be in dotfiles repo)

### Why
- Clean separation: Secrets are now exclusively in `chezmoi-source` with Age encryption
- Security hygiene: Even though git-crypt encrypted, better to not have secrets history
- Simplification: Cleaner git history without legacy encryption artifacts

### Impact
- ⚠️ **Mac must reset dotfiles:** Run on Mac: `cd ~/dotfiles && git fetch --all && git reset --hard origin/main`
- ✅ Secrets unchanged: All secrets still in `chezmoi-source` (Age encrypted)
- ✅ Functionality unchanged: All dotfiles features work as before
