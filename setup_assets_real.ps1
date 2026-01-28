# =============================================================================
# setup_assets_real.ps1 - Download Real Kenney Assets
# =============================================================================

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   PROJECT: REBOOT - KENNEY ASSET DOWNLOADER            " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

# Setup folder structure
Write-Host "[1/4] Creating folder structure..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "assets/sprites/player" | Out-Null
New-Item -ItemType Directory -Force -Path "assets/sprites/tilesets" | Out-Null
New-Item -ItemType Directory -Force -Path "assets/sprites/items" | Out-Null
Write-Host "  Folders created." -ForegroundColor Green

# TLS 1.2 for HTTPS
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 1. Player (Robot) - Menggunakan Robot Pack
Write-Host ""
Write-Host "[2/4] Downloading Player Assets..." -ForegroundColor Yellow

$playerAssets = @{
    "idle.png" = "https://raw.githubusercontent.com/KenneyNL/assets/master/Platformer%20Art%20Deluxe/Request%20pack/Characters/character_robot_idle.png"
    "run.png" = "https://raw.githubusercontent.com/KenneyNL/assets/master/Platformer%20Art%20Deluxe/Request%20pack/Characters/character_robot_walk0.png"
    "jump.png" = "https://raw.githubusercontent.com/KenneyNL/assets/master/Platformer%20Art%20Deluxe/Request%20pack/Characters/character_robot_jump.png"
}

foreach ($file in $playerAssets.Keys) {
    $outPath = "assets/sprites/player/$file"
    try {
        Invoke-WebRequest -Uri $playerAssets[$file] -OutFile $outPath -UseBasicParsing -ErrorAction Stop
        Write-Host "  OK: $file" -ForegroundColor Green
    }
    catch {
        Write-Host "  SKIP: $file (URL not accessible)" -ForegroundColor Yellow
    }
}

# 2. Tilesets (Environment)
Write-Host ""
Write-Host "[3/4] Downloading Tilesets..." -ForegroundColor Yellow

$tileAssets = @{
    "grass_mid.png" = "https://raw.githubusercontent.com/KenneyNL/assets/master/Platformer%20Art%20Deluxe/Request%20pack/Tiles/grassMid.png"
    "crate.png" = "https://raw.githubusercontent.com/KenneyNL/assets/master/Platformer%20Art%20Deluxe/Request%20pack/Tiles/boxCrate_double.png"
    "stone.png" = "https://raw.githubusercontent.com/KenneyNL/assets/master/Platformer%20Art%20Deluxe/Request%20pack/Tiles/stoneMid.png"
}

foreach ($file in $tileAssets.Keys) {
    $outPath = "assets/sprites/tilesets/$file"
    try {
        Invoke-WebRequest -Uri $tileAssets[$file] -OutFile $outPath -UseBasicParsing -ErrorAction Stop
        Write-Host "  OK: $file" -ForegroundColor Green
    }
    catch {
        Write-Host "  SKIP: $file (URL not accessible)" -ForegroundColor Yellow
    }
}

# 3. Items (Core Fragments)
Write-Host ""
Write-Host "[4/4] Downloading Items..." -ForegroundColor Yellow

$itemAssets = @{
    "core_fragment.png" = "https://raw.githubusercontent.com/KenneyNL/assets/master/Platformer%20Art%20Deluxe/Request%20pack/Items/gemBlue.png"
    "gem_green.png" = "https://raw.githubusercontent.com/KenneyNL/assets/master/Platformer%20Art%20Deluxe/Request%20pack/Items/gemGreen.png"
    "gem_red.png" = "https://raw.githubusercontent.com/KenneyNL/assets/master/Platformer%20Art%20Deluxe/Request%20pack/Items/gemRed.png"
}

foreach ($file in $itemAssets.Keys) {
    $outPath = "assets/sprites/items/$file"
    try {
        Invoke-WebRequest -Uri $itemAssets[$file] -OutFile $outPath -UseBasicParsing -ErrorAction Stop
        Write-Host "  OK: $file" -ForegroundColor Green
    }
    catch {
        Write-Host "  SKIP: $file (URL not accessible)" -ForegroundColor Yellow
    }
}

# Summary
Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host "   DOWNLOAD COMPLETE!                                   " -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Files downloaded to:" -ForegroundColor White
Get-ChildItem -Path "assets/sprites" -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  $($_.FullName)" -ForegroundColor Gray
}
Write-Host ""
Write-Host "Next: Open Godot and reimport assets!" -ForegroundColor Cyan
