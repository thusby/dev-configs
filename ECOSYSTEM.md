# Development Ecosystem Overview

Oversikt over korleis alle konfigurasjonssystem heng saman i Terje Husby sitt utviklingsmiljø.

---

## 🏗️ Arkitektur

```
┌─────────────────────────────────────────────────────────────┐
│                    CHEZMOI (Master)                         │
│              ~/.local/share/chezmoi/                        │
│  Handterer: dotfiles, Development/, Claude configs          │
└─────────────────────┬───────────────────────────────────────┘
                      │
      ┌───────────────┼───────────────┬─────────────────┐
      │               │               │                 │
      ▼               ▼               ▼                 ▼
┌──────────┐  ┌──────────────┐  ┌─────────┐  ┌──────────────┐
│ dotfiles │  │ Development/ │  │ .claude │  │ .config/     │
│ (privat) │  │  projects/   │  │         │  │   Claude/    │
└─────┬────┘  └──────┬───────┘  └─────────┘  └──────────────┘
      │              │
      │              ├─────────────────┐
      │              │                 │
      ▼              ▼                 ▼
┌──────────┐  ┌────────────┐  ┌──────────────┐
│ secrets/ │  │ Prosjekt   │  │ dev-configs  │
│ (krypt.) │  │ (kode)     │  │ (shared)     │
└──────────┘  └────────────┘  └──────────────┘
                     │
                     │ symlinks/imports
                     │
                     ▼
              ┌──────────────┐
              │ tech-stack   │
              │ (dokumentert)│
              └──────────────┘
```

---

## 📦 Komponentar

### 1. **chezmoi** - Master Configuration Manager
**Lokasjon:** `~/.local/share/chezmoi/`

**Handterer:**
- Personlege dotfiles (shell, git, etc.)
- Development/projects/ struktur
- Claude Code settings
- Kryss-plattform synkronisering

**Kommandoar:**
```bash
chezmoi apply        # Deploy alle endringar
chezmoi add FILE     # Legg til fil i chezmoi
chezmoi edit FILE    # Rediger fil i chezmoi
chezmoi managed      # Vis alle handterte filer
```

**Handterte stiar:**
```
~/.claude/settings.json
~/.config/Claude/claude_desktop_config.json
~/Development/projects/
~/dotfiles/
```

---

### 2. **dotfiles** - Personlege Konfigurasjonar + Secrets
**Lokasjon:** `~/dotfiles/`

**Føremål:** Personleg system-konfigurasjon og krypterte secrets

**Struktur:**
```
dotfiles/
├── secrets/                 # Dekryptert frå chezmoi (IKKJE i git)
│   ├── .env.readwise
│   ├── gmail/
│   │   ├── credentials.json
│   │   └── token.json
│   └── tana/token.txt
├── shell/
│   └── env.sh              # Platform-deteksjon ($PROJECTS_DIR)
├── git/
├── claude/
├── ssh/
└── scripts/
```

**Sikkerheit:**
- Age + YubiKey kryptering via chezmoi
- Encrypted source: `~/.local/share/chezmoi/dotfiles/secrets/*.age`
- Symlinks frå prosjekt til decrypted secrets/
- `.env.example` i prosjekt, faktiske `.env` i dotfiles

**Bruk i prosjekt (maintainer):**
```bash
ln -s ~/dotfiles/secrets/.env.readwise ~/Development/projects/mcp-readwise/.env
```

**Bruk i prosjekt (contributors):**
```bash
cp .env.example .env
# Edit .env med eigne credentials
```

---

### 3. **dev-configs** - Delte Prosjekt-standardar
**Lokasjon:** `~/Development/dev-configs/`

**Føremål:** Team/prosjekt-standardar for kode-kvalitet og formatting

**Struktur:**
```
dev-configs/
├── python/
│   └── pyproject-base.toml   # ruff, mypy, pytest, black
├── c-embedded/
│   ├── .clang-format         # Zephyr RTOS style
│   └── .editorconfig         # Multi-språk
├── git/
│   ├── python.gitignore
│   └── node.gitignore
├── setup.sh                  # Auto-setup script
└── USAGE.md
```

**Bruk i prosjekt:**
```bash
# Import i pyproject.toml
[tool.ruff]
extend = "../../dev-configs/python/pyproject-base.toml"

# Eller symlink
ln -s ../../dev-configs/c-embedded/.clang-format .clang-format
```

**Prosjekt som bruker dette:**
- mcp-common, coordinator, localfarm (Python)
- zephyr-meta (C/C++ embedded)

---

### 4. **tech-stack.md** - Teknologi-dokumentasjon
**Lokasjon:** `~/Development/tech-stack.md`

**Føremål:** Samla oversikt over teknologiar brukt i alle prosjekt

**Innhald:**
- Framework & runtime for kvart prosjekt
- Dependencies og versjonar
- Deployment & infrastructure
- Cross-project technology summary

**Prosjekt dokumentert:**
- localfarm (Django + Vue.js)
- mcp-common (FastMCP monorepo)
- coordinator (Multi-agent systems)
- zephyr-meta (Embedded systems)
- openvino (AI/ML inference)

---

## 🔄 Workflow & Samanheng

### Scenario 1: Starte nytt Python-prosjekt

1. **Lag prosjekt-mappe:**
   ```bash
   cd ~/Development/projects/
   mkdir mitt-prosjekt
   cd mitt-prosjekt
   ```

2. **Setup dev-configs:**
   ```bash
   ../../dev-configs/setup.sh python .
   ```

3. **Lag .env.example (for andre):**
   ```bash
   cat > .env.example <<EOF
   API_KEY=your_api_key_here
   DATABASE_URL=postgresql://localhost/dbname
   EOF
   ```

4. **Link secrets (for deg):**
   ```bash
   ln -s ~/dotfiles/secrets/.env.mitt-prosjekt .env
   ```

5. **Legg til i chezmoi (om du vil synke):**
   ```bash
   chezmoi add ~/Development/projects/mitt-prosjekt/
   ```

6. **Oppdater tech-stack.md:**
   - Dokumenter teknologi-valg
   - Legg til i prosjekt-oversikten

---

### Scenario 2: Jobbe på tvers av Mac/Linux

1. **chezmoi synkroniserer automatisk:**
   ```bash
   # På maskin 1
   chezmoi add FILE
   cd ~/.local/share/chezmoi && git push

   # På maskin 2
   cd ~/.local/share/chezmoi && git pull
   chezmoi apply
   ```

2. **Konsistent path på alle plattformer:**
   ```bash
   # ~/dotfiles/shell/env.sh
   # Consistent across all platforms
   export PROJECTS_DIR="$HOME/Development"
   ```
   ```

3. **Prosjekt bruker $PROJECTS_DIR:**
   ```bash
   : ${PROJECTS_DIR:="$HOME/Development"}  # Fallback
   ```

---

### Scenario 3: Dele prosjekt med andre

1. **Prosjektet skal ikkje vere avhengig av dotfiles:**
   - ✅ Commit `.env.example`
   - ✅ Commit dev-configs reference
   - ✅ Dokumenter setup i README
   - ❌ ALDRI commit `.env` med secrets

2. **Contributor setup:**
   ```bash
   git clone https://github.com/thusby/prosjekt
   cd prosjekt
   cp .env.example .env
   # Edit .env med eigne credentials
   npm install
   npm start
   ```

---

## 🔐 Sikkerheit & Secrets

### Lagring av Secrets

| Type | Lokasjon | Kryptering | Tilgang |
|------|----------|------------|---------|
| API tokens | `~/.local/share/chezmoi/dotfiles/secrets/*.age` | Age+YubiKey | Kun maintainer |
| OAuth creds | `~/.local/share/chezmoi/dotfiles/secrets/gmail/*.age` | Age+YubiKey | Kun maintainer |
| .env templates | Prosjekt `/.env.example` | Ingen (public) | Alle |
| Lokal .env | Prosjekt `/.env` | Ingen (gitignore) | Lokal |

### Age + YubiKey Workflow

```bash
# Dekrypter secrets (krev YubiKey touch)
chezmoi apply

# Eller bruk helper function
unlock-session

# Legg til nytt secret
# 1. Krypter med Age
echo "SECRET=value" | age -r age1yubikey1q0... -o ~/.local/share/chezmoi/dotfiles/secrets/encrypted_dot_env.new-service.age

# 2. Dekrypter lokalt
chezmoi apply

# 3. Commit encrypted version
cd ~/.local/share/chezmoi
git add dotfiles/secrets/encrypted_dot_env.new-service.age
git commit -m "Add secrets for new-service (Age encrypted)"
git push
```

---

## 📋 Ansvar & Grenser

| Komponent | Ansvar | Git Repo | Deles? |
|-----------|--------|----------|--------|
| **chezmoi** | Master config manager | Privat | Nei (personleg) |
| **dotfiles** | Personleg system + secrets | Privat | Nei (kryptert) |
| **dev-configs** | Team standards | Prosjekt-repo | Ja (open source) |
| **tech-stack.md** | Dokumentasjon | Prosjekt-repo | Ja (dokumentasjon) |
| **Prosjekt-kode** | Business logic | Prosjekt-repo | Ja (open source) |

---

## 🎯 Design-prinsipp

### Separasjon av Concerns

1. **Personleg (dotfiles):**
   - Shell aliases/functions
   - Git global config
   - SSH keys
   - Secrets

2. **Team (dev-configs):**
   - Linting rules
   - Code formatting
   - Test configuration
   - Build standards

3. **Prosjekt (kvar repo):**
   - Business logic
   - .env.example templates
   - README med setup
   - Prosjekt-spesifikke configs

### Avhengigheiter

```
prosjekt → dev-configs (optional, via import/symlink)
prosjekt ↛ dotfiles (ALDRI direkte avhengig)
prosjekt → tech-stack.md (dokumentasjon)

maintainer → dotfiles (secrets via symlink)
contributor → .env.example (copy to .env)
```

---

## 🚀 Komme i gang

### For Maintainer (deg)

```bash
# 1. Sjekk at alt er på plass
chezmoi managed
ls -la ~/dotfiles/secrets/
ls -la ~/Development/dev-configs/

# 2. Start nytt prosjekt
cd ~/Development/projects/
mkdir nytt-prosjekt
cd nytt-prosjekt

# 3. Setup
../../dev-configs/setup.sh python .
ln -s ~/dotfiles/secrets/.env.nytt-prosjekt .env

# 4. Add til chezmoi (optional)
chezmoi add ~/Development/projects/nytt-prosjekt/

# 5. Oppdater dokumentasjon
vim ~/Development/tech-stack.md
```

### For Contributor (andre)

```bash
# 1. Klon prosjekt
git clone https://github.com/thusby/prosjekt
cd prosjekt

# 2. Setup secrets
cp .env.example .env
vim .env  # Fyll inn credentials

# 3. Les dev-configs (optional)
cat ../../dev-configs/USAGE.md

# 4. Start utvikling
npm install
npm start
```

---

## 🔧 Vedlikehald

### Oppdatere dev-configs

```bash
cd ~/Development/dev-configs/
vim python/pyproject-base.toml
git commit -m "ruff: enable new rule XYZ"
git push

# Påverka prosjekt får automatisk oppdatering (via extend/symlink)
```

### Legge til nytt secret

```bash
# 1. Krypter med Age
cd ~/.local/share/chezmoi
echo "API_KEY=xyz" | age -r age1yubikey1q0... -o dotfiles/secrets/encrypted_dot_env.new-service.age

# 2. Commit encrypted version
git add dotfiles/secrets/encrypted_dot_env.new-service.age
git commit -m "Add secrets for new-service (Age encrypted)"
git push

# 3. Dekrypter lokalt
chezmoi apply  # Touch YubiKey

# 4. Symlink frå prosjekt
cd ~/Development/projects/new-service/
ln -s ~/dotfiles/secrets/.env.new-service .env
```

### Synkronisere til ny maskin

```bash
# På ny maskin
chezmoi init https://github.com/thusby/chezmoi-source
chezmoi apply  # Touch YubiKey for secrets

# Secrets blir automatisk dekryptert til ~/dotfiles/secrets/
```

---

## 📊 Oversikt: Kva går kor?

| Filtype | Eksempel | Lokasjon | Synkes av |
|---------|----------|----------|-----------|
| Personleg config | `.bashrc`, `.gitconfig` | `~/dotfiles/` | git |
| Secrets (encrypted) | `encrypted_*.age` | `~/.local/share/chezmoi/dotfiles/secrets/` | git (chezmoi) |
| Secrets (decrypted) | `.env`, `credentials.json` | `~/dotfiles/secrets/` | chezmoi apply |
| Team standards | `pyproject-base.toml` | `dev-configs/` | git |
| Prosjekt-kode | `main.py`, `package.json` | `projects/X/` | git |
| Prosjekt templates | `.env.example` | `projects/X/` | git |
| Claude settings | `settings.json` | `~/.claude/` | chezmoi |
| Dokumentasjon | `tech-stack.md` | `~/Development/` | git |

---

## 🎓 Best Practices

1. ✅ **Age + YubiKey for secrets** - Hardware-backed encryption
2. ✅ **Secrets encrypted in chezmoi** - `.age` files in git
3. ✅ **Standards i dev-configs** - Delt på tvers av prosjekt
4. ✅ **Templates i prosjekt** - `.env.example` for andre
5. ✅ **Dokumentasjon i tech-stack.md** - Samla oversikt
6. ✅ **chezmoi for synk** - Personleg config på tvers av maskiner
7. ✅ **Symlinks for maintainer** - Effektiv secrets-handtering
8. ✅ **Copy for contributors** - Enkel onboarding

---

## 🔗 Relaterte Dokument

- **dotfiles/DOTFILES.md** - Detaljert dotfiles-dokumentasjon
- **dev-configs/README.md** - Team standards-oversikt
- **dev-configs/USAGE.md** - Bruksrettleiing for configs
- **tech-stack.md** - Teknologi-dokumentasjon

---

## 👤 Author

**Terje Husby** - Cohesive development ecosystem architecture
