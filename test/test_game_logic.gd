# =============================================================================
# test_game_logic.gd - Unit Test untuk Game Logic
# =============================================================================
# Test suite untuk memverifikasi game systems:
# - Core collection
# - Ability unlock flow
# - Level progression
# - Save/Load system
# =============================================================================
# CARA MENJALANKAN:
# 1. Pastikan GUT addon sudah terinstall
# 2. Buka GUT Panel via menu atau F6
# 3. Klik "Run All"
# =============================================================================

extends GutTest

# Referensi ke autoloads untuk testing
var game_manager: Node = null
var save_manager: Node = null


# -----------------------------------------------------------------------------
# SETUP & TEARDOWN
# -----------------------------------------------------------------------------

## Setup sebelum setiap test
func before_each() -> void:
	# Dapatkan referensi ke autoloads
	game_manager = get_node_or_null("/root/GameManager")
	save_manager = get_node_or_null("/root/SaveManager")
	
	# Reset game state untuk test yang bersih
	if game_manager:
		game_manager.new_game()


## Cleanup setelah setiap test
func after_each() -> void:
	# Reset state
	if game_manager:
		game_manager.new_game()


# -----------------------------------------------------------------------------
# TEST: CORE COLLECTION SYSTEM
# -----------------------------------------------------------------------------

## Test: Core collection mulai dari 0
func test_cores_start_at_zero() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	assert_eq(game_manager.cores_collected, 0, "Cores harus mulai dari 0")


## Test: Mengumpulkan core menambah counter
func test_collecting_core_increments_counter() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	var initial: int = game_manager.cores_collected
	game_manager.collect_core()
	
	assert_eq(game_manager.cores_collected, initial + 1, "Core count harus bertambah 1")


## Test: Tidak bisa mengumpulkan lebih dari MAX_CORES
func test_cannot_exceed_max_cores() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	# Collect semua cores
	for i in range(10):  # Lebih dari MAX_CORES
		game_manager.collect_core()
	
	assert_lte(
		game_manager.cores_collected, 
		game_manager.MAX_CORES, 
		"Tidak boleh lebih dari MAX_CORES"
	)


## Test: Core collection emit signal
func test_core_collection_emits_signal() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	# Gunakan watch_signals dari GUT
	watch_signals(game_manager)
	
	game_manager.collect_core()
	
	assert_signal_emitted(game_manager, "core_collected", "Signal core_collected harus di-emit")


# -----------------------------------------------------------------------------
# TEST: ABILITY UNLOCK SYSTEM
# -----------------------------------------------------------------------------

## Test: Semua ability terkunci di awal
func test_all_abilities_start_locked() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	assert_false(game_manager.can_dash, "Dash harus terkunci")
	assert_false(game_manager.can_double_jump, "Double jump harus terkunci")
	assert_false(game_manager.can_glide, "Glide harus terkunci")


## Test: unlock_dash() mengaktifkan dash
func test_unlock_dash_enables_dash() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	game_manager.unlock_dash()
	
	assert_true(game_manager.can_dash, "Dash harus aktif setelah unlock")


## Test: unlock_double_jump() mengaktifkan double jump
func test_unlock_double_jump_enables_double_jump() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	game_manager.unlock_double_jump()
	
	assert_true(game_manager.can_double_jump, "Double jump harus aktif setelah unlock")


## Test: unlock_glide() mengaktifkan glide
func test_unlock_glide_enables_glide() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	game_manager.unlock_glide()
	
	assert_true(game_manager.can_glide, "Glide harus aktif setelah unlock")


## Test: Ability unlock emit signal
func test_ability_unlock_emits_signal() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	watch_signals(game_manager)
	
	game_manager.unlock_dash()
	
	assert_signal_emitted(game_manager, "ability_unlocked", "Signal ability_unlocked harus di-emit")


## Test: is_ability_unlocked() helper bekerja
func test_is_ability_unlocked_helper() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	# Awal semua false
	assert_false(game_manager.is_ability_unlocked("dash"))
	assert_false(game_manager.is_ability_unlocked("double_jump"))
	assert_false(game_manager.is_ability_unlocked("glide"))
	
	# Unlock satu-satu dan cek
	game_manager.unlock_dash()
	assert_true(game_manager.is_ability_unlocked("dash"))
	
	game_manager.unlock_double_jump()
	assert_true(game_manager.is_ability_unlocked("double_jump"))
	
	game_manager.unlock_glide()
	assert_true(game_manager.is_ability_unlocked("glide"))


## Test: Unknown ability returns false
func test_unknown_ability_returns_false() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	assert_false(game_manager.is_ability_unlocked("unknown_ability"))
	assert_false(game_manager.is_ability_unlocked(""))


# -----------------------------------------------------------------------------
# TEST: HEALTH SYSTEM
# -----------------------------------------------------------------------------

## Test: Health dimulai penuh
func test_health_starts_full() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	assert_eq(
		game_manager.player_health, 
		game_manager.player_max_health, 
		"Health harus penuh di awal"
	)


## Test: Heal tidak melebihi max health
func test_heal_caps_at_max() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	# Damage dulu
	game_manager.damage_player(50)
	
	# Heal berlebihan
	game_manager.heal_player(9999)
	
	assert_eq(
		game_manager.player_health, 
		game_manager.player_max_health, 
		"Health tidak boleh melebihi max"
	)


## Test: reset_health() mengembalikan ke max
func test_reset_health_restores_max() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	game_manager.damage_player(50)
	game_manager.reset_health()
	
	assert_eq(game_manager.player_health, game_manager.player_max_health)


# -----------------------------------------------------------------------------
# TEST: NEW GAME / RESET
# -----------------------------------------------------------------------------

## Test: new_game() mereset semua progress
func test_new_game_resets_all_progress() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	# Set berbagai state
	game_manager.collect_core()
	game_manager.collect_core()
	game_manager.unlock_dash()
	game_manager.unlock_double_jump()
	game_manager.damage_player(30)
	
	# Reset
	game_manager.new_game()
	
	# Verifikasi reset
	assert_eq(game_manager.cores_collected, 0, "Cores harus reset ke 0")
	assert_false(game_manager.can_dash, "Dash harus terkunci kembali")
	assert_false(game_manager.can_double_jump, "Double jump harus terkunci kembali")
	assert_false(game_manager.can_glide, "Glide harus terkunci kembali")
	assert_eq(game_manager.player_health, game_manager.player_max_health, "Health harus full")
	assert_false(game_manager.is_game_over, "is_game_over harus false")


# -----------------------------------------------------------------------------
# TEST: PAUSE SYSTEM
# -----------------------------------------------------------------------------

## Test: Game dimulai tidak dalam pause
func test_game_starts_unpaused() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	assert_false(game_manager.is_paused, "Game tidak boleh pause saat mulai")


## Test: toggle_pause() mengubah state
func test_toggle_pause_changes_state() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	var initial_state: bool = game_manager.is_paused
	
	game_manager.toggle_pause()
	assert_ne(game_manager.is_paused, initial_state, "Pause state harus berubah")
	
	game_manager.toggle_pause()
	assert_eq(game_manager.is_paused, initial_state, "Pause state harus kembali")


## Test: Pause emit signal
func test_pause_emits_signal() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	watch_signals(game_manager)
	
	game_manager.toggle_pause()
	
	assert_signal_emitted(game_manager, "game_paused", "Signal game_paused harus di-emit")
	
	# Unpause untuk cleanup
	game_manager.toggle_pause()


# -----------------------------------------------------------------------------
# TEST: LEVEL MANAGEMENT
# -----------------------------------------------------------------------------

## Test: LEVEL_ORDER berisi 5 level
func test_level_order_has_five_levels() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	assert_eq(game_manager.LEVEL_ORDER.size(), 5, "Harus ada 5 level dalam urutan")


## Test: Semua path level valid
func test_all_level_paths_valid() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	for level_path in game_manager.LEVEL_ORDER:
		assert_true(
			level_path.begins_with("res://scenes/levels/"),
			"Level path harus di folder scenes/levels"
		)
		assert_true(
			level_path.ends_with(".tscn"),
			"Level harus file .tscn"
		)


# -----------------------------------------------------------------------------
# TEST: GETTER FUNCTIONS (untuk testing)
# -----------------------------------------------------------------------------

## Test: get_cores_count() returns correct value
func test_get_cores_count() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	game_manager.collect_core()
	game_manager.collect_core()
	
	assert_eq(game_manager.get_cores_count(), 2)


## Test: get_player_health() returns correct value
func test_get_player_health() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	game_manager.damage_player(25)
	
	assert_eq(game_manager.get_player_health(), game_manager.player_max_health - 25)


# -----------------------------------------------------------------------------
# TEST: EDGE CASES
# -----------------------------------------------------------------------------

## Test: Multiple unlocks tidak stack
func test_multiple_unlocks_dont_stack() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	game_manager.unlock_dash()
	game_manager.unlock_dash()
	game_manager.unlock_dash()
	
	# Harus tetap true, tidak ada side effect
	assert_true(game_manager.can_dash)


## Test: Damage 0 tidak mengubah health
func test_zero_damage_no_change() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	var initial: int = game_manager.player_health
	game_manager.damage_player(0)
	
	assert_eq(game_manager.player_health, initial)


## Test: Heal 0 tidak mengubah health
func test_zero_heal_no_change() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	game_manager.damage_player(30)
	var after_damage: int = game_manager.player_health
	
	game_manager.heal_player(0)
	
	assert_eq(game_manager.player_health, after_damage)
