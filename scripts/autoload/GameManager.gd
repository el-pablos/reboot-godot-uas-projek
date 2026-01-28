# ===================================================
# GameManager.gd - Autoload Global untuk Game State
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Mengelola state game, progress pemain, dan data persistent.
# ===================================================

extends Node
class_name GameManagerClass

# --- SIGNALS ---
signal core_collected(total: int)
signal player_died
signal level_completed(level_name: String)
signal ability_unlocked(ability_name: String)
signal game_paused(is_paused: bool)

# --- KONSTANTA ---
const MAX_CORES: int = 5
const SAVE_PATH: String = "user://savegame.save"

# --- DATA PEMAIN ---
var player_health: int = 100
var player_max_health: int = 100
var cores_collected: int = 0
var current_level: String = ""

# --- ABILITY UNLOCK STATUS ---
# Default semua terkunci, dibuka sesuai progress game
var can_dash: bool = false         # Unlock setelah Boss 1 (Scrapper)
var can_double_jump: bool = false  # Unlock setelah Boss 2 (Spore-Bot)
var can_glide: bool = false        # Unlock setelah Boss 3 (Tempest)

# --- GAME STATE ---
var is_paused: bool = false
var is_game_over: bool = false


func _ready() -> void:
	# Set pause mode agar autoload tetap berjalan saat game di-pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[GameManager] Sistem game manager aktif!")


# === FUNGSI CORE COLLECTION ===
func collect_core() -> void:
	"""Dipanggil saat pemain mengambil pecahan core."""
	if cores_collected < MAX_CORES:
		cores_collected += 1
		core_collected.emit(cores_collected)
		print("[GameManager] Core terkumpul: %d/%d" % [cores_collected, MAX_CORES])
		
		# Cek apakah semua core sudah terkumpul
		if cores_collected >= MAX_CORES:
			print("[GameManager] SEMUA CORE TERKUMPUL! Final boss unlocked!")


# === FUNGSI UNLOCK ABILITY ===
func unlock_dash() -> void:
	"""Unlock air dash - hadiah dari Boss Scrapper."""
	can_dash = true
	ability_unlocked.emit("dash")
	print("[GameManager] ABILITY UNLOCKED: Air Dash!")


func unlock_double_jump() -> void:
	"""Unlock double jump - hadiah dari Boss Spore-Bot."""
	can_double_jump = true
	ability_unlocked.emit("double_jump")
	print("[GameManager] ABILITY UNLOCKED: Double Jump!")


func unlock_glide() -> void:
	"""Unlock glide - hadiah dari Boss Tempest."""
	can_glide = true
	ability_unlocked.emit("glide")
	print("[GameManager] ABILITY UNLOCKED: Glide!")


# === FUNGSI HEALTH ===
func damage_player(amount: int) -> void:
	"""Kurangi HP pemain. Emit signal jika mati."""
	player_health = max(0, player_health - amount)
	print("[GameManager] Player kena damage: %d. HP tersisa: %d" % [amount, player_health])
	
	if player_health <= 0:
		is_game_over = true
		player_died.emit()
		print("[GameManager] GAME OVER - Bip hancur!")


func heal_player(amount: int) -> void:
	"""Tambah HP pemain (tidak melebihi max)."""
	player_health = min(player_max_health, player_health + amount)
	print("[GameManager] Player heal: +%d. HP sekarang: %d" % [amount, player_health])


func reset_health() -> void:
	"""Reset HP ke full (saat respawn/new game)."""
	player_health = player_max_health


# === FUNGSI PAUSE ===
func toggle_pause() -> void:
	"""Toggle pause state game."""
	is_paused = !is_paused
	get_tree().paused = is_paused
	game_paused.emit(is_paused)
	print("[GameManager] Game %s" % ["PAUSED" if is_paused else "RESUMED"])


# === FUNGSI LEVEL ===
func change_level(level_path: String) -> void:
	"""Pindah ke level baru."""
	current_level = level_path
	get_tree().change_scene_to_file(level_path)
	print("[GameManager] Loading level: %s" % level_path)


func complete_level(level_name: String) -> void:
	"""Dipanggil saat level selesai."""
	level_completed.emit(level_name)
	print("[GameManager] Level selesai: %s" % level_name)


# === FUNGSI RESET/NEW GAME ===
func new_game() -> void:
	"""Reset semua progress untuk game baru."""
	player_health = player_max_health
	cores_collected = 0
	can_dash = false
	can_double_jump = false
	can_glide = false
	is_game_over = false
	is_paused = false
	print("[GameManager] New game dimulai! Semua progress di-reset.")


# === FUNGSI TESTING (untuk unit test) ===
func get_cores_count() -> int:
	"""Getter untuk testing."""
	return cores_collected


func get_player_health() -> int:
	"""Getter untuk testing."""
	return player_health


func is_ability_unlocked(ability_name: String) -> bool:
	"""Cek status ability untuk testing."""
	match ability_name:
		"dash":
			return can_dash
		"double_jump":
			return can_double_jump
		"glide":
			return can_glide
		_:
			return false
