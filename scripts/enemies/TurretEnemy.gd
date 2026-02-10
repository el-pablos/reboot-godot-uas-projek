# ===================================================
# TurretEnemy.gd - THE TURRET (Static Defense)
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Static enemy mounted on walls or ceilings.
# Behavior:
# - Stays in place, rotates to track player
# - Uses laser sight (Line2D) to telegraph attacks
# - Fires after charge delay, giving player time to dodge
# - Cannot be stunned, high armor
# ===================================================

extends SmartEnemy
class_name TurretEnemy

# === TURRET-SPECIFIC EXPORTS ===
@export_group("Turret Settings")
## Maximum rotation angle (degrees from starting direction)
@export var max_rotation: float = 90.0
## Rotation speed (degrees per second)
@export var rotation_speed: float = 60.0
## Starting aim direction (use for wall/ceiling mounting)
@export var base_direction: Vector2 = Vector2.DOWN

@export_group("Laser Attack")
## Time laser is visible before firing (telegraph)
@export var laser_charge_time: float = 1.2
## Duration of laser beam (damage window)
@export var laser_duration: float = 0.3
## Cooldown between laser attacks
@export var laser_cooldown: float = 2.5
## Laser beam damage
@export var laser_damage: int = 25
## Laser detection range
@export var laser_range: float = 400.0

@export_group("Visual")
## Color of targeting laser (before firing)
@export var targeting_color: Color = Color(1, 0, 0, 0.4)
## Color of active laser (firing)
@export var active_laser_color: Color = Color(1, 0.2, 0.2, 1.0)
## Laser beam width
@export var laser_width: float = 4.0

# === INTERNAL ===
var current_aim_angle: float = 0.0
var target_aim_angle: float = 0.0
var is_charging_laser: bool = false
var is_firing_laser: bool = false
var laser_timer: float = 0.0

# Node references
@onready var turret_head: Node2D = $TurretHead if has_node("TurretHead") else null
@onready var laser_line: Line2D = $LaserLine if has_node("LaserLine") else null
@onready var laser_raycast: RayCast2D = $LaserRayCast if has_node("LaserRayCast") else null
@onready var laser_light: PointLight2D = $LaserLight if has_node("LaserLight") else null


func _on_enemy_ready() -> void:
	"""Turret-specific setup."""
	# Turrets don't move
	gravity = 0.0
	patrol_speed = 0.0
	chase_speed = 0.0
	
	# High health, armored
	max_health = 80
	current_health = max_health
	contact_damage = 0  # No contact damage
	
	# Can't be knocked back
	knockback_force = 0.0
	
	# Start in idle (scanning mode)
	change_state(State.IDLE)
	
	# Setup laser systems
	_setup_laser()
	
	print("[Turret] %s initialized - Static laser turret" % name)


func _setup_laser() -> void:
	"""Setup laser line and raycast."""
	# Create laser line if not exists
	if not laser_line:
		laser_line = Line2D.new()
		laser_line.name = "LaserLine"
		laser_line.width = laser_width
		laser_line.default_color = targeting_color
		laser_line.add_point(Vector2.ZERO)
		laser_line.add_point(Vector2(laser_range, 0))
		laser_line.visible = false
		add_child(laser_line)
	
	# Create laser raycast for hit detection
	if not laser_raycast:
		laser_raycast = RayCast2D.new()
		laser_raycast.name = "LaserRayCast"
		laser_raycast.enabled = true
		laser_raycast.target_position = Vector2(laser_range, 0)
		laser_raycast.collision_mask = 3  # World + Player
		add_child(laser_raycast)
	
	# Create laser light effect
	if not laser_light:
		laser_light = PointLight2D.new()
		laser_light.name = "LaserLight"
		laser_light.color = Color(1, 0.2, 0.2)
		laser_light.energy = 0.0
		laser_light.texture_scale = 0.3
		
		var light_tex := load("res://assets/sprites/effects/light_radial.png")
		if light_tex:
			laser_light.texture = light_tex
		
		add_child(laser_light)


func _apply_gravity(_delta: float) -> void:
	"""Override: Turrets are static, no gravity."""
	velocity = Vector2.ZERO


func _state_idle(delta: float) -> void:
	"""Scanning mode - slowly rotate looking for player."""
	# Slow scan rotation
	current_aim_angle += rotation_speed * 0.3 * delta
	if current_aim_angle > max_rotation:
		current_aim_angle = -max_rotation
	
	# Apply rotation to turret head
	_apply_rotation()
	
	# Check for player in vision
	if can_see_player:
		change_state(State.CHASE)


func _state_chase(delta: float) -> void:
	"""Tracking mode - follow player and prepare to fire."""
	if not target_player or not can_see_player:
		change_state(State.SEARCH)
		return
	
	# Calculate angle to player
	var to_player: Vector2 = target_player.global_position - global_position
	target_aim_angle = rad_to_deg(to_player.angle()) - rad_to_deg(base_direction.angle())
	
	# Clamp to rotation limits
	target_aim_angle = clampf(target_aim_angle, -max_rotation, max_rotation)
	
	# Rotate toward player
	var angle_diff: float = target_aim_angle - current_aim_angle
	var rotate_amount: float = sign(angle_diff) * minf(absf(angle_diff), rotation_speed * delta)
	current_aim_angle += rotate_amount
	
	_apply_rotation()
	
	# Start charging if aimed at player and cooldown ready
	if absf(angle_diff) < 5 and attack_cooldown_timer <= 0:
		_start_laser_charge()


func _start_laser_charge() -> void:
	"""Begin charging laser."""
	is_charging_laser = true
	laser_timer = 0.0
	change_state(State.ATTACK)
	
	# Show targeting laser
	if laser_line:
		laser_line.visible = true
		laser_line.default_color = targeting_color
		laser_line.width = laser_width * 0.5
	
	# Play charge sound
	AudioManager.play_sfx("laser_charge")
	
	print("[Turret] %s: Charging laser..." % name)


func _state_attack(delta: float) -> void:
	"""Charging and firing laser."""
	laser_timer += delta
	
	# Continue tracking player during charge (slower)
	if target_player and is_charging_laser:
		var to_player: Vector2 = target_player.global_position - global_position
		target_aim_angle = rad_to_deg(to_player.angle()) - rad_to_deg(base_direction.angle())
		target_aim_angle = clampf(target_aim_angle, -max_rotation, max_rotation)
		
		var angle_diff: float = target_aim_angle - current_aim_angle
		var rotate_amount: float = sign(angle_diff) * minf(absf(angle_diff), rotation_speed * 0.3 * delta)
		current_aim_angle += rotate_amount
		_apply_rotation()
	
	# Update laser visual during charge
	if is_charging_laser:
		var charge_progress: float = laser_timer / laser_charge_time
		
		if laser_line:
			# Laser gets brighter and wider as it charges
			var alpha: float = 0.4 + charge_progress * 0.4
			laser_line.default_color = Color(1, 0, 0, alpha)
			laser_line.width = laser_width * (0.5 + charge_progress * 0.5)
		
		if laser_light:
			laser_light.energy = charge_progress * 1.5
		
		# Fire when fully charged
		if laser_timer >= laser_charge_time:
			_fire_laser()
	
	# Laser is firing
	elif is_firing_laser:
		# Update laser hit detection
		_update_laser_damage()
		
		# Laser beam visual
		if laser_line:
			laser_line.default_color = active_laser_color
			laser_line.width = laser_width * 2.0
		
		if laser_light:
			laser_light.energy = 3.0
		
		# End laser after duration
		if laser_timer >= laser_charge_time + laser_duration:
			_end_laser()


func _fire_laser() -> void:
	"""Fire the laser beam."""
	is_charging_laser = false
	is_firing_laser = true
	
	# Play fire sound
	AudioManager.play_sfx("laser_fire")
	
	# Screen shake
	var camera := get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(6.0, 0.1)
	
	print("[Turret] %s: FIRE!" % name)


func _update_laser_damage() -> void:
	"""Check if laser is hitting player."""
	if not laser_raycast:
		return
	
	laser_raycast.force_raycast_update()
	
	if laser_raycast.is_colliding():
		var collider := laser_raycast.get_collider()
		
		# Update laser line end point to collision
		if laser_line:
			var hit_point: Vector2 = laser_raycast.get_collision_point()
			var local_point: Vector2 = to_local(hit_point)
			laser_line.set_point_position(1, local_point)
		
		# Damage player
		if collider is Player and attack_cooldown_timer <= 0:
			var player := collider as Player
			var knockback_dir := laser_raycast.target_position.normalized()
			player.take_damage(laser_damage, knockback_dir * 100)
			attack_cooldown_timer = 0.2  # Brief cooldown to prevent multi-hit
	else:
		# No collision - extend to full range
		if laser_line:
			laser_line.set_point_position(1, Vector2(laser_range, 0))


func _end_laser() -> void:
	"""End laser firing."""
	is_firing_laser = false
	is_charging_laser = false
	attack_cooldown_timer = laser_cooldown
	
	# Hide laser
	if laser_line:
		laser_line.visible = false
	
	if laser_light:
		laser_light.energy = 0.0
	
	change_state(State.CHASE if can_see_player else State.IDLE)
	
	print("[Turret] %s: Laser cooldown" % name)


func _state_search(delta: float) -> void:
	"""Lost target - scan for player."""
	# Slowly scan back and forth
	current_aim_angle += rotation_speed * 0.5 * delta * patrol_direction
	
	if current_aim_angle >= max_rotation or current_aim_angle <= -max_rotation:
		patrol_direction *= -1
	
	_apply_rotation()
	
	# Check for player
	if can_see_player:
		change_state(State.CHASE)
		return
	
	# Return to idle after search duration
	if search_timer <= 0:
		change_state(State.IDLE)


func _apply_rotation() -> void:
	"""Apply rotation to turret head and laser."""
	var aim_rad: float = deg_to_rad(current_aim_angle) + base_direction.angle()
	
	if turret_head:
		turret_head.rotation = aim_rad
	
	if laser_line:
		laser_line.rotation = aim_rad
	
	if laser_raycast:
		laser_raycast.target_position = Vector2(laser_range, 0).rotated(aim_rad)
	
	if vision_raycast:
		vision_raycast.target_position = Vector2(vision_range, 0).rotated(aim_rad)


func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	"""Override: Turrets can't be knocked back."""
	if is_dead:
		return
	
	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	took_damage.emit(amount, knockback_dir)
	
	# No knockback, no stun - just flash
	_flash_damage()
	
	# Cancel charging on damage
	if is_charging_laser:
		is_charging_laser = false
		laser_timer = 0.0
		if laser_line:
			laser_line.visible = false
		if laser_light:
			laser_light.energy = 0.0
		change_state(State.CHASE)
	
	AudioManager.play_sfx("enemy_hit")
	
	if current_health <= 0:
		_die()


func _spawn_death_effect() -> void:
	"""Override: Big explosion for turret."""
	var explosion_scene := load("res://scenes/effects/ExplosionParticles.tscn")
	if explosion_scene:
		var explosion := explosion_scene.instantiate()
		explosion.global_position = global_position
		# Make explosion bigger for turret
		if explosion.has_method("set_scale"):
			explosion.scale = Vector2(1.5, 1.5)
		get_parent().add_child(explosion)
	
	# Big screen shake
	var camera := get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(12.0, 0.3)
