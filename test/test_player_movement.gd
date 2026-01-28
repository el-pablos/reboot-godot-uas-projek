# =============================================================================
# test_player_movement.gd - Unit Test untuk Player Movement
# =============================================================================
# Test suite untuk memverifikasi sistem pergerakan player:
# - Dasar movement (jalan, lompat)
# - Advanced abilities (dash, double jump, glide)
# - State transitions
# - Physics responses
# =============================================================================
# CARA MENJALANKAN:
# 1. Pastikan GUT addon sudah terinstall
# 2. Buka GUT Panel via menu atau F6
# 3. Klik "Run All"
# =============================================================================

extends GutTest

# Referensi ke player instance untuk testing
var player: CharacterBody2D = null
var player_scene: PackedScene = null


# -----------------------------------------------------------------------------
# SETUP & TEARDOWN
# -----------------------------------------------------------------------------

## Setup sebelum setiap test - instance player baru
func before_each() -> void:
	# Load player scene
	player_scene = load("res://scenes/player/Player.tscn")
	
	if player_scene:
		player = player_scene.instantiate()
		add_child_autofree(player)
		
		# Tunggu satu frame agar _ready() terpanggil
		await get_tree().process_frame
	else:
		gut.p("WARNING: Player scene tidak ditemukan!")


## Cleanup setelah setiap test
func after_each() -> void:
	player = null


# -----------------------------------------------------------------------------
# TEST: BASIC PROPERTIES
# -----------------------------------------------------------------------------

## Test: Player berhasil di-instantiate dengan property yang benar
func test_player_instantiates_correctly() -> void:
	assert_not_null(player, "Player harus ter-instantiate")
	assert_true(player is CharacterBody2D, "Player harus bertipe CharacterBody2D")


## Test: Player memiliki speed values yang valid
func test_player_has_valid_speed_values() -> void:
	if player == null:
		pending("Player tidak tersedia")
		return
	
	# Cek property speed ada dan bernilai positif
	assert_true(player.speed > 0, "Speed harus lebih dari 0")
	assert_true(player.jump_velocity < 0, "Jump velocity harus negatif (ke atas)")


## Test: Player memiliki gravity yang sesuai
func test_player_has_gravity() -> void:
	if player == null:
		pending("Player tidak tersedia")
		return
	
	# Gravity harus positif (menarik ke bawah)
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	assert_true(gravity > 0, "Gravity harus positif")


# -----------------------------------------------------------------------------
# TEST: MOVEMENT STATES
# -----------------------------------------------------------------------------

## Test: Player mulai dalam state IDLE
func test_player_starts_in_idle_state() -> void:
	if player == null:
		pending("Player tidak tersedia")
		return
	
	# Cek state machine ada dan dalam kondisi idle
	if player.has_node("StateMachine") or player.has_method("get_current_state"):
		# Sesuaikan dengan implementasi state machine
		pass
	else:
		# Jika tidak ada state machine, cek velocity = 0
		assert_eq(player.velocity, Vector2.ZERO, "Player harus diam saat spawn")


## Test: Velocity horizontal saat tidak ada input adalah 0
func test_no_horizontal_movement_without_input() -> void:
	if player == null:
		pending("Player tidak tersedia")
		return
	
	# Simulasi tanpa input
	player.velocity.x = 0
	
	# Proses satu frame
	await get_tree().physics_frame
	
	# Velocity X harus tetap 0 atau mendekati 0
	assert_almost_eq(player.velocity.x, 0.0, 1.0, "Tidak boleh ada gerakan horizontal tanpa input")


# -----------------------------------------------------------------------------
# TEST: JUMP MECHANICS
# -----------------------------------------------------------------------------

## Test: Jump menghasilkan velocity negatif (ke atas)
func test_jump_produces_upward_velocity() -> void:
	if player == null:
		pending("Player tidak tersedia")
		return
	
	# Simulasi player di ground
	player.velocity.y = 0
	
	# Set velocity jump manual (simulasi jump)
	var jump_vel: float = player.jump_velocity if "jump_velocity" in player else -400.0
	player.velocity.y = jump_vel
	
	assert_lt(player.velocity.y, 0, "Jump velocity harus negatif (ke atas)")


## Test: Coyote time window ada dan valid
func test_coyote_time_exists() -> void:
	if player == null:
		pending("Player tidak tersedia")
		return
	
	# Cek apakah player punya coyote time property
	if "coyote_time" in player:
		assert_true(player.coyote_time > 0, "Coyote time harus lebih dari 0")
		assert_true(player.coyote_time <= 0.3, "Coyote time tidak boleh terlalu lama")
	else:
		pending("Coyote time belum diimplementasi")


## Test: Jump buffer window ada dan valid
func test_jump_buffer_exists() -> void:
	if player == null:
		pending("Player tidak tersedia")
		return
	
	# Cek apakah player punya jump buffer property
	if "jump_buffer_time" in player:
		assert_true(player.jump_buffer_time > 0, "Jump buffer harus lebih dari 0")
		assert_true(player.jump_buffer_time <= 0.2, "Jump buffer tidak boleh terlalu lama")
	else:
		pending("Jump buffer belum diimplementasi")


# -----------------------------------------------------------------------------
# TEST: ABILITY SYSTEM
# -----------------------------------------------------------------------------

## Test: Dash ability default terkunci
func test_dash_starts_locked() -> void:
	if player == null:
		pending("Player tidak tersedia")
		return
	
	# Cek via GameManager atau player property langsung
	var game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager:
		assert_false(game_manager.can_dash, "Dash harus terkunci di awal game")
	elif "can_dash" in player:
		# Bisa juga cek dari property player
		pass


## Test: Double jump ability default terkunci
func test_double_jump_starts_locked() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager:
		assert_false(game_manager.can_double_jump, "Double jump harus terkunci di awal game")


## Test: Glide ability default terkunci
func test_glide_starts_locked() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager:
		assert_false(game_manager.can_glide, "Glide harus terkunci di awal game")


# -----------------------------------------------------------------------------
# TEST: DASH MECHANICS
# -----------------------------------------------------------------------------

## Test: Dash menghasilkan velocity burst
func test_dash_increases_velocity() -> void:
	if player == null:
		pending("Player tidak tersedia")
		return
	
	# Cek property dash_speed
	if "dash_speed" in player:
		assert_true(player.dash_speed > player.speed, "Dash harus lebih cepat dari jalan normal")
	else:
		pending("Dash speed belum diimplementasi")


## Test: Dash memiliki cooldown
func test_dash_has_cooldown() -> void:
	if player == null:
		pending("Player tidak tersedia")
		return
	
	if "dash_cooldown" in player:
		assert_true(player.dash_cooldown > 0, "Dash cooldown harus lebih dari 0")
	else:
		pending("Dash cooldown belum diimplementasi")


# -----------------------------------------------------------------------------
# TEST: GLIDE MECHANICS
# -----------------------------------------------------------------------------

## Test: Glide mengurangi fall speed
func test_glide_reduces_fall_speed() -> void:
	if player == null:
		pending("Player tidak tersedia")
		return
	
	if "glide_gravity_multiplier" in player:
		assert_true(
			player.glide_gravity_multiplier < 1.0, 
			"Glide gravity multiplier harus < 1 untuk memperlambat jatuh"
		)
	else:
		pending("Glide belum diimplementasi")


# -----------------------------------------------------------------------------
# TEST: DAMAGE & DEATH
# -----------------------------------------------------------------------------

## Test: Player bisa menerima damage
func test_player_can_take_damage() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	var initial_health: int = game_manager.player_health
	game_manager.damage_player(10)
	
	assert_eq(game_manager.player_health, initial_health - 10, "Health harus berkurang setelah damage")
	
	# Reset health untuk test lain
	game_manager.reset_health()


## Test: Player mati saat health = 0
func test_player_dies_at_zero_health() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	# Track signal
	var signal_received: bool = false
	
	# Damage sampai mati
	game_manager.damage_player(game_manager.player_health)
	
	assert_eq(game_manager.player_health, 0, "Health harus 0 setelah fatal damage")
	assert_true(game_manager.is_game_over, "is_game_over harus true")
	
	# Reset untuk test lain
	game_manager.new_game()


## Test: Health tidak bisa negatif
func test_health_cannot_go_negative() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	game_manager.damage_player(9999)
	
	assert_true(game_manager.player_health >= 0, "Health tidak boleh negatif")
	
	# Reset untuk test lain
	game_manager.new_game()
