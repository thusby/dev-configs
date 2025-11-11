# Sync-oversikt mellom Linux og Mac

## 1. Git-basert sync (automatisk via git pull/push)

### ~/dotfiles (git@github.com:thusby/dotfiles.git)
- **Innhald**: Shell-konfigurasjon, scripts, symlinks
- **Viktig**: secrets/ er i .gitignore (ikkje i git)
- **Scripts**: unlock-session, lock-session (i scripts/)
- **Sync**: `cd ~/dotfiles && git pull`

### ~/Development/dev-configs (git@github.com:thusby/dev-configs.git)
- **Innhald**: Delte dev-konfigurasjonar + **Chezmoi source**
- **Inkluderer**:
  - TECH-STACK.md
  - CHEZMOI-SETUP.md (dokumentasjon)
  - chezmoi-source/ (encrypted secrets + templates)
  - decrypt-secrets.sh (workaround)
  - re-encrypt-secrets.sh (re-krypter secrets)
- **Sync**: `cd ~/Development/dev-configs && git pull`

### ~/.local/share/chezmoi → ~/Development/dev-configs/chezmoi-source
- **Type**: Symlink
- **Innhald**: Chezmoi source (templates, encrypted secrets)
- **Viktig**: Alle secrets encrypted med Age + Yubikey (cached touch policy)
- **Sync**: Via dev-configs repo
- **Dekryptering**: `chezmoi apply --force` eller `unlock-session`

### ~/Development/projects/mcp-common (git@github.com:thusby/mcp-common.git)
- **Innhald**: MCP-serverar (Gmail, Readwise, Tana)
- **.mcp.json**: Generert av Chezmoi template (ikkje i git)
- **Sync**: `cd ~/Development/projects/mcp-common && git pull`

### ~/Development/projects/localfarm-platform (git@github.com:thusby/localfarm-platform.git)
- **Innhald**: LocalFarm platform kode
- **Sync**: `cd ~/Development/projects/localfarm-platform && git pull`

## 2. Chezmoi-managed (automatisk via chezmoi apply)

### ~/dotfiles/secrets/ (Dekrypterte secrets)
- **Innhald**: Dekrypterte secrets (Age keys, Gmail tokens, etc)
- **Status**: Lokale filer, IKKJE i git
- **Kilde**: Dekryptert frå dev-configs/chezmoi-source/dotfiles/secrets/encrypted_*.age
- **Sync**: `chezmoi apply --force` (krev Yubikey PIN + touch)
- **Alternativ**: `unlock-session` (wrapper rundt chezmoi apply)

### ~/Development/projects/mcp-common/.mcp.json
- **Innhald**: MCP server konfigurasjon
- **Status**: Generert av Chezmoi template
- **Template**: chezmoi-source/Development/projects/mcp-common/dot_mcp.json.tmpl
- **Sync**: Automatisk via `chezmoi apply` (brukar {{ .chezmoi.homeDir }})

### ~/.claude/settings.json
- **Innhald**: Claude Code settings
- **Status**: Generert av Chezmoi template
- **Template**: chezmoi-source/dot_claude/settings.json.tmpl
- **Sync**: Automatisk via `chezmoi apply`

### ~/.config/Claude/claude_desktop_config.json
- **Innhald**: Claude Desktop konfigurasjon
- **Status**: Generert av Chezmoi template
- **Template**: chezmoi-source/private_dot_config/Claude/claude_desktop_config.json.tmpl
- **Sync**: Automatisk via `chezmoi apply`

## 3. Ikkje synca (maskin-spesifikk)

### ~/.cache/chezmoi-unlocked
- **Formål**: Session state marker
- **Sync**: NEI - maskin-spesifikk

### ~/.config/chezmoi/chezmoistate.boltdb
- **Formål**: Chezmoi state database
- **Sync**: NEI - maskin-spesifikk

### ~/.config/chezmoi/chezmoi.toml
- **Formål**: Chezmoi konfigurasjon (Age recipient)
- **Sync**: Manuell kopiering (same konfig på begge maskinar)

### ~/.config/chezmoi/yubikey.txt
- **Formål**: Age identity for Yubikey
- **Sync**: Manuell kopiering (same Yubikey-identitet)

## 4. Anbefalt sync-workflow

### Dagleg sync (hente endringar):
```bash
# Dotfiles
cd ~/dotfiles && git pull

# Dev configs (inkluderer Chezmoi source)
cd ~/Development/dev-configs && git pull

# Dekrypter secrets med Yubikey (om nødvendig)
unlock-session
# eller
export PATH="$HOME/.cargo/bin:$PATH"
chezmoi apply --force

# MCP-common
cd ~/Development/projects/mcp-common && git pull

# LocalFarm
cd ~/Development/projects/localfarm-platform && git pull
```

### Pushe endringar:
```bash
# Frå den maskinen der du gjorde endringar
cd ~/dotfiles && git push
cd ~/Development/dev-configs && git push
cd ~/Development/projects/mcp-common && git push
cd ~/Development/projects/localfarm-platform && git push
```

### Oppdatere secrets:
```bash
# 1. Endre dekryptert fil
vim ~/dotfiles/secrets/.env.readwise

# 2. Re-kryptere med Yubikey
cd ~/Development/dev-configs
./re-encrypt-secrets.sh

# 3. Commit og push
git add -A
git commit -m "Update secrets"
git push

# 4. På andre maskinar
cd ~/Development/dev-configs && git pull
chezmoi apply --force  # Dekrypter med Yubikey
```

## 5. Yubikey + Age + Chezmoi

### Konfigurasjon
- **Yubikey**: Primary Serial 12765346
- **Touch policy**: Cached (15 sekund)
- **PIN policy**: Once (per session)
- **Age identity**: AGE-PLUGIN-YUBIKEY-15TYVYQYZYQMEE6C2557XS
- **Recipient**: age1yubikey1q0ejnkxdcpffq89w4ymda7l62nenh4cptnc2wj4aqw6j8t8k6csgjvq5ctg

### Encrypted Secrets (i git)
```
~/Development/dev-configs/chezmoi-source/dotfiles/secrets/
├── encrypted_dot_env.pet.age
├── encrypted_dot_env.readwise.age
├── age/encrypted_key.txt.age
├── ansible/encrypted_galaxy_token.age
├── claude/encrypted_credentials.json.age
├── conda/encrypted_aau_token.age
├── conda/encrypted_aau_token_host.age
├── gmail/encrypted_credentials.json.age
├── gmail/encrypted_dot_env.gmail.age
├── gmail/encrypted_token.json.age
├── gpg/encrypted_private-key.asc.age
├── gpg/encrypted_public-key.asc.age
├── postman/encrypted_dot_env.postman.age
└── tana/encrypted_dot_env.tana.age
```

### Decrypted Secrets (IKKJE i git)
```
~/dotfiles/secrets/
├── .env.pet
├── .env.readwise
├── age/key.txt
├── ansible/galaxy_token
├── claude/credentials.json
├── conda/aau_token
├── conda/aau_token_host
├── gmail/credentials.json
├── gmail/.env.gmail
├── gmail/token.json
├── gpg/private-key.asc
├── gpg/public-key.asc
├── postman/.env.postman
└── tana/.env.tana
```

### Fordel med cached touch policy
- **Éin Yubikey-touch** dekrypterer alle 14 secrets
- Touch caches i 15 sekund
- `chezmoi apply --force` fungerer sømløst
- Framleis hardware-backed security

## 6. Oppsett på ny maskin

Sjå **CHEZMOI-SETUP.md** i dev-configs repo for detaljert guide.

**Kort versjon:**
```bash
# 1. Clone repos
cd ~/Development
git clone git@github.com:thusby/dev-configs.git
git clone git@github.com:thusby/dotfiles.git

# 2. Sett opp Chezmoi symlink
ln -s ~/Development/dev-configs/chezmoi-source ~/.local/share/chezmoi

# 3. Kopier Chezmoi config
# (yubikey.txt og chezmoi.toml frå anna maskin)

# 4. Dekrypter secrets
export PATH="$HOME/.cargo/bin:$PATH"
chezmoi apply --force

# 5. Kopier session scripts
cp ~/dotfiles/scripts/{unlock-session,lock-session} ~/.local/bin/
chmod +x ~/.local/bin/{unlock-session,lock-session}
```

## 7. Forbetringsforslag

### A. Encrypted-at-rest (Issue #1)
**Status**: Dekrypterte secrets ligg som klartekst i ~/dotfiles/secrets/

**Alternativ**:
1. Disk-kryptering (LUKS/FileVault) + lock-session ved logout
2. tmpfs for ~/dotfiles/secrets (RAM-disk)
3. Session-basert: lock-session slettar dekrypterte filer

### B. Backup Yubikey
**TODO**: Sett opp backup Yubikey (Serial: 33709875) med same Age-identitet

### C. Automasjon
Vurder eit `sync-all.sh` script:
```bash
#!/bin/bash
echo "Syncing all repos..."
cd ~/dotfiles && git pull
cd ~/Development/dev-configs && git pull
chezmoi apply --force
cd ~/Development/projects/mcp-common && git pull
cd ~/Development/projects/localfarm-platform && git pull
echo "✅ All repos synced!"
```

## 8. Viktige Filer

### Dokumentasjon
- `~/Development/dev-configs/CHEZMOI-SETUP.md` - Komplett Chezmoi guide
- `~/Development/dev-configs/TECH-STACK.md` - Tech stack oversikt
- Denne fila: Sync-oversikt

### Scripts
- `~/dotfiles/scripts/unlock-session` - Dekrypter secrets med Yubikey
- `~/dotfiles/scripts/lock-session` - Låse sesjon
- `~/Development/dev-configs/decrypt-secrets.sh` - Manuell dekryptering (workaround)
- `~/Development/dev-configs/re-encrypt-secrets.sh` - Re-krypter endra secrets

### Konfig
- `~/.config/chezmoi/chezmoi.toml` - Chezmoi Age konfig
- `~/.config/chezmoi/yubikey.txt` - Age identity
- `~/dotfiles/shell/.zshrc` - Session check for låste secrets

## 9. Framtidig Arbeid

- [ ] Issue #1: Implementer encrypted-at-rest
- [ ] Sett opp backup Yubikey
- [ ] Lag sync-all.sh automation script
- [ ] Vurder Chezmoi-templates for fleire config-filer
- [ ] Dokumenter MCP server oppsett i detalj
