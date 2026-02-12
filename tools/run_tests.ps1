# =============================================================
# run_tests.ps1 — Headless test runner untuk Project: REBOOT
# Usage: .\tools\run_tests.ps1 [-GodotPath "path\to\godot.exe"]
# =============================================================
param(
    [string]$GodotPath = ""
)

$ErrorActionPreference = "Stop"

# Auto-detect Godot jika tidak diberikan
if (-not $GodotPath) {
    # Cari di lokasi umum
    $candidates = @(
        "D:\Download-12-12-2025\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64_console.exe",
        "$env:LOCALAPPDATA\Godot\godot.exe",
        "godot"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) {
            $GodotPath = $c
            break
        }
    }
    if (-not $GodotPath) {
        $GodotPath = "godot"
    }
}

$ProjectDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ProjectFile = Join-Path $ProjectDir "project.godot"

if (-not (Test-Path $ProjectFile)) {
    Write-Host "❌ project.godot tidak ditemukan di $ProjectDir" -ForegroundColor Red
    exit 1
}

Write-Host "================================================"
Write-Host " Project: REBOOT — Headless Test Runner"
Write-Host "================================================"
Write-Host "Godot  : $GodotPath"
Write-Host "Project: $ProjectDir"
Write-Host ""

# Simpan isi project.godot asli
$originalContent = Get-Content $ProjectFile -Raw

# Ganti main scene ke TestRunner
Write-Host "[1/3] Mengganti main scene ke TestRunner..." -ForegroundColor Cyan
$modifiedContent = $originalContent -replace 'run/main_scene="[^"]*"', 'run/main_scene="res://test/TestRunner.tscn"'
Set-Content -Path $ProjectFile -Value $modifiedContent -NoNewline

# Jalankan test headless
Write-Host "[2/3] Menjalankan test headless..." -ForegroundColor Cyan
Write-Host ""

$exitCode = 0
try {
    $process = Start-Process -FilePath $GodotPath -ArgumentList "--headless", "--path", $ProjectDir, "--quit" -Wait -PassThru -NoNewWindow
    $exitCode = $process.ExitCode
} catch {
    Write-Host "⚠️ Error menjalankan Godot: $_" -ForegroundColor Yellow
    $exitCode = 1
}

Write-Host ""

# Kembalikan main scene
Write-Host "[3/3] Mengembalikan main scene..." -ForegroundColor Cyan
Set-Content -Path $ProjectFile -Value $originalContent -NoNewline

Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "✅ SEMUA TEST LULUS!" -ForegroundColor Green
} else {
    Write-Host "❌ ADA TEST GAGAL (exit code: $exitCode)" -ForegroundColor Red
}

exit $exitCode
