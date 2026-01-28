# ===================================================
# AudioManager.gd - Autoload untuk Manajemen Audio
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Mengelola semua audio: musik, SFX, volume settings.
# Mendukung pemanggilan SFX via String name (smart dictionary).
# ===================================================

extends Node
class_name AudioManagerClass

# --- AUDIO BUSES ---
const MASTER_BUS: String = "Master"
const MUSIC_BUS: String = "Music"
const SFX_BUS: String = "SFX"

# --- AUDIO PLAYERS ---
var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS: int = 8  # Pool untuk SFX simultaneous

# --- VOLUME (0.0 - 1.0) ---
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0

# --- SFX LIBRARY (Smart Dictionary System) ---
# Mapping nama SFX ke path file. File akan di-load saat pertama kali dipanggil.
const SFX_PATHS: Dictionary = {
	"collect": "res://assets/audio/sfx/collect.wav",
	"jump": "res://assets/audio/sfx/jump.wav",
	"hit": "res://assets/audio/sfx/hit.wav",
	"dash": "res://assets/audio/sfx/dash.wav",
	"double_jump": "res://assets/audio/sfx/double_jump.wav",
	"land": "res://assets/audio/sfx/land.wav",
	"hurt": "res://assets/audio/sfx/hurt.wav",
	"death": "res://assets/audio/sfx/death.wav",
	"boss_hit": "res://assets/audio/sfx/boss_hit.wav",
	"level_complete": "res://assets/audio/sfx/level_complete.wav",
	"menu_select": "res://assets/audio/sfx/menu_select.wav",
	"menu_confirm": "res://assets/audio/sfx/menu_confirm.wav"
}

# Cache untuk SFX yang sudah di-load
var sfx_cache: Dictionary = {}


func _ready() -> void:
	# Setup music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = MUSIC_BUS
	add_child(music_player)
	
	# Setup SFX player pool
	for i in range(MAX_SFX_PLAYERS):
		var sfx_player := AudioStreamPlayer.new()
		sfx_player.bus = SFX_BUS
		add_child(sfx_player)
		sfx_players.append(sfx_player)
	
	print("[AudioManager] Audio system ready! Pool SFX: %d" % MAX_SFX_PLAYERS)


# === MUSIK ===
func play_music(stream: AudioStream, fade_in: float = 0.5) -> void:
	"""Mainkan musik dengan fade in."""
	if music_player.stream == stream and music_player.playing:
		return  # Musik sama sudah main
	
	music_player.stream = stream
	music_player.volume_db = -80.0
	music_player.play()
	
	# Fade in
	var tween := create_tween()
	tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), fade_in)
	print("[AudioManager] Playing music: %s" % stream.resource_path if stream else "null")


func stop_music(fade_out: float = 0.5) -> void:
	"""Stop musik dengan fade out."""
	var tween := create_tween()
	tween.tween_property(music_player, "volume_db", -80.0, fade_out)
	tween.tween_callback(music_player.stop)


# === SFX ===
func play_sfx(sfx_name_or_stream, volume_scale: float = 1.0) -> void:
	"""Mainkan SFX. Mendukung String (nama SFX) atau AudioStream langsung.
	
	Contoh penggunaan:
		AudioManager.play_sfx(\"collect\")  # Dari library
		AudioManager.play_sfx(my_stream)   # AudioStream langsung
	"""
	var stream: AudioStream = null
	
	# Handle jika input adalah String (nama SFX dari library)
	if sfx_name_or_stream is String:
		var sfx_name: String = sfx_name_or_stream
		stream = _get_sfx_from_library(sfx_name)
		if stream == null:
			push_warning("[AudioManager] SFX '%s' tidak ditemukan di library!" % sfx_name)
			return
	# Handle jika input adalah AudioStream langsung
	elif sfx_name_or_stream is AudioStream:
		stream = sfx_name_or_stream
	else:
		push_warning("[AudioManager] play_sfx: Invalid argument type")
		return
	
	# Mainkan SFX menggunakan pool
	_play_sfx_stream(stream, volume_scale)


func _get_sfx_from_library(sfx_name: String) -> AudioStream:
	"""Ambil SFX dari library. Load dan cache jika belum ada."""
	# Cek cache dulu
	if sfx_cache.has(sfx_name):
		return sfx_cache[sfx_name]
	
	# Cek apakah nama ada di library
	if not SFX_PATHS.has(sfx_name):
		return null
	
	# Load file dan cache
	var path: String = SFX_PATHS[sfx_name]
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream:
			sfx_cache[sfx_name] = stream
			return stream
	
	# File tidak ada - ini normal jika placeholder belum dibuat
	print("[AudioManager] SFX file not found (placeholder needed): %s" % path)
	return null


func _play_sfx_stream(stream: AudioStream, volume_scale: float) -> void:
	"""Internal: Mainkan AudioStream menggunakan pool player."""
	if stream == null:
		return
	
	# Cari player yang tidak sedang main
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = linear_to_db(sfx_volume * volume_scale)
			player.play()
			return
	
	# Semua player sibuk, paksa player pertama
	sfx_players[0].stream = stream
	sfx_players[0].volume_db = linear_to_db(sfx_volume * volume_scale)
	sfx_players[0].play()


func play_sfx_by_path(path: String, volume_scale: float = 1.0) -> void:
	"""Mainkan SFX dari path resource. Gunakan cache."""
	if not sfx_cache.has(path):
		if not ResourceLoader.exists(path):
			push_warning("[AudioManager] SFX tidak ditemukan: %s" % path)
			return
		var stream = load(path)
		if stream:
			sfx_cache[path] = stream
		else:
			push_warning("[AudioManager] Gagal load SFX: %s" % path)
			return
	
	_play_sfx_stream(sfx_cache[path], volume_scale)


# === VOLUME CONTROLS ===
func set_master_volume(value: float) -> void:
	"""Set master volume (0.0 - 1.0)."""
	master_volume = clamp(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index(MASTER_BUS),
		linear_to_db(master_volume)
	)


func set_music_volume(value: float) -> void:
	"""Set music volume (0.0 - 1.0)."""
	music_volume = clamp(value, 0.0, 1.0)
	music_player.volume_db = linear_to_db(music_volume)


func set_sfx_volume(value: float) -> void:
	"""Set SFX volume (0.0 - 1.0)."""
	sfx_volume = clamp(value, 0.0, 1.0)
