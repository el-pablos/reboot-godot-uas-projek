<# tools/capture_media.ps1
   Jalankan screenshot capture tool via Godot CLI.
   Output: docs/media/*.png
#>
param(
    [string]$GodotPath = ""
)

$ErrorActionPreference = "Stop"

# Auto-detect Godot jika tidak diberikan
if (-not $GodotPath) {
    $GodotPath = Get-Command "godot" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    if (-not $GodotPath) {
        # Cek lokasi umum
        $candidates = @(
            "D:\Download-12-12-2025\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64_console.exe"
        )
        foreach ($c in $candidates) {
            if (Test-Path $c) { $GodotPath = $c; break }
        }
    }
    if (-not $GodotPath) {
        Write-Error "Godot tidak ditemukan. Berikan path via -GodotPath parameter."
        exit 1
    }
}

Write-Host "Godot  : $GodotPath" -ForegroundColor Cyan
Write-Host "Project: $(Get-Location)" -ForegroundColor Cyan
Write-Host ""

# Pastikan folder output ada
if (-not (Test-Path "docs/media")) {
    New-Item -ItemType Directory -Path "docs/media" -Force | Out-Null
}

# Jalankan capture tool
# Catatan: --headless mungkin tidak bisa render viewport.
# Jika gagal, jalankan tanpa --headless (windowed mode singkat).
Write-Host "=== Menjalankan capture tool ===" -ForegroundColor Yellow
& "$GodotPath" --path . -s tools/capture_screenshots.gd --quit-after 30 2>&1
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
    Write-Host ""
    Write-Host "WARNING: Exit code $exitCode — beberapa screenshot mungkin gagal." -ForegroundColor Red
}

# Cek hasil
$pngs = Get-ChildItem -Path "docs/media" -Filter "*.png" -ErrorAction SilentlyContinue
if ($pngs.Count -gt 0) {
    Write-Host ""
    Write-Host "=== Screenshot yang berhasil ===" -ForegroundColor Green
    foreach ($f in $pngs) {
        Write-Host "  - $($f.Name)  ($([math]::Round($f.Length/1KB, 1)) KB)"
    }
    Write-Host ""
    Write-Host "Total: $($pngs.Count) file(s)" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "TIDAK ADA screenshot yang tersimpan." -ForegroundColor Red
    Write-Host "Coba jalankan manual tanpa headless:" -ForegroundColor Yellow
    Write-Host "  & `"$GodotPath`" --path . -s tools/capture_screenshots.gd"
}
