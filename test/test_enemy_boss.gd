# =============================================================================
# test_enemy_boss.gd - Unit Test untuk Enemy & Boss Systems (Standalone)
# =============================================================================
# Test suite untuk memverifikasi enemy/boss systems tanpa GUT dependency.
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
	print("🧪 RUNNING: test_enemy_boss.gd")
	print("=".repeat(60))
	
	game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager:
		game_manager.new_game()
	
	# Jalankan semua test
	run_all_tests()
	
	# Print hasil
	print_results()


func run_all_tests() -> void:
	test_enemy_base_script_exists()
	test_walking_enemy_script_exists()
	test_flying_enemy_script_exists()
	test_boss_base_script_exists()
	test_boss_scrapper_script_exists()
	test_boss_spore_bot_script_exists()
	test_boss_tempest_script_exists()
	test_boss_overlord_script_exists()
	test_boss_1_rewards_dash()
	test_boss_2_rewards_double_jump()
	test_boss_3_rewards_glide()
	test_ability_unlock_order()
	test_five_cores_needed_for_final()
	test_each_level_gives_one_core()
	test_level_1_exists()
	test_level_2_exists()
	test_level_3_exists()
	test_level_4_exists()
	test_level_5_exists()


func print_results() -> void:
	print("\n" + "-".repeat(60))
	print("📊 HASIL TEST ENEMY & BOSS")
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


# -----------------------------------------------------------------------------
# TESTS: SCRIPT EXISTENCE
# -----------------------------------------------------------------------------

func test_enemy_base_script_exists() -> void:
	print("\n[Test] EnemyBase Script Exists")
	var script = load("res://scripts/enemies/EnemyBase.gd")
	assert_not_null(script, "EnemyBase.gd harus ada")


func test_walking_enemy_script_exists() -> void:
	print("\n[Test] WalkingEnemy Script Exists")
	var script = load("res://scripts/enemies/WalkingEnemy.gd")
	assert_not_null(script, "WalkingEnemy.gd harus ada")


func test_flying_enemy_script_exists() -> void:
	print("\n[Test] FlyingEnemy Script Exists")
	var script = load("res://scripts/enemies/FlyingEnemy.gd")
	assert_not_null(script, "FlyingEnemy.gd harus ada")


func test_boss_base_script_exists() -> void:
	print("\n[Test] BossBase Script Exists")
	var script = load("res://scripts/enemies/BossBase.gd")
	assert_not_null(script, "BossBase.gd harus ada")


func test_boss_scrapper_script_exists() -> void:
	print("\n[Test] BossScrapper Script Exists")
	var script = load("res://scripts/enemies/BossScrapper.gd")
	assert_not_null(script, "BossScrapper.gd harus ada")


func test_boss_spore_bot_script_exists() -> void:
	print("\n[Test] BossSporeBot Script Exists")
	var script = load("res://scripts/enemies/BossSporeBot.gd")
	assert_not_null(script, "BossSporeBot.gd harus ada")


func test_boss_tempest_script_exists() -> void:
	print("\n[Test] BossTempest Script Exists")
	var script = load("res://scripts/enemies/BossTempest.gd")
	assert_not_null(script, "BossTempest.gd harus ada")


func test_boss_overlord_script_exists() -> void:
	print("\n[Test] BossOverlord Script Exists")
	var script = load("res://scripts/enemies/BossOverlord.gd")
	assert_not_null(script, "BossOverlord.gd harus ada")


# -----------------------------------------------------------------------------
# TESTS: BOSS REWARDS
# -----------------------------------------------------------------------------

func test_boss_1_rewards_dash() -> void:
	print("\n[Test] Boss 1 Rewards Dash")
	if game_manager == null:
		assert_true(false, "GameManager tidak tersedia")
		return
	
	game_manager.new_game()
	assert_false(game_manager.can_dash, "Dash terkunci sebelum boss")
	game_manager.unlock_dash()
	assert_true(game_manager.can_dash, "Dash terbuka setelah boss 1")
	game_manager.new_game()


func test_boss_2_rewards_double_jump() -> void:
	print("\n[Test] Boss 2 Rewards Double Jump")
	if game_manager == null:
		assert_true(false, "GameManager tidak tersedia")
		return
	
	game_manager.new_game()
	assert_false(game_manager.can_double_jump, "Double jump terkunci")
	game_manager.unlock_double_jump()
	assert_true(game_manager.can_double_jump, "Double jump terbuka")
	game_manager.new_game()


func test_boss_3_rewards_glide() -> void:
	print("\n[Test] Boss 3 Rewards Glide")
	if game_manager == null:
		assert_true(false, "GameManager tidak tersedia")
		return
	
	game_manager.new_game()
	assert_false(game_manager.can_glide, "Glide terkunci")
	game_manager.unlock_glide()
	assert_true(game_manager.can_glide, "Glide terbuka")
	game_manager.new_game()


func test_ability_unlock_order() -> void:
	print("\n[Test] Ability Unlock Order")
	if game_manager == null:
		assert_true(false, "GameManager tidak tersedia")
		return
	
	game_manager.new_game()
	
	# Awal: semua terkunci
	var all_locked: bool = not game_manager.can_dash and not game_manager.can_double_jump and not game_manager.can_glide
	assert_true(all_locked, "Awal semua terkunci")
	
	# Unlock berurutan
	game_manager.unlock_dash()
	assert_true(game_manager.can_dash and not game_manager.can_double_jump, "Setelah boss 1")
	
	game_manager.unlock_double_jump()
	assert_true(game_manager.can_dash and game_manager.can_double_jump and not game_manager.can_glide, "Setelah boss 2")
	
	game_manager.unlock_glide()
	assert_true(game_manager.can_dash and game_manager.can_double_jump and game_manager.can_glide, "Setelah boss 3")
	
	game_manager.new_game()


# -----------------------------------------------------------------------------
# TESTS: CORE COLLECTION
# -----------------------------------------------------------------------------

func test_five_cores_needed_for_final() -> void:
	print("\n[Test] Five Cores Needed for Final")
	if game_manager == null:
		assert_true(false, "GameManager tidak tersedia")
		return
	
	assert_eq(game_manager.MAX_CORES, 5, "MAX_CORES harus 5")


func test_each_level_gives_one_core() -> void:
	print("\n[Test] Each Level Gives One Core")
	if game_manager == null:
		assert_true(false, "GameManager tidak tersedia")
		return
	
	game_manager.new_game()
	for i in range(5):
		game_manager.collect_core()
	assert_eq(game_manager.cores_collected, 5, "5 cores setelah 5 collect")
	game_manager.new_game()


# -----------------------------------------------------------------------------
# TESTS: LEVEL SCENES
# -----------------------------------------------------------------------------

func test_level_1_exists() -> void:
	print("\n[Test] Level 1 Scene Exists")
	var scene = load("res://scenes/levels/Level_01_GoldenIsles.tscn")
	assert_not_null(scene, "Level 1 harus ada")


func test_level_2_exists() -> void:
	print("\n[Test] Level 2 Scene Exists")
	var scene = load("res://scenes/levels/Level_02_RustFactory.tscn")
	assert_not_null(scene, "Level 2 harus ada")


func test_level_3_exists() -> void:
	print("\n[Test] Level 3 Scene Exists")
	var scene = load("res://scenes/levels/Level_03_CrystalLabs.tscn")
	assert_not_null(scene, "Level 3 harus ada")


func test_level_4_exists() -> void:
	print("\n[Test] Level 4 Scene Exists")
	var scene = load("res://scenes/levels/Level_04_StormSpire.tscn")
	assert_not_null(scene, "Level 4 harus ada")


func test_level_5_exists() -> void:
	print("\n[Test] Level 5 Scene Exists")
	var scene = load("res://scenes/levels/Level_05_OverlordFortress.tscn")
	assert_not_null(scene, "Level 5 harus ada")
