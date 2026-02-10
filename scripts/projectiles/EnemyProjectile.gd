# ===================================================
# EnemyProjectile.gd - Enemy Projectile Base
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Projectile fired by enemies (Watcher Drone, etc.)
# Features:
# - Homing optional
# - Trail effect
# - Auto-destroy on collision or timeout
# ===================================================

extends Area2D
class_name EnemyProjectile

# === EXPORTS ===
@export_group("Movement")
## Movement direction (normalized)
@export var direction: Vector2 = Vector2.RIGHT
## Movement speed (pixels/sec)
@export var speed: float = 300.0
## Lifetime before auto-destroy (seconds)
@export var lifetime: float = 5.0
## Does this projectile home toward player?
@export var is_homing: bool = false
## Homing turn rate (degrees/sec)
@export var homing_strength: float = 90.0

@export_group("Damage")
## Damage dealt to player
@export var damage: int = 15
## Knockback force applied to player
@export var knockback_force: float = 150.0

@export_group("Visual")
## Trail color
@export var trail_color: Color = Color(1, 0.3, 0.3)
## Enable glow
@export var has_glow: bool = true

# === INTERNAL ===
var velocity_vec: Vector2 = Vector2.ZERO
var time_alive: float = 0.0
var target: Player = null

# Node references
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var trail: Line2D = $Trail if has_node("Trail") else null
@onready var light: PointLight2D = $PointLight2D if has_node("PointLight2D") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null


func _ready() -> void:
	# Setup collision
	collision_layer = 8  # Layer 4: Enemy projectile
	collision_mask = 3   # Mask: World (1) + Player (2)
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Initialize velocity
	velocity_vec = direction.normalized() * speed
	rotation = direction.angle()
	
	# Find player for homing
	if is_homing:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0] as Player
	
	# Setup trail
	_setup_trail()
	
	# Setup glow
	_setup_glow()
	
	# Create collision shape if not exists
	if not collision_shape:
		_create_collision()


func _create_collision() -> void:
	"""Create collision shape."""
	collision_shape = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	collision_shape.shape = circle
	add_child(collision_shape)


func _setup_trail() -> void:
	"""Setup projectile trail."""
	if not trail:
		trail = Line2D.new()
		trail.name = "Trail"
		trail.width = 3.0
		trail.default_color = trail_color
		trail.top_level = true  # Trail stays in world space
		add_child(trail)
	
	# Initialize trail points
	trail.clear_points()
	for i in range(10):
		trail.add_point(global_position)


func _setup_glow() -> void:
	"""Setup projectile glow."""
	if has_glow and not light:
		light = PointLight2D.new()
		light.color = trail_color
		light.energy = 1.5
		light.texture_scale = 0.3
		
		var light_tex := load("res://assets/sprites/effects/light_radial.png")
		if light_tex:
			light.texture = light_tex
		
		add_child(light)


func _physics_process(delta: float) -> void:
	time_alive += delta
	
	# Lifetime check
	if time_alive >= lifetime:
		_destroy()
		return
	
	# Homing behavior
	if is_homing and target and is_instance_valid(target):
		var to_target: Vector2 = (target.global_position - global_position).normalized()
		var current_dir: Vector2 = velocity_vec.normalized()
		
		# Smooth turn toward target
		var turn_amount: float = deg_to_rad(homing_strength) * delta
		var angle_to_target: float = current_dir.angle_to(to_target)
		var actual_turn: float = sign(angle_to_target) * minf(absf(angle_to_target), turn_amount)
		
		velocity_vec = velocity_vec.rotated(actual_turn)
	
	# Move
	position += velocity_vec * delta
	rotation = velocity_vec.angle()
	
	# Update trail
	_update_trail()


func _update_trail() -> void:
	"""Update trail line."""
	if not trail:
		return
	
	# Add new point at current position
	trail.add_point(global_position)
	
	# Remove old points (keep max 10)
	while trail.get_point_count() > 10:
		trail.remove_point(0)


func _on_body_entered(body: Node2D) -> void:
	"""Handle collision with physics bodies."""
	if body is Player:
		_hit_player(body as Player)
	elif body is TileMap or body is StaticBody2D:
		_hit_wall()


func _on_area_entered(area: Area2D) -> void:
	"""Handle collision with areas (player hitbox, etc.)."""
	var parent := area.get_parent()
	if parent is Player:
		_hit_player(parent as Player)


func _hit_player(player: Player) -> void:
	"""Damage player and destroy."""
	var knockback_dir := velocity_vec.normalized()
	knockback_dir.y = -0.3
	knockback_dir = knockback_dir.normalized()
	
	player.take_damage(damage, knockback_dir * knockback_force)
	
	_spawn_hit_effect()
	_destroy()


func _hit_wall() -> void:
	"""Hit wall - destroy with effect."""
	_spawn_hit_effect()
	_destroy()


func _spawn_hit_effect() -> void:
	"""Spawn particle effect on hit."""
	# Try to spawn hit particles
	var hit_scene: PackedScene = load("res://scenes/effects/HitParticles.tscn")
	if hit_scene:
		var hit: Node2D = hit_scene.instantiate()
		hit.global_position = global_position
		get_parent().add_child(hit)
	
	# Play hit sound
	AudioManager.play_sfx("hit")


func _destroy() -> void:
	"""Clean up and remove projectile."""
	# Clear trail
	if trail:
		trail.queue_free()
	
	queue_free()
