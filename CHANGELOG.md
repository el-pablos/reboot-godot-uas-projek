# Changelog

Semua perubahan penting pada project ini akan didokumentasikan di file ini.

Format berdasarkan [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
dan project ini mengikuti [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

### [0.2.0] - Planned
- [ ] Proper tilemap implementation
- [ ] Animated sprites untuk BIP dan enemies
- [ ] Sound effects dan background music
- [ ] Screen shake dan juice effects
- [ ] Mobile touch controls

### [0.3.0] - Planned
- [ ] Save/Load system integration
- [ ] Settings menu (volume, controls)
- [ ] Achievement system
- [ ] Speedrun timer

### [1.0.0] - Release
- [ ] Full art assets
- [ ] Complete audio
- [ ] Polish dan bug fixes
- [ ] Export untuk Windows/Linux/Web
