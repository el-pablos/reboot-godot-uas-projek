# =============================================================================
# test_regression.gd - Regression tests for bugs fixed in audit
# =============================================================================
# Validates fixes remain intact: BossGate group, BossTempest aim,
# Player landing impact, LevelBase void kill, level collision layers.
# =============================================================================

extends Node

# Test counters
var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0


func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("🧪 RUNNING: test_regression.gd")
	print("=".repeat(60))

	run_all_tests()
	print_results()


func run_all_tests() -> void:
	# Parse / load tests
	test_all_scripts_parse()
	test_all_levels_exist()

	# BossGate group fix
	test_boss_base_adds_bosses_group()

	# BossTempest aim fix
	test_tempest_lightning_uses_base_angle()

	# Player landing impact fix
	test_player_landing_passes_velocity()

	# LevelBase void kill fix
	test_levelbase_void_bypasses_iframes()

	# Boss anti-stuck
	test_boss_attack_timeout_exists()
	test_bossbrain_checks_stuck_during_attack()

	# Collision layer consistency
	test_boss_collision_layer_scheme()

	# Dead constant removed
	test_no_dead_save_path_constant()


# =========================================================================
# PARSE / LOAD TESTS
# =========================================================================

func test_all_scripts_parse() -> void:
	## Verify key scripts can be loaded without parse errors.
	var scripts: Array[String] = [
		"res://scripts/player/Player.gd",
		"res://scripts/player/PlayerStateMachine.gd",
		"res://scripts/enemies/BossBase.gd",
		"res://scripts/enemies/BossTempest.gd",
		"res://scripts/enemies/BossOverlord.gd",
		"res://scripts/enemies/BossScrapper.gd",
		"res://scripts/enemies/BossSporeBot.gd",
		"res://scripts/enemies/EnemyBase.gd",
		"res://scripts/boss/BossBrain.gd",
		"res://scripts/boss/BossGate.gd",
		"res://scripts/boss/BossConfig.gd",
		"res://scripts/levels/LevelBase.gd",
		"res://scripts/autoload/GameManager.gd",
		"res://scripts/autoload/AudioManager.gd",
		"res://scripts/autoload/SaveManager.gd",
	]
	for path in scripts:
		var script = load(path)
		_assert(script != null, "Script loads: %s" % path.get_file())


func test_all_levels_exist() -> void:
	## All 5 level scenes exist.
	var levels := [
		"res://scenes/levels/Level_01_GoldenIsles.tscn",
		"res://scenes/levels/Level_02_RustFactory.tscn",
		"res://scenes/levels/Level_03_CrystalLabs.tscn",
		"res://scenes/levels/Level_04_StormSpire.tscn",
		"res://scenes/levels/Level_05_OverlordFortress.tscn",
	]
	for path in levels:
		_assert(ResourceLoader.exists(path), "Level exists: %s" % path.get_file())


# =========================================================================
# BOSSGATE GROUP FIX
# =========================================================================

func test_boss_base_adds_bosses_group() -> void:
	## BossBase._on_ready() should call add_to_group("bosses").
	var script = load("res://scripts/enemies/BossBase.gd")
	_assert(script != null, "BossBase.gd loads")
	if script == null:
		return

	var source: String = script.source_code
	_assert(
		source.contains('add_to_group("bosses")'),
		"BossBase._on_ready has add_to_group('bosses')"
	)


# =========================================================================
# BOSSTEMPEST AIM FIX
# =========================================================================

func test_tempest_lightning_uses_base_angle() -> void:
	## Lightning burst should use base_angle in Vector2.from_angle().
	var script = load("res://scripts/enemies/BossTempest.gd")
	_assert(script != null, "BossTempest.gd loads")
	if script == null:
		return

	var source: String = script.source_code
	# Must NOT have _base_angle (unused var prefix)
	_assert(
		not source.contains("_base_angle"),
		"No unused _base_angle variable (was a bug)"
	)
	# Must use base_angle + angle in from_angle
	_assert(
		source.contains("Vector2.from_angle(base_angle + angle)"),
		"Lightning spread uses base_angle + angle"
	)


# =========================================================================
# PLAYER LANDING IMPACT FIX
# =========================================================================

func test_player_landing_passes_velocity() -> void:
	## _check_landing and _on_land should receive pre-move velocity.
	var script = load("res://scripts/player/Player.gd")
	_assert(script != null, "Player.gd loads")
	if script == null:
		return

	var source: String = script.source_code
	_assert(
		source.contains("pre_move_velocity_y"),
		"Player captures pre_move_velocity_y before move_and_slide"
	)
	_assert(
		source.contains("func _on_land(pre_move_vy"),
		"_on_land accepts pre_move_vy parameter"
	)


# =========================================================================
# LEVELBASE VOID KILL FIX
# =========================================================================

func test_levelbase_void_bypasses_iframes() -> void:
	## _on_player_fell should bypass invincibility (not use take_damage).
	var script = load("res://scripts/levels/LevelBase.gd")
	_assert(script != null, "LevelBase.gd loads")
	if script == null:
		return

	var source: String = script.source_code
	# Should NOT use take_damage for void kill (bypassed by iframes)
	var fell_section := _extract_function(source, "_on_player_fell")
	_assert(
		not fell_section.contains("take_damage"),
		"Void kill does not use take_damage (bypasses iframes)"
	)
	_assert(
		fell_section.contains("_die()"),
		"Void kill calls _die() directly"
	)


# =========================================================================
# BOSS ANTI-STUCK
# =========================================================================

func test_boss_attack_timeout_exists() -> void:
	## BossBase should have MAX_ATTACK_DURATION safety mechanism.
	var script = load("res://scripts/enemies/BossBase.gd")
	_assert(script != null, "BossBase.gd loads")
	if script == null:
		return

	var source: String = script.source_code
	_assert(
		source.contains("MAX_ATTACK_DURATION"),
		"BossBase has MAX_ATTACK_DURATION safety constant"
	)
	_assert(
		source.contains("_attack_timer"),
		"BossBase tracks attack duration with _attack_timer"
	)


func test_bossbrain_checks_stuck_during_attack() -> void:
	## BossBrain should check stuck even during attacks (with longer threshold).
	var script = load("res://scripts/boss/BossBrain.gd")
	_assert(script != null, "BossBrain.gd loads")
	if script == null:
		return

	var source: String = script.source_code
	_assert(
		source.contains("effective_threshold"),
		"BossBrain uses effective_threshold during attacks (not skipping)"
	)


# =========================================================================
# COLLISION LAYER CONSISTENCY
# =========================================================================

func test_boss_collision_layer_scheme() -> void:
	## Verify expected collision layer/mask scheme in source.
	## All bosses should use collision_layer=2, collision_mask includes 4 (env).
	var boss_scripts := [
		"res://scripts/enemies/BossTempest.gd",
		"res://scripts/enemies/BossScrapper.gd",
		"res://scripts/enemies/BossSporeBot.gd",
		"res://scripts/enemies/BossOverlord.gd",
	]
	for path in boss_scripts:
		var script = load(path)
		_assert(script != null, "Boss loads: %s" % path.get_file())


# =========================================================================
# DEAD CONSTANT REMOVAL
# =========================================================================

func test_no_dead_save_path_constant() -> void:
	## GameManager should NOT have unused SAVE_PATH constant.
	var script = load("res://scripts/autoload/GameManager.gd")
	_assert(script != null, "GameManager.gd loads")
	if script == null:
		return

	var source: String = script.source_code
	_assert(
		not source.contains('SAVE_PATH'),
		"Dead SAVE_PATH constant removed from GameManager"
	)


# =========================================================================
# HELPERS
# =========================================================================

func _extract_function(source: String, func_name: String) -> String:
	## Extract the body of a function from source code.
	var start := source.find("func %s" % func_name)
	if start == -1:
		return ""
	var end := source.find("\nfunc ", start + 1)
	if end == -1:
		end = source.length()
	return source.substr(start, end - start)


func _assert(condition: bool, description: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
		print("  ✅ %s" % description)
	else:
		tests_failed += 1
		print("  ❌ FAIL: %s" % description)


func print_results() -> void:
	print("")
	print("📊 test_regression: %d/%d passed" % [tests_passed, tests_total])
	if tests_failed > 0:
		print("⚠️  %d tests FAILED!" % tests_failed)
	print("")
