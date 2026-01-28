# =============================================================================
# test_game_logic.gd - Unit Test untuk Game Logic (Standalone)
# =============================================================================
# Test suite untuk memverifikasi game systems tanpa GUT dependency.
# =============================================================================

extends Node

# Test counters
var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

# Reference
var game_manager: Node = null


# -----------------------------------------------------------------------------
# ENTRY POINT
# -----------------------------------------------------------------------------

func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("🧪 RUNNING: test_game_logic.gd")
	print("=".repeat(60))
	
	game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager == null:
		print("❌ CRITICAL: GameManager tidak ditemukan!")
		return
	
	# Reset state
	game_manager.new_game()
	
	# Jalankan semua test
	run_all_tests()
	
	# Print hasil
	print_results()


func run_all_tests() -> void:
	test_cores_start_at_zero()
	test_collecting_core_increments_counter()
	test_cannot_exceed_max_cores()
	test_all_abilities_start_locked()
	test_unlock_dash_enables_dash()
	test_unlock_double_jump_enables_double_jump()
	test_unlock_glide_enables_glide()
	test_is_ability_unlocked_helper()
	test_unknown_ability_returns_false()
	test_health_starts_full()
	test_heal_caps_at_max()
	test_reset_health_restores_max()
	test_new_game_resets_all_progress()
	test_game_starts_unpaused()
	test_level_order_has_five_levels()
	test_all_level_paths_valid()
	test_get_cores_count()
	test_get_player_health()
	test_multiple_unlocks_dont_stack()
	test_zero_damage_no_change()
	test_zero_heal_no_change()


func print_results() -> void:
	print("\n" + "-".repeat(60))
	print("📊 HASIL TEST GAME LOGIC")
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


func assert_false(condition: bool, message: String) -> void:
	assert_true(not condition, message)


func assert_eq(a: Variant, b: Variant, message: String) -> void:
	assert_true(a == b, message + " (got: %s, expected: %s)" % [str(a), str(b)])


func assert_lte(a: int, b: int, message: String) -> void:
	assert_true(a <= b, message)


# -----------------------------------------------------------------------------
# TESTS: CORE COLLECTION
# -----------------------------------------------------------------------------

func test_cores_start_at_zero() -> void:
	print("\n[Test] Cores Start at Zero")
	game_manager.new_game()
	assert_eq(game_manager.cores_collected, 0, "Cores harus mulai dari 0")


func test_collecting_core_increments_counter() -> void:
	print("\n[Test] Collecting Core Increments Counter")
	game_manager.new_game()
	var initial: int = game_manager.cores_collected
	game_manager.collect_core()
	assert_eq(game_manager.cores_collected, initial + 1, "Core count harus +1")
	game_manager.new_game()


func test_cannot_exceed_max_cores() -> void:
	print("\n[Test] Cannot Exceed Max Cores")
	game_manager.new_game()
	for i in range(10):
		game_manager.collect_core()
	assert_lte(game_manager.cores_collected, game_manager.MAX_CORES, "Tidak boleh > MAX_CORES")
	game_manager.new_game()


# -----------------------------------------------------------------------------
# TESTS: ABILITIES
# -----------------------------------------------------------------------------

func test_all_abilities_start_locked() -> void:
	print("\n[Test] All Abilities Start Locked")
	game_manager.new_game()
	assert_false(game_manager.can_dash, "Dash harus terkunci")
	assert_false(game_manager.can_double_jump, "Double jump harus terkunci")
	assert_false(game_manager.can_glide, "Glide harus terkunci")


func test_unlock_dash_enables_dash() -> void:
	print("\n[Test] Unlock Dash Enables Dash")
	game_manager.new_game()
	game_manager.unlock_dash()
	assert_true(game_manager.can_dash, "Dash harus aktif setelah unlock")
	game_manager.new_game()


func test_unlock_double_jump_enables_double_jump() -> void:
	print("\n[Test] Unlock Double Jump")
	game_manager.new_game()
	game_manager.unlock_double_jump()
	assert_true(game_manager.can_double_jump, "Double jump harus aktif")
	game_manager.new_game()


func test_unlock_glide_enables_glide() -> void:
	print("\n[Test] Unlock Glide")
	game_manager.new_game()
	game_manager.unlock_glide()
	assert_true(game_manager.can_glide, "Glide harus aktif")
	game_manager.new_game()


func test_is_ability_unlocked_helper() -> void:
	print("\n[Test] is_ability_unlocked Helper")
	game_manager.new_game()
	
	assert_false(game_manager.is_ability_unlocked("dash"), "Dash awal false")
	game_manager.unlock_dash()
	assert_true(game_manager.is_ability_unlocked("dash"), "Dash setelah unlock true")
	
	game_manager.new_game()


func test_unknown_ability_returns_false() -> void:
	print("\n[Test] Unknown Ability Returns False")
	assert_false(game_manager.is_ability_unlocked("unknown_ability"), "Unknown = false")
	assert_false(game_manager.is_ability_unlocked(""), "Empty string = false")


# -----------------------------------------------------------------------------
# TESTS: HEALTH
# -----------------------------------------------------------------------------

func test_health_starts_full() -> void:
	print("\n[Test] Health Starts Full")
	game_manager.new_game()
	assert_eq(game_manager.player_health, game_manager.player_max_health, "Health harus penuh")


func test_heal_caps_at_max() -> void:
	print("\n[Test] Heal Caps at Max")
	game_manager.new_game()
	game_manager.damage_player(50)
	game_manager.heal_player(9999)
	assert_eq(game_manager.player_health, game_manager.player_max_health, "Health tidak > max")
	game_manager.new_game()


func test_reset_health_restores_max() -> void:
	print("\n[Test] Reset Health Restores Max")
	game_manager.new_game()
	game_manager.damage_player(50)
	game_manager.reset_health()
	assert_eq(game_manager.player_health, game_manager.player_max_health, "Health full setelah reset")


# -----------------------------------------------------------------------------
# TESTS: GAME STATE
# -----------------------------------------------------------------------------

func test_new_game_resets_all_progress() -> void:
	print("\n[Test] New Game Resets All Progress")
	game_manager.collect_core()
	game_manager.collect_core()
	game_manager.unlock_dash()
	game_manager.unlock_double_jump()
	game_manager.damage_player(30)
	
	game_manager.new_game()
	
	assert_eq(game_manager.cores_collected, 0, "Cores reset ke 0")
	assert_false(game_manager.can_dash, "Dash terkunci")
	assert_false(game_manager.can_double_jump, "Double jump terkunci")
	assert_false(game_manager.can_glide, "Glide terkunci")
	assert_eq(game_manager.player_health, game_manager.player_max_health, "Health full")
	assert_false(game_manager.is_game_over, "is_game_over false")


func test_game_starts_unpaused() -> void:
	print("\n[Test] Game Starts Unpaused")
	game_manager.new_game()
	assert_false(game_manager.is_paused, "Game tidak pause saat mulai")


# -----------------------------------------------------------------------------
# TESTS: LEVEL MANAGEMENT
# -----------------------------------------------------------------------------

func test_level_order_has_five_levels() -> void:
	print("\n[Test] Level Order Has 5 Levels")
	assert_eq(game_manager.LEVEL_ORDER.size(), 5, "Harus ada 5 level")


func test_all_level_paths_valid() -> void:
	print("\n[Test] All Level Paths Valid")
	var all_valid := true
	for level_path in game_manager.LEVEL_ORDER:
		if not level_path.begins_with("res://scenes/levels/"):
			all_valid = false
		if not level_path.ends_with(".tscn"):
			all_valid = false
	assert_true(all_valid, "Semua path level valid")


# -----------------------------------------------------------------------------
# TESTS: GETTERS
# -----------------------------------------------------------------------------

func test_get_cores_count() -> void:
	print("\n[Test] get_cores_count()")
	game_manager.new_game()
	game_manager.collect_core()
	game_manager.collect_core()
	assert_eq(game_manager.get_cores_count(), 2, "get_cores_count = 2")
	game_manager.new_game()


func test_get_player_health() -> void:
	print("\n[Test] get_player_health()")
	game_manager.new_game()
	game_manager.damage_player(25)
	assert_eq(game_manager.get_player_health(), game_manager.player_max_health - 25, "get_player_health correct")
	game_manager.new_game()


# -----------------------------------------------------------------------------
# TESTS: EDGE CASES
# -----------------------------------------------------------------------------

func test_multiple_unlocks_dont_stack() -> void:
	print("\n[Test] Multiple Unlocks Don't Stack")
	game_manager.new_game()
	game_manager.unlock_dash()
	game_manager.unlock_dash()
	game_manager.unlock_dash()
	assert_true(game_manager.can_dash, "Still true after multiple unlocks")
	game_manager.new_game()


func test_zero_damage_no_change() -> void:
	print("\n[Test] Zero Damage No Change")
	game_manager.new_game()
	var initial: int = game_manager.player_health
	game_manager.damage_player(0)
	assert_eq(game_manager.player_health, initial, "Health unchanged with 0 damage")


func test_zero_heal_no_change() -> void:
	print("\n[Test] Zero Heal No Change")
	game_manager.new_game()
	game_manager.damage_player(30)
	var after_damage: int = game_manager.player_health
	game_manager.heal_player(0)
	assert_eq(game_manager.player_health, after_damage, "Health unchanged with 0 heal")
	game_manager.new_game()
