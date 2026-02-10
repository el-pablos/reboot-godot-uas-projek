# Changelog

Semua perubahan penting pada project ini akan didokumentasikan di file ini.

Format berdasarkan [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
dan project ini mengikuti [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-11

### Added
- Settings Menu lengkap (audio/video/gameplay) dengan persist ke ConfigFile
- SettingsManager autoload untuk kelola settings global
- Audio bus layout: Master, Music, SFX
- CI/CD: GitHub Actions headless test + export builds workflow
- Export presets: Windows Desktop, Linux, Web
- RELEASE_NOTES.md untuk reviewer
- SECURITY.md untuk standar repo
- GitHub Actions CI badges di README

### Fixed
- Boss Level 4 (Tempest) dipindah ke atas TopPlatform (sebelumnya unreachable)
- Boss Level 5 (Overlord) dipindah ke dalam BossArena (sebelumnya di luar)
- ToxicPool1 Level 3 dikasih Hazard script (sebelumnya tidak ada damage)
- killzone_y semua level dikecilkan ke 800 (konsisten, anti-softlock)
- GameManager.reset_health() dipanggil saat respawn (fix health desync)
- Hit-stop dan screen-shake sekarang pakai SettingsManager (bisa dimatikan)
- Camera shake cek SettingsManager sebelum aktif

### Improved
- Game feel: hit feedback, collect feedback, damage camera shake
- Git hygiene: md/ untracked, test/ tracked, .import/ ignored
- README sinkron dengan CI (119 tests, badges, headless instructions)

### Tests
- 119/119 unit tests passed
- CI headless tests stabil (3 runs sukses berturut-turut)
- Export builds workflow sukses (Windows + Linux + Web artifacts)

---

## [0.2.0] - 2026-02-11

### Fixed (P0 — Critical)
- DEBUG_UNLOCK_ALL_ABILITIES dimatikan, ability hanya dibuka via boss defeat
- Path MainMenu salah di 3 file, ditambah guard ResourceLoader.exists()
- is_game_over tidak di-reset saat respawn/reload, Engine.time_scale bisa stuck 0.1
- Boss Level 2–5 tertimpa SmartEnemy script, dikembalikan ke script asli
- Health jadi single source of truth via GameManager, HUD tidak polling tiap frame

### Fixed (P1 — Crash Risk)
- 8 file unsafe await di-guard dengan is_inside_tree()
- Infinite loop di MachinePress dan WindZone diganti while is_inside_tree()
- PauseMenu pakai GameManager.go_to_main_menu() bukan direct scene change

### Added
- 12 SFX procedural (jump, dash, hit, death, collect, dll) + 1 BGM loop
- Font pixel PressStart2P (OFL) sebagai default theme
- Boss scenes terpisah (BossScrapper, BossSporeBot, BossTempest, BossOverlord .tscn)
- Enemy variants: PatrollerEnemy, SmartEnemy, TurretEnemy, WatcherDrone
- Effects: BackgroundManager, ExplosionEffect, LightingManager
- TestRunner auto-quit di headless mode
- Test glide_gravity diperbaiki sesuai property Player.gd aktual

### Tests
- 119/119 unit tests passed (5 suite: player, game logic, enemy/boss, AI, combat)
- Headless import clean (14 assets)

---

## [0.1.0] - 2024

### Added

#### Phase 1: Project Setup
- Inisialisasi Git repository dengan `.gitignore`
- Setup `project.godot` untuk Godot 4.x
- Buat struktur folder (assets, scenes, scripts, test)
- Implementasi 3 autoload singletons:
  - `GameManager.gd` - State management, abilities, health
  - `AudioManager.gd` - SFX pool (8 players), music with fade
  - `SaveManager.gd` - JSON save/load system
- Scene `MainMenu.tscn` dengan navigasi

#### Phase 2: Assets
- Python script `asset_downloader.py` untuk download CC0 assets
- Placeholder SVG sprites:
  - bip.svg (player)
  - enemy.svg (musuh dasar)
  - boss.svg (boss placeholder)
  - ground.svg (platform)
  - platform.svg (floating platform)
  - core_fragment.svg (collectible)

#### Phase 3: Player System
- `Player.gd` dengan CharacterBody2D
- `PlayerStateMachine.gd` dengan 8 states:
  - IDLE, RUN, JUMP, FALL, DASH, GLIDE, HURT, DEAD
- Movement features:
  - Horizontal movement dengan acceleration/friction
  - Jump dengan variable height
  - Coyote time (0.15s)
  - Jump buffer (0.1s)
  - Unlockable: Dash, Double Jump, Glide
- Scene `Player.tscn`

#### Phase 4: Levels
- `LevelBase.gd` - Base class untuk semua level
- 5 Level scenes:
  - `Level_01_GoldenIsles.tscn` - Tutorial, basic platforming
  - `Level_02_RustFactory.tscn` - Machine press hazards
  - `Level_03_CrystalLabs.tscn` - Bounce platforms
  - `Level_04_StormSpire.tscn` - Wind zones
  - `Level_05_OverlordFortress.tscn` - Final level, lava/laser
- Hazard scripts:
  - `Hazard.gd` - Base hazard class
  - `MachinePress.gd` - Periodic crushing
  - `WindZone.gd` - Push player
  - `BouncePlatform.gd` - Trampoline effect
- `CoreFragment.gd` - Collectible untuk progress

#### Phase 5: Enemies & Bosses
- Enemy inheritance hierarchy:
  - `EnemyBase.gd` - Abstract base dengan health, detection, states
  - `WalkingEnemy.gd` - Patrol dan chase behavior
  - `FlyingEnemy.gd` - Hover dan swoop attack
- Boss system:
  - `BossBase.gd` - Multi-phase system, attack patterns
  - `BossScrapper.gd` - Slam + dash, rewards: Dash
  - `BossSporeBot.gd` - Spawn minions + poison, rewards: Double Jump
  - `BossTempest.gd` - Flight + lightning, rewards: Glide
  - `BossOverlord.gd` - 2-phase final boss (robot → spirit)

#### Phase 6: UI System
- `HUD.gd` / `HUD.tscn` - Health bar, core counter, ability icons
- `DialogSystem.gd` / `DialogSystem.tscn` - Oracle dialog dengan typing effect
- `PauseMenu.gd` / `PauseMenu.tscn` - Pause functionality
- `GameOverScreen.gd` / `GameOverScreen.tscn` - Death screen dengan retry
- `VictoryScreen.gd` / `VictoryScreen.tscn` - Level/game complete

#### Phase 7: Testing
- `.gut_settings.json` - GUT configuration
- `test/test_player_movement.gd` - 15+ player tests
- `test/test_game_logic.gd` - 25+ game logic tests
- `test/test_enemy_boss.gd` - 15+ enemy/boss tests

#### Phase 8: Documentation
- `README.md` - Full project documentation
- `CHANGELOG.md` - This file

### Technical Notes
- Engine: Godot 4.6
- Language: GDScript (type-safe)
- Architecture: State Machine + Inheritance patterns
- Testing: GUT framework
- Assets: Placeholder SVGs (CC0 production assets planned)

---

## Future Plans

### [0.3.0] - Planned
- [ ] Settings menu (volume, fullscreen, gameplay tweaks)
- [ ] CI/CD GitHub Actions (test + export)
- [ ] Export presets Windows/Linux/Web
- [ ] Polish game feel (camera, particles, accessibility)

### [1.0.0] - Release
- [ ] Full art assets
- [ ] Complete audio per-level
- [ ] Achievement system
- [ ] Mobile touch controls
