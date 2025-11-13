# Claude Code Permissions Hierarchy

**Motto:** Minst mogleg godkjenningar, innanfor sikre ramer

## 3-Nivå Struktur

```
1. Global (read-only basis)
   → ~/Development/dev-configs/claude-global-settings.json
   → Trygge read-only kommandoar
   → Gjeld for ALLE prosjekt

2. Development System (infrastructure)
   → ~/Development/.claude/settings.local.json
   → System-setup, git, docker, secrets
   → Gjeld for alt under ~/Development

3. Project-Specific (minimal)
   → ~/Development/projects/X/.claude/settings.local.json
   → Berre det som er unikt for prosjektet
   → Bruk template: project-template-settings.local.json
```

## Prinsipp for plassering

### Global (claude-global-settings.json)
**Når:** Kommandoen er:
- Read-only (inga destruktive operasjonar)
- Nyttig for alle prosjekt
- Trygg utan kontekst

**Døme:**
```json
"Bash(cat:*)",
"Bash(ls:*)",
"Bash(git status:*)",
"Bash(git log:*)",
"WebSearch"
```

### Development System (Development/.claude/settings.local.json)
**Når:** Kommandoen er:
- Infrastruktur eller system-setup
- Generell utviklingsverktøy (git write, docker, npm)
- Kan vere destruktiv, men kontrollert
- Gjeld på tvers av prosjekt

**VIKTIG:** JSON-filer støttar ikkje kommentarar! Bruk `development-template-settings.local.json` som base.

**Inkludert (sjå template for full liste):**
```json
Git write: git add, commit, push, pull, merge, rebase, checkout, reset, stash, tag
GitHub CLI: gh (alle subkommandoar)
File ops: mkdir, touch, cp, mv, ln, chmod, tar, zip, unzip
Network: curl, wget, ssh, scp, rsync
Process: kill, killall, pkill
System: systemctl, journalctl, apt
Docker: docker, docker compose
Python: python, pip, uv, pytest
Node: node, npm, npx
Rust: cargo, rustc
Secrets: chezmoi, age, age-plugin-yubikey, gpg, ykman
Tasks: task, harsh
Claude: claude mcp
Web: code.claude.com, gofastmcp.com

Deny: sudo rm, rm -rf /, dd
```

### Project-Specific (projects/X/.claude/settings.local.json)
**Når:** Kommandoen er:
- Spesifikk for dette prosjektet
- IKKJE nyttig for andre prosjekt
- Prosjekt-spesifikke build scripts eller verktøy

**Døme:**
```json
"Bash(./build.sh:*)",
"Bash(ansible-playbook:*)",
"Bash(make:*)",
"WebFetch(domain:api.myproject.com)"
```

## Setup for nytt prosjekt

### 1. Kopier template
```bash
cp ~/Development/dev-configs/project-template-settings.local.json \
   ~/Development/projects/mitt-prosjekt/.claude/settings.local.json
```

### 2. Legg til berre prosjekt-spesifikke permissions
```json
{
  "permissions": {
    "allow": [
      // Fjern placeholder
      // "Bash(echo PROJECT_PLACEHOLDER:*)",

      // Legg til prosjekt-spesifikke permissions
      "Bash(./scripts/deploy.sh:*)",
      "WebFetch(domain:api.example.com)"
    ]
  }
}
```

### 3. IKKJE dupliser global eller development permissions!

## Arv-hierarki

Claude Code arvar permissions oppover:

```
Project-specific
    ↓ (arver)
Development System
    ↓ (arver)
Global (implisitt gjennom dev-configs standard)
```

## Sikkerheitsprinsipp

### ✅ ALLTID TILLATE (Global)
- Read-only filoperasjonar (cat, ls, grep)
- Git read-only (status, log, diff)
- System info (df, ps, whoami)
- Dokumentasjon (WebSearch, docs.python.org)

### ⚠️ TILLATE MED OMTANKE (Development)
- Git write (commit, push)
- Docker operations
- System admin (sudo systemctl)
- Package managers (apt, npm)

### ❌ ALDRI TILLATE (Deny)
- `sudo rm:*` (destruktiv)
- `rm -rf /:*` (katastrofal)
- `dd:*` (disk-destruktiv)

## Eksempel: Web-prosjekt

```json
// projects/my-web-app/.claude/settings.local.json
{
  "permissions": {
    "allow": [
      // Build system (prosjekt-spesifikk)
      "Bash(npm run build:*)",
      "Bash(npm run test:*)",

      // Deployment (prosjekt-spesifikk)
      "Bash(./scripts/deploy-staging.sh:*)",

      // API for development (prosjekt-spesifikk)
      "WebFetch(domain:api.myapp.com)",
      "WebFetch(domain:staging.myapp.com)"
    ]
  }
}
```

**Merk:** Treng IKKJE `git commit`, `npm install`, `docker compose` - dei er allereie i Development-nivå!

## Eksempel: Embedded-prosjekt (STM32)

```json
// projects/dev-stm32/.claude/settings.local.json
{
  "permissions": {
    "allow": [
      // Build system (prosjekt-spesifikk)
      "Bash(make:*)",
      "Bash(./build.sh:*)",

      // Flashing (prosjekt-spesifikk)
      "Bash(st-flash:*)",
      "Bash(openocd:*)",

      // Toolchain (prosjekt-spesifikk)
      "Bash(arm-none-eabi-gcc:*)",
      "Bash(arm-none-eabi-size:*)",

      // PDF docs (prosjekt-spesifikk)
      "Bash(pdftotext:*)",

      // Vendor docs (prosjekt-spesifikk)
      "WebFetch(domain:www.st.com)",
      "WebFetch(domain:community.st.com)"
    ]
  }
}
```

## Eksempel: Server-operations prosjekt

```json
// projects/localfarm/.claude/settings.local.json
{
  "permissions": {
    "allow": [
      // Ansible (prosjekt-spesifikk)
      "Bash(ansible:*)",
      "Bash(ansible-playbook:*)",
      "Bash(ansible-vault view:*)",

      // Remote server access (prosjekt-spesifikk - spesifikke hosts)
      "Bash(ssh farm-server:*)",
      "Bash(ssh farm-backup:*)",

      // Read production configs (prosjekt-spesifikk)
      "Read(//opt/monitoring/**)",
      "Read(//etc/nginx/**)",

      // Service verification (prosjekt-spesifikk)
      "Bash(./verify_services.sh:*)"
    ]
  }
}
```

## Vedlikehald

### Oppdatere global standard
Rediger `~/Development/dev-configs/claude-global-settings.json` og push til git. Alle prosjekt får oppdateringa automatisk.

### Oppdatere development-nivå
Rediger `~/Development/.claude/settings.local.json`. Dette er maskin-spesifikk og går IKKJE i git.

### Oppdatere prosjekt
Rediger `~/Development/projects/X/.claude/settings.local.json`. Dette går i prosjekt-repoet og deles med andre.

## Feilsøking

### "Permission denied" for standard kommando
→ Legg til i **Global** (claude-global-settings.json) om det er trygt for alle

### "Permission denied" for git commit
→ Sjekk at **Development** settings.local.json eksisterer i ~/Development/.claude/

### For mange godkjenningar
→ Fjern duplikat frå prosjekt-settings som allereie er i Global eller Development

### Usikker på plassering?
→ Start med **prosjekt-spesifikk**, flytt oppover når du ser det vert brukt av fleire prosjekt

## Migrering frå eksisterande prosjekt

1. **Les eksisterande** `settings.local.json`
2. **Identifiser kva som er global** (read-only, nyttig for alle)
3. **Identifiser kva som er development** (git write, docker, system)
4. **Behald berre prosjekt-spesifikke** permissions
5. **Test** at alt funkar

## Referanse

Se også:
- `AI-INSTRUCTIONS.md` - For AI assistants generelt
- `ARCHITECTURE.md` - For ecosystem-arkitektur
- `ECOSYSTEM.md` - For fil-plassering generelt
