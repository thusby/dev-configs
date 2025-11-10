# Mac Migration: Developer → Development

Guide for å endre frå `~/Development` til `~/Development` på Mac for konsistens.

---

## Kvifor endre?

- ✅ Same struktur på Mac og Linux
- ✅ Enklare scripts (ingen platform-deteksjon)
- ✅ Konsistent `$PROJECTS_DIR` på begge plattformer

`Developer` er **ikkje** Mac-spesifikt, berre ein populær konvensjon.

---

## Før du startar

### 1. Backup først!

```bash
# På Mac
cd ~
tar -czf ~/Desktop/Developer-backup-$(date +%Y%m%d).tar.gz Developer/
```

### 2. Sjekk kva som peikar til ~/Development

```bash
# Søk etter hardkoda paths
grep -r "Developer" ~/.zshrc ~/.bashrc ~/.config/ 2>/dev/null

# Sjekk symlinks
find ~ -type l -ls 2>/dev/null | grep Developer
```

---

## Migrasjonssteg

### Steg 1: Rename directory

```bash
# På Mac
cd ~
mv Developer Development
```

### Steg 2: Oppdater dotfiles/shell/env.sh

**Tidlegare versjon:**
```bash
# dotfiles/shell/env.sh
case "$OSTYPE" in
    darwin*) PROJECTS_DIR="$HOME/Development" ;;
    linux*)  PROJECTS_DIR="$HOME/Development" ;;
esac
```

**Ny versjon (konsistent):**
```bash
# dotfiles/shell/env.sh
# Consistent across all platforms
export PROJECTS_DIR="$HOME/Development"
```

### Steg 3: Oppdater chezmoi

```bash
# På Mac
chezmoi edit ~/Development/projects/

# Eller legg til på nytt
chezmoi add ~/Development/
```

### Steg 4: Oppdater chezmoi source files

```bash
cd ~/.local/share/chezmoi/

# Rename directory if it's managed by chezmoi
mv Developer Development

# Update any references
grep -r "Developer" . | grep -v ".git"

# Commit changes
git add -A
git commit -m "mac: Rename Developer to Development for consistency"
git push
```

### Steg 5: Test at alt fungerer

```bash
# Test env variable
source ~/dotfiles/shell/env.sh
echo $PROJECTS_DIR  # Should show: /Users/thusby/Development

# Test prosjekt access
cd $PROJECTS_DIR/projects/mcp-common
ls -la

# Test symlinks til secrets
cd $PROJECTS_DIR/projects/mcp-readwise
ls -la .env  # Skal vise symlink

# Test dev-configs
cd $PROJECTS_DIR/dev-configs
./setup.sh python ../mcp-common  # Test at relative paths fungerer
```

---

## Oppdater dokumentasjon

### 1. ECOSYSTEM.md

Fjern platform-spesifikk path-tabell og bruk konsistent path:

```markdown
## Platform Support

All platforms use: `~/Development/projects/`

Previously used platform-specific paths:
- Mac: ~/Development (deprecated)
- Linux: ~/Development
```

### 2. dotfiles/DOTFILES.md

Oppdater platform-tabell:

```markdown
| Platform | Projects Path        |
|----------|---------------------|
| Mac      | `~/Development`     |
| Linux    | `~/Development`     |
```

---

## Potensielle Problem

### Problem 1: Symlinks til secrets

**Symptom:** Symlinks peikar til feil path

**Løysing:**
```bash
cd ~/Development/projects/mcp-readwise
ls -la .env

# Om symlink er øydelagt:
rm .env
ln -s ~/dotfiles/secrets/.env.readwise .env
```

### Problem 2: Hardkoda paths i scripts

**Symptom:** Scripts finn ikkje prosjekt

**Løysing:**
```bash
# Søk etter hardkoda paths
cd ~/Development/projects/
grep -r "$HOME/Development" . --exclude-dir=.git --exclude-dir=node_modules

# Erstatt med $PROJECTS_DIR eller ~/Development
```

### Problem 3: chezmoi state

**Symptom:** chezmoi apply prøver å lage Developer igjen

**Løysing:**
```bash
cd ~/.local/share/chezmoi/
# Rename managed directory
mv Developer Development

git add -A
git commit -m "Rename Developer to Development"
chezmoi apply
```

---

## Rollback Plan

Om noko går gale:

```bash
# Restore frå backup
cd ~
tar -xzf ~/Desktop/Developer-backup-*.tar.gz

# Revert dotfiles changes
cd ~/dotfiles
git log  # Find commit before changes
git revert COMMIT_HASH

# Revert chezmoi changes
cd ~/.local/share/chezmoi
git revert COMMIT_HASH
chezmoi apply
```

---

## Etter migrering

### Oppdater andre maskiner

På Linux-maskiner (som allereie bruker Development):

```bash
cd ~/.local/share/chezmoi
git pull
chezmoi apply

# Verifiser at env.sh er oppdatert
source ~/dotfiles/shell/env.sh
echo $PROJECTS_DIR  # Should show: /home/thusby/Development
```

### Oppdater prosjekt-dokumentasjon

```bash
cd ~/Development/dev-configs/
vim ECOSYSTEM.md
# Fjern Mac-spesifikke paths

git commit -m "docs: Update to use consistent Development path"
git push
```

---

## Quick Migration Script

```bash
#!/bin/bash
# migrate-to-development.sh

set -e

echo "🔄 Migrating ~/Development to ~/Development on Mac"

# 1. Backup
echo "📦 Creating backup..."
tar -czf ~/Desktop/Developer-backup-$(date +%Y%m%d).tar.gz ~/Development/

# 2. Rename
echo "📁 Renaming directory..."
mv ~/Development ~/Development

# 3. Update env.sh
echo "🔧 Updating dotfiles/shell/env.sh..."
cd ~/dotfiles
sed -i '' 's/Developer/Development/g' shell/env.sh

# 4. Update chezmoi
echo "🔄 Updating chezmoi..."
cd ~/.local/share/chezmoi/
if [ -d "Developer" ]; then
    mv Developer Development
fi
git add -A
git commit -m "mac: Rename Developer to Development for consistency"

# 5. Apply changes
echo "✅ Applying changes..."
source ~/dotfiles/shell/env.sh
chezmoi apply

# 6. Test
echo "🧪 Testing..."
echo "PROJECTS_DIR=$PROJECTS_DIR"
ls -la ~/Development/projects/

echo ""
echo "✅ Migration complete!"
echo "   Backup saved to: ~/Desktop/Developer-backup-*.tar.gz"
echo "   New path: ~/Development"
```

Køyr med:
```bash
chmod +x migrate-to-development.sh
./migrate-to-development.sh
```

---

## Verifisering Checklist

- [ ] `~/Development/` eksisterer
- [ ] `~/Development/` eksisterer IKKJE
- [ ] `echo $PROJECTS_DIR` viser `~/Development`
- [ ] Symlinks til secrets fungerer
- [ ] Prosjekt kan buildast/køyrast
- [ ] chezmoi managed lista er oppdatert
- [ ] Git repos er intakte
- [ ] dev-configs setup fungerer

---

## Konklusjon

Etter migrering har du:

✅ Same path på Mac og Linux: `~/Development`
✅ Enklare dotfiles (ingen platform-deteksjon)
✅ Konsistent scripts på tvers av plattformer
✅ Backup av gammal struktur

**Anbefalt:** Gjer migrering! Det vil forenkle vedlikehaldet framover.
