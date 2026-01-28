#!/usr/bin/env python3
# ===================================================
# asset_downloader.py - Script Download Aset Otomatis
# Project: REBOOT
# Author: el-pablos (yeteprem.end23juni@gmail.com)
# ===================================================
# Script ini mendownload aset CC0/free dari berbagai sumber
# untuk keperluan game Project: REBOOT.
# ===================================================

import os
import requests
import zipfile
import io
from pathlib import Path

# === KONFIGURASI PATH ===
PROJECT_ROOT = Path(__file__).parent
ASSETS_DIR = PROJECT_ROOT / "assets"

# Subfolder assets
SPRITES_PLAYER = ASSETS_DIR / "sprites" / "player"
SPRITES_ENEMIES = ASSETS_DIR / "sprites" / "enemies"
SPRITES_ENV = ASSETS_DIR / "sprites" / "environment"
SPRITES_UI = ASSETS_DIR / "sprites" / "ui"
AUDIO_SFX = ASSETS_DIR / "audio" / "sfx"
AUDIO_MUSIC = ASSETS_DIR / "audio" / "music"
FONTS_DIR = ASSETS_DIR / "fonts"
TILESETS_DIR = ASSETS_DIR / "tilesets"

# === DAFTAR ASET YANG DIBUTUHKAN ===
# Format: (nama_aset, url_download, folder_tujuan, deskripsi)
ASSET_LIST = [
    # --- KENNEY.NL ASSETS (CC0) ---
    # Platformer Characters
    (
        "platformer-art-deluxe",
        "https://kenney.nl/media/pages/assets/platformer-art-deluxe/7aa61a6c7a-1677495488/kenney_platformer-art-deluxe.zip",
        SPRITES_ENV,
        "Tileset platformer dasar (ground, platforms, dll)"
    ),
    # Robot characters
    (
        "platformer-characters",
        "https://kenney.nl/media/pages/assets/platformer-characters-1/53a7a4eed0-1677495504/kenney_platformer-characters-1.zip",
        SPRITES_PLAYER,
        "Karakter platformer (bisa dipakai untuk Bip)"
    ),
    # Industrial tileset
    (
        "scifi-rts",
        "https://kenney.nl/media/pages/assets/sci-fi-rts/ed4f5e95bf-1677495407/kenney_sci-fi-rts.zip",
        TILESETS_DIR,
        "Tileset sci-fi untuk Factory level"
    ),
    # UI elements
    (
        "ui-pack-space",
        "https://kenney.nl/media/pages/assets/ui-pack-space-expansion/e56bf3afe5-1677495298/kenney_ui-pack-space-expansion.zip",
        SPRITES_UI,
        "UI elements dengan tema space/sci-fi"
    ),
    # Game icons
    (
        "game-icons",
        "https://kenney.nl/media/pages/assets/game-icons/03c4f2bcf7-1677495435/kenney_game-icons.zip",
        SPRITES_UI,
        "Icon untuk HUD dan menu"
    ),
    # SFX
    (
        "interface-sounds",
        "https://kenney.nl/media/pages/assets/interface-sounds/d12d65c8b2-1677495345/kenney_interface-sounds.zip",
        AUDIO_SFX,
        "Sound effect untuk UI"
    ),
    (
        "impact-sounds",
        "https://kenney.nl/media/pages/assets/impact-sounds/a4d4e0c0bd-1677495349/kenney_impact-sounds.zip",
        AUDIO_SFX,
        "Sound effect untuk hit/damage"
    ),
]

# === URL ALTERNATIF (DIRECT LINK) JIKA DOWNLOAD GAGAL ===
FALLBACK_URLS = """
=== DAFTAR URL ASET UNTUK DOWNLOAD MANUAL ===
Jika script gagal download, silakan download manual dari URL berikut:

1. KENNEY.NL - PLATFORMER ART DELUXE (Tileset dasar):
   https://kenney.nl/assets/platformer-art-deluxe
   
2. KENNEY.NL - PLATFORMER CHARACTERS (Karakter robot):
   https://kenney.nl/assets/platformer-characters-1
   
3. KENNEY.NL - SCI-FI RTS (Tileset Factory/Lab):
   https://kenney.nl/assets/sci-fi-rts
   
4. KENNEY.NL - UI PACK SPACE (UI Sci-fi):
   https://kenney.nl/assets/ui-pack-space-expansion
   
5. KENNEY.NL - GAME ICONS (Icon HUD):
   https://kenney.nl/assets/game-icons

6. KENNEY.NL - IMPACT SOUNDS (SFX Hit):
   https://kenney.nl/assets/impact-sounds
   
7. KENNEY.NL - INTERFACE SOUNDS (SFX UI):
   https://kenney.nl/assets/interface-sounds

=== OPENGAMEART ALTERNATIF ===
- Robot Sprites: https://opengameart.org/content/robot-sprite
- Platformer Tiles: https://opengameart.org/content/platformer-art-complete-pack-often-updated
- Sci-fi Tileset: https://opengameart.org/content/sci-fi-interior-tiles
- Jump SFX: https://opengameart.org/content/8-bit-jump

Ekstrak ke folder masing-masing di:
- assets/sprites/player/
- assets/sprites/environment/
- assets/tilesets/
- assets/audio/sfx/
"""


def create_directories() -> None:
    """Buat semua folder yang diperlukan."""
    folders = [
        SPRITES_PLAYER, SPRITES_ENEMIES, SPRITES_ENV, SPRITES_UI,
        AUDIO_SFX, AUDIO_MUSIC, FONTS_DIR, TILESETS_DIR
    ]
    for folder in folders:
        folder.mkdir(parents=True, exist_ok=True)
        print(f"[OK] Folder dibuat: {folder}")


def download_and_extract(name: str, url: str, dest_folder: Path, desc: str) -> bool:
    """Download dan ekstrak file ZIP ke folder tujuan."""
    print(f"\n[DOWNLOAD] {name}")
    print(f"  URL: {url}")
    print(f"  Tujuan: {dest_folder}")
    print(f"  Deskripsi: {desc}")
    
    try:
        # Set timeout dan headers
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        }
        response = requests.get(url, headers=headers, timeout=60, stream=True)
        response.raise_for_status()
        
        # Ekstrak ZIP
        with zipfile.ZipFile(io.BytesIO(response.content)) as zf:
            # Buat subfolder dengan nama aset
            extract_path = dest_folder / name
            extract_path.mkdir(parents=True, exist_ok=True)
            zf.extractall(extract_path)
            print(f"  [OK] Berhasil diekstrak ke: {extract_path}")
            return True
            
    except requests.exceptions.RequestException as e:
        print(f"  [ERROR] Gagal download: {e}")
        return False
    except zipfile.BadZipFile:
        print(f"  [ERROR] File bukan ZIP valid atau corrupt")
        return False
    except Exception as e:
        print(f"  [ERROR] Error tidak diketahui: {e}")
        return False


def create_placeholder_sprites() -> None:
    """
    Buat placeholder sprite sederhana menggunakan SVG.
    Digunakan jika download aset gagal.
    """
    print("\n[INFO] Membuat placeholder sprites...")
    
    # Placeholder untuk Bip (player) - kotak biru dengan mata
    bip_svg = '''<svg width="32" height="32" xmlns="http://www.w3.org/2000/svg">
  <rect width="32" height="32" fill="#4fc3f7" rx="4"/>
  <circle cx="10" cy="12" r="3" fill="#fff"/>
  <circle cx="22" cy="12" r="3" fill="#fff"/>
  <circle cx="10" cy="12" r="1.5" fill="#1a237e"/>
  <circle cx="22" cy="12" r="1.5" fill="#1a237e"/>
  <rect x="8" y="22" width="16" height="3" fill="#1a237e" rx="1"/>
</svg>'''
    
    # Placeholder untuk enemy - kotak merah
    enemy_svg = '''<svg width="32" height="32" xmlns="http://www.w3.org/2000/svg">
  <rect width="32" height="32" fill="#f44336" rx="4"/>
  <circle cx="10" cy="12" r="3" fill="#fff"/>
  <circle cx="22" cy="12" r="3" fill="#fff"/>
  <circle cx="10" cy="12" r="1.5" fill="#b71c1c"/>
  <circle cx="22" cy="12" r="1.5" fill="#b71c1c"/>
  <path d="M8 24 L16 18 L24 24" stroke="#b71c1c" stroke-width="2" fill="none"/>
</svg>'''
    
    # Placeholder tile - kotak hijau (ground)
    ground_svg = '''<svg width="32" height="32" xmlns="http://www.w3.org/2000/svg">
  <rect width="32" height="32" fill="#4caf50"/>
  <rect y="0" width="32" height="8" fill="#8bc34a"/>
</svg>'''
    
    # Placeholder tile - kotak abu (platform)
    platform_svg = '''<svg width="64" height="16" xmlns="http://www.w3.org/2000/svg">
  <rect width="64" height="16" fill="#9e9e9e" rx="2"/>
  <rect x="2" y="2" width="60" height="4" fill="#bdbdbd"/>
</svg>'''
    
    # Placeholder boss - kotak besar ungu
    boss_svg = '''<svg width="64" height="64" xmlns="http://www.w3.org/2000/svg">
  <rect width="64" height="64" fill="#9c27b0" rx="8"/>
  <circle cx="20" cy="24" r="6" fill="#fff"/>
  <circle cx="44" cy="24" r="6" fill="#fff"/>
  <circle cx="20" cy="24" r="3" fill="#4a148c"/>
  <circle cx="44" cy="24" r="3" fill="#4a148c"/>
  <rect x="16" y="44" width="32" height="6" fill="#4a148c" rx="2"/>
</svg>'''
    
    # Core fragment - berlian kuning
    core_svg = '''<svg width="16" height="16" xmlns="http://www.w3.org/2000/svg">
  <polygon points="8,0 16,8 8,16 0,8" fill="#ffc107"/>
  <polygon points="8,2 14,8 8,14 2,8" fill="#ffeb3b"/>
  <polygon points="8,4 12,8 8,12 4,8" fill="#fff9c4"/>
</svg>'''
    
    # Simpan placeholders
    placeholders = [
        (SPRITES_PLAYER / "bip_placeholder.svg", bip_svg),
        (SPRITES_ENEMIES / "enemy_placeholder.svg", enemy_svg),
        (SPRITES_ENEMIES / "boss_placeholder.svg", boss_svg),
        (SPRITES_ENV / "ground_placeholder.svg", ground_svg),
        (SPRITES_ENV / "platform_placeholder.svg", platform_svg),
        (SPRITES_ENV / "core_fragment.svg", core_svg),
    ]
    
    for filepath, content in placeholders:
        filepath.parent.mkdir(parents=True, exist_ok=True)
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"  [OK] Placeholder dibuat: {filepath.name}")


def main() -> None:
    """Fungsi utama."""
    print("=" * 60)
    print("PROJECT: REBOOT - ASSET DOWNLOADER")
    print("=" * 60)
    
    # Buat folder
    create_directories()
    
    # Tracking hasil download
    success_count = 0
    fail_count = 0
    
    # Download semua aset
    for name, url, folder, desc in ASSET_LIST:
        if download_and_extract(name, url, folder, desc):
            success_count += 1
        else:
            fail_count += 1
    
    # Hasil
    print("\n" + "=" * 60)
    print("HASIL DOWNLOAD")
    print("=" * 60)
    print(f"Berhasil: {success_count}")
    print(f"Gagal: {fail_count}")
    
    # Jika ada yang gagal, tampilkan URL alternatif dan buat placeholder
    if fail_count > 0:
        print(FALLBACK_URLS)
        create_placeholder_sprites()
        print("\n[INFO] Placeholder sprites sudah dibuat untuk development.")
        print("[INFO] Silakan download aset asli dari URL di atas untuk production.")
    
    print("\n[SELESAI] Asset downloader selesai!")


if __name__ == "__main__":
    main()
