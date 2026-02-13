# =============================================================================
# test_boss_attack.gd - Tests that bosses actually attack (telegraph fix)
# =============================================================================
# Verifies the BossBrain telegraph → attack_requested flow works correctly.
# Root cause fixed: infinite telegraph loop prevented attack_requested
# from ever being emitted.
# =============================================================================

extends Node

# Test counters
var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0


func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("🧪 RUNNING: test_boss_attack.gd")
	print("=".repeat(60))

	run_all_tests()
	print_results()


func run_all_tests() -> void:
	# BossBrain telegraph flag
	test_brain_has_telegraph_completed_flag()
	test_brain_telegraph_completed_starts_false()
	test_brain_telegraph_sets_completed_on_expire()
	test_brain_telegraph_completed_resets_on_state_change()
	test_brain_telegraph_completed_resets_on_start_telegraph()
	test_brain_telegraph_completed_resets_on_end_attack()

	# Attack flow simulation
	test_attack_close_emits_after_telegraph()
	test_attack_far_emits_after_telegraph()
	test_attack_close_no_telegraph_still_emits()
	test_attack_far_no_telegraph_still_emits()

	# Per-boss attack handler connection
	test_scrapper_has_attack_handler()
	test_sporebot_has_attack_handler()
	test_tempest_has_attack_handler()
	test_overlord_has_attack_handler()

	# Per-boss _start_attack and _end_attack
	test_scrapper_attack_lifecycle()
	test_sporebot_attack_lifecycle()
	test_tempest_attack_lifecycle()
	test_overlord_attack_lifecycle()

	# BossConfig telegraph durations
	test_all_configs_have_telegraph_duration()

	# Anti-stuck guard
	test_brain_unstuck_guard_exists()


func print_results() -> void:
	print("\n" + "-".repeat(60))
	print("📊 HASIL TEST BOSS ATTACK")
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


# === HELPERS ===

func assert_true(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
		print("  ✅ PASS: %s" % message)
	else:
		tests_failed += 1
		print("  ❌ FAIL: %s" % message)


func assert_eq(a: Variant, b: Variant, message: String) -> void:
	assert_true(a == b, message + " (got: %s, expected: %s)" % [str(a), str(b)])


func _create_brain_with_config(telegraph_dur: float = 0.4) -> BossBrain:
	## Helper: create a BossBrain with a test config.
	var brain := BossBrain.new()
	var config := BossConfig.new()
	config.telegraph_duration = telegraph_dur
	config.attack_cooldown_min = 1.0
	config.attack_cooldown_max = 2.0
	brain.config = config
	return brain


func _create_mock_boss() -> Node:
	## Helper: create a mock boss with is_attacking, sprite, etc.
	var mock_script: GDScript = load("res://test/mock_boss.gd")
	var mock: CharacterBody2D = mock_script.new()
	mock.name = "MockBoss"
	return mock


# === TELEGRAPH FLAG TESTS ===

func test_brain_has_telegraph_completed_flag() -> void:
	print("\n[Test] BossBrain has _telegraph_completed flag")
	var brain := BossBrain.new()
	assert_true("_telegraph_completed" in brain, "BossBrain should have _telegraph_completed property")
	brain.free()


func test_brain_telegraph_completed_starts_false() -> void:
	print("\n[Test] _telegraph_completed starts as false")
	var brain := BossBrain.new()
	assert_eq(brain._telegraph_completed, false, "_telegraph_completed should start false")
	brain.free()


func test_brain_telegraph_sets_completed_on_expire() -> void:
	print("\n[Test] Telegraph timer expiring sets _telegraph_completed = true")
	var brain := _create_brain_with_config(0.1)
	# Simulate: start telegraph
	brain._start_telegraph(0.1)
	assert_eq(brain.is_telegraphing, true, "Should be telegraphing after _start_telegraph")
	assert_eq(brain._telegraph_completed, false, "Should NOT be completed during telegraph")
	# Simulate: timer expires
	brain._update_timers(0.2)  # delta > telegraph_timer
	assert_eq(brain.is_telegraphing, false, "Should stop telegraphing after timer expires")
	assert_eq(brain._telegraph_completed, true, "_telegraph_completed should be true after timer expires")
	brain.free()


func test_brain_telegraph_completed_resets_on_state_change() -> void:
	print("\n[Test] _telegraph_completed resets on _change_state()")
	var brain := _create_brain_with_config()
	brain._telegraph_completed = true
	# Create a mock boss parent
	var dummy := _create_mock_boss()
	dummy.add_child(brain)
	brain.boss = dummy
	brain._change_state(BossBrain.AIState.CHASE)
	assert_eq(brain._telegraph_completed, false, "_telegraph_completed should reset on state change")
	dummy.free()


func test_brain_telegraph_completed_resets_on_start_telegraph() -> void:
	print("\n[Test] _telegraph_completed resets on _start_telegraph()")
	var brain := _create_brain_with_config()
	brain._telegraph_completed = true
	brain._start_telegraph(0.5)
	assert_eq(brain._telegraph_completed, false, "_telegraph_completed should reset when new telegraph starts")
	brain.free()


func test_brain_telegraph_completed_resets_on_end_attack() -> void:
	print("\n[Test] _telegraph_completed resets on end_attack()")
	var brain := _create_brain_with_config()
	brain._telegraph_completed = true
	brain.end_attack()
	assert_eq(brain._telegraph_completed, false, "_telegraph_completed should reset on end_attack()")
	brain.free()


# === ATTACK EMISSION TESTS ===

func test_attack_close_emits_after_telegraph() -> void:
	print("\n[Test] _do_attack_close emits attack_requested after telegraph completes")
	var brain := _create_brain_with_config(0.5)
	var dummy := _create_mock_boss()
	dummy.add_child(brain)
	brain.boss = dummy

	var received_attacks: Array = []
	brain.attack_requested.connect(func(t: String): received_attacks.append(t))

	# Step 1: first call starts telegraph
	brain._do_attack_close()
	assert_eq(brain.is_telegraphing, true, "Should start telegraphing")
	assert_eq(received_attacks.size(), 0, "Should NOT emit during telegraph")

	# Step 2: simulate telegraph expiring
	brain._update_timers(1.0)
	assert_eq(brain._telegraph_completed, true, "_telegraph_completed should be set")

	# Step 3: call again — should emit attack
	brain._do_attack_close()
	assert_eq(received_attacks.size(), 1, "Should have emitted attack_requested('close')")
	if received_attacks.size() > 0:
		assert_eq(received_attacks[0], "close", "Attack type should be 'close'")

	dummy.free()


func test_attack_far_emits_after_telegraph() -> void:
	print("\n[Test] _do_attack_far emits attack_requested after telegraph completes")
	var brain := _create_brain_with_config(0.5)
	var dummy := _create_mock_boss()
	dummy.add_child(brain)
	brain.boss = dummy

	var received_attacks: Array = []
	brain.attack_requested.connect(func(t: String): received_attacks.append(t))

	# Step 1: start telegraph
	brain._do_attack_far()
	assert_eq(brain.is_telegraphing, true, "Should start telegraphing for far attack")

	# Step 2: expire telegraph
	brain._update_timers(1.0)

	# Step 3: call again — should emit
	brain._do_attack_far()
	assert_eq(received_attacks.size(), 1, "Should have emitted attack_requested('far')")
	if received_attacks.size() > 0:
		assert_eq(received_attacks[0], "far", "Attack type should be 'far'")

	dummy.free()


func test_attack_close_no_telegraph_still_emits() -> void:
	print("\n[Test] _do_attack_close emits immediately when telegraph_duration == 0")
	var brain := _create_brain_with_config(0.0)  # No telegraph
	var dummy := _create_mock_boss()
	dummy.add_child(brain)
	brain.boss = dummy

	var received: Array = []
	brain.attack_requested.connect(func(t: String): received.append(t))

	brain._do_attack_close()
	assert_eq(received.size(), 1, "Should emit immediately with telegraph_duration=0")

	dummy.free()


func test_attack_far_no_telegraph_still_emits() -> void:
	print("\n[Test] _do_attack_far emits immediately when telegraph_duration == 0")
	var brain := _create_brain_with_config(0.0)
	var dummy := _create_mock_boss()
	dummy.add_child(brain)
	brain.boss = dummy

	var received: Array = []
	brain.attack_requested.connect(func(t: String): received.append(t))

	brain._do_attack_far()
	assert_eq(received.size(), 1, "Should emit immediately with telegraph_duration=0")

	dummy.free()


# === PER-BOSS ATTACK HANDLER TESTS ===

func test_scrapper_has_attack_handler() -> void:
	print("\n[Test] BossScrapper overrides _on_brain_attack_requested")
	var script: GDScript = load("res://scripts/enemies/BossScrapper.gd")
	assert_true(script != null, "BossScrapper.gd should exist")
	if script:
		var source: String = script.source_code
		assert_true(source.find("_on_brain_attack_requested") >= 0,
			"BossScrapper should override _on_brain_attack_requested")
		assert_true(source.find("_attack_slam") >= 0,
			"BossScrapper should have _attack_slam")
		assert_true(source.find("_attack_dash") >= 0,
			"BossScrapper should have _attack_dash")


func test_sporebot_has_attack_handler() -> void:
	print("\n[Test] BossSporeBot overrides _on_brain_attack_requested")
	var script: GDScript = load("res://scripts/enemies/BossSporeBot.gd")
	assert_true(script != null, "BossSporeBot.gd should exist")
	if script:
		var source: String = script.source_code
		assert_true(source.find("_on_brain_attack_requested") >= 0,
			"BossSporeBot should override _on_brain_attack_requested")
		assert_true(source.find("_attack_spore_burst") >= 0,
			"BossSporeBot should have _attack_spore_burst")


func test_tempest_has_attack_handler() -> void:
	print("\n[Test] BossTempest overrides _on_brain_attack_requested")
	var script: GDScript = load("res://scripts/enemies/BossTempest.gd")
	assert_true(script != null, "BossTempest.gd should exist")
	if script:
		var source: String = script.source_code
		assert_true(source.find("_on_brain_attack_requested") >= 0,
			"BossTempest should override _on_brain_attack_requested")
		assert_true(source.find("_attack_lightning_bolt") >= 0,
			"BossTempest should have _attack_lightning_bolt")


func test_overlord_has_attack_handler() -> void:
	print("\n[Test] BossOverlord overrides _on_brain_attack_requested")
	var script: GDScript = load("res://scripts/enemies/BossOverlord.gd")
	assert_true(script != null, "BossOverlord.gd should exist")
	if script:
		var source: String = script.source_code
		assert_true(source.find("_on_brain_attack_requested") >= 0,
			"BossOverlord should override _on_brain_attack_requested")
		assert_true(source.find("_attack_horizontal_laser") >= 0,
			"BossOverlord should have _attack_horizontal_laser")


# === ATTACK LIFECYCLE TESTS ===

func _test_boss_attack_lifecycle(boss_script_path: String, boss_name: String) -> void:
	## Generic test: boss can call _start_attack/_end_attack.
	var script: GDScript = load(boss_script_path)
	assert_true(script != null, "%s script should load" % boss_name)
	if not script:
		return
	var source: String = script.source_code
	assert_true(source.find("_start_attack(") >= 0,
		"%s should call _start_attack()" % boss_name)
	assert_true(source.find("_end_attack()") >= 0,
		"%s should call _end_attack()" % boss_name)


func test_scrapper_attack_lifecycle() -> void:
	print("\n[Test] BossScrapper attack lifecycle")
	_test_boss_attack_lifecycle("res://scripts/enemies/BossScrapper.gd", "BossScrapper")


func test_sporebot_attack_lifecycle() -> void:
	print("\n[Test] BossSporeBot attack lifecycle")
	_test_boss_attack_lifecycle("res://scripts/enemies/BossSporeBot.gd", "BossSporeBot")


func test_tempest_attack_lifecycle() -> void:
	print("\n[Test] BossTempest attack lifecycle")
	_test_boss_attack_lifecycle("res://scripts/enemies/BossTempest.gd", "BossTempest")


func test_overlord_attack_lifecycle() -> void:
	print("\n[Test] BossOverlord attack lifecycle")
	_test_boss_attack_lifecycle("res://scripts/enemies/BossOverlord.gd", "BossOverlord")


# === CONFIG TESTS ===

func test_all_configs_have_telegraph_duration() -> void:
	print("\n[Test] All BossConfig factory configs have telegraph_duration > 0")
	var scrapper := BossConfig.create_scrapper_config()
	assert_true(scrapper.telegraph_duration > 0,
		"Scrapper config telegraph_duration > 0 (got: %s)" % scrapper.telegraph_duration)

	var sporebot := BossConfig.create_sporebot_config()
	assert_true(sporebot.telegraph_duration > 0,
		"SporeBot config telegraph_duration > 0 (got: %s)" % sporebot.telegraph_duration)

	var tempest := BossConfig.create_tempest_config()
	assert_true(tempest.telegraph_duration > 0,
		"Tempest config telegraph_duration > 0 (got: %s)" % tempest.telegraph_duration)

	var overlord := BossConfig.create_overlord_config()
	assert_true(overlord.telegraph_duration > 0,
		"Overlord config telegraph_duration > 0 (got: %s)" % overlord.telegraph_duration)


# === ANTI-STUCK TESTS ===

func test_brain_unstuck_guard_exists() -> void:
	print("\n[Test] BossBrain has unstuck guard")
	var brain := BossBrain.new()
	assert_true("_stuck_timer" in brain, "BossBrain should have _stuck_timer")
	assert_true("_stuck_threshold" in brain, "BossBrain should have _stuck_threshold")
	assert_true(brain.has_method("_check_unstuck"), "BossBrain should have _check_unstuck()")
	assert_true(brain.has_method("_do_unstuck_nudge"), "BossBrain should have _do_unstuck_nudge()")
	brain.free()
