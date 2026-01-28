# ===================================================
# LevelBase.gd - Script Dasar untuk Semua Level
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Semua level mewarisi script ini. Berisi logika:
# - Spawn point
# - Killzone
# - Level completion
# - Parallax background
# ===================================================

extends Node2D
class_name LevelBase

# --- SIGNALS ---
signal level_started
signal level_completed
signal player_respawned

# === EXPORT VARIABLES ===

@export_group("Level Info")
## Nama level untuk display
@export var level_name: String = "Level"
## Deskripsi singkat level
@export var level_description: String = ""
## Path ke level selanjutnya
@export var next_level_path: String = ""

@export_group("Spawn Settings")
## Posisi spawn player
@export var spawn_position: Vector2 = Vector2(100, 100)
## Offset spawn setelah respawn
@export var respawn_offset: Vector2 = Vector2(0, -20)

@export_group("Killzone")
## Y position di bawah mana player mati (jatuh ke void)
@export var killzone_y: float = 800.0

@export_group("Background")
## Warna background default
@export var background_color: Color = Color(0.15, 0.2, 0.3)

# === INTERNAL ===
var player: Player
var is_level_completed: bool = false


func _ready() -> void:
	# Set background color
	RenderingServer.set_default_clear_color(background_color)
	
	# Cari atau spawn player
	_setup_player()
	
	# Connect signals
	_connect_signals()
	
	# Notify level started
	level_started.emit()
	print("[Level] %s dimulai!" % level_name)


func _physics_process(_delta: float) -> void:
	# Cek killzone
	if player and player.global_position.y > killzone_y:
		_on_player_fell()


func _setup_player() -> void:
	"""Setup player di level."""
	# Cari player yang sudah ada
	player = get_node_or_null("Player") as Player
	
	if not player:
		# Spawn player baru
		var player_scene := preload("res://scenes/player/Player.tscn")
		player = player_scene.instantiate()
		add_child(player)
	
	# Set posisi spawn
	player.global_position = spawn_position
	print("[Level] Player spawned di: %s" % spawn_position)


func _connect_signals() -> void:
	"""Connect signal player."""
	if player:
		if not player.died.is_connected(_on_player_died):
			player.died.connect(_on_player_died)


func _on_player_fell() -> void:
	"""Player jatuh ke void."""
	if player:
		player.take_damage(player.max_health)  # Instant kill


func _on_player_died() -> void:
	"""Player mati, respawn."""
	print("[Level] Player mati! Respawning...")
	
	# Tunggu sebentar
	await get_tree().create_timer(1.0).timeout
	
	# Respawn
	_respawn_player()


func _respawn_player() -> void:
	"""Respawn player di spawn point."""
	if player:
		player.global_position = spawn_position + respawn_offset
		player.reset_player()
		player_respawned.emit()
		print("[Level] Player respawned di: %s" % player.global_position)


func complete_level() -> void:
	"""Dipanggil saat level selesai (sentuh goal/kalahkan boss)."""
	if is_level_completed:
		return
	
	is_level_completed = true
	level_completed.emit()
	
	# Notify GameManager
	if GameManager:
		GameManager.complete_level(level_name)
	
	print("[Level] %s COMPLETED!" % level_name)
	
	# Pindah ke level selanjutnya
	if next_level_path != "":
		await get_tree().create_timer(2.0).timeout
		GameManager.change_level(next_level_path)


func get_player() -> Player:
	"""Getter untuk player."""
	return player
