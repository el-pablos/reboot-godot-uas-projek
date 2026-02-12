# 🤖 Project: REBOOT

<div align="center">

![Godot Engine](https://img.shields.io/badge/Godot-4.6-478CBF?style=for-the-badge&logo=godot-engine&logoColor=white)
![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen?style=for-the-badge)
![Tests](https://img.shields.io/badge/Tests-205%20Passed-success?style=for-the-badge)
![Visual](https://img.shields.io/badge/Visual-Pixel%20Art-orange?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)

[![🚀 Auto Release](https://github.com/el-pablos/reboot-godot-uas-projek/actions/workflows/release-on-push.yml/badge.svg)](https://github.com/el-pablos/reboot-godot-uas-projek/actions/workflows/release-on-push.yml)
[![🌐 Web Deploy](https://github.com/el-pablos/reboot-godot-uas-projek/actions/workflows/deploy-web-pages.yml/badge.svg)](https://github.com/el-pablos/reboot-godot-uas-projek/actions/workflows/deploy-web-pages.yml)

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
| **Serang** | `J` atau `Mouse Left` *(melee + projectile)* |
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
- **Melee Attack** — wrench swing (25 damage, knockback)
- **Ranged Attack** — energy bolt projectile (15 damage, 400 px/s)
- Combo system: tekan `J` untuk melee + ranged sekaligus
- Health system dengan regenerasi
- Kumpulkan 5 **Core Fragments**
- Progressive ability unlock melalui boss fights

### 🗺️ Game Levels

| Level | Nama | Tema | Boss | Gate |
|-------|------|------|------|------|
| 1 | Golden Isles | Tutorial/Pantai | — | — |
| 2 | Rust Factory | Pabrik Industrial | Scrapper | ✅ |
| 3 | Crystal Labs | Laboratorium | Spore-Bot | ✅ |
| 4 | Storm Spire | Menara Badai | Tempest | ✅ |
| 5 | Overlord Fortress | Markas Final | **Overlord** | ✅ |

Boss ditempatkan di **mid-challenge** — pemain harus mengalahkan boss dan melewati BossGate sebelum bisa mengambil Core Fragment.

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
└── BossBase  ← BossBrain (AI state machine)
    ├── BossScrapper (rewards: Dash)
    ├── BossSporeBot (rewards: Double Jump)
    ├── BossTempest (rewards: Glide)
    └── BossOverlord (Final Boss)
```

### BossBrain AI State Machine
```
ROAM → CHASE → ATTACK_CLOSE / ATTACK_FAR
  ↑       ↕         ↓
  └── REPOSITION ← RECOVER ← PHASE_CHANGE
```

Setiap boss menggunakan `BossBrain` + `BossConfig` (Resource) untuk AI yang fair:
- **Telegraph** visual sebelum setiap serangan
- **Cooldown** antar serangan (recovery window)
- **Arena bounds** agar boss tidak keluar area
- **Phase modifiers** yang meningkatkan agresivitas per fase

---

## 📊 Quality Assurance

| Metric | Status |
|--------|--------|
| Unit Tests | **205/205 Passed** ✅ |
| Parse Errors | **0** ✅ |
| Code Coverage | **Core Systems** ✅ |
| Headless Import | **Clean** ✅ |

### Menjalankan Test Headless (Lokal)

Gunakan helper scripts di `tools/`:

```powershell
# Windows (PowerShell)
.\tools\run_tests.ps1

# Atau dengan path Godot custom
.\tools\run_tests.ps1 -GodotPath "C:\path\to\godot.exe"
```

```bash
# Linux / macOS
bash tools/run_tests.sh

# Atau dengan path Godot custom
bash tools/run_tests.sh /path/to/godot
```

Script otomatis:
1. Mengganti main scene ke TestRunner
2. Menjalankan Godot headless
3. Mengembalikan main scene
4. Return exit code (0 = semua lulus)

### Test Suites

| Suite | Tests |
|-------|-------|
| test_player_movement.gd | 21 |
| test_game_logic.gd | 30 |
| test_enemy_boss.gd | 25 |
| test_enemy_ai.gd | 25 |
| test_combat_system.gd | 18 |
| test_gameplay_qa.gd | 69 |
| test_boss_rework.gd | 17 |
| **Total** | **205** |

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
│   ├── boss/               # BossBrain AI, BossConfig, BossGate
│   ├── hazards/            # Level hazards (MachinePress, WindZone, etc.)
│   ├── collectibles/       # Core Fragment
│   └── ui/                 # UI Controllers
├── test/                   # 205 headless tests (7 suites)
└── project.godot           # Godot project config
```

---

## 🚀 Automated Releases

Setiap push ke branch `master` otomatis:
1. **Headless Tests** — 205 unit tests dijalankan
2. **Export Builds** — Windows, Linux, dan Web
3. **GitHub Release** — tag `v0.1.<run>` dibuat + desktop builds di-attach
4. **Web Deploy** — build web otomatis di-deploy ke GitHub Pages

### Versioning Scheme

| Format | Contoh | Penjelasan |
|--------|--------|------------|
| `v0.1.<RUN_NUMBER>` | `v0.1.42` | Nomor run workflow GitHub Actions |

Tag dibuat otomatis oleh `github-actions[bot]`, tanpa token pribadi.

### Download Builds

> **[📥 Releases Page](https://github.com/el-pablos/reboot-godot-uas-projek/releases)**

Setiap release berisi:
- `REBOOT.exe` — Windows build (PCK embedded, single file)
- `REBOOT.x86_64` — Linux build (PCK embedded, single file)

### 🌐 Mainkan di Browser

> **[🎮 Play Online](https://el-pablos.github.io/reboot-godot-uas-projek/)**

Web build otomatis di-deploy ke GitHub Pages setiap ada tag rilis baru.

### Quality Gate

Release **tidak akan dibuat** jika:
- Headless tests gagal (exit code ≠ 0)
- Export build error

Pipeline berjalan di satu job berurutan sehingga kegagalan di step manapun menghentikan proses.

---

## 🔧 Troubleshooting

| Masalah | Solusi |
|---------|--------|
| Parser Error: "Class X hides global script class" | Cek duplikat `class_name` di file backup: `grep -rn 'class_name' scripts/` |
| Boss nyangkut / stuck | BossBrain punya unstuck guard (2 detik threshold). Jika masih terjadi, cek collision_mask boss |
| Player jatuh tembus platform | Cek CollisionPolygon2D di level .tscn — pastikan half-extent = 16 × scale (bukan 32 × scale) |
| Serangan tidak kena musuh | Pastikan enemy ada di group `"enemies"` dan punya method `take_damage()` |
| Test gagal di CI | Godot 4.6 di CI vs 4.5.1 lokal — cek versi-specific API |

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
