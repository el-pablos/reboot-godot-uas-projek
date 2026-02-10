# =============================================================================
# test_player_movement.gd - Unit Test untuk Player Movement (Standalone)
# =============================================================================
# Test suite untuk memverifikasi sistem pergerakan player.
# Bisa dijalankan tanpa GUT - extend Node dan run langsung.
# =============================================================================

extends Node

# Referensi ke player instance untuk testing
var player: CharacterBody2D = null
var player_scene: PackedScene = null

# Test counters
var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0


# -----------------------------------------------------------------------------
# ENTRY POINT
# -----------------------------------------------------------------------------

func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("🧪 RUNNING: test_player_movement.gd")
	print("=".repeat(60))
	
	# Jalankan semua test
	await run_all_tests()
	
	# Print hasil
	print_results()


func run_all_tests() -> void:
	test_player_scene_exists()
	await test_player_instantiates_correctly()
	await test_player_has_valid_speed_values()
	await test_player_has_jump_velocity()
	await test_coyote_time_exists()
	await test_jump_buffer_exists()
	await test_dash_speed_exists()
	await test_glide_multiplier_exists()
	test_dash_starts_locked()
	test_double_jump_starts_locked()
	test_glide_starts_locked()
	test_player_can_take_damage()
	test_player_dies_at_zero_health()
	test_health_cannot_go_negative()
	await test_reset_player_function_exists()
	await test_reset_player_resets_velocity()
	await test_reset_player_resets_health()


func print_results() -> void:
	print("\n" + "-".repeat(60))
	print("📊 HASIL TEST PLAYER MOVEMENT")
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


func assert_not_null(obj: Variant, message: String) -> void:
	assert_true(obj != null, message)


func assert_eq(a: Variant, b: Variant, message: String) -> void:
	assert_true(a == b, message + " (got: %s, expected: %s)" % [str(a), str(b)])


func assert_lt(a: float, b: float, message: String) -> void:
	assert_true(a < b, message)


func setup_player() -> void:
	if player != null:
		player.queue_free()
		player = null
	
	player_scene = load("res://scenes/player/Player.tscn")
	if player_scene:
		player = player_scene.instantiate()
		add_child(player)


func cleanup_player() -> void:
	if player != null:
		player.queue_free()
		player = null


# -----------------------------------------------------------------------------
# TESTS
# -----------------------------------------------------------------------------

func test_player_scene_exists() -> void:
	print("\n[Test] Player Scene Exists")
	var scene = load("res://scenes/player/Player.tscn")
	assert_not_null(scene, "Player.tscn harus ada")


func test_player_instantiates_correctly() -> void:
	print("\n[Test] Player Instantiates Correctly")
	setup_player()
	await get_tree().process_frame
	
	assert_not_null(player, "Player harus ter-instantiate")
	assert_true(player is CharacterBody2D, "Player harus bertipe CharacterBody2D")
	
	cleanup_player()


func test_player_has_valid_speed_values() -> void:
	print("\n[Test] Player Has Valid Speed")
	setup_player()
	await get_tree().process_frame
	
	if player and "speed" in player:
		assert_true(player.speed > 0, "Speed harus > 0 (got: %d)" % player.speed)
	else:
		assert_true(false, "Property 'speed' tidak ditemukan")
	
	cleanup_player()


func test_player_has_jump_velocity() -> void:
	print("\n[Test] Player Has Jump Velocity")
	setup_player()
	await get_tree().process_frame
	
	if player and "jump_velocity" in player:
		assert_lt(player.jump_velocity, 0, "Jump velocity harus negatif (ke atas)")
	else:
		assert_true(false, "Property 'jump_velocity' tidak ditemukan")
	
	cleanup_player()


func test_coyote_time_exists() -> void:
	print("\n[Test] Coyote Time Exists")
	setup_player()
	await get_tree().process_frame
	
	if player and "coyote_time" in player:
		assert_true(player.coyote_time > 0, "Coyote time harus > 0")
		assert_true(player.coyote_time <= 0.3, "Coyote time tidak boleh > 0.3s")
	else:
		assert_true(false, "Property 'coyote_time' tidak ditemukan")
	
	cleanup_player()


func test_jump_buffer_exists() -> void:
	print("\n[Test] Jump Buffer Exists")
	setup_player()
	await get_tree().process_frame
	
	if player and "jump_buffer_time" in player:
		assert_true(player.jump_buffer_time > 0, "Jump buffer harus > 0")
		assert_true(player.jump_buffer_time <= 0.2, "Jump buffer tidak boleh > 0.2s")
	else:
		assert_true(false, "Property 'jump_buffer_time' tidak ditemukan")
	
	cleanup_player()


func test_dash_speed_exists() -> void:
	print("\n[Test] Dash Speed Exists")
	setup_player()
	await get_tree().process_frame
	
	if player and "dash_speed" in player and "speed" in player:
		assert_true(player.dash_speed > player.speed, "Dash harus lebih cepat dari walk")
	else:
		assert_true(false, "Property 'dash_speed' tidak ditemukan")
	
	cleanup_player()


func test_glide_multiplier_exists() -> void:
	print("\n[Test] Glide Gravity Exists")
	setup_player()
	await get_tree().process_frame
	
	if player and "glide_gravity" in player:
		assert_true(player.glide_gravity > 0 and player.glide_gravity < 980, "Glide gravity harus positif dan lebih kecil dari normal gravity")
	else:
		assert_true(false, "Property 'glide_gravity' tidak ditemukan")
	
	cleanup_player()


func test_dash_starts_locked() -> void:
	print("\n[Test] Dash Starts Locked")
	var game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager:
		game_manager.new_game()
		assert_false(game_manager.can_dash, "Dash harus terkunci di awal")
	else:
		assert_true(false, "GameManager tidak tersedia")


func test_double_jump_starts_locked() -> void:
	print("\n[Test] Double Jump Starts Locked")
	var game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager:
		assert_false(game_manager.can_double_jump, "Double jump harus terkunci di awal")
	else:
		assert_true(false, "GameManager tidak tersedia")


func test_glide_starts_locked() -> void:
	print("\n[Test] Glide Starts Locked")
	var game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager:
		assert_false(game_manager.can_glide, "Glide harus terkunci di awal")
	else:
		assert_true(false, "GameManager tidak tersedia")


func test_player_can_take_damage() -> void:
	print("\n[Test] Player Can Take Damage")
	var game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager:
		game_manager.new_game()
		var initial_health: int = game_manager.player_health
		game_manager.damage_player(10)
		
		assert_eq(game_manager.player_health, initial_health - 10, "Health harus berkurang")
		game_manager.reset_health()
	else:
		assert_true(false, "GameManager tidak tersedia")


func test_player_dies_at_zero_health() -> void:
	print("\n[Test] Player Dies at Zero Health")
	var game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager:
		game_manager.new_game()
		game_manager.damage_player(game_manager.player_health)
		
		assert_eq(game_manager.player_health, 0, "Health harus 0")
		assert_true(game_manager.is_game_over, "is_game_over harus true")
		game_manager.new_game()
	else:
		assert_true(false, "GameManager tidak tersedia")


func test_health_cannot_go_negative() -> void:
	print("\n[Test] Health Cannot Go Negative")
	var game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager:
		game_manager.new_game()
		game_manager.damage_player(9999)
		
		assert_true(game_manager.player_health >= 0, "Health tidak boleh negatif")
		game_manager.new_game()
	else:
		assert_true(false, "GameManager tidak tersedia")


# -----------------------------------------------------------------------------
# NEW TESTS: reset_player() function (CRITICAL FIX)
# -----------------------------------------------------------------------------

func test_reset_player_function_exists() -> void:
	print("\n[Test] reset_player() Function Exists")
	setup_player()
	await get_tree().process_frame
	
	if player:
		assert_true(player.has_method("reset_player"), "Player harus punya fungsi reset_player()")
	else:
		assert_true(false, "Player tidak ter-instantiate")
	
	cleanup_player()


func test_reset_player_resets_velocity() -> void:
	print("\n[Test] reset_player() Resets Velocity")
	setup_player()
	await get_tree().process_frame
	
	if player and player.has_method("reset_player"):
		# Set velocity ke nilai non-zero
		player.velocity = Vector2(150, -300)
		
		# Call reset
		player.reset_player()
		
		assert_eq(player.velocity, Vector2.ZERO, "Velocity harus Vector2.ZERO setelah reset")
	else:
		assert_true(false, "reset_player() tidak tersedia")
	
	cleanup_player()


func test_reset_player_resets_health() -> void:
	print("\n[Test] reset_player() Resets Health")
	setup_player()
	await get_tree().process_frame
	
	if player and player.has_method("reset_player"):
		# Damage player dulu
		if player.has_method("take_damage"):
			player.take_damage(50)
		else:
			player.current_health = 50
		
		var before_health: int = player.current_health
		
		# Call reset
		player.reset_player()
		
		assert_eq(player.current_health, player.max_health, 
			"Health harus max (%d) setelah reset, got: %d" % [player.max_health, player.current_health])
	else:
		assert_true(false, "reset_player() tidak tersedia")
	
	cleanup_player()
