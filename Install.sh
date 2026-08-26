rm -rf ~/.lynx
rm -f ~/.local/bin/build-lynx

mkdir -p ~/.lynx ~/.local/bin

curl -fsSL "https://raw.githubusercontent.com/Pax0102/build-lynx/main/build-lynx.sh" \
  -o ~/.lynx/build-lynx.sh

chmod +x ~/.lynx/build-lynx.sh

cat > ~/.local/bin/build-lynx <<'EOF'
#!/usr/bin/env bash
exec "$HOME/.lynx/build-lynx.sh" "$@"
EOF

chmod +x ~/.local/bin/build-lynx

export PATH="$HOME/.local/bin:$PATH"

echo "Installed."
echo "Running..."
build-lynx
