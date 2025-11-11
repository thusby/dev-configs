# Chezmoi + Age + Yubikey Oppsett

## Oversikt

Me brukar **Chezmoi** for dotfile-administrasjon med **Age-kryptering** og **Yubikey** for hardware-backed secrets.

### Nøkkelkomponentar

- **Chezmoi source**: `~/Development/dev-configs/chezmoi-source/` (git-tracka)
- **Symlink**: `~/.local/share/chezmoi` → `~/Development/dev-configs/chezmoi-source`
- **Encrypted secrets**: `dev-configs/chezmoi-source/dotfiles/secrets/encrypted_*.age`
- **Decrypted secrets**: `~/dotfiles/secrets/` (IKKJE i git)
- **Yubikey**: Primary Serial 12765346 med **cached touch policy** (15 sekund)

## Yubikey Konfigurasjon

### Touch Policy
```
Touch policy: Cached (15 seconds)
PIN policy: Once (per session)
```

**Fordel**: Éin Yubikey-touch dekrypterer alle 14 secrets (cache i 15 sek).

### Age Identitet
```
# ~/.config/chezmoi/yubikey.txt
AGE-PLUGIN-YUBIKEY-15TYVYQYZYQMEE6C2557XS

# Recipient
age1yubikey1q0ejnkxdcpffq89w4ymda7l62nenh4cptnc2wj4aqw6j8t8k6csgjvq5ctg
```

## Dagleg Bruk

### Dekryptere Secrets (Første gong / Etter reboot)

**Metode 1: Automatisk med unlock-session**
```bash
unlock-session
```
- Køyrer `chezmoi apply --force`
- Krev Yubikey PIN + éin touch
- Dekrypterer alle 14 secrets
- Markerer sesjon som ulåst

**Metode 2: Manuelt med Chezmoi**
```bash
export PATH="$HOME/.cargo/bin:$PATH"
chezmoi apply --force
```

### Verifisere Dekrypterte Secrets
```bash
ls -la ~/dotfiles/secrets/
head -1 ~/dotfiles/secrets/.env.pet
```

### Låse Sesjon (Valgfritt)
```bash
lock-session
```
- Slettar `~/.cache/chezmoi-unlocked`
- **MERK**: Slettar IKKJE dekrypterte filer (sjå Issue #1)

## Endre Secrets

### 1. Endre Dekryptert Fil
```bash
vim ~/dotfiles/secrets/.env.readwise
```

### 2. Re-kryptere Med Yubikey
```bash
cd ~/Development/dev-configs
./re-encrypt-secrets.sh
```
- Krev Yubikey touch
- Re-krypterer alle 14 filer

### 3. Commit og Push
```bash
cd ~/Development/dev-configs
git add -A
git commit -m "Update secrets"
git push
```

### 4. Sync Til Andre Maskinar
```bash
# På Mac/andre maskinar
cd ~/Development/dev-configs
git pull
chezmoi apply --force  # Dekrypter med Yubikey
```

## Filstruktur

### Git-tracka (Encrypted)
```
~/Development/dev-configs/
├── chezmoi-source/
│   ├── dotfiles/secrets/
│   │   ├── encrypted_dot_env.pet.age
│   │   ├── encrypted_dot_env.readwise.age
│   │   ├── gmail/
│   │   │   ├── encrypted_credentials.json.age
│   │   │   ├── encrypted_dot_env.gmail.age
│   │   │   └── encrypted_token.json.age
│   │   └── ... (14 encrypted files totalt)
│   ├── Development/projects/mcp-common/
│   │   └── dot_mcp.json.tmpl  # Template med {{ .chezmoi.homeDir }}
│   └── private_dot_config/Claude/
│       └── claude_desktop_config.json.tmpl
├── decrypt-secrets.sh    # Manuell dekryptering (workaround)
└── re-encrypt-secrets.sh # Re-krypter endra secrets
```

### Lokal (Decrypted, IKKJE i git)
```
~/dotfiles/secrets/
├── .env.pet           # Dekryptert klartekst
├── .env.readwise      # Dekryptert klartekst
├── gmail/
│   ├── credentials.json
│   ├── .env.gmail
│   └── token.json
└── ... (14 dekrypterte filer totalt)
```

### Chezmoi Config
```
~/.config/chezmoi/
├── chezmoi.toml    # Age config + recipient
└── yubikey.txt     # Age identity
```

## Templates

Chezmoi genererer filer med dynamiske paths:

### .mcp.json Template
```json
{
  "mcpServers": {
    "gmail": {
      "command": "uv",
      "args": [
        "--directory",
        "{{ .chezmoi.homeDir }}/Development/projects/mcp-common/packages/mcp-gmail",
        ...
      ],
      "env": {
        "MCP_GMAIL_CREDENTIALS_PATH": "{{ .chezmoi.homeDir }}/dotfiles/secrets/gmail/credentials.json",
        ...
      }
    }
  }
}
```

**Resultat på Linux**: `/home/thusby/Development/...`
**Resultat på Mac**: `/Users/thusby/Development/...`

## Oppsett På Ny Maskin

### 1. Installer Avhengigheiter
```bash
# Age plugin for Yubikey
cargo install age-plugin-yubikey

# Chezmoi (om ikkje installert)
brew install chezmoi  # Mac
# eller apt install chezmoi  # Linux
```

### 2. Clone Repos
```bash
cd ~/Development
git clone git@github.com:thusby/dev-configs.git
git clone git@github.com:thusby/dotfiles.git
```

### 3. Sett Opp Chezmoi
```bash
# Lag symlink til dev-configs chezmoi source
ln -s ~/Development/dev-configs/chezmoi-source ~/.local/share/chezmoi

# Verifiser
chezmoi source-path
chezmoi managed | grep dotfiles/secrets | head -5
```

### 4. Kopier Chezmoi Config
```bash
# Kopier frå anna maskin, eller opprett ny
mkdir -p ~/.config/chezmoi

# yubikey.txt
cat > ~/.config/chezmoi/yubikey.txt << 'EOF'
# age identity file for Yubikey
# Primary Yubikey (Serial: 12765346)
# Touch policy: Cached (15 seconds)
AGE-PLUGIN-YUBIKEY-15TYVYQYZYQMEE6C2557XS
EOF

# chezmoi.toml (sjå ~/Development/dev-configs/docs/ for full versjon)
```

### 5. Dekrypter Secrets
```bash
# Sett inn Yubikey
ykman list

# Dekrypter
export PATH="$HOME/.cargo/bin:$PATH"
chezmoi apply --force
```

### 6. Kopier Session Scripts
```bash
cp ~/dotfiles/scripts/unlock-session ~/.local/bin/
cp ~/dotfiles/scripts/lock-session ~/.local/bin/
chmod +x ~/.local/bin/{unlock-session,lock-session}
```

### 7. Verifiser
```bash
# Sjekk dekrypterte filer
ls -la ~/dotfiles/secrets/
head -1 ~/dotfiles/secrets/.env.pet

# Sjekk MCP config
cat ~/Development/projects/mcp-common/.mcp.json
```

## Feilsøking

### "age: error: yubikey plugin: couldn't start plugin"
```bash
# Legg til cargo bin i PATH
export PATH="$HOME/.cargo/bin:$PATH"

# Eller legg til i ~/.zshrc / ~/.bashrc
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc
```

### "Touch policy: Always" (gammal config)
Viss du har den gamle touch policy (krev touch for kvar fil), regenerer identitet:
```bash
age-plugin-yubikey --generate --slot 1 --touch-policy cached --name primary --force
# Oppdater yubikey.txt og chezmoi.toml
# Re-krypter alle secrets
```

### Chezmoi apply hengar
- Køyr på fysisk maskin (ikkje over SSH)
- Bruk `--force` for å skippe interaktiv diff
- Sjekk at `age-plugin-yubikey` er i PATH

### "not a terminal" / TTY-problem
Normal ved køyring over SSH. Køyr direkte på maskina eller bruk workaround:
```bash
~/Development/dev-configs/decrypt-secrets.sh
```

## Security Considerations

### Encrypted at Rest
**Status**: Dekrypterte secrets ligg som **klartekst** i `~/dotfiles/secrets/`

**Løysingar** (sjå Issue #1):
1. **Disk-kryptering** (LUKS/FileVault) - Anbefalt
2. **Session-basert**: Bruk `lock-session` ved logout
3. **tmpfs**: Mount `~/dotfiles/secrets` i RAM

### Backup Yubikey
**VIKTIG**: Viss primær Yubikey (12765346) blir mista:
1. Alle secrets må re-krypterast med backup Yubikey
2. Eller dekrypterte filer i `~/dotfiles/secrets/` kan brukast til re-kryptering

**TODO**: Sett opp backup Yubikey med same secrets.

## Ressursar

- [Chezmoi Age dokumentasjon](https://www.chezmoi.io/user-guide/encryption/age/)
- [age-plugin-yubikey](https://github.com/str4d/age-plugin-yubikey)
- [Age best practices](https://words.filippo.io/passage/)
- Issue #1: Encrypted-at-rest diskusjon
