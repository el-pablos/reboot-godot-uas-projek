# 🤖 Project: REBOOT — Release Notes v0.2.0

## Untuk Reviewer / Penguji

### ⚡ Quick Start
1. Download build sesuai platform (Windows/Linux/Web)
2. Jalankan executable — tidak perlu install
3. Gunakan keyboard untuk bermain

### 🕹️ Kontrol

| Aksi | Keyboard |
|------|----------|
| Gerak | `A` / `D` atau `←` / `→` |
| Lompat | `Space` atau `W` atau `↑` |
| Serang | `J` atau `Z` |
| Dash | `Shift` *(unlock setelah Boss 1)* |
| Double Jump | *(unlock setelah Boss 2)* |
| Glide | Tahan `Space` di udara *(unlock setelah Boss 3)* |
| Pause | `Escape` |

### 🗺️ Level Progression

| # | Level | Boss | Unlock |
|---|-------|------|--------|
| 1 | The Golden Isles | — (Tutorial) | — |
| 2 | The Rust Factory | The Scrapper | Air Dash |
| 3 | Crystal Labs | The Architect | Double Jump |
| 4 | Storm Spire | The Tempest | Glide |
| 5 | Overlord Fortress | The Overlord | — (Final) |

### 🎯 Objektif
- Kalahkan boss di setiap level untuk unlock ability baru
- Kumpulkan **Core Fragments** (collectible) di setiap level
- Reach dan kalahkan **The Overlord** di Level 5

### ⚙️ Settings Menu
- Accessible dari Main Menu dan Pause Menu
- **Audio**: Master, Music, SFX volume sliders
- **Video**: Fullscreen, VSync toggles
- **Gameplay**: Screen Shake on/off, Hit Stop (Off/Low/High)
- Settings persist di `user://settings.cfg`

### 🧪 Test Suite
- **119 tests** across 5 suites — semua PASSED
- Run headless: swap main scene ke `test/TestRunner.tscn`, jalankan `godot --headless`
- Exit code 0 = semua test passed

### 🐛 Known Issues / Limitations
- Tidak ada checkpoint system (respawn ke awal level jika mati)
- Save system hanya track level progress & unlocks, bukan posisi mid-level
- Web build mungkin ada delay audio pada first play
- Resolution fixed 1280×720 (stretch mode: canvas_items)

### 📋 Changelog v0.2.0 Highlights
- ✅ Settings Menu dengan persist (audio/video/gameplay)
- ✅ Polish game feel: hit stop, screen shake, damage feedback
- ✅ Anti-softlock fixes: boss repositioning, killzone tightening, hazard scripts
- ✅ GameManager health reset on respawn
- ✅ CI/CD: GitHub Actions test + export workflows
- ✅ Export presets: Windows, Linux, Web

### 📂 Project Structure
```
scenes/          → Godot scenes (.tscn)
scripts/         → GDScript source code
  autoload/      → GameManager, AudioManager, SaveManager, SettingsManager
  player/        → Player controller & camera
  enemies/       → Enemy AI & boss scripts
  levels/        → Level base & logic
  ui/            → Menus & HUD
assets/          → Sprites, audio, fonts
test/            → 5 test suites + TestRunner
.github/         → CI/CD workflows
```

### 🔧 Build from Source
1. Install Godot 4.6 (standard atau mono)
2. Clone repo, open `project.godot`
3. F5 untuk run dari editor

---

*Dibuat oleh Tim Project: REBOOT • Godot Engine 4.6*
