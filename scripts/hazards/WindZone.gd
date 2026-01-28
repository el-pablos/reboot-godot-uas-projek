# ===================================================
# WindZone.gd - Zona Angin untuk Level Storm
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Area yang mendorong player ke arah tertentu.
# ===================================================

extends Area2D
class_name WindZone

@export_group("Wind Settings")
## Arah angin (akan di-normalize)
@export var wind_direction: Vector2 = Vector2(1, 0)
## Kekuatan dorong angin
@export var wind_force: float = 300.0
## Apakah angin konstan atau berfluktuasi?
@export var fluctuating: bool = false
## Interval fluktuasi (detik)
@export var fluctuation_interval: float = 2.0

# Internal
var current_force: float = 0.0
var bodies_in_zone: Array[CharacterBody2D] = []
var is_active: bool = true


func _ready() -> void:
	wind_direction = wind_direction.normalized()
	current_force = wind_force
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Set collision
	collision_layer = 64  # Layer 7: Trigger
	collision_mask = 1    # Mask 1: Player
	
	# Start fluctuation jika enabled
	if fluctuating:
		_start_fluctuation()


func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	# Apply wind ke semua body di zone
	for body in bodies_in_zone:
		if body is Player:
			var player := body as Player
			player.velocity += wind_direction * current_force * delta


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		bodies_in_zone.append(body as CharacterBody2D)


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		bodies_in_zone.erase(body as CharacterBody2D)


func _start_fluctuation() -> void:
	while true:
		await get_tree().create_timer(fluctuation_interval).timeout
		
		# Random force antara 50% - 150%
		current_force = wind_force * randf_range(0.5, 1.5)


func set_active(active: bool) -> void:
	is_active = active


func set_wind_direction(direction: Vector2) -> void:
	wind_direction = direction.normalized()
