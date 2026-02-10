# ===================================================
# test_integration_level4.gd - Integration Test untuk Double Jump
# Project: REBOOT
# ===================================================
# Test ini memvalidasi bahwa:
# 1. GameManager menyimpan state ability dengan benar
# 2. Player menerima max_jumps = 2 saat sync
# ===================================================

extends Node


func _ready() -> void:
	print("=" .repeat(60))
	print("🧪 INTEGRATION TEST: Level 4 Double Jump")
	print("=" .repeat(60))
	
	var all_passed: bool = true
	
	# Test 1: GameManager State
	print("\n📋 TEST 1: GameManager.can_double_jump value")
	var test1_passed: bool = _test_gamemanager_state()
	all_passed = all_passed and test1_passed
	
	# Test 2: Simulate MainMenu → New Game flow
	print("\n📋 TEST 2: After new_game() call, abilities stay unlocked")
	var test2_passed: bool = _test_new_game_preserves_debug_unlocks()
	all_passed = all_passed and test2_passed
	
	# Test 3: Player Sync
	print("\n📋 TEST 3: Player receives max_jumps = 2 after sync")
	var test3_passed: bool = await _test_player_sync()
	all_passed = all_passed and test3_passed
	
	# Test 4: Jump Logic
	print("\n📋 TEST 4: Jump logic allows air jump")
	var test4_passed: bool = await _test_jump_logic()
	all_passed = all_passed and test4_passed
	
	# Summary
	print("\n" + "=" .repeat(60))
	if all_passed:
		print("✅ ALL TESTS PASSED!")
	else:
		print("❌ SOME TESTS FAILED!")
	print("=" .repeat(60))
	
	# Auto-quit after test
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()


func _test_gamemanager_state() -> bool:
	# Check if GameManager exists
	if not GameManager:
		print("  ❌ FAIL: GameManager autoload not found!")
		return false
	
	print("  GameManager.can_double_jump = %s" % GameManager.can_double_jump)
	
	if GameManager.can_double_jump == true:
		print("  ✅ PASS: can_double_jump is TRUE")
		return true
	else:
		print("  ❌ FAIL: can_double_jump is FALSE!")
		print("  → GameManager._ready() mungkin belum dijalankan atau nilai di-reset")
		return false


func _test_new_game_preserves_debug_unlocks() -> bool:
	# Simulate what happens when user clicks "New Game" in MainMenu
	print("  [Simulating] MainMenu calls GameManager.new_game()...")
	GameManager.new_game()
	
	print("  After new_game(): can_double_jump = %s" % GameManager.can_double_jump)
	
	if GameManager.can_double_jump:
		print("  ✅ PASS: DEBUG_UNLOCK preserved can_double_jump after new_game()")
		return true
	else:
		print("  ❌ FAIL: new_game() reset can_double_jump to false!")
		print("  → _apply_debug_unlocks() tidak dipanggil di new_game()")
		return false


func _test_player_sync() -> bool:
	# Force set GameManager state
	GameManager.can_double_jump = true
	print("  [Setup] GameManager.can_double_jump = true")
	
	# Load Player scene
	var player_scene = load("res://scenes/player/Player.tscn")
	if player_scene == null:
		print("  ❌ FAIL: Cannot load Player.tscn!")
		return false
	
	var player = player_scene.instantiate()
	add_child(player)
	
	# Wait one frame for _ready() to complete
	await get_tree().process_frame
	
	print("  Player.can_double_jump = %s" % player.can_double_jump)
	print("  Player.max_jumps = %d" % player.max_jumps)
	print("  Player.jump_height = %.1f" % player.jump_height)
	
	var passed: bool = true
	
	# Check can_double_jump
	if player.can_double_jump:
		print("  ✅ PASS: player.can_double_jump = true")
	else:
		print("  ❌ FAIL: player.can_double_jump = false!")
		passed = false
	
	# Check max_jumps
	if player.max_jumps == 2:
		print("  ✅ PASS: player.max_jumps = 2")
	else:
		print("  ❌ FAIL: player.max_jumps = %d (expected 2)" % player.max_jumps)
		passed = false
	
	# Cleanup
	player.queue_free()
	
	return passed


func _test_jump_logic() -> bool:
	# This test simulates jump conditions
	GameManager.can_double_jump = true
	
	var player_scene = load("res://scenes/player/Player.tscn")
	var player = player_scene.instantiate()
	add_child(player)
	
	await get_tree().process_frame
	
	# Simulate: player sudah lompat sekali (jump_count = 1), tidak di tanah
	player.jump_count = 1
	
	# Check if can_double_jump allows second jump
	var can_air_jump: bool = player.can_double_jump and player.jump_count < player.max_jumps
	
	print("  Simulated state: jump_count=1, max_jumps=%d" % player.max_jumps)
	print("  can_air_jump = %s" % can_air_jump)
	
	if can_air_jump:
		print("  ✅ PASS: Air jump logic allows second jump")
	else:
		print("  ❌ FAIL: Air jump logic blocks second jump!")
		print("  → can_double_jump=%s, jump_count=%d, max_jumps=%d" % [player.can_double_jump, player.jump_count, player.max_jumps])
	
	player.queue_free()
	return can_air_jump
