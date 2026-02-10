# ===================================================
# HUD.gd - Heads-Up Display
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Menampilkan: Health bar, Core counter, Ability status
# ===================================================

extends CanvasLayer
class_name HUD

# Node references
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthBar/HealthLabel
@onready var core_label: Label = $MarginContainer/VBoxContainer/CoreCounter
@onready var ability_container: HBoxContainer = $MarginContainer/VBoxContainer/AbilityContainer
@onready var dash_icon: TextureRect = $MarginContainer/VBoxContainer/AbilityContainer/DashIcon if has_node("MarginContainer/VBoxContainer/AbilityContainer/DashIcon") else null
@onready var double_jump_icon: TextureRect = $MarginContainer/VBoxContainer/AbilityContainer/DoubleJumpIcon if has_node("MarginContainer/VBoxContainer/AbilityContainer/DoubleJumpIcon") else null
@onready var glide_icon: TextureRect = $MarginContainer/VBoxContainer/AbilityContainer/GlideIcon if has_node("MarginContainer/VBoxContainer/AbilityContainer/GlideIcon") else null


# Cached player reference
var _cached_player: Player = null


func _ready() -> void:
	# Connect ke GameManager signals
	if GameManager:
		GameManager.core_collected.connect(_on_core_collected)
		GameManager.ability_unlocked.connect(_on_ability_unlocked)
		GameManager.health_changed.connect(_on_gm_health_changed)
	
	# Initial update
	_update_core_counter(GameManager.cores_collected if GameManager else 0)
	_update_abilities()
	
	# Initial health from GameManager
	if GameManager:
		_update_health_bar(GameManager.player_health, GameManager.player_max_health)


func _process(_delta: float) -> void:
	# Only find player once (cache reference)
	if _cached_player == null or not is_instance_valid(_cached_player):
		_cached_player = _find_player()
		if _cached_player:
			connect_to_player(_cached_player)


func _find_player() -> Player:
	"""Cari player di scene."""
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Player
	
	# Fallback: cari manual
	var root := get_tree().current_scene
	if root:
		var player := root.find_child("Player", true, false)
		if player is Player:
			return player as Player
	
	return null


# === HEALTH BAR ===

func _update_health_bar(current: int, max_hp: int) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current
		
		# Warna berdasarkan HP
		if current < max_hp * 0.25:
			health_bar.modulate = Color(1, 0.3, 0.3)  # Merah
		elif current < max_hp * 0.5:
			health_bar.modulate = Color(1, 0.8, 0.3)  # Kuning
		else:
			health_bar.modulate = Color(0.3, 1, 0.5)  # Hijau
	
	if health_label:
		health_label.text = "%d / %d" % [current, max_hp]


func connect_to_player(player: Player) -> void:
	"""Connect ke signal player."""
	if player:
		if not player.health_changed.is_connected(_on_player_health_changed):
			player.health_changed.connect(_on_player_health_changed)
		_update_health_bar(player.current_health, player.max_health)


func _on_player_health_changed(new_health: int, max_health: int) -> void:
	_update_health_bar(new_health, max_health)


func _on_gm_health_changed(current: int, max_hp: int) -> void:
	_update_health_bar(current, max_hp)


# === CORE COUNTER ===

func _update_core_counter(count: int) -> void:
	if core_label:
		core_label.text = "CORE: %d / 5" % count
		
		# Flash effect saat collect
		var tween := create_tween()
		tween.tween_property(core_label, "modulate", Color(1, 1, 0), 0.1)
		tween.tween_property(core_label, "modulate", Color.WHITE, 0.2)


func _on_core_collected(total: int) -> void:
	_update_core_counter(total)


# === ABILITIES ===

func _update_abilities() -> void:
	"""Update tampilan ability icons."""
	if not GameManager:
		return
	
	# Update modulate based on unlock status
	# Locked = dim (0.3 alpha), Unlocked = full bright
	if dash_icon:
		dash_icon.modulate = Color(1, 1, 1, 1) if GameManager.can_dash else Color(1, 1, 1, 0.3)
	if double_jump_icon:
		double_jump_icon.modulate = Color(1, 1, 1, 1) if GameManager.can_double_jump else Color(1, 1, 1, 0.3)
	if glide_icon:
		glide_icon.modulate = Color(1, 1, 1, 1) if GameManager.can_glide else Color(1, 1, 1, 0.3)


func _on_ability_unlocked(ability_name: String) -> void:
	"""Flash ability icon saat unlock."""
	_update_abilities()
	
	# Show unlock notification
	_show_ability_unlock_notification(ability_name)


func _show_ability_unlock_notification(ability_name: String) -> void:
	"""Tampilkan notifikasi unlock."""
	var ability_display := ""
	match ability_name:
		"dash":
			ability_display = "AIR DASH"
		"double_jump":
			ability_display = "DOUBLE JUMP"
		"glide":
			ability_display = "GLIDE"
	
	print("[HUD] NEW ABILITY UNLOCKED: %s" % ability_display)
	# TODO: Tampilkan popup di layar
