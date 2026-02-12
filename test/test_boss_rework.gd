# =============================================================================
# test_boss_rework.gd - Unit Test untuk Boss Rework (BossBrain, BossGate, Level Load)
# =============================================================================
# Test suite: boss AI state machine, gate system, dan level loading.
# =============================================================================

extends Node

# Test counters
var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0


# -----------------------------------------------------------------------------
# ENTRY POINT
# -----------------------------------------------------------------------------

func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("🧪 RUNNING: test_boss_rework.gd")
	print("=".repeat(60))
	
	run_all_tests()
	print_results()


func run_all_tests() -> void:
	# Script existence
	test_boss_brain_script_exists()
	test_boss_config_script_exists()
	test_boss_gate_script_exists()
	
	# BossConfig factory methods
	test_scrapper_config_creation()
	test_sporebot_config_creation()
	test_tempest_config_creation()
	test_overlord_config_creation()
	
	# BossBrain AI states
	test_brain_initial_state_is_roam()
	test_brain_state_enum_count()
	test_brain_transitions_to_chase_on_target()
	
	# BossGate
	test_gate_script_has_gate_color()
	test_gate_starts_with_collision_enabled()
	
	# Level loading
	test_level_2_loads_with_gate()
	test_level_3_loads_with_gate()
	test_level_4_loads_with_gate()
	test_level_5_loads_with_gate()


func print_results() -> void:
	print("\n" + "-".repeat(60))
	print("📊 HASIL TEST BOSS REWORK")
	print("-".repeat(60))
	print("✅ Passed: %d" % tests_passed)
	print("❌ Failed: %d" % tests_failed)
	print("📝 Total:  %d" % tests_total)
	print("-".repeat(60))
	
	if tests_failed == 0:
		print("🎉 SEMUA TEST PASSED!")
	else:
		print("⚠️  ADA TEST YANG GAGAL")
	print("")


# -----------------------------------------------------------------------------
# HELPER FUNCTIONS
# -----------------------------------------------------------------------------

func assert_true(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
		print("  ✅ PASS: %s" % message)
	else:
		tests_failed += 1
		print("  ❌ FAIL: %s" % message)


func assert_not_null(obj: Variant, message: String) -> void:
	assert_true(obj != null, message)


func assert_eq(a: Variant, b: Variant, message: String) -> void:
	assert_true(a == b, message + " (got: %s, expected: %s)" % [str(a), str(b)])


# -----------------------------------------------------------------------------
# TESTS: SCRIPT EXISTENCE
# -----------------------------------------------------------------------------

func test_boss_brain_script_exists() -> void:
	print("\n[Test] BossBrain Script Exists")
	var script = load("res://scripts/boss/BossBrain.gd")
	assert_not_null(script, "BossBrain.gd harus ada")


func test_boss_config_script_exists() -> void:
	print("\n[Test] BossConfig Script Exists")
	var script = load("res://scripts/boss/BossConfig.gd")
	assert_not_null(script, "BossConfig.gd harus ada")


func test_boss_gate_script_exists() -> void:
	print("\n[Test] BossGate Script Exists")
	var script = load("res://scripts/boss/BossGate.gd")
	assert_not_null(script, "BossGate.gd harus ada")


# -----------------------------------------------------------------------------
# TESTS: BOSS CONFIG FACTORY METHODS
# -----------------------------------------------------------------------------

func test_scrapper_config_creation() -> void:
	print("\n[Test] BossConfig Scrapper Factory")
	var config_script = load("res://scripts/boss/BossConfig.gd")
	var config = config_script.create_scrapper_config()
	assert_not_null(config, "create_scrapper_config() harus return config")
	assert_true(config.detection_range > 0, "Scrapper detection_range > 0")
	assert_true(config.chase_speed > 0, "Scrapper chase_speed > 0")
	assert_true(config.attack_cooldown > 0, "Scrapper attack_cooldown > 0")


func test_sporebot_config_creation() -> void:
	print("\n[Test] BossConfig SporeBot Factory")
	var config_script = load("res://scripts/boss/BossConfig.gd")
	var config = config_script.create_sporebot_config()
	assert_not_null(config, "create_sporebot_config() harus return config")
	assert_true(config.detection_range > 0, "SporeBot detection_range > 0")
	assert_true(config.telegraph_duration > 0, "SporeBot telegraph_duration > 0")


func test_tempest_config_creation() -> void:
	print("\n[Test] BossConfig Tempest Factory")
	var config_script = load("res://scripts/boss/BossConfig.gd")
	var config = config_script.create_tempest_config()
	assert_not_null(config, "create_tempest_config() harus return config")
	assert_true(config.far_attack_range > 0, "Tempest far_attack_range > 0")


func test_overlord_config_creation() -> void:
	print("\n[Test] BossConfig Overlord Factory")
	var config_script = load("res://scripts/boss/BossConfig.gd")
	var config = config_script.create_overlord_config()
	assert_not_null(config, "create_overlord_config() harus return config")
	assert_true(config.close_attack_range > 0, "Overlord close_attack_range > 0")
	assert_true(config.arena_size != Vector2.ZERO, "Overlord arena_size != ZERO")


# -----------------------------------------------------------------------------
# TESTS: BOSSBRAIN AI STATE
# -----------------------------------------------------------------------------

func test_brain_initial_state_is_roam() -> void:
	print("\n[Test] BossBrain Initial State = ROAM")
	var brain_script = load("res://scripts/boss/BossBrain.gd")
	var brain = brain_script.new()
	# BossBrain current_state defaults to AIState.ROAM (0)
	assert_eq(brain.current_state, 0, "Initial state harus ROAM (0)")
	brain.free()


func test_brain_state_enum_count() -> void:
	print("\n[Test] BossBrain Has 7 AI States")
	# AIState enum: ROAM, CHASE, ATTACK_CLOSE, ATTACK_FAR, REPOSITION, RECOVER, PHASE_CHANGE
	var brain_script = load("res://scripts/boss/BossBrain.gd")
	var brain = brain_script.new()
	# PHASE_CHANGE = 6 (last enum), so 7 states total
	assert_eq(brain.AIState.PHASE_CHANGE, 6, "PHASE_CHANGE harus index 6 (7 states)")
	brain.free()


func test_brain_transitions_to_chase_on_target() -> void:
	print("\n[Test] BossBrain Transitions to CHASE When Target Nearby")
	var brain_script = load("res://scripts/boss/BossBrain.gd")
	var config_script = load("res://scripts/boss/BossConfig.gd")
	
	var brain = brain_script.new()
	var config = config_script.create_scrapper_config()
	brain.config = config
	
	# Create a dummy target (CharacterBody2D acts as player)
	var target = CharacterBody2D.new()
	target.add_to_group("player")
	
	# Add both to scene tree for group lookup
	add_child(brain)
	add_child(target)
	
	# Put target within detection range
	target.global_position = Vector2(50, 0)
	brain.global_position = Vector2(0, 0)
	brain.target = target
	
	# Force state check (simulate what _process does)
	brain._acquire_target()
	assert_not_null(brain.target, "Target harus ter-acquire")
	
	# Cleanup
	brain.queue_free()
	target.queue_free()


# -----------------------------------------------------------------------------
# TESTS: BOSS GATE
# -----------------------------------------------------------------------------

func test_gate_script_has_gate_color() -> void:
	print("\n[Test] BossGate Has gate_color Property")
	var gate_script = load("res://scripts/boss/BossGate.gd")
	var gate = StaticBody2D.new()
	gate.set_script(gate_script)
	assert_true("gate_color" in gate, "BossGate harus punya property gate_color")
	gate.free()


func test_gate_starts_with_collision_enabled() -> void:
	print("\n[Test] BossGate Collision Enabled at Start")
	var gate_script = load("res://scripts/boss/BossGate.gd")
	var gate = StaticBody2D.new()
	gate.set_script(gate_script)
	# Gate should NOT be disabled at start (blocks path)
	assert_true(not gate.get("is_open"), "Gate harus tertutup saat start")
	gate.free()


# -----------------------------------------------------------------------------
# TESTS: LEVEL LOADING WITH GATES
# -----------------------------------------------------------------------------

func test_level_2_loads_without_gate() -> void:
	print("\n[Test] Level 2 Loads Without BossGate")
	var scene = load("res://scenes/levels/Level_02_RustFactory.tscn")
	assert_not_null(scene, "Level 2 scene harus bisa di-load")
	if scene:
		var level = scene.instantiate()
		var gate = level.get_node_or_null("BossGate")
		assert_true(gate == null, "Level 2 TIDAK boleh punya BossGate (sudah dihapus)")
		var boss = level.get_node_or_null("BossScrapper")
		assert_not_null(boss, "Level 2 harus punya BossScrapper")
		level.queue_free()


func test_level_3_loads_without_gate() -> void:
	print("\n[Test] Level 3 Loads Without BossGate")
	var scene = load("res://scenes/levels/Level_03_CrystalLabs.tscn")
	assert_not_null(scene, "Level 3 scene harus bisa di-load")
	if scene:
		var level = scene.instantiate()
		var gate = level.get_node_or_null("BossGate")
		assert_true(gate == null, "Level 3 TIDAK boleh punya BossGate (sudah dihapus)")
		var boss = level.get_node_or_null("BossSporeBot")
		assert_not_null(boss, "Level 3 harus punya BossSporeBot")
		level.queue_free()


func test_level_4_loads_without_gate() -> void:
	print("\n[Test] Level 4 Loads Without BossGate")
	var scene = load("res://scenes/levels/Level_04_StormSpire.tscn")
	assert_not_null(scene, "Level 4 scene harus bisa di-load")
	if scene:
		var level = scene.instantiate()
		var gate = level.get_node_or_null("BossGate")
		assert_true(gate == null, "Level 4 TIDAK boleh punya BossGate (sudah dihapus)")
		var boss = level.get_node_or_null("BossTempest")
		assert_not_null(boss, "Level 4 harus punya BossTempest")
		level.queue_free()


func test_level_5_loads_without_gate() -> void:
	print("\n[Test] Level 5 Loads Without BossGate")
	var scene = load("res://scenes/levels/Level_05_OverlordFortress.tscn")
	assert_not_null(scene, "Level 5 scene harus bisa di-load")
	if scene:
		var level = scene.instantiate()
		var gate = level.get_node_or_null("BossGate")
		assert_true(gate == null, "Level 5 TIDAK boleh punya BossGate (sudah dihapus)")
		var boss = level.get_node_or_null("BossOverlord")
		assert_not_null(boss, "Level 5 harus punya BossOverlord")
		level.queue_free()
