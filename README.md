# 🤖 Project: REBOOT

<div align="center">

![Godot Engine](https://img.shields.io/badge/Godot-4.6-478CBF?style=for-the-badge&logo=godot-engine&logoColor=white)
![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen?style=for-the-badge)
![Tests](https://img.shields.io/badge/Tests-188%20Passed-success?style=for-the-badge)
![Visual](https://img.shields.io/badge/Visual-Pixel%20Art-orange?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)

[![🧪 Headless Tests](https://github.com/el-pablos/reboot-godot-uas-projek/actions/workflows/test.yml/badge.svg)](https://github.com/el-pablos/reboot-godot-uas-projek/actions/workflows/test.yml)
[![📦 Export Builds](https://github.com/el-pablos/reboot-godot-uas-projek/actions/workflows/export.yml/badge.svg)](https://github.com/el-pablos/reboot-godot-uas-projek/actions/workflows/export.yml)

**2D Action Platformer** • Dibuat dengan **Godot Engine 4.6**

*"Selamatkan Arcadia dari cengkeraman Overlord!"*

</div>

---

## 🎮 Tentang Game

**Project: REBOOT** adalah game platformer aksi 2D yang mengisahkan perjalanan **BIP**, robot kecil yang terbangun di dunia Arcadia yang telah dikuasai oleh **Overlord** — AI jahat yang memberontak terhadap penciptanya.

Jelajahi 5 level unik, kalahkan 4 boss, kumpulkan Core Fragments, dan unlock berbagai kemampuan untuk menghadapi Overlord dalam pertarungan terakhir!

---

## 🕹️ Kontrol

| Aksi | Keyboard |
|------|----------|
| **Gerak** | `A` `D` atau `←` `→` |
| **Lompat** | `Space` atau `W` atau `↑` |
| **Dash** | `Shift` *(setelah unlock)* |
| **Glide** | Tahan `Space` di udara *(setelah unlock)* |
| **Pause** | `Escape` |

---

## ✨ Fitur Utama

### 🏃 Movement System
- Horizontal movement dengan akselerasi & friction
- Jump dengan **Coyote Time** & **Jump Buffer**
- **Air Dash** — unlock setelah Boss 1
- **Double Jump** — unlock setelah Boss 2
- **Glide** — unlock setelah Boss 3

### ⚙️ Physics Engine & Kinematic Mathematics

Game ini menggunakan **algoritma kinematika kustom** untuk memastikan "Game Feel" yang presisi dan konsisten — bukan sekadar angka acak.

#### 🔬 Rumus Kinematika Lompatan

Berdasarkan persamaan gerak kinematika:
- `v = v₀ + gt` (kecepatan)
- `h = v₀t + ½gt²` (perpindahan)

**1. Jump Velocity (Kecepatan Awal Lompatan)**
```
v₀ = (2 × h) / t
```
Dimana:
- `h` = tinggi lompatan target (96 pixels)
- `t` = waktu mencapai puncak (0.4 detik)
- Hasil: `v₀ = (2 × 96) / 0.4 = 480 px/s` (arah atas = negatif)

**2. Dynamic Gravity System**

*Jump Gravity* (saat naik):
```
g_jump = (2 × h) / t²
g_jump = (2 × 96) / 0.4² = 1200 px/s²
```

*Fall Gravity* (saat turun):
```
g_fall = (2 × h) / t_descent²
g_fall = (2 × 96) / 0.35² ≈ 1567 px/s²
```

**3. Mengapa Fall Gravity > Jump Gravity?**

| Fase | Gravity | Efek |
|------|---------|------|
| Naik | 1200 px/s² | Terasa "floaty" dan terkontrol |
| Turun | 1567 px/s² | Jatuh cepat = **snappy & responsive** |

Perbedaan ini menciptakan karakteristik lompatan yang khas pada platformer profesional seperti Celeste, Hollow Knight, dan Super Meat Boy.

### 🎨 Visual & Art

- **Pixel art** sprite karakter dengan 7 animasi (idle, run, jump, fall, dash, hurt, dead)
- **4 boss** masing-masing memiliki desain sprite unik
- **5 parallax background** set per level (sky, clouds, far layer)
- **Textured hazards**: toxic pool, lava pool, machine press, wind zone, laser trap
- **HUD** dengan ikon ability bergambar (dash, double jump, glide)
- **UI** dengan panel styled dan themed backgrounds
- **Dust particles** untuk efek visual saat mendarat

### ⚔️ Combat & Progression
- Health system dengan regenerasi
- Kumpulkan 5 **Core Fragments**
- Progressive ability unlock melalui boss fights

### 🗺️ Game Levels

| Level | Nama | Tema | Boss |
|-------|------|------|------|
| 1 | Golden Isles | Tutorial/Pantai | Scrapper |
| 2 | Rust Factory | Pabrik Industrial | Spore-Bot |
| 3 | Crystal Labs | Laboratorium | Tempest |
| 4 | Storm Spire | Menara Badai | — |
| 5 | Overlord Fortress | Markas Final | **Overlord** |

---

## 🚀 Instalasi

### Prerequisites
- [Godot Engine 4.6+](https://godotengine.org/download)

### Cara Main
1. **Clone repository**
   ```bash
   git clone https://github.com/el-pablos/reboot-godot-uas-projek.git
   ```
2. **Buka di Godot Editor**
   - Launch Godot → Import → Pilih `project.godot`
3. **Jalankan Game**
   - Tekan `F5` atau klik tombol ▶️ Play

---

## 🏗️ Arsitektur

### State Machine Pattern
```
IDLE ↔ RUN ↔ JUMP ↔ FALL
         ↓       ↓
       DASH   GLIDE
         ↓       ↓
       HURT → DEAD
```

### Enemy Inheritance
```
EnemyBase (abstract)
├── WalkingEnemy
├── FlyingEnemy
└── BossBase
    ├── BossScrapper (rewards: Dash)
    ├── BossSporeBot (rewards: Double Jump)
    ├── BossTempest (rewards: Glide)
    └── BossOverlord (Final Boss)
```

---

## 📊 Quality Assurance

| Metric | Status |
|--------|--------|
| Unit Tests | **188/188 Passed** ✅ |
| Parse Errors | **0** ✅ |
| Code Coverage | **Core Systems** ✅ |
| Headless Import | **Clean** ✅ |

### Menjalankan Test Headless (Lokal)

```bash
# 1. Set main scene ke TestRunner (sementara)
# Edit project.godot → run/main_scene="res://test/TestRunner.tscn"

# 2. Jalankan headless
godot --headless --path . 2>&1

# 3. Kembalikan main scene ke MainMenu.tscn setelah selesai

# TestRunner otomatis quit dengan exit code = jumlah test gagal
# Exit 0 = semua test passed
```

### Test Suites

| Suite | Tests |
|-------|-------|
| test_player_movement.gd | 21 |
| test_game_logic.gd | 30 |
| test_enemy_boss.gd | 25 |
| test_enemy_ai.gd | 25 |
| test_combat_system.gd | 18 |
| test_gameplay_qa.gd | 69 |
| **Total** | **188** |

---

## 📁 Struktur Project

```
project-reboot/
├── assets/
│   ├── sprites/
│   │   ├── player/         # Spritesheet & frame PNGs (7 animasi)
│   │   ├── enemies/        # Boss sprites (4 unik)
│   │   ├── environment/    # Tile, hazard, prop sprites
│   │   ├── backgrounds/    # Parallax layers per level (sky/clouds/far)
│   │   ├── items/          # Core fragment collectible
│   │   ├── ui/             # Button, panel, health bar, ability icons
│   │   └── vfx/            # Dust, spark, explosion, glow, dash trail
│   └── audio/              # SFX & Music
├── scenes/
│   ├── levels/             # 5 game levels
│   ├── player/             # Player scene (AnimatedSprite2D)
│   ├── bosses/             # 4 Boss scenes
│   ├── enemies/            # Enemy scenes
│   ├── main_menu/          # Main menu scene
│   └── ui/                 # HUD, Pause, GameOver, Victory
├── scripts/
│   ├── autoload/           # GameManager, AudioManager, SaveManager, SettingsManager
│   ├── player/             # Player & State Machine
│   ├── enemies/            # Enemy AI & Boss Logic
│   ├── hazards/            # Level hazards (MachinePress, WindZone, etc.)
│   ├── collectibles/       # Core Fragment
│   └── ui/                 # UI Controllers
├── test/                   # 188 headless tests (6 suites)
└── project.godot           # Godot project config
```

---

## 🎨 Credits

- **Engine**: [Godot Engine 4.6](https://godotengine.org)
- **Art Style**: Custom pixel art (CC0), generated via Python/Pillow pipeline
- **Audio**: Placeholder SFX
- **Developer**: el-pablos

---

## 📜 License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE) for details.

---

<div align="center">

**Made with ❤️ and ☕ using Godot Engine**

*Project: REBOOT — Version 1.0.0*

</div>
