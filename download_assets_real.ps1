# =============================================================================
# download_assets_real.ps1 - Download Real CC0 Assets untuk Project: REBOOT
# =============================================================================

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   PROJECT: REBOOT - ASSET DOWNLOADER v2.0              " -ForegroundColor Cyan  
Write-Host "   Downloading CC0 Assets from Kenney.nl                " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

# Base paths
$projectRoot = Get-Location
$assetsDir = Join-Path $projectRoot "assets"

# Create directories
Write-Host "[1/4] Creating directory structure..." -ForegroundColor Yellow

$directories = @(
    (Join-Path $assetsDir "sprites\player"),
    (Join-Path $assetsDir "sprites\enemies"),
    (Join-Path $assetsDir "sprites\tiles"),
    (Join-Path $assetsDir "sprites\items"),
    (Join-Path $assetsDir "audio\sfx"),
    (Join-Path $assetsDir "audio\music")
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        Write-Host "  Created: $dir" -ForegroundColor Gray
    }
}

# Download function
function Download-Asset {
    param([string]$Url, [string]$OutputPath, [string]$Name)
    
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $Url -OutFile $OutputPath -UseBasicParsing -ErrorAction Stop
        if (Test-Path $OutputPath) {
            Write-Host "  OK: $Name" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "  SKIP: $Name (will use placeholder)" -ForegroundColor Yellow
        return $false
    }
    return $false
}

Write-Host ""
Write-Host "[2/4] Attempting to download from online sources..." -ForegroundColor Yellow

# Try downloading from various sources (may fail, that's ok)
$playerPath = Join-Path $assetsDir "sprites\player\robot.png"
Download-Asset -Url "https://kenney.nl/content/3-assets/70-platformer-art-deluxe/platformerArtDeluxe_v2.zip" -OutputPath $playerPath -Name "Player sprite"

Write-Host ""
Write-Host "[3/4] Creating SVG placeholder sprites..." -ForegroundColor Yellow

# Player placeholder
$playerSvg = @'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <rect x="16" y="24" width="32" height="32" rx="4" fill="#5DADE2" stroke="#1A5276" stroke-width="2"/>
  <rect x="20" y="8" width="24" height="20" rx="3" fill="#85C1E9" stroke="#1A5276" stroke-width="2"/>
  <circle cx="28" cy="18" r="4" fill="#F1C40F"/>
  <circle cx="36" cy="18" r="4" fill="#F1C40F"/>
  <circle cx="28" cy="18" r="2" fill="#1A5276"/>
  <circle cx="36" cy="18" r="2" fill="#1A5276"/>
  <line x1="32" y1="8" x2="32" y2="2" stroke="#1A5276" stroke-width="2"/>
  <circle cx="32" cy="2" r="3" fill="#E74C3C"/>
  <rect x="20" y="56" width="8" height="8" fill="#5DADE2" stroke="#1A5276"/>
  <rect x="36" y="56" width="8" height="8" fill="#5DADE2" stroke="#1A5276"/>
</svg>
'@

$playerFile = Join-Path $assetsDir "sprites\player\bip.svg"
$playerSvg | Out-File -FilePath $playerFile -Encoding utf8 -Force
Write-Host "  Created: bip.svg (player)" -ForegroundColor Cyan

# Enemy placeholder
$enemySvg = @'
<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">
  <circle cx="24" cy="24" r="20" fill="#E74C3C" stroke="#641E16" stroke-width="2"/>
  <circle cx="18" cy="20" r="4" fill="#F1C40F"/>
  <circle cx="30" cy="20" r="4" fill="#F1C40F"/>
  <path d="M16 32 Q24 28 32 32" stroke="#641E16" stroke-width="3" fill="none"/>
</svg>
'@

$enemyFile = Join-Path $assetsDir "sprites\enemies\enemy.svg"
$enemySvg | Out-File -FilePath $enemyFile -Encoding utf8 -Force
Write-Host "  Created: enemy.svg" -ForegroundColor Cyan

# Boss placeholder
$bossSvg = @'
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
  <rect x="24" y="32" width="80" height="80" rx="8" fill="#8E44AD" stroke="#4A235A" stroke-width="4"/>
  <circle cx="48" cy="56" r="12" fill="#F1C40F"/>
  <circle cx="80" cy="56" r="12" fill="#F1C40F"/>
  <circle cx="48" cy="56" r="6" fill="#E74C3C"/>
  <circle cx="80" cy="56" r="6" fill="#E74C3C"/>
  <rect x="40" y="80" width="48" height="16" rx="4" fill="#4A235A"/>
</svg>
'@

$bossFile = Join-Path $assetsDir "sprites\enemies\boss.svg"
$bossSvg | Out-File -FilePath $bossFile -Encoding utf8 -Force
Write-Host "  Created: boss.svg" -ForegroundColor Cyan

# Ground tile
$groundSvg = @'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <rect width="64" height="64" fill="#5D4E37"/>
  <rect y="0" width="64" height="16" fill="#7D6E57"/>
  <rect x="8" y="8" width="48" height="4" fill="#8B7355"/>
</svg>
'@

$groundFile = Join-Path $assetsDir "sprites\tiles\ground.svg"
$groundSvg | Out-File -FilePath $groundFile -Encoding utf8 -Force
Write-Host "  Created: ground.svg" -ForegroundColor Cyan

# Platform tile
$platformSvg = @'
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="32" viewBox="0 0 128 32">
  <rect width="128" height="32" rx="4" fill="#6C7A89"/>
  <rect y="0" width="128" height="8" rx="4" fill="#95A5A6"/>
  <line x1="32" y1="0" x2="32" y2="32" stroke="#5D6D7E" stroke-width="2"/>
  <line x1="64" y1="0" x2="64" y2="32" stroke="#5D6D7E" stroke-width="2"/>
  <line x1="96" y1="0" x2="96" y2="32" stroke="#5D6D7E" stroke-width="2"/>
</svg>
'@

$platformFile = Join-Path $assetsDir "sprites\tiles\platform.svg"
$platformSvg | Out-File -FilePath $platformFile -Encoding utf8 -Force
Write-Host "  Created: platform.svg" -ForegroundColor Cyan

# Core fragment
$coreSvg = @'
<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">
  <polygon points="16,2 28,12 24,28 8,28 4,12" fill="#00BFFF" stroke="#FFFFFF" stroke-width="1"/>
  <polygon points="16,6 24,13 21,24 11,24 8,13" fill="#FFFFFF" opacity="0.3"/>
</svg>
'@

$coreFile = Join-Path $assetsDir "sprites\items\core_fragment.svg"
$coreSvg | Out-File -FilePath $coreFile -Encoding utf8 -Force
Write-Host "  Created: core_fragment.svg" -ForegroundColor Cyan

# Industrial tile
$industrialSvg = @'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <rect width="64" height="64" fill="#4A4A4A"/>
  <rect x="4" y="4" width="24" height="24" fill="#5A5A5A"/>
  <rect x="36" y="4" width="24" height="24" fill="#5A5A5A"/>
  <rect x="4" y="36" width="24" height="24" fill="#5A5A5A"/>
  <rect x="36" y="36" width="24" height="24" fill="#5A5A5A"/>
  <line x1="0" y1="32" x2="64" y2="32" stroke="#FFD700" stroke-width="4"/>
</svg>
'@

$industrialFile = Join-Path $assetsDir "sprites\tiles\industrial.svg"
$industrialSvg | Out-File -FilePath $industrialFile -Encoding utf8 -Force
Write-Host "  Created: industrial.svg" -ForegroundColor Cyan

# SciFi tile
$scifiSvg = @'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <rect width="64" height="64" fill="#1A1A2E"/>
  <rect x="2" y="2" width="60" height="60" fill="none" stroke="#00FFFF" stroke-width="2"/>
  <line x1="0" y1="32" x2="64" y2="32" stroke="#00FFFF" stroke-width="1" opacity="0.5"/>
  <line x1="32" y1="0" x2="32" y2="64" stroke="#00FFFF" stroke-width="1" opacity="0.5"/>
  <circle cx="32" cy="32" r="8" fill="none" stroke="#00FFFF" stroke-width="2"/>
</svg>
'@

$scifiFile = Join-Path $assetsDir "sprites\tiles\scifi.svg"
$scifiSvg | Out-File -FilePath $scifiFile -Encoding utf8 -Force
Write-Host "  Created: scifi.svg" -ForegroundColor Cyan

Write-Host ""
Write-Host "[4/4] Listing created assets..." -ForegroundColor Yellow

Get-ChildItem -Path (Join-Path $assetsDir "sprites") -Recurse -File | ForEach-Object {
    Write-Host "  $($_.FullName)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host "   ASSET CREATION COMPLETE!                             " -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host "   All SVG placeholder sprites have been created.       " -ForegroundColor Green
Write-Host "   Open Godot to import and use them in your scenes.    " -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host ""
