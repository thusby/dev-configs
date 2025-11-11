#!/bin/bash
# Re-krypterer alle secrets med ny Yubikey identitet (cached touch policy)

set -e

export PATH="$HOME/.cargo/bin:$PATH"

RECIPIENT="age1yubikey1q0ejnkxdcpffq89w4ymda7l62nenh4cptnc2wj4aqw6j8t8k6csgjvq5ctg"
SOURCE_DIR="$HOME/dotfiles/secrets"
CHEZMOI_SOURCE="$HOME/Development/dev-configs/chezmoi-source/dotfiles/secrets"

echo "🔐 Re-krypterer alle secrets med ny Yubikey identitet..."
echo "📍 Recipient: $RECIPIENT"
echo "👆 Yubikey vil blinke - røre éin gong (cache i 15 sek)"
echo ""

# Function to re-encrypt a file
reencrypt_file() {
    local src="$1"
    local dst="$2"

    echo "  Krypterer: $src -> $dst"
    mkdir -p "$(dirname $dst)"
    age -r "$RECIPIENT" -o "$dst" "$src"
    echo "  ✓ Ferdig"
}

# Re-encrypt all secrets
reencrypt_file "$SOURCE_DIR/.env.pet" "$CHEZMOI_SOURCE/encrypted_dot_env.pet.age"
reencrypt_file "$SOURCE_DIR/.env.readwise" "$CHEZMOI_SOURCE/encrypted_dot_env.readwise.age"
reencrypt_file "$SOURCE_DIR/age/key.txt" "$CHEZMOI_SOURCE/age/encrypted_key.txt.age"
reencrypt_file "$SOURCE_DIR/ansible/galaxy_token" "$CHEZMOI_SOURCE/ansible/encrypted_galaxy_token.age"
reencrypt_file "$SOURCE_DIR/claude/credentials.json" "$CHEZMOI_SOURCE/claude/encrypted_credentials.json.age"
reencrypt_file "$SOURCE_DIR/conda/aau_token" "$CHEZMOI_SOURCE/conda/encrypted_aau_token.age"
reencrypt_file "$SOURCE_DIR/conda/aau_token_host" "$CHEZMOI_SOURCE/conda/encrypted_aau_token_host.age"
reencrypt_file "$SOURCE_DIR/gmail/credentials.json" "$CHEZMOI_SOURCE/gmail/encrypted_credentials.json.age"
reencrypt_file "$SOURCE_DIR/gmail/.env.gmail" "$CHEZMOI_SOURCE/gmail/encrypted_dot_env.gmail.age"
reencrypt_file "$SOURCE_DIR/gmail/token.json" "$CHEZMOI_SOURCE/gmail/encrypted_token.json.age"
reencrypt_file "$SOURCE_DIR/gpg/private-key.asc" "$CHEZMOI_SOURCE/gpg/encrypted_private-key.asc.age"
reencrypt_file "$SOURCE_DIR/gpg/public-key.asc" "$CHEZMOI_SOURCE/gpg/encrypted_public-key.asc.age"
reencrypt_file "$SOURCE_DIR/postman/.env.postman" "$CHEZMOI_SOURCE/postman/encrypted_dot_env.postman.age"
reencrypt_file "$SOURCE_DIR/tana/.env.tana" "$CHEZMOI_SOURCE/tana/encrypted_dot_env.tana.age"

echo ""
echo "✅ Alle secrets re-krypterte!"
echo ""
echo "📋 Neste steg:"
echo "   cd ~/Development/dev-configs"
echo "   git add -A"
echo "   git commit -m 'Re-encrypt secrets with cached touch policy'"
echo "   git push"
