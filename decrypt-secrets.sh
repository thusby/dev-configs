#!/bin/bash
# Dekrypterer alle Age-krypterte secrets manuelt
# Workaround for Chezmoi TTY-problem med Yubikey touch

set -e

export PATH="$HOME/.cargo/bin:$PATH"

CHEZMOI_SOURCE="$HOME/Development/dev-configs/chezmoi-source"
TARGET_BASE="$HOME"

echo "🔐 Dekrypterer secrets med Yubikey..."
echo "📍 Source: $CHEZMOI_SOURCE"
echo ""

# Function to decrypt a file
decrypt_file() {
    local src="$1"
    local dst="$2"

    echo "  Dekrypterer: $(basename $src) -> $dst"
    mkdir -p "$(dirname $dst)"
    age -d -i ~/.config/chezmoi/yubikey.txt "$src" > "$dst"
    echo "  ✓ Ferdig"
}

# Decrypt all secrets
decrypt_file "$CHEZMOI_SOURCE/dotfiles/secrets/encrypted_dot_env.pet.age" "$TARGET_BASE/dotfiles/secrets/.env.pet"
decrypt_file "$CHEZMOI_SOURCE/dotfiles/secrets/encrypted_dot_env.readwise.age" "$TARGET_BASE/dotfiles/secrets/.env.readwise"
decrypt_file "$CHEZMOI_SOURCE/dotfiles/secrets/age/encrypted_key.txt.age" "$TARGET_BASE/dotfiles/secrets/age/key.txt"
decrypt_file "$CHEZMOI_SOURCE/dotfiles/secrets/ansible/encrypted_galaxy_token.age" "$TARGET_BASE/dotfiles/secrets/ansible/galaxy_token"
decrypt_file "$CHEZMOI_SOURCE/dotfiles/secrets/claude/encrypted_credentials.json.age" "$TARGET_BASE/dotfiles/secrets/claude/credentials.json"
decrypt_file "$CHEZMOI_SOURCE/dotfiles/secrets/conda/encrypted_aau_token.age" "$TARGET_BASE/dotfiles/secrets/conda/aau_token"
decrypt_file "$CHEZMOI_SOURCE/dotfiles/secrets/conda/encrypted_aau_token_host.age" "$TARGET_BASE/dotfiles/secrets/conda/aau_token_host"
decrypt_file "$CHEZMOI_SOURCE/dotfiles/secrets/gmail/encrypted_credentials.json.age" "$TARGET_BASE/dotfiles/secrets/gmail/credentials.json"
decrypt_file "$CHEZMOI_SOURCE/dotfiles/secrets/gmail/encrypted_dot_env.gmail.age" "$TARGET_BASE/dotfiles/secrets/gmail/.env.gmail"
decrypt_file "$CHEZMOI_SOURCE/dotfiles/secrets/gmail/encrypted_token.json.age" "$TARGET_BASE/dotfiles/secrets/gmail/token.json"
decrypt_file "$CHEZMOI_SOURCE/dotfiles/secrets/gpg/encrypted_private-key.asc.age" "$TARGET_BASE/dotfiles/secrets/gpg/private-key.asc"
decrypt_file "$CHEZMOI_SOURCE/dotfiles/secrets/gpg/encrypted_public-key.asc.age" "$TARGET_BASE/dotfiles/secrets/gpg/public-key.asc"
decrypt_file "$CHEZMOI_SOURCE/dotfiles/secrets/postman/encrypted_dot_env.postman.age" "$TARGET_BASE/dotfiles/secrets/postman/.env.postman"
decrypt_file "$CHEZMOI_SOURCE/dotfiles/secrets/tana/encrypted_dot_env.tana.age" "$TARGET_BASE/dotfiles/secrets/tana/.env.tana"

echo ""
echo "✅ Alle secrets dekrypterte!"
echo ""
echo "📋 Verifiser:"
echo "   ls -la ~/dotfiles/secrets/"
echo "   head -1 ~/dotfiles/secrets/.env.pet"
