# ===================================================
# GameManager.gd - OVERHAULED Autoload Global
# Project: REBOOT (Modern Precision Platformer)
# Author: el-pablos
# ===================================================
# SOURCE OF TRUTH untuk semua game state & progression.
# Menggunakan Dictionary-based ability system untuk persistence.
# ===================================================

extends Node
# Original class_name: GameManagerClass (removed to avoid conflict)

# === SIGNALS ===
signal core_collected(total: int)
signal player_died
signal level_completed(level_name: String)
signal ability_unlocked(ability_name: String)
signal game_paused(is_paused: bool)
signal player_stats_changed

# === CONSTANTS ===
const MAX_CORES: int = 5
const SAVE_PATH: String = "user://reboot_save.json"

# DEBUG MODE: Set true untuk testing dengan semua ability unlocked
const DEBUG_MODE: bool = true

# === LEVEL PROGRESSION ===
const LEVEL_ORDER: Array[String] = [
	"res://scenes/levels/Level_01_GoldenIsles.tscn",
	"res://scenes/levels/Level_02_RustFactory.tscn",
	"res://scenes/levels/Level_03_CrystalLabs.tscn",
	"res://scenes/levels/Level_04_StormSpire.tscn",
	"res://scenes/levels/Level_05_OverlordFortress.tscn"
]

# Ability unlock per level (setelah complete)
const LEVEL_REWARDS: Dictionary = {
	"Level_01_GoldenIsles": "",  # Tutorial - no reward
	"Level_02_RustFactory": "dash",
	"Level_03_CrystalLabs": "double_jump",
	"Level_04_StormSpire": "glide",
	"Level_05_OverlordFortress": ""  # Final - victory
}

# === PERSISTENT DATA (Dictionary-based untuk robustness) ===
# Ini adalah SOURCE OF TRUTH yang TIDAK PERNAH DI-RESET saat change_scene

var _player_data: Dictionary = {
	"health": 100,
	"max_health": 100,
	"cores_collected": 0,
	"current_level": "",
	"checkpoint_position": Vector2.ZERO
}

var _abilities: Dictionary = {
	"dash": false,
	"double_jump": false,
	"glide": false
}

var _game_state: Dictionary = {
	"is_paused": false,
	"is_game_over": false,
	"total_deaths": 0,
	"total_playtime": 0.0
}

# === COMPUTED GETTERS (Clean API) ===
var player_health: int:
	get: return _player_data.health
	set(value): _player_data.health = clampi(value, 0, _player_data.max_health)

var player_max_health: int:
	get: return _player_data.max_health

var cores_collected: int:
	get: return _player_data.cores_collected
	set(value): _player_data.cores_collected = clampi(value, 0, MAX_CORES)

var current_level: String:
	get: return _player_data.current_level
	set(value): _player_data.current_level = value

var can_dash: bool:
	get: return _abilities.dash
	set(value): _abilities.dash = value

var can_double_jump: bool:
	get: return _abilities.double_jump
	set(value): _abilities.double_jump = value

var can_glide: bool:
	get: return _abilities.glide
	set(value): _abilities.glide = value

var is_paused: bool:
	get: return _game_state.is_paused
	set(value): _game_state.is_paused = value

var is_game_over: bool:
	get: return _game_state.is_game_over
	set(value): _game_state.is_game_over = value


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Apply debug mode if enabled
	if DEBUG_MODE:
		debug_unlock_all()
	
	print("[GameManager] 🎮 Game Manager initialized!")
	print("[GameManager] DEBUG_MODE: %s" % DEBUG_MODE)


func _process(delta: float) -> void:
	if not is_paused and not is_game_over:
		_game_state.total_playtime += delta


# =========================================
# ABILITY SYSTEM (Robust & Persistent)
# =========================================

func unlock_ability(ability_name: String) -> void:
	"""Unlock an ability by name. Emits signal for Player to sync."""
	if ability_name in _abilities:
		_abilities[ability_name] = true
		ability_unlocked.emit(ability_name)
		print("[GameManager] ✨ ABILITY UNLOCKED: %s" % ability_name.to_upper())

func is_ability_unlocked(ability_name: String) -> bool:
	"""Check if ability is unlocked."""
	return _abilities.get(ability_name, false)

func get_abilities_dict() -> Dictionary:
	"""Return copy of abilities dictionary (for Player sync)."""
	return _abilities.duplicate()

func debug_unlock_all() -> void:
	"""DEBUG: Unlock all abilities instantly."""
	for ability in _abilities:
		_abilities[ability] = true
	print("[GameManager] 🔓 DEBUG: All abilities force unlocked!")
	player_stats_changed.emit()

func unlock_dash() -> void:
	unlock_ability("dash")

func unlock_double_jump() -> void:
	unlock_ability("double_jump")

func unlock_glide() -> void:
	unlock_ability("glide")


# =========================================
# PLAYER STATS INJECTION
# =========================================

func get_player_stats() -> Dictionary:
	"""Return all player stats for injection into new Player instance."""
	return {
		"health": _player_data.health,
		"max_health": _player_data.max_health,
		"can_dash": _abilities.dash,
		"can_double_jump": _abilities.double_jump,
		"can_glide": _abilities.glide,
		"max_jumps": 2 if _abilities.double_jump else 1
	}

func inject_stats_to_player(player_node: Node) -> void:
	"""Inject all stats into a Player node. Call this in Player._ready()."""
	if player_node == null:
		push_error("[GameManager] inject_stats_to_player: player is null!")
		return
	
	var stats := get_player_stats()
	
	player_node.can_dash = stats.can_dash
	player_node.can_double_jump = stats.can_double_jump
	player_node.can_glide = stats.can_glide
	player_node.max_jumps = stats.max_jumps
	player_node.current_health = stats.health
	player_node.max_health = stats.max_health
	
	# Recalculate physics if double jump enabled
	if stats.can_double_jump:
		player_node.jump_height = 110.0
		player_node._recalculate_jump_physics()
	
	print("[GameManager] 📊 Stats injected: dash=%s, double_jump=%s (max_jumps=%d), glide=%s" % [
		stats.can_dash, stats.can_double_jump, stats.max_jumps, stats.can_glide
	])

# Alias for compatibility
func apply_upgrades_to_player(player_node: Node) -> void:
	inject_stats_to_player(player_node)


# =========================================
# CORE COLLECTION
# =========================================

func collect_core() -> void:
	"""Collect a core fragment."""
	if cores_collected < MAX_CORES:
		_player_data.cores_collected += 1
		core_collected.emit(cores_collected)
		print("[GameManager] 💎 Core collected: %d/%d" % [cores_collected, MAX_CORES])
		
		if cores_collected >= MAX_CORES:
			print("[GameManager] 🏆 ALL CORES COLLECTED! Final boss unlocked!")

func collect_core_and_advance() -> void:
	"""Collect core and transition to next level."""
	collect_core()
	
	var level_name := current_level.get_file().get_basename()
	level_completed.emit(level_name)
	
	# Check for ability reward
	if level_name in LEVEL_REWARDS:
		var reward: String = LEVEL_REWARDS[level_name]
		if reward != "":
			unlock_ability(reward)
	
	# Delay for effects, then load next
	await get_tree().create_timer(1.0).timeout
	load_next_level()


# =========================================
# HEALTH SYSTEM
# =========================================

func damage_player(amount: int) -> void:
	player_health -= amount
	print("[GameManager] 💔 Player damaged: -%d (HP: %d/%d)" % [amount, player_health, player_max_health])
	
	if player_health <= 0:
		_game_state.is_game_over = true
		_game_state.total_deaths += 1
		player_died.emit()
		print("[GameManager] ☠️ GAME OVER")

func heal_player(amount: int) -> void:
	player_health += amount
	print("[GameManager] 💚 Player healed: +%d (HP: %d/%d)" % [amount, player_health, player_max_health])

func reset_health() -> void:
	_player_data.health = _player_data.max_health

func reset_player_health() -> void:
	reset_health()


# =========================================
# LEVEL MANAGEMENT
# =========================================

func change_level(level_path: String) -> void:
	"""Change to a new level. Preserves all persistent data."""
	_player_data.current_level = level_path
	print("[GameManager] 🚀 Loading level: %s" % level_path)
	get_tree().change_scene_to_file(level_path)

func reload_current_level() -> void:
	if current_level != "":
		print("[GameManager] 🔄 Reloading: %s" % current_level)
		get_tree().reload_current_scene()

func load_next_level() -> void:
	var current_index := LEVEL_ORDER.find(current_level)
	
	if current_index < 0:
		push_warning("[GameManager] Current level not in LEVEL_ORDER, loading first level")
		if LEVEL_ORDER.size() > 0:
			change_level(LEVEL_ORDER[0])
		return
	
	var next_index := current_index + 1
	if next_index < LEVEL_ORDER.size():
		change_level(LEVEL_ORDER[next_index])
	else:
		print("[GameManager] 🎉 ALL LEVELS COMPLETE!")
		_show_victory_screen()

func complete_level(level_name: String) -> void:
	level_completed.emit(level_name)
	print("[GameManager] ✅ Level complete: %s" % level_name)


# =========================================
# PAUSE SYSTEM
# =========================================

func toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	game_paused.emit(is_paused)
	print("[GameManager] %s" % ["⏸️ PAUSED" if is_paused else "▶️ RESUMED"])


# =========================================
# NEW GAME / RESET
# =========================================

func new_game() -> void:
	"""Start a new game. Resets progress but applies debug unlocks if enabled."""
	_player_data = {
		"health": 100,
		"max_health": 100,
		"cores_collected": 0,
		"current_level": "",
		"checkpoint_position": Vector2.ZERO
	}
	
	_abilities = {
		"dash": false,
		"double_jump": false,
		"glide": false
	}
	
	_game_state.is_game_over = false
	_game_state.is_paused = false
	
	# CRITICAL: Apply debug unlocks AFTER reset
	if DEBUG_MODE:
		debug_unlock_all()
	
	print("[GameManager] 🆕 New game started!")

func reset_game() -> void:
	new_game()


# =========================================
# NAVIGATION
# =========================================

func go_to_main_menu() -> void:
	is_paused = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	print("[GameManager] 🏠 Returning to main menu")

func _show_victory_screen() -> void:
	var victory_path := "res://scenes/ui/VictoryScreen.tscn"
	if ResourceLoader.exists(victory_path):
		get_tree().change_scene_to_file(victory_path)
	else:
		go_to_main_menu()


# =========================================
# TESTING HELPERS
# =========================================

func get_cores_count() -> int:
	return cores_collected

func get_player_health() -> int:
	return player_health
