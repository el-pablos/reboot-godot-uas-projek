#!/usr/bin/env bash
# tools/capture_media.sh
# Jalankan screenshot capture tool via Godot CLI (Linux/macOS/CI).
# Output: docs/media/*.png

set -euo pipefail

GODOT="${1:-godot}"

# Cek Godot ada
if ! command -v "$GODOT" &>/dev/null && [ ! -f "$GODOT" ]; then
    echo "ERROR: Godot tidak ditemukan: $GODOT"
    echo "Usage: $0 [path-to-godot]"
    exit 1
fi

echo "Godot  : $GODOT"
echo "Project: $(pwd)"
echo ""

# Buat folder output
mkdir -p docs/media

# Jalankan capture tool
echo "=== Menjalankan capture tool ==="
"$GODOT" --path . -s tools/capture_screenshots.gd --quit-after 30 2>&1 || true
# Note: --headless mungkin skip viewport render.
# Jika output kosong, coba tanpa --headless.

# Cek hasil
count=$(find docs/media -name "*.png" 2>/dev/null | wc -l)
if [ "$count" -gt 0 ]; then
    echo ""
    echo "=== Screenshot yang berhasil ==="
    ls -lh docs/media/*.png 2>/dev/null
    echo ""
    echo "Total: $count file(s)"
else
    echo ""
    echo "TIDAK ADA screenshot yang tersimpan."
    echo "Coba jalankan manual tanpa headless:"
    echo "  $GODOT --path . -s tools/capture_screenshots.gd"
fi
