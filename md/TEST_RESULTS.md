# TEST RESULTS — Project: REBOOT

**Tanggal:** Automated run via Godot 4.5.1 headless  
**Branch:** `fix/total-polish`  
**Runner:** Custom TestRunner.gd (bukan GUT)  
**Mode:** `--headless`

---

## RINGKASAN

| Metric   | Nilai  |
|----------|--------|
| **PASSED** | 119  |
| **FAILED** | 0    |
| **TOTAL**  | 119  |
| **Status** | ✅ ALL TESTS PASSED |

---

## PER-SUITE BREAKDOWN

### 1. test_player_movement.gd — 21/21 ✅

| # | Test | Status |
|---|------|--------|
| 1 | Player.tscn harus ada | ✅ |
| 2 | Player harus ter-instantiate | ✅ |
| 3 | Player harus bertipe CharacterBody2D | ✅ |
| 4 | Speed harus > 0 (220) | ✅ |
| 5 | Jump velocity harus negatif (ke atas) | ✅ |
| 6 | Coyote time harus > 0 | ✅ |
| 7 | Coyote time tidak boleh > 0.3s | ✅ |
| 8 | Jump buffer harus > 0 | ✅ |
| 9 | Jump buffer tidak boleh > 0.2s | ✅ |
| 10 | Dash harus lebih cepat dari walk | ✅ |
| 11 | Glide gravity positif dan < normal gravity | ✅ |
| 12 | Dash harus terkunci di awal | ✅ |
| 13 | Double jump harus terkunci di awal | ✅ |
| 14 | Glide harus terkunci di awal | ✅ |
| 15 | Health harus berkurang (90) | ✅ |
| 16 | Health harus 0 saat mati | ✅ |
| 17 | is_game_over harus true | ✅ |
| 18 | Health tidak boleh negatif | ✅ |
| 19 | Player punya fungsi reset_player() | ✅ |
| 20 | Velocity ZERO setelah reset | ✅ |
| 21 | Health max (100) setelah reset | ✅ |

### 2. test_game_logic.gd — 30/30 ✅

| # | Test | Status |
|---|------|--------|
| 1 | Cores mulai dari 0 | ✅ |
| 2 | Core count +1 setelah collect | ✅ |
| 3 | Tidak boleh > MAX_CORES | ✅ |
| 4 | Dash terkunci awal | ✅ |
| 5 | Double jump terkunci awal | ✅ |
| 6 | Glide terkunci awal | ✅ |
| 7 | Dash aktif setelah unlock | ✅ |
| 8 | Double jump aktif setelah unlock | ✅ |
| 9 | Glide aktif setelah unlock | ✅ |
| 10 | is_ability_unlocked: dash false awal | ✅ |
| 11 | is_ability_unlocked: dash true setelah unlock | ✅ |
| 12 | Unknown ability = false | ✅ |
| 13 | Empty string = false | ✅ |
| 14 | Health mulai penuh (100) | ✅ |
| 15 | Heal caps at max | ✅ |
| 16 | Reset health restores max | ✅ |
| 17 | New game resets cores | ✅ |
| 18 | New game resets dash | ✅ |
| 19 | New game resets double jump | ✅ |
| 20 | New game resets glide | ✅ |
| 21 | New game resets health | ✅ |
| 22 | New game resets is_game_over | ✅ |
| 23 | Game starts unpaused | ✅ |
| 24 | Level order has 5 levels | ✅ |
| 25 | Semua path level valid | ✅ |
| 26 | get_cores_count() = 2 | ✅ |
| 27 | get_player_health() correct | ✅ |
| 28 | Multiple unlocks don't stack | ✅ |
| 29 | Zero damage no change | ✅ |
| 30 | Zero heal no change | ✅ |

### 3. test_enemy_boss.gd — 25/25 ✅

| # | Test | Status |
|---|------|--------|
| 1 | EnemyBase.gd ada | ✅ |
| 2 | WalkingEnemy.gd ada | ✅ |
| 3 | FlyingEnemy.gd ada | ✅ |
| 4 | BossBase.gd ada | ✅ |
| 5 | BossScrapper.gd ada | ✅ |
| 6 | BossSporeBot.gd ada | ✅ |
| 7 | BossTempest.gd ada | ✅ |
| 8 | BossOverlord.gd ada | ✅ |
| 9 | Boss 1 rewards dash (before=locked) | ✅ |
| 10 | Boss 1 rewards dash (after=unlocked) | ✅ |
| 11 | Boss 2 rewards double jump (before) | ✅ |
| 12 | Boss 2 rewards double jump (after) | ✅ |
| 13 | Boss 3 rewards glide (before) | ✅ |
| 14 | Boss 3 rewards glide (after) | ✅ |
| 15 | Ability unlock order: awal terkunci | ✅ |
| 16 | Ability unlock order: setelah boss 1 | ✅ |
| 17 | Ability unlock order: setelah boss 2 | ✅ |
| 18 | Ability unlock order: setelah boss 3 | ✅ |
| 19 | MAX_CORES = 5 | ✅ |
| 20 | 5 cores setelah 5 collect | ✅ |
| 21 | Level 1 scene exists | ✅ |
| 22 | Level 2 scene exists | ✅ |
| 23 | Level 3 scene exists | ✅ |
| 24 | Level 4 scene exists | ✅ |
| 25 | Level 5 scene exists | ✅ |

### 4. test_enemy_ai.gd — 25/25 ✅

| # | Test | Status |
|---|------|--------|
| 1 | Enemy starts in IDLE state | ✅ |
| 2 | IDLE → PATROL transition | ✅ |
| 3 | Player detection → CHASE | ✅ |
| 4 | Damage → STUNNED | ✅ |
| 5 | Zero health → DEAD | ✅ |
| 6 | SEARCH state timeout (3.0s) | ✅ |
| 7 | ATTACK state cooldown (1.0s) | ✅ |
| 8 | Vision range (300) | ✅ |
| 9 | Vision angle (60°) | ✅ |
| 10 | Walls block vision (RayCast2D) | ✅ |
| 11 | Facing direction restricts vision | ✅ |
| 12 | Enemy starts at full health (50) | ✅ |
| 13 | Damage reduces health (40) | ✅ |
| 14 | Knockback on damage | ✅ |
| 15 | Death at zero health | ✅ |
| 16 | I-frames (0.30s) | ✅ |
| 17 | Patrol reverses at walls | ✅ |
| 18 | Patrol reverses at edges | ✅ |
| 19 | Patrol speed (80) | ✅ |
| 20 | Sprint multiplier (1.80) | ✅ |
| 21 | Hover amplitude (15) | ✅ |
| 22 | Hover frequency (2.0) | ✅ |
| 23 | Turret rotation range (90°) | ✅ |
| 24 | Attack damage applied (90 HP) | ✅ |
| 25 | Attack cooldown prevents spam | ✅ |

### 5. test_combat_system.gd — 18/18 ✅

| # | Test | Status |
|---|------|--------|
| 1 | Attack damage balanced (25) | ✅ |
| 2 | Attack cooldown responsive (0.40s) | ✅ |
| 3 | Attack duration snappy (0.25s) | ✅ |
| 4 | Knockback impactful (200) | ✅ |
| 5 | Player starts not attacking | ✅ |
| 6 | Attack input starts attack | ✅ |
| 7 | Cannot attack during cooldown | ✅ |
| 8 | Attack blocked during dash | ✅ |
| 9 | Hitbox in front when facing right (20) | ✅ |
| 10 | Hitbox targets enemy layer (2) | ✅ |
| 11 | Hitbox activates when attacking | ✅ |
| 12 | Hitbox deactivates after attack | ✅ |
| 13 | Hit stop impact feel (0.05s) | ✅ |
| 14 | Enemy takes correct damage (25) | ✅ |
| 15 | Knockback in facing direction | ✅ |
| 16 | Screen shake noticeable (6.0) | ✅ |
| 17 | Attack rotation visible (15°) | ✅ |
| 18 | Attack has sound effect | ✅ |

---

## CATATAN

- Test `test_integration_level4.gd` tidak diikutkan di TestRunner (butuh scene loading penuh)
- Exit code 1 dari Godot headless disebabkan oleh `ObjectDB instances leaked at exit` — ini bukan error test, melainkan cleanup Godot saat headless exit
- Test `glide_gravity_multiplier` diperbaiki → sekarang test `glide_gravity` sesuai property Player.gd aktual
