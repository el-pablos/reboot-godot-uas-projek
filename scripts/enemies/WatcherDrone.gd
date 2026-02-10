# ===================================================
# WatcherDrone.gd - THE WATCHER (Flying Drone)
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Flying enemy that patrols in sine wave patterns.
# Behavior:
# - Floats in sine wave motion
# - Stops and aims when player spotted
# - Fires projectiles with telegraph warning
# - Retreats if player gets too close
# ===================================================

extends SmartEnemy
class_name WatcherDrone

# === WATCHER-SPECIFIC EXPORTS ===
@export_group("Flight Pattern")
## Amplitude of sine wave motion
@export var hover_amplitude: float = 30.0
## Frequency of sine wave (cycles per second)
@export var hover_frequency: float = 1.5
## Horizontal patrol speed
@export var flight_speed: float = 40.0

@export_group("Projectile Attack")
## Projectile scene to instantiate
@export var projectile_scene: PackedScene
## Time to charge before firing (telegraph)
@export var charge_time: float = 0.8
## Projectile speed
@export var projectile_speed: float = 300.0
## Time between shots
@export var fire_rate: float = 2.0
## Maximum firing range
@export var fire_range: float = 300.0
## Minimum safe distance (retreats if player closer)
@export var retreat_distance: float = 80.0

# === INTERNAL ===
var base_y: float = 0.0
var hover_time: float = 0.0
var is_charging_shot: bool = false
var charge_progress: float = 0.0
var aim_direction: Vector2 = Vector2.RIGHT

# Node references
@onready var muzzle: Marker2D = $Muzzle if has_node("Muzzle") else null
@onready var charge_light: PointLight2D = $ChargeLight if has_node("ChargeLight") else null
@onready var aim_line: Line2D = $AimLine if has_node("AimLine") else null


func _on_enemy_ready() -> void:
	"""Watcher-specific setup."""
	# Store starting Y for hover calculations
	base_y = global_position.y
	
	# Drones don't take fall damage
	gravity = 0.0
	
	# Lower health, ranged attacker
	max_health = 30
	current_health = max_health
	contact_damage = 10
	
	# Create aim line if not exists
	if not aim_line:
		_create_aim_line()
	
	# Create charge light if not exists
	if not charge_light:
		_create_charge_light()
	
	# Set projectile scene if not set
	if not projectile_scene:
		projectile_scene = load("res://scenes/projectiles/EnemyProjectile.tscn")
	
	print("[Watcher] %s initialized - Flying drone with projectiles" % name)


func _create_aim_line() -> void:
	"""Create laser sight line for aiming."""
	aim_line = Line2D.new()
	aim_line.name = "AimLine"
	aim_line.width = 2.0
	aim_line.default_color = Color(1, 0, 0, 0.3)
	aim_line.add_point(Vector2.ZERO)
	aim_line.add_point(Vector2(fire_range, 0))
	aim_line.visible = false
	add_child(aim_line)


func _create_charge_light() -> void:
	"""Create light that glows during charge."""
	charge_light = PointLight2D.new()
	charge_light.name = "ChargeLight"
	charge_light.color = Color(1, 0.3, 0.3)
	charge_light.energy = 0.0
	charge_light.texture_scale = 0.5
	
	# Try to load light texture
	var light_tex := load("res://assets/sprites/effects/light_radial.png")
	if light_tex:
		charge_light.texture = light_tex
	
	add_child(charge_light)


func _apply_gravity(_delta: float) -> void:
	"""Override: No gravity for flying enemies."""
	# Hover in sine wave pattern
	hover_time += _delta * hover_frequency * TAU
	var hover_offset: float = sin(hover_time) * hover_amplitude
	
	# Smoothly move to target Y
	var target_y: float = base_y + hover_offset
	velocity.y = (target_y - global_position.y) * 5.0


func _state_patrol(_delta: float) -> void:
	"""Override: Patrol with sine wave hover."""
	# Horizontal movement
	velocity.x = patrol_direction * flight_speed
	
	# Turn at level boundaries (use X position check if no walls)
	if wall_check and wall_check.is_colliding():
		patrol_direction *= -1
	
	# Random direction changes
	if rng.randf() < 0.002:
		patrol_direction *= -1
	
	# Random pauses
	if rng.randf() < 0.001:
		change_state(State.IDLE)
	
	# Check for player
	if can_see_player:
		change_state(State.CHASE)


func _state_chase(_delta: float) -> void:
	"""Override: Stop and aim at player, maintaining distance."""
	if not target_player or not can_see_player:
		change_state(State.SEARCH)
		return
	
	var distance: float = global_position.distance_to(target_player.global_position)
	var to_player: Vector2 = (target_player.global_position - global_position).normalized()
	
	# Retreat if too close
	if distance < retreat_distance:
		velocity.x = -to_player.x * chase_speed
		# Update base_y to current position for smooth retreat
		base_y = global_position.y
	# In firing range - stop and aim
	elif distance < fire_range:
		velocity.x = move_toward(velocity.x, 0, flight_speed * 2 * _delta)
		
		# Start charging if not already
		if not is_charging_shot and attack_cooldown_timer <= 0:
			_start_charge()
	# Too far - approach
	else:
		velocity.x = to_player.x * flight_speed * 0.5


func _start_charge() -> void:
	"""Start charging a shot."""
	is_charging_shot = true
	charge_progress = 0.0
	change_state(State.ATTACK)
	
	# Show aim line
	if aim_line:
		aim_line.visible = true
	
	# Play charge sound
	AudioManager.play_sfx("laser_charge")
	
	print("[Watcher] %s: Charging shot..." % name)


func _state_attack(delta: float) -> void:
	"""Override: Charge and fire projectile."""
	if not is_charging_shot:
		change_state(State.CHASE)
		return
	
	# Stop moving during attack
	velocity.x = move_toward(velocity.x, 0, 200 * delta)
	
	# Update aim direction
	if target_player:
		aim_direction = (target_player.global_position - global_position).normalized()
		
		# Update aim line
		if aim_line:
			aim_line.rotation = aim_direction.angle()
			# Aim line gets brighter as charge progresses
			aim_line.default_color = Color(1, 0, 0, 0.3 + charge_progress * 0.5)
			aim_line.width = 2.0 + charge_progress * 3.0
	
	# Increase charge
	charge_progress += delta / charge_time
	
	# Update charge light
	if charge_light:
		charge_light.energy = charge_progress * 2.0
	
	# Fire when fully charged!
	if charge_progress >= 1.0:
		_fire_projectile()


func _fire_projectile() -> void:
	"""Fire a projectile at the player."""
	is_charging_shot = false
	charge_progress = 0.0
	attack_cooldown_timer = fire_rate
	
	# Hide aim line
	if aim_line:
		aim_line.visible = false
		aim_line.default_color = Color(1, 0, 0, 0.3)
		aim_line.width = 2.0
	
	# Reset charge light
	if charge_light:
		charge_light.energy = 0.0
	
	# Spawn projectile
	if projectile_scene:
		var projectile := projectile_scene.instantiate()
		projectile.global_position = muzzle.global_position if muzzle else global_position
		projectile.direction = aim_direction
		projectile.speed = projectile_speed
		projectile.damage = contact_damage
		get_parent().add_child(projectile)
		
		print("[Watcher] %s: FIRE!" % name)
	
	# Play fire sound
	AudioManager.play_sfx("laser_fire")
	
	# Small recoil
	velocity.x = -aim_direction.x * 50
	
	change_state(State.CHASE)


func _state_idle(_delta: float) -> void:
	"""Override: Hover in place during idle."""
	velocity.x = move_toward(velocity.x, 0, flight_speed * 2 * _delta)
	
	# Random look around
	if rng.randf() < 0.01:
		facing_right = not facing_right
	
	# Check for player
	if can_see_player:
		change_state(State.CHASE)
		return
	
	# Return to patrol
	if state_timer >= idle_duration:
		change_state(State.PATROL)


func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	"""Override: Cancel charging on damage."""
	is_charging_shot = false
	charge_progress = 0.0
	
	if aim_line:
		aim_line.visible = false
	if charge_light:
		charge_light.energy = 0.0
	
	super.take_damage(amount, knockback_dir)


func _spawn_death_effect() -> void:
	"""Override: Aerial explosion with sparks."""
	var explosion_scene := load("res://scenes/effects/ExplosionParticles.tscn")
	if explosion_scene:
		var explosion := explosion_scene.instantiate()
		explosion.global_position = global_position
		get_parent().add_child(explosion)
	
	# Slight screen shake
	var camera := get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(5.0, 0.15)
