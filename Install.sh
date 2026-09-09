#!/usr/bin/env bash

set -e

# 1. Clean and recreate directories
rm -rf ~/.lynx ~/.local/bin/build-lynx
mkdir -p ~/.lynx ~/.local/bin

# 2. Optimized wrapper script with 64 dynamic parts
cat > ~/.lynx/build-lynx.sh <<'EOF'
#!/usr/bin/env bash
set -e

URL="https://githubusercontent.com"
OUT_DIR="$HOME/.lynx/chunks"
rm -rf "$OUT_DIR" && mkdir -p "$OUT_DIR"

# Instantly fetch the total content size in bytes
TOTAL_SIZE=$(curl -sI "$URL" | grep -i 'Content-Length' | awk '{print $2}' | tr -d '\r')

# Fallback size if remote server hides Content-Length
if [ -z "$TOTAL_SIZE" ] || [ "$TOTAL_SIZE" -le 0 ]; then
  TOTAL_SIZE=3000
fi

NUM_PARTS=64
CHUNK_SIZE=$(( TOTAL_SIZE / NUM_PARTS ))

# Generate 64 precise, sequential byte ranges
for i in $(seq 0 $((NUM_PARTS - 1))); do
  START=$(( i * CHUNK_SIZE ))
  if [ "$i" -eq $((NUM_PARTS - 1)) ]; then
    END="" # Let the last chunk pull everything remaining
  else
    END=$(( START + CHUNK_SIZE - 1 ))
  fi
  # Format with zero-padded index to guarantee correct sorting file order
  printf "%03d:%d-%s\n" "$i" "$START" "$END"
done | xargs -I {} -P $NUM_PARTS bash -c '
  INDEX=$(echo "{}" | cut -d: -f1)
  RANGE=$(echo "{}" | cut -d: -f2)
  curl -fsSL -r "$RANGE" "'"$URL"'" -o "'"$OUT_DIR"'/part_$INDEX"
'

# Recombine all 64 mini-parts instantly
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
