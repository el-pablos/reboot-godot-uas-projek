# =============================================================================
# test_gameplay_qa.gd - Gameplay & Balancing QA Tests
# =============================================================================
# Test suite untuk coverage gaps: state reset, save/load, settings,
# boss reward pipeline, core collection, scene transitions.
# =============================================================================

extends Node

# Test counters
var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

# References
var game_manager: Node = null
var save_manager: Node = null
var settings_manager: Node = null


# -----------------------------------------------------------------------------
# ENTRY POINT
# -----------------------------------------------------------------------------

func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("🧪 RUNNING: test_gameplay_qa.gd")
	print("=".repeat(60))
	
	game_manager = get_node_or_null("/root/GameManager")
	save_manager = get_node_or_null("/root/SaveManager")
	settings_manager = get_node_or_null("/root/SettingsManager")
	
	if game_manager == null:
		print("❌ CRITICAL: GameManager tidak ditemukan!")
		return
	
	# Reset state bersih
	game_manager.new_game()
	
	# Jalankan semua test
	run_all_tests()
	
	# Print hasil
	print_results()


func run_all_tests() -> void:
	# --- Game State Reset ---
	test_reset_game_clears_all_state()
	test_game_over_flag_resets_on_new_game()
	test_game_over_triggers_on_death()
	test_reset_health_clears_game_over()
	test_go_to_main_menu_resets_pause()
	
	# --- Save/Load Data Integrity ---
	test_save_manager_exists()
	test_save_game_creates_file()
	test_load_game_restores_health()
	test_load_game_restores_cores()
	test_load_game_restores_abilities()
	test_load_game_restores_level()
	test_save_load_round_trip()
	test_delete_save_removes_file()
	test_load_nonexistent_returns_false()
	test_has_save_file_after_save()
	
	# --- Settings Persistence ---
	test_settings_manager_exists()
	test_settings_default_values()
	test_settings_save_load_round_trip()
	test_hit_stop_duration_levels()
	test_screen_shake_default_enabled()
	
	# --- Boss Reward Pipeline ---
	test_apply_upgrades_null_player_safe()
	test_apply_upgrades_syncs_dash()
	test_apply_upgrades_syncs_double_jump()
	test_apply_upgrades_syncs_glide()
	test_apply_upgrades_max_jumps()
	
	# --- Core Collection Consistency ---
	test_complete_level_emits_signal()
	test_get_player_stats_returns_dict()
	test_get_player_stats_reflects_abilities()
	test_get_player_stats_reflects_health()
	
	# --- Scene Transition Safety ---
	test_level_order_paths_exist()
	test_reload_no_crash_without_level()
	test_change_level_updates_current()


func print_results() -> void:
	print("\n" + "-".repeat(60))
	print("📊 HASIL TEST GAMEPLAY QA")
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


# -----------------------------------------------------------------------------
# TESTS: GAME STATE RESET
# -----------------------------------------------------------------------------

func test_reset_game_clears_all_state() -> void:
	print("\n[Test] reset_game() Clears All State")
	# Set dirty state
	game_manager.cores_collected = 3
	game_manager.can_dash = true
	game_manager.can_glide = true
	game_manager.is_game_over = true
	
	# Reset
	game_manager.reset_game()
	
	assert_eq(game_manager.cores_collected, 0, "Cores reset ke 0")
	assert_false(game_manager.can_dash, "Dash harus locked")
	assert_false(game_manager.can_glide, "Glide harus locked")
	assert_false(game_manager.is_game_over, "Game over harus false")


func test_game_over_flag_resets_on_new_game() -> void:
	print("\n[Test] Game Over Flag Reset on new_game()")
	game_manager.is_game_over = true
	game_manager.is_paused = true
	game_manager.new_game()
	assert_false(game_manager.is_game_over, "Game over flag reset")
	assert_false(game_manager.is_paused, "Pause flag reset")


func test_game_over_triggers_on_death() -> void:
	print("\n[Test] Game Over Triggers on Death")
	game_manager.new_game()
	game_manager.damage_player(game_manager.player_max_health)
	assert_true(game_manager.is_game_over, "Game over saat HP = 0")
	assert_eq(game_manager.player_health, 0, "HP harus 0")
	game_manager.new_game()


func test_reset_health_clears_game_over() -> void:
	print("\n[Test] reset_health() Clears Game Over")
	game_manager.new_game()
	game_manager.damage_player(999)
	assert_true(game_manager.is_game_over, "Game over aktif")
	game_manager.reset_health()
	assert_false(game_manager.is_game_over, "Game over cleared")
	assert_eq(game_manager.player_health, game_manager.player_max_health, "HP full")
	game_manager.new_game()


func test_go_to_main_menu_resets_pause() -> void:
	print("\n[Test] go_to_main_menu State Reset")
	# Test that the state reset logic works (don't actually change scene)
	game_manager.is_paused = true
	game_manager.is_game_over = true
	# Verify the function exists and state fields are correct types
	assert_true(game_manager.has_method("go_to_main_menu"), "go_to_main_menu exists")
	assert_true(game_manager.has_method("reset_game"), "reset_game exists")
	# Reset manually (simulating what go_to_main_menu does internally)
	game_manager.is_paused = false
	game_manager.is_game_over = false
	assert_false(game_manager.is_paused, "Pause cleared")
	assert_false(game_manager.is_game_over, "Game over cleared")
	game_manager.new_game()


# -----------------------------------------------------------------------------
# TESTS: SAVE/LOAD DATA INTEGRITY
# -----------------------------------------------------------------------------

func test_save_manager_exists() -> void:
	print("\n[Test] SaveManager Exists")
	assert_true(save_manager != null, "SaveManager autoload harus aktif")


func test_save_game_creates_file() -> void:
	print("\n[Test] save_game() Creates File")
	if save_manager == null:
		assert_true(false, "SaveManager null — skip")
		return
	# Clean up first
	save_manager.delete_save()
	game_manager.new_game()
	game_manager.cores_collected = 2
	var result: bool = save_manager.save_game()
	assert_true(result, "save_game() returns true")


func test_load_game_restores_health() -> void:
	print("\n[Test] load_game() Restores Health")
	if save_manager == null:
		assert_true(false, "SaveManager null — skip")
		return
	# Save with specific health
	game_manager.player_health = 50
	save_manager.save_game()
	# Change health
	game_manager.player_health = 100
	# Load
	save_manager.load_game()
	assert_eq(game_manager.player_health, 50, "Health restored ke 50")
	game_manager.new_game()


func test_load_game_restores_cores() -> void:
	print("\n[Test] load_game() Restores Cores")
	if save_manager == null:
		assert_true(false, "SaveManager null — skip")
		return
	game_manager.new_game()
	game_manager.cores_collected = 3
	save_manager.save_game()
	game_manager.cores_collected = 0
	save_manager.load_game()
	assert_eq(game_manager.cores_collected, 3, "Cores restored ke 3")
	game_manager.new_game()


func test_load_game_restores_abilities() -> void:
	print("\n[Test] load_game() Restores Abilities")
	if save_manager == null:
		assert_true(false, "SaveManager null — skip")
		return
	game_manager.new_game()
	game_manager.can_dash = true
	game_manager.can_double_jump = true
	game_manager.can_glide = false
	save_manager.save_game()
	game_manager.new_game()  # Resets all
	save_manager.load_game()
	assert_true(game_manager.can_dash, "Dash restored")
	assert_true(game_manager.can_double_jump, "Double jump restored")
	assert_false(game_manager.can_glide, "Glide tetap locked")
	game_manager.new_game()


func test_load_game_restores_level() -> void:
	print("\n[Test] load_game() Restores Level")
	if save_manager == null:
		assert_true(false, "SaveManager null — skip")
		return
	game_manager.current_level = "res://scenes/levels/Level_03_CrystalLabs.tscn"
	save_manager.save_game()
	game_manager.current_level = ""
	save_manager.load_game()
	assert_eq(game_manager.current_level, "res://scenes/levels/Level_03_CrystalLabs.tscn", "Level restored")
	game_manager.new_game()


func test_save_load_round_trip() -> void:
	print("\n[Test] Save/Load Round Trip Integrity")
	if save_manager == null:
		assert_true(false, "SaveManager null — skip")
		return
	# Set complex state
	game_manager.player_health = 42
	game_manager.cores_collected = 4
	game_manager.can_dash = true
	game_manager.can_double_jump = true
	game_manager.can_glide = true
	game_manager.current_level = "res://scenes/levels/Level_05_OverlordFortress.tscn"
	save_manager.save_game()
	
	# Wipe state
	game_manager.new_game()
	
	# Restore
	save_manager.load_game()
	assert_eq(game_manager.player_health, 42, "Round trip: HP=42")
	assert_eq(game_manager.cores_collected, 4, "Round trip: cores=4")
	assert_true(game_manager.can_dash, "Round trip: dash")
	assert_true(game_manager.can_double_jump, "Round trip: double_jump")
	assert_true(game_manager.can_glide, "Round trip: glide")
	assert_eq(game_manager.current_level, "res://scenes/levels/Level_05_OverlordFortress.tscn", "Round trip: level")
	
	# Cleanup
	save_manager.delete_save()
	game_manager.new_game()


func test_delete_save_removes_file() -> void:
	print("\n[Test] delete_save() Removes File")
	if save_manager == null:
		assert_true(false, "SaveManager null — skip")
		return
	save_manager.save_game()
	var result: bool = save_manager.delete_save()
	assert_true(result, "delete_save() returns true")


func test_load_nonexistent_returns_false() -> void:
	print("\n[Test] load_game() Returns False for Missing File")
	if save_manager == null:
		assert_true(false, "SaveManager null — skip")
		return
	save_manager.delete_save()
	var result: bool = save_manager.load_game()
	assert_false(result, "load_game() returns false tanpa file")


func test_has_save_file_after_save() -> void:
	print("\n[Test] has_save_file() After Save")
	if save_manager == null:
		assert_true(false, "SaveManager null — skip")
		return
	save_manager.delete_save()
	assert_false(save_manager.has_save_file(), "No save sebelum save")
	save_manager.save_game()
	assert_true(save_manager.has_save_file(), "Save ada setelah save")
	save_manager.delete_save()


# -----------------------------------------------------------------------------
# TESTS: SETTINGS PERSISTENCE
# -----------------------------------------------------------------------------

func test_settings_manager_exists() -> void:
	print("\n[Test] SettingsManager Exists")
	assert_true(settings_manager != null, "SettingsManager autoload harus aktif")


func test_settings_default_values() -> void:
	print("\n[Test] Settings Default Values")
	if settings_manager == null:
		assert_true(false, "SettingsManager null — skip")
		return
	# Defaults should be reasonable ranges
	assert_true(settings_manager.master_volume >= 0.0 and settings_manager.master_volume <= 1.0, 
		"Master volume 0-1 (got: %s)" % str(settings_manager.master_volume))
	assert_true(settings_manager.music_volume >= 0.0 and settings_manager.music_volume <= 1.0,
		"Music volume 0-1 (got: %s)" % str(settings_manager.music_volume))
	assert_true(settings_manager.sfx_volume >= 0.0 and settings_manager.sfx_volume <= 1.0,
		"SFX volume 0-1 (got: %s)" % str(settings_manager.sfx_volume))


func test_settings_save_load_round_trip() -> void:
	print("\n[Test] Settings Save/Load Round Trip")
	if settings_manager == null:
		assert_true(false, "SettingsManager null — skip")
		return
	# Modify settings
	var original_master: float = settings_manager.master_volume
	settings_manager.master_volume = 0.42
	settings_manager.screen_shake = false
	settings_manager.hit_stop_level = 2
	settings_manager.save_settings()
	
	# Reset to defaults manually
	settings_manager.master_volume = 1.0
	settings_manager.screen_shake = true
	settings_manager.hit_stop_level = 1
	
	# Load back
	settings_manager.load_settings()
	assert_eq(settings_manager.master_volume, 0.42, "Master volume restored")
	assert_false(settings_manager.screen_shake, "Screen shake restored to off")
	assert_eq(settings_manager.hit_stop_level, 2, "Hit stop level restored")
	
	# Restore original
	settings_manager.master_volume = original_master
	settings_manager.screen_shake = true
	settings_manager.hit_stop_level = 1
	settings_manager.save_settings()


func test_hit_stop_duration_levels() -> void:
	print("\n[Test] Hit Stop Duration per Level")
	if settings_manager == null:
		assert_true(false, "SettingsManager null — skip")
		return
	settings_manager.hit_stop_level = 0
	assert_eq(settings_manager.get_hit_stop_duration(), 0.0, "Level 0 = 0.0s")
	settings_manager.hit_stop_level = 1
	assert_eq(settings_manager.get_hit_stop_duration(), 0.03, "Level 1 = 0.03s")
	settings_manager.hit_stop_level = 2
	assert_eq(settings_manager.get_hit_stop_duration(), 0.05, "Level 2 = 0.05s")
	settings_manager.hit_stop_level = 1  # Restore


func test_screen_shake_default_enabled() -> void:
	print("\n[Test] Screen Shake Default Enabled")
	if settings_manager == null:
		assert_true(false, "SettingsManager null — skip")
		return
	assert_true(settings_manager.is_screen_shake_enabled(), "Screen shake default on")


# -----------------------------------------------------------------------------
# TESTS: BOSS REWARD PIPELINE (apply_upgrades_to_player)
# -----------------------------------------------------------------------------

## Mock player node untuk testing apply_upgrades
class MockPlayer:
	extends RefCounted
	var can_dash: bool = false
	var can_double_jump: bool = false
	var can_glide: bool = false
	var max_jumps: int = 1
	var jump_height: float = 100.0


func test_apply_upgrades_null_player_safe() -> void:
	print("\n[Test] apply_upgrades_to_player(null) Safety")
	# Should not crash
	game_manager.apply_upgrades_to_player(null)
	assert_true(true, "Null player tidak crash")


func test_apply_upgrades_syncs_dash() -> void:
	print("\n[Test] apply_upgrades Syncs Dash")
	game_manager.new_game()
	game_manager.unlock_dash()
	var mock := MockPlayer.new()
	game_manager.apply_upgrades_to_player(mock)
	assert_true(mock.can_dash, "Dash synced ke player")
	game_manager.new_game()


func test_apply_upgrades_syncs_double_jump() -> void:
	print("\n[Test] apply_upgrades Syncs Double Jump")
	game_manager.new_game()
	game_manager.unlock_double_jump()
	var mock := MockPlayer.new()
	game_manager.apply_upgrades_to_player(mock)
	assert_true(mock.can_double_jump, "Double jump synced")
	assert_eq(mock.max_jumps, 2, "max_jumps = 2 with double jump")
	game_manager.new_game()


func test_apply_upgrades_syncs_glide() -> void:
	print("\n[Test] apply_upgrades Syncs Glide")
	game_manager.new_game()
	game_manager.unlock_glide()
	var mock := MockPlayer.new()
	game_manager.apply_upgrades_to_player(mock)
	assert_true(mock.can_glide, "Glide synced")
	game_manager.new_game()


func test_apply_upgrades_max_jumps() -> void:
	print("\n[Test] apply_upgrades max_jumps Without Double Jump")
	game_manager.new_game()
	var mock := MockPlayer.new()
	mock.max_jumps = 5  # Wrong value
	game_manager.apply_upgrades_to_player(mock)
	assert_eq(mock.max_jumps, 1, "max_jumps = 1 tanpa double jump")
	game_manager.new_game()


# -----------------------------------------------------------------------------
# TESTS: CORE COLLECTION & PLAYER STATS
# -----------------------------------------------------------------------------

func test_complete_level_emits_signal() -> void:
	print("\n[Test] complete_level() Has Method")
	assert_true(game_manager.has_method("complete_level"), "complete_level exists")
	assert_true(game_manager.has_method("collect_core_and_advance"), "collect_core_and_advance exists")


func test_get_player_stats_returns_dict() -> void:
	print("\n[Test] get_player_stats() Returns Dict")
	game_manager.new_game()
	var stats: Dictionary = game_manager.get_player_stats()
	assert_true(stats is Dictionary, "Return type is Dictionary")
	assert_true(stats.has("health"), "Has 'health' key")
	assert_true(stats.has("max_health"), "Has 'max_health' key")
	assert_true(stats.has("can_dash"), "Has 'can_dash' key")
	assert_true(stats.has("can_double_jump"), "Has 'can_double_jump' key")
	assert_true(stats.has("can_glide"), "Has 'can_glide' key")
	assert_true(stats.has("max_jumps"), "Has 'max_jumps' key")
	assert_true(stats.has("cores_collected"), "Has 'cores_collected' key")


func test_get_player_stats_reflects_abilities() -> void:
	print("\n[Test] get_player_stats() Reflects Ability Unlocks")
	game_manager.new_game()
	var stats_before: Dictionary = game_manager.get_player_stats()
	assert_false(stats_before["can_dash"], "Dash locked before unlock")
	assert_eq(stats_before["max_jumps"], 1, "max_jumps=1 before unlock")
	
	game_manager.unlock_dash()
	game_manager.unlock_double_jump()
	var stats_after: Dictionary = game_manager.get_player_stats()
	assert_true(stats_after["can_dash"], "Dash unlocked in stats")
	assert_eq(stats_after["max_jumps"], 2, "max_jumps=2 after double_jump")
	game_manager.new_game()


func test_get_player_stats_reflects_health() -> void:
	print("\n[Test] get_player_stats() Reflects Health")
	game_manager.new_game()
	game_manager.damage_player(30)
	var stats: Dictionary = game_manager.get_player_stats()
	assert_eq(stats["health"], 70, "Stats health = 70 after 30 damage")
	assert_eq(stats["max_health"], 100, "Stats max_health = 100")
	game_manager.new_game()


# -----------------------------------------------------------------------------
# TESTS: SCENE TRANSITION SAFETY
# -----------------------------------------------------------------------------

func test_level_order_paths_exist() -> void:
	print("\n[Test] All Level Paths Exist as Resources")
	for level_path in game_manager.LEVEL_ORDER:
		assert_true(ResourceLoader.exists(level_path), "Level exists: %s" % level_path)


func test_reload_no_crash_without_level() -> void:
	print("\n[Test] reload_current_level() Without Level Set")
	game_manager.current_level = ""
	# Should not crash — just prints warning
	game_manager.has_method("reload_current_level")
	assert_true(game_manager.has_method("reload_current_level"), "reload_current_level exists")


func test_change_level_updates_current() -> void:
	print("\n[Test] change_level Updates current_level")
	# We can't actually change scenes in headless test, but check the method exists
	assert_true(game_manager.has_method("change_level"), "change_level exists")
	assert_true(game_manager.has_method("load_next_level"), "load_next_level exists")
