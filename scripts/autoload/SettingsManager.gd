# ===================================================
# SettingsManager.gd - Autoload untuk Settings Persist
# Project: REBOOT
# ===================================================
# Mengelola settings game (audio, video, gameplay).
# Simpan ke ConfigFile (user://settings.cfg).
# NOTE: Autoload scripts MUST NOT have class_name!
# ===================================================

extends Node

const SETTINGS_FILE: String = "user://settings.cfg"

# --- AUDIO ---
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0

# --- VIDEO ---
var fullscreen: bool = false
var vsync: bool = true

# --- GAMEPLAY ---
var screen_shake: bool = true
var hit_stop_level: int = 1  # 0=off, 1=low, 2=high

# --- SIGNALS ---
signal settings_changed


func _ready() -> void:
	load_settings()
	apply_all()
	print("[SettingsManager] Settings loaded and applied")


# === SAVE ===
func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("video", "vsync", vsync)
	config.set_value("gameplay", "screen_shake", screen_shake)
	config.set_value("gameplay", "hit_stop_level", hit_stop_level)
	var err := config.save(SETTINGS_FILE)
	if err != OK:
		push_warning("[SettingsManager] Gagal simpan settings: %d" % err)


# === LOAD ===
func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_FILE)
	if err != OK:
		# File belum ada — pakai default, bukan crash
		return
	master_volume = config.get_value("audio", "master_volume", 1.0)
	music_volume = config.get_value("audio", "music_volume", 0.8)
	sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
	fullscreen = config.get_value("video", "fullscreen", false)
	vsync = config.get_value("video", "vsync", true)
	screen_shake = config.get_value("gameplay", "screen_shake", true)
	hit_stop_level = config.get_value("gameplay", "hit_stop_level", 1)


# === APPLY ===
func apply_all() -> void:
	_apply_audio()
	_apply_video()
	settings_changed.emit()


func _apply_audio() -> void:
	var master_idx := AudioServer.get_bus_index("Master")
	var music_idx := AudioServer.get_bus_index("Music")
	var sfx_idx := AudioServer.get_bus_index("SFX")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_volume))
		AudioServer.set_bus_mute(master_idx, master_volume <= 0.01)
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(music_volume))
		AudioServer.set_bus_mute(music_idx, music_volume <= 0.01)
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(sfx_volume))
		AudioServer.set_bus_mute(sfx_idx, sfx_volume <= 0.01)
	# Sync AudioManager vars
	if Engine.has_singleton("AudioManager") or has_node("/root/AudioManager"):
		var am = get_node_or_null("/root/AudioManager")
		if am:
			am.master_volume = master_volume
			am.music_volume = music_volume
			am.sfx_volume = sfx_volume


func _apply_video() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


# === HELPERS ===
func get_hit_stop_duration() -> float:
	match hit_stop_level:
		0: return 0.0
		1: return 0.03
		2: return 0.05
		_: return 0.03


func is_screen_shake_enabled() -> bool:
	return screen_shake
