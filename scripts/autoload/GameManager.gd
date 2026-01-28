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
	"""Dipanggil saat pemain mengambil pecahan core (tanpa advance level)."""
	if cores_collected < MAX_CORES:
		cores_collected += 1
		core_collected.emit(cores_collected)
		print("[GameManager] Core terkumpul: %d/%d" % [cores_collected, MAX_CORES])
		
		# Cek apakah semua core sudah terkumpul
		if cores_collected >= MAX_CORES:
			print("[GameManager] SEMUA CORE TERKUMPUL! Final boss unlocked!")


func collect_core_and_advance() -> void:
	"""Dipanggil saat pemain mengambil core DAN harus pindah level."""
	if cores_collected < MAX_CORES:
		cores_collected += 1
		core_collected.emit(cores_collected)
		print("[GameManager] Core collected! Total: %d/%d" % [cores_collected, MAX_CORES])
	
	# Complete current level
	var level_name: String = current_level.get_file().get_basename()
	level_completed.emit(level_name)
	print("[GameManager] Level complete: %s" % level_name)
	
	# Delay sebentar agar SFX selesai, lalu load next level
	await get_tree().create_timer(1.0).timeout
	load_next_level()


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


# === FUNGSI LEVEL MANAGEMENT (untuk UI screens) ===
## Daftar urutan level
const LEVEL_ORDER: Array[String] = [
	"res://scenes/levels/Level_01_GoldenIsles.tscn",
	"res://scenes/levels/Level_02_RustFactory.tscn",
	"res://scenes/levels/Level_03_CrystalLabs.tscn",
	"res://scenes/levels/Level_04_StormSpire.tscn",
	"res://scenes/levels/Level_05_OverlordFortress.tscn"
]


func reload_current_level() -> void:
	"""Reload level saat ini (untuk retry)."""
	if current_level != "":
		get_tree().reload_current_scene()
		print("[GameManager] Reloading level: %s" % current_level)
	else:
		print("[GameManager] Warning: No current level to reload")


func load_next_level() -> void:
	"""Load level berikutnya dalam urutan."""
	var current_index: int = LEVEL_ORDER.find(current_level)
	
	if current_index >= 0 and current_index < LEVEL_ORDER.size() - 1:
		var next_level: String = LEVEL_ORDER[current_index + 1]
		change_level(next_level)
		print("[GameManager] Loading next level: %s" % next_level)
	else:
		# Sudah level terakhir atau tidak ditemukan
		print("[GameManager] No next level available")


func go_to_main_menu() -> void:
	"""Kembali ke main menu."""
	# Reset pause state
	is_paused = false
	get_tree().paused = false
	
	# Pindah ke main menu
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	print("[GameManager] Returning to main menu")


func reset_player_health() -> void:
	"""Alias untuk reset_health (kompatibilitas)."""
	reset_health()


func reset_game() -> void:
	"""Reset seluruh game state (alias untuk new_game)."""
	new_game()
	print("[GameManager] Game state reset")
