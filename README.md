# 🤖 Project: REBOOT

**2D Action Platformer** dibuat dengan **Godot 4.x**

> *"Selamatkan Arcadia dari cengkeraman Overlord!"*

![Godot Engine](https://img.shields.io/badge/Godot-4.6-478CBF?style=flat-square&logo=godot-engine)
![GDScript](https://img.shields.io/badge/GDScript-Type%20Safe-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

---

## 📖 Deskripsi

**Project: REBOOT** adalah game platformer aksi 2D yang menceritakan perjalanan **BIP**, sebuah robot kecil yang bangun di dunia Arcadia yang telah dikuasai oleh **Overlord**, AI jahat yang telah memberontak terhadap penciptanya.

Pemain harus menjelajahi 5 level unik, mengalahkan 4 boss, mengumpulkan Core Fragments, dan unlock berbagai kemampuan untuk akhirnya menghadapi Overlord dalam pertarungan terakhir.

---

## 🎮 Fitur Utama

### Movement System
- ⬆️ **Lompat** dengan Coyote Time & Jump Buffer
- 💨 **Air Dash** (unlock setelah Boss 1)
- 🦘 **Double Jump** (unlock setelah Boss 2)
- 🪂 **Glide** (unlock setelah Boss 3)

### Combat & Progression
- 💚 Health System dengan regenerasi
- 💎 Collect 5 Core Fragments
- 🏆 Progressive ability unlock melalui boss fights

### Game Levels
| # | Level | Tema | Hazard Utama | Boss |
|---|-------|------|--------------|------|
| 1 | Golden Isles | Tutorial/Pantai | Pits | Scrapper |
| 2 | Rust Factory | Pabrik Tua | Machine Press | Spore-Bot |
| 3 | Crystal Labs | Laboratorium | Bounce Platforms | Tempest |
| 4 | Storm Spire | Menara Badai | Wind Zones | - |
| 5 | Overlord Fortress | Markas Boss | Lava + Laser | Overlord |

---

## 🗂️ Struktur Project

```
game-satria-reboot/
├── 📁 assets/
│   ├── sprites/           # Placeholder sprites (SVG)
│   ├── audio/sfx/         # Sound effects
│   └── audio/music/       # Background music
│
├── 📁 scenes/
│   ├── levels/            # 5 level scenes
│   ├── player/            # Player.tscn
│   ├── enemies/           # Enemy & Boss scenes
│   └── ui/                # HUD, Menu, Dialog scenes
│
├── 📁 scripts/
│   ├── autoload/          # GameManager, AudioManager, SaveManager
│   ├── player/            # Player.gd, PlayerStateMachine.gd
│   ├── enemies/           # EnemyBase, WalkingEnemy, FlyingEnemy, Bosses
│   ├── hazards/           # Hazard.gd, MachinePress, WindZone, etc.
│   ├── collectibles/      # CoreFragment.gd
│   ├── levels/            # LevelBase.gd
│   └── ui/                # HUD.gd, DialogSystem.gd, PauseMenu.gd
│
├── 📁 test/               # GUT unit tests
│   ├── test_player_movement.gd
│   ├── test_game_logic.gd
│   └── test_enemy_boss.gd
│
├── project.godot          # Godot project config
├── asset_downloader.py    # Python script untuk download asset
└── README.md              # Dokumentasi ini
```

---

## 🚀 Cara Menjalankan

### Prerequisites
- [Godot Engine 4.6+](https://godotengine.org/download)
- Git (untuk clone repository)

### Steps
1. **Clone repository**
   ```bash
   git clone https://github.com/el-pablos/reboot-godot-uas-projek.git
   cd reboot-godot-uas-projek
   ```

2. **Buka di Godot**
   - Launch Godot Engine
   - Klik "Import"
   - Navigate ke folder project dan pilih `project.godot`

3. **Run Game**
   - Tekan F5 atau klik tombol Play
   - Main scene: `scenes/ui/MainMenu.tscn`

---

## 🧪 Testing dengan GUT

Project ini menggunakan **GUT (Godot Unit Test)** framework untuk unit testing.

### Setup GUT
1. Download GUT dari [Asset Library](https://godotengine.org/asset-library/asset/1079) atau [GitHub](https://github.com/bitwes/Gut)
2. Extract ke folder `addons/gut/`
3. Project → Project Settings → Plugins → Enable "Gut"

### Run Tests
1. Buka GUT panel (via menu atau tekan shortcut)
2. Klik "Run All" untuk menjalankan semua test
3. Atau jalankan via command line:
   ```bash
   godot --headless -s addons/gut/gut_cmdln.gd
   ```

### Test Suites
- `test_player_movement.gd` - Test movement, jump, abilities
- `test_game_logic.gd` - Test core collection, unlock system, save/load
- `test_enemy_boss.gd` - Test enemy scripts, boss rewards

---

## 🎯 Controls

| Action | Key |
|--------|-----|
| Move | ⬅️ ➡️ Arrow Keys / A D |
| Jump | Space / W / ⬆️ |
| Dash | Shift (setelah unlock) |
| Glide | Hold Jump di udara (setelah unlock) |
| Pause | Escape |
| Interact | E |

---

## 📋 Development Phases

- [x] **Phase 1**: Git init & project config
- [x] **Phase 2**: Asset downloader & placeholder sprites
- [x] **Phase 3**: Player State Machine (movement, abilities)
- [x] **Phase 4**: 5 Level scenes dengan unique hazards
- [x] **Phase 5**: Enemy AI & Boss Logic (inheritance pattern)
- [x] **Phase 6**: UI System (HUD, Dialog, Pause, GameOver, Victory)
- [x] **Phase 7**: Unit Testing dengan GUT
- [x] **Phase 8**: Documentation & Final Polish

---

## 🏗️ Architecture

### State Machine Pattern
Player menggunakan state machine untuk mengelola transisi antar state:

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
├── WalkingEnemy (patrol, chase)
├── FlyingEnemy (hover, swoop)
└── BossBase (phases, attack patterns)
    ├── BossScrapper (slam, dash)
    ├── BossSporeBot (spawn minions, poison cloud)
    ├── BossTempest (fly, lightning)
    └── BossOverlord (2 phases: robot → spirit)
```

### Autoload Singletons
- **GameManager**: Game state, abilities, health, level progression
- **AudioManager**: SFX pool, music with fade, volume control
- **SaveManager**: JSON-based save/load system

---

## 🎨 Assets

Semua asset menggunakan placeholder SVG untuk development. Untuk production:
- Sprites: [Kenney.nl](https://kenney.nl) (CC0)
- SFX: [OpenGameArt](https://opengameart.org) (CC0/CC-BY)
- Music: Original atau royalty-free

---

## 📜 License

This project is licensed under the MIT License.

---

## 👤 Author

**el-pablos**  
Email: yeteprem.end23juni@gmail.com  
GitHub: [@el-pablos](https://github.com/el-pablos)

---

## 🙏 Acknowledgments

- Godot Engine Team
- Kenney.nl untuk CC0 assets
- GUT Testing Framework
- Komunitas Godot Indonesia

---

*Made with ❤️ and ☕ using Godot Engine*
