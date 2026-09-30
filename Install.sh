#!/usr/bin/env bash

set -e

BASE_URL="https://raw.githubusercontent.com/Pax0102/build-lynx/main"
INSTALL_DIR="$HOME/.lynx"
SCRIPT_PATH="$INSTALL_DIR/build-lynx.sh"
BIN_DIR="$HOME/.local/bin"

mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

curl -fsSL "$BASE_URL/build-lynx.sh" -o "$SCRIPT_PATH"

chmod +x "$SCRIPT_PATH"

cat > "$BIN_DIR/build-lynx" <<EOF
#!/usr/bin/env bash
exec "$SCRIPT_PATH" "\$@"
EOF

chmod +x "$BIN_DIR/build-lynx"

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    SHELL_NAME="$(basename "$SHELL")"

    case "$SHELL_NAME" in
        bash)
            PROFILE="$HOME/.bashrc"
            ;;
        zsh)
            PROFILE="$HOME/.zshrc"
            ;;
        *)
            PROFILE="$HOME/.profile"
            ;;
    esac

    if ! grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$PROFILE" 2>/dev/null; then
        printf '%s\n' 'export PATH="$HOME/.local/bin:$PATH"' >> "$PROFILE"
    fi

    export PATH="$BIN_DIR:$PATH"
fi
