# ===================================================
# SaveManager.gd - Autoload untuk Save/Load System
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Mengelola save dan load game progress.
# ===================================================

extends Node
class_name SaveManagerClass

# --- KONSTANTA ---
const SAVE_PATH: String = "user://reboot_save.json"
const SETTINGS_PATH: String = "user://reboot_settings.json"

# --- SIGNALS ---
signal game_saved
signal game_loaded
signal save_error(message: String)


func _ready() -> void:
	print("[SaveManager] Save system ready!")
	print("[SaveManager] Save path: %s" % SAVE_PATH)


# === SAVE GAME ===
func save_game() -> bool:
	"""Simpan progress game ke file."""
	var save_data: Dictionary = {
		"version": "1.0",
		"timestamp": Time.get_datetime_string_from_system(),
		"player": {
			"health": GameManager.player_health,
			"max_health": GameManager.player_max_health,
			"cores_collected": GameManager.cores_collected
		},
		"abilities": {
			"can_dash": GameManager.can_dash,
			"can_double_jump": GameManager.can_double_jump,
			"can_glide": GameManager.can_glide
		},
		"progress": {
			"current_level": GameManager.current_level
		}
	}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		var error_msg := "Gagal membuka file save: %s" % FileAccess.get_open_error()
		push_error("[SaveManager] %s" % error_msg)
		save_error.emit(error_msg)
		return false
	
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	
	game_saved.emit()
	print("[SaveManager] Game tersimpan!")
	return true


# === LOAD GAME ===
func load_game() -> bool:
	"""Load progress game dari file."""
	if not FileAccess.file_exists(SAVE_PATH):
		push_warning("[SaveManager] File save tidak ditemukan.")
		return false
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		var error_msg := "Gagal membuka file save: %s" % FileAccess.get_open_error()
		push_error("[SaveManager] %s" % error_msg)
		save_error.emit(error_msg)
		return false
	
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		var error_msg := "Gagal parse JSON: %s" % json.get_error_message()
		push_error("[SaveManager] %s" % error_msg)
		save_error.emit(error_msg)
		return false
	
	var save_data: Dictionary = json.data
	
	# Restore player data
	if save_data.has("player"):
		var player_data: Dictionary = save_data["player"]
		GameManager.player_health = player_data.get("health", 100)
		GameManager.player_max_health = player_data.get("max_health", 100)
		GameManager.cores_collected = player_data.get("cores_collected", 0)
	
	# Restore abilities
	if save_data.has("abilities"):
		var abilities: Dictionary = save_data["abilities"]
		GameManager.can_dash = abilities.get("can_dash", false)
		GameManager.can_double_jump = abilities.get("can_double_jump", false)
		GameManager.can_glide = abilities.get("can_glide", false)
	
	# Restore progress
	if save_data.has("progress"):
		var progress: Dictionary = save_data["progress"]
		GameManager.current_level = progress.get("current_level", "")
	
	game_loaded.emit()
	print("[SaveManager] Game berhasil di-load!")
	return true


# === DELETE SAVE ===
func delete_save() -> bool:
	"""Hapus file save (untuk new game)."""
	if FileAccess.file_exists(SAVE_PATH):
		var error := DirAccess.remove_absolute(SAVE_PATH)
		if error != OK:
			push_error("[SaveManager] Gagal hapus save: %s" % error)
			return false
		print("[SaveManager] Save file dihapus.")
	return true


# === SETTINGS ===
func save_settings(settings: Dictionary) -> bool:
	"""Simpan pengaturan game (volume, controls, dll)."""
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return false
	
	file.store_string(JSON.stringify(settings, "\t"))
	file.close()
	print("[SaveManager] Settings tersimpan!")
	return true


func load_settings() -> Dictionary:
	"""Load pengaturan game."""
	if not FileAccess.file_exists(SETTINGS_PATH):
		return get_default_settings()
	
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return get_default_settings()
	
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return get_default_settings()
	
	file.close()
	return json.data


func get_default_settings() -> Dictionary:
	"""Return default settings."""
	return {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"fullscreen": false,
		"vsync": true
	}


# === CHECK SAVE EXISTS ===
func has_save_file() -> bool:
	"""Cek apakah ada save file."""
	return FileAccess.file_exists(SAVE_PATH)
