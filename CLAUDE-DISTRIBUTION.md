# Claude Code Settings Distribution

Distribusjonssystem for 3-nivå Claude Code permissions-hierarki.

## 📦 Oversikt

```
~/Development/dev-configs/          # Dette repoet (git-tracked)
├── setup-claude-hierarchy.sh      # Oppretta grunnstruktur
├── setup-new-project.sh            # Sett opp nytt prosjekt
├── update-project-settings.sh      # Oppdater eitt prosjekt
├── update-all-projects.sh          # Oppdater alle prosjekt
├── claude-global-settings.json     # Global permissions (referanse)
├── development-template-settings.local.json  # Development-nivå template
└── project-template-settings.local.json      # Prosjekt-nivå template
```

## 🚀 Første gongs oppsett

### 1. Sett opp hierarkiet
```bash
cd ~/Development/dev-configs
./setup-claude-hierarchy.sh
```

Dette opprettar:
- `~/Development/.claude/settings.local.json` (development-nivå)
- Verifiserer at `~/.claude/CLAUDE.md` symlink eksisterer (global-nivå)

### 2. Verifiser strukturen
```bash
# Global (via dotfiles)
ls -l ~/.claude/CLAUDE.md

# Development
cat ~/Development/.claude/settings.local.json

# Prosjekt (lagar seinare)
```

## 🎯 Opprett nytt prosjekt

```bash
./setup-new-project.sh ~/Development/projects/my-new-project
```

Dette:
1. Opprettar `.claude/` mappe i prosjektet
2. Kopierer `project-template-settings.local.json`
3. Gir deg instruksjonar for vidare redigering

### Redigere prosjekt-settings

```bash
cd ~/Development/projects/my-new-project
nano .claude/settings.local.json
```

**Viktig:** Fjern `PROJECT_PLACEHOLDER` og legg til **berre** prosjektspesifikke permissions.

**Døme:**
```json
{
  "permissions": {
    "allow": [
      // Build system
      "Bash(make:*)",
      "Bash(./build.sh:*)",

      // Prosjekt-spesifikk API
      "WebFetch(domain:api.myproject.com)"
    ]
  }
}
```

**Commit til git:**
```bash
git add .claude/settings.local.json
git commit -m "Add Claude Code project settings"
```

## 🔄 Oppdater eksisterande prosjekt

### Eitt prosjekt
```bash
./update-project-settings.sh ~/Development/projects/existing-project
```

Dette:
1. Skapar backup av eksisterande settings
2. Analyserer for duplikat permissions
3. Tilbyr automatisk cleanup
4. Fjerner global/development permissions som no er dekka av hierarkiet

### Alle prosjekt
```bash
./update-all-projects.sh
```

Går igjennom alle prosjekt under `~/Development/projects/` med `.claude/settings.local.json`.

## 📋 Hierarki-referanse

### Nivå 1: Global (read-only)
**Fil:** `~/.claude/CLAUDE.md` → `~/dotfiles/claude/CLAUDE.global.md`
**Innhald:** Prosjekt-kontekst og dokumentasjon
**Managed by:** dotfiles (chezmoi)

**Permissions:** (referanse i `claude-global-settings.json`)
- Read-only filoperasjonar: cat, ls, grep
- Git read: status, log, diff
- System info: whoami, df, ps
- Web: WebSearch, github.com, docs.python.org

### Nivå 2: Development (infrastructure)
**Fil:** `~/Development/.claude/settings.local.json`
**Innhald:** Infrastruktur og systemoppsett
**Managed by:** lokalt (IKKJE i git)

**Permissions:**
- Git write: commit, push, pull
- Docker: docker, docker compose
- Package managers: npm, pip, uv
- System admin: systemctl, apt

### Nivå 3: Project (spesifikke)
**Fil:** `~/Development/projects/X/.claude/settings.local.json`
**Innhald:** BERRE prosjektspesifikke permissions
**Managed by:** prosjekt-repo (i git)

**Permissions:** (døme)
- Build scripts: ./build.sh, make
- Toolchains: arm-none-eabi-gcc, openocd
- APIs: WebFetch(domain:api.example.com)

## 🔧 Vedlikehald

### Oppdater global standard
```bash
# Rediger referanse
nano ~/Development/dev-configs/claude-global-settings.json
git commit -am "Update global permissions reference"
git push

# NB: Faktiske globale permissions er hardkoda i Claude Code
# Denne fila er berre for dokumentasjon
```

### Oppdater development template
```bash
# Rediger template
nano ~/Development/dev-configs/development-template-settings.local.json
git commit -am "Update development template"

# Distribuer til eksisterande
cp development-template-settings.local.json ~/Development/.claude/settings.local.json
```

### Oppdater prosjekt template
```bash
# Rediger template
nano ~/Development/dev-configs/project-template-settings.local.json
git commit -am "Update project template"

# Nye prosjekt vil bruke ny template automatisk
```

## 🧪 Test hierarkiet

```bash
# Sjekk kva settings som gjeld for eit prosjekt
cd ~/Development/projects/my-project

# Claude Code vil arve i denne rekkefølgja:
# 1. Global (hardkoda + ~/.claude/CLAUDE.md)
# 2. Development (~/Development/.claude/settings.local.json)
# 3. Project (./claude/settings.local.json)
```

## 🐛 Feilsøking

### "Permission denied" for standard kommando
```bash
# Sjekk om det er i global-nivå
grep "Bash(COMMAND:" ~/Development/dev-configs/claude-global-settings.json

# Eller development-nivå
grep "Bash(COMMAND:" ~/Development/.claude/settings.local.json
```

### For mange godkjenningar
```bash
# Køyr cleanup på prosjekt
./update-project-settings.sh ~/Development/projects/my-project
```

### Backup etter feilaktig cleanup
```bash
cd ~/Development/projects/my-project/.claude
ls -la *.backup-*
# Gjenopprett
cp settings.local.json.backup-YYYYMMDD-HHMMSS settings.local.json
```

## 📚 Relatert dokumentasjon

- `CLAUDE-PERMISSIONS.md` - Full hierarki-dokumentasjon
- `AI-INSTRUCTIONS.md` - AI assistant retningslinjer
- `ECOSYSTEM.md` - Overordna ecosystem-struktur

## 🔐 Sikkerheit

**ALLTID** i `deny`-lista:
```json
"deny": [
  "Bash(sudo rm:*)",
  "Bash(rm -rf /:*)",
  "Bash(dd:*)"
]
```

**ALDRI** commit:
- Credentials
- API keys
- Private secrets
- Personal dotfiles som `~/Development/.claude/settings.local.json`

## 🎓 Døme

### Scenario 1: Nytt web-prosjekt
```bash
./setup-new-project.sh ~/Development/projects/my-web-app
cd ~/Development/projects/my-web-app
nano .claude/settings.local.json
# Legg til: Bash(npm run build:*), WebFetch(domain:api.myapp.com)
git add .claude/settings.local.json
git commit -m "Add Claude settings"
```

### Scenario 2: Migrere eksisterande prosjekt
```bash
./update-project-settings.sh ~/Development/projects/old-project
# Sjekk output, reviewer endringar
cd ~/Development/projects/old-project
git diff .claude/settings.local.json
git add .claude/settings.local.json
git commit -m "Migrate to 3-level Claude hierarchy"
```

### Scenario 3: Bulk-oppdatering av alle prosjekt
```bash
./update-all-projects.sh
# Reviewer alle endringar
cd ~/Development/projects
for dir in */; do
  echo "=== $dir ==="
  git -C "$dir" diff .claude/settings.local.json
done
```
