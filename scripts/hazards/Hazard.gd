# ===================================================
# Hazard.gd - Script Dasar untuk Semua Hazard
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Base class untuk hazard: spikes, lava, laser, dll.
# ===================================================

extends Area2D
class_name Hazard

@export_group("Damage")
## Damage yang diberikan ke player
@export var damage: int = 25
## Knockback direction (normalized)
@export var knockback_force: float = 200.0
## Apakah instant kill?
@export var instant_kill: bool = false

@export_group("Timing")
## Cooldown antara hit (untuk hazard yang tetap aktif)
@export var damage_cooldown: float = 1.0

var can_damage: bool = true


func _ready() -> void:
	# Connect signal
	body_entered.connect(_on_body_entered)
	
	# Set collision
	collision_layer = 8  # Layer 4: Hazard
	collision_mask = 1   # Mask 1: Player


func _on_body_entered(body: Node2D) -> void:
	if body is Player and can_damage:
		_apply_damage(body as Player)


func _apply_damage(player: Player) -> void:
	if not can_damage:
		return
	
	var damage_amount := player.max_health if instant_kill else damage
	
	# Hitung knockback direction
	var knockback_dir := (player.global_position - global_position).normalized()
	knockback_dir.y = -0.5  # Selalu sedikit ke atas
	knockback_dir = knockback_dir.normalized() * knockback_force
	
	player.take_damage(damage_amount, knockback_dir)
	
	# Cooldown
	can_damage = false
	await get_tree().create_timer(damage_cooldown).timeout
	can_damage = true
