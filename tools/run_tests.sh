#!/bin/bash
# =============================================================
# run_tests.sh — Headless test runner untuk Project: REBOOT
# Usage: bash tools/run_tests.sh [path/to/godot]
# =============================================================
set -e

# Default Godot path — override via argument
GODOT="${1:-godot}"

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_FILE="$PROJECT_DIR/project.godot"

if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ project.godot tidak ditemukan di $PROJECT_DIR"
    exit 1
fi

echo "================================================"
echo " Project: REBOOT — Headless Test Runner"
echo "================================================"
echo "Godot  : $GODOT"
echo "Project: $PROJECT_DIR"
echo ""

# Simpan main scene asli
ORIGINAL_MAIN=$(grep 'run/main_scene=' "$PROJECT_FILE" | head -1)

# Ganti main scene ke TestRunner
echo "[1/3] Mengganti main scene ke TestRunner..."
sed -i 's|run/main_scene=.*|run/main_scene="res://test/TestRunner.tscn"|' "$PROJECT_FILE"

# Jalankan test headless
echo "[2/3] Menjalankan test headless..."
echo ""

EXIT_CODE=0
"$GODOT" --headless --path "$PROJECT_DIR" --quit 2>&1 || EXIT_CODE=$?

echo ""

# Kembalikan main scene
echo "[3/3] Mengembalikan main scene..."
sed -i "s|run/main_scene=.*|${ORIGINAL_MAIN}|" "$PROJECT_FILE"

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ SEMUA TEST LULUS!"
else
    echo "❌ ADA TEST GAGAL (exit code: $EXIT_CODE)"
fi

exit $EXIT_CODE
