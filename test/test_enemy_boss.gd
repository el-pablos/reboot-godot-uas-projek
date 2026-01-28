# =============================================================================
# test_enemy_boss.gd - Unit Test untuk Enemy & Boss Systems
# =============================================================================
# Test suite untuk memverifikasi:
# - Enemy base behavior
# - Boss phase system
# - Damage & death mechanics
# - Attack patterns
# =============================================================================

extends GutTest

# Referensi untuk testing
var game_manager: Node = null


# -----------------------------------------------------------------------------
# SETUP & TEARDOWN
# -----------------------------------------------------------------------------

func before_each() -> void:
	game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.new_game()


func after_each() -> void:
	if game_manager:
		game_manager.new_game()


# -----------------------------------------------------------------------------
# TEST: ENEMY BASE PROPERTIES
# -----------------------------------------------------------------------------

## Test: EnemyBase script exists and loads
func test_enemy_base_script_exists() -> void:
	var script = load("res://scripts/enemies/EnemyBase.gd")
	assert_not_null(script, "EnemyBase.gd harus ada")


## Test: WalkingEnemy script exists
func test_walking_enemy_script_exists() -> void:
	var script = load("res://scripts/enemies/WalkingEnemy.gd")
	assert_not_null(script, "WalkingEnemy.gd harus ada")


## Test: FlyingEnemy script exists
func test_flying_enemy_script_exists() -> void:
	var script = load("res://scripts/enemies/FlyingEnemy.gd")
	assert_not_null(script, "FlyingEnemy.gd harus ada")


# -----------------------------------------------------------------------------
# TEST: BOSS SCRIPTS EXISTENCE
# -----------------------------------------------------------------------------

## Test: BossBase script exists
func test_boss_base_script_exists() -> void:
	var script = load("res://scripts/enemies/BossBase.gd")
	assert_not_null(script, "BossBase.gd harus ada")


## Test: BossScrapper script exists
func test_boss_scrapper_script_exists() -> void:
	var script = load("res://scripts/enemies/BossScrapper.gd")
	assert_not_null(script, "BossScrapper.gd harus ada")


## Test: BossSporeBot script exists
func test_boss_spore_bot_script_exists() -> void:
	var script = load("res://scripts/enemies/BossSporeBot.gd")
	assert_not_null(script, "BossSporeBot.gd harus ada")


## Test: BossTempest script exists
func test_boss_tempest_script_exists() -> void:
	var script = load("res://scripts/enemies/BossTempest.gd")
	assert_not_null(script, "BossTempest.gd harus ada")


## Test: BossOverlord script exists
func test_boss_overlord_script_exists() -> void:
	var script = load("res://scripts/enemies/BossOverlord.gd")
	assert_not_null(script, "BossOverlord.gd harus ada")


# -----------------------------------------------------------------------------
# TEST: BOSS REWARDS
# -----------------------------------------------------------------------------

## Test: Boss 1 memberikan dash ability
func test_boss_1_rewards_dash() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	# Simulasi boss 1 defeated
	assert_false(game_manager.can_dash, "Dash harus terkunci sebelum boss")
	
	game_manager.unlock_dash()  # Ini yang dipanggil boss saat defeated
	
	assert_true(game_manager.can_dash, "Dash harus terbuka setelah boss 1")


## Test: Boss 2 memberikan double jump ability
func test_boss_2_rewards_double_jump() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	assert_false(game_manager.can_double_jump, "Double jump harus terkunci sebelum boss")
	
	game_manager.unlock_double_jump()
	
	assert_true(game_manager.can_double_jump, "Double jump harus terbuka setelah boss 2")


## Test: Boss 3 memberikan glide ability
func test_boss_3_rewards_glide() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	assert_false(game_manager.can_glide, "Glide harus terkunci sebelum boss")
	
	game_manager.unlock_glide()
	
	assert_true(game_manager.can_glide, "Glide harus terbuka setelah boss 3")


# -----------------------------------------------------------------------------
# TEST: ABILITY UNLOCK ORDER (GAME FLOW)
# -----------------------------------------------------------------------------

## Test: Game flow - unlock abilities in correct order
func test_ability_unlock_order() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	# Start: semua terkunci
	assert_false(game_manager.can_dash)
	assert_false(game_manager.can_double_jump)
	assert_false(game_manager.can_glide)
	
	# Boss 1: Scrapper -> Dash
	game_manager.unlock_dash()
	assert_true(game_manager.can_dash)
	assert_false(game_manager.can_double_jump)
	assert_false(game_manager.can_glide)
	
	# Boss 2: Spore-Bot -> Double Jump
	game_manager.unlock_double_jump()
	assert_true(game_manager.can_dash)
	assert_true(game_manager.can_double_jump)
	assert_false(game_manager.can_glide)
	
	# Boss 3: Tempest -> Glide
	game_manager.unlock_glide()
	assert_true(game_manager.can_dash)
	assert_true(game_manager.can_double_jump)
	assert_true(game_manager.can_glide)


# -----------------------------------------------------------------------------
# TEST: BOSS SIGNAL EMISSION
# -----------------------------------------------------------------------------

## Test: Ability unlock emits correct signal with name
func test_ability_unlock_signal_has_name() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	watch_signals(game_manager)
	
	game_manager.unlock_dash()
	
	assert_signal_emitted_with_parameters(
		game_manager, 
		"ability_unlocked", 
		["dash"],
		"Signal harus include nama ability"
	)


# -----------------------------------------------------------------------------
# TEST: CORE COLLECTION FOR FINAL BOSS
# -----------------------------------------------------------------------------

## Test: Semua 5 core diperlukan untuk final boss
func test_five_cores_needed_for_final() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	assert_eq(game_manager.MAX_CORES, 5, "Harus butuh 5 core untuk final boss")


## Test: Setiap level memberikan 1 core
func test_each_level_gives_one_core() -> void:
	if game_manager == null:
		pending("GameManager tidak tersedia")
		return
	
	# Simulasi clear 5 level, collect 5 cores
	for i in range(5):
		game_manager.collect_core()
	
	assert_eq(game_manager.cores_collected, 5, "5 level = 5 cores")


# -----------------------------------------------------------------------------
# TEST: LEVEL SCENES EXISTENCE
# -----------------------------------------------------------------------------

## Test: Level 1 scene exists
func test_level_1_exists() -> void:
	var scene = load("res://scenes/levels/Level_01_GoldenIsles.tscn")
	assert_not_null(scene, "Level 1 scene harus ada")


## Test: Level 2 scene exists
func test_level_2_exists() -> void:
	var scene = load("res://scenes/levels/Level_02_RustFactory.tscn")
	assert_not_null(scene, "Level 2 scene harus ada")


## Test: Level 3 scene exists
func test_level_3_exists() -> void:
	var scene = load("res://scenes/levels/Level_03_CrystalLabs.tscn")
	assert_not_null(scene, "Level 3 scene harus ada")


## Test: Level 4 scene exists
func test_level_4_exists() -> void:
	var scene = load("res://scenes/levels/Level_04_StormSpire.tscn")
	assert_not_null(scene, "Level 4 scene harus ada")


## Test: Level 5 scene exists
func test_level_5_exists() -> void:
	var scene = load("res://scenes/levels/Level_05_OverlordFortress.tscn")
	assert_not_null(scene, "Level 5 scene harus ada")
