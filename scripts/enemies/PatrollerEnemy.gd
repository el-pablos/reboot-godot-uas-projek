# ===================================================
# PatrollerEnemy.gd - THE PATROLLER (Ground Robot)
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Ground-based robot guard that patrols platforms.
# Behavior:
# - Walks back and forth on platforms
# - Sprints toward player when spotted
# - Charges and rams player for contact damage
# - Turns at edges to avoid falling
# ===================================================

extends SmartEnemy
class_name PatrollerEnemy

# === PATROLLER-SPECIFIC EXPORTS ===
@export_group("Patroller Behavior")
## Speed multiplier when sprinting toward player
@export var sprint_multiplier: float = 1.8
## Distance at which patroller starts sprinting
@export var sprint_trigger_distance: float = 150.0
## Charge duration before stopping
@export var charge_duration: float = 0.5
## Cooldown after charge attack
@export var charge_cooldown: float = 1.5

# === INTERNAL ===
var is_sprinting: bool = false
var is_charging: bool = false
var charge_timer: float = 0.0
var charge_direction: float = 0.0


func _on_enemy_ready() -> void:
	## Patroller-specific setup.
	# Ensure we have edge detection
	use_edge_detection = true
	
	# Higher contact damage during charge
	contact_damage = 20
	
	# Medium speed robot
	patrol_speed = 50.0
	chase_speed = 100.0
	sprint_speed = 180.0
	
	print("[Patroller] %s initialized - Ground patrol robot" % name)


func _state_chase(_delta: float) -> void:
	## Override: Sprint toward player when in range.
	if not target_player:
		change_state(State.SEARCH)
		return
	
	var distance: float = global_position.distance_to(target_player.global_position)
	var direction: float = sign(target_player.global_position.x - global_position.x)
	
	# Sprint if close enough
	if distance < sprint_trigger_distance:
		is_sprinting = true
		velocity.x = direction * sprint_speed
	else:
		is_sprinting = false
		velocity.x = direction * chase_speed
	
	# Check for edge while chasing
	if ground_check and not ground_check.is_colliding() and is_on_floor():
		# Stop at edge, don't fall!
		velocity.x = 0
		is_sprinting = false
	
	# Check for wall
	if wall_check and wall_check.is_colliding():
		velocity.x = 0
		is_sprinting = false
	
	# Initiate charge attack if very close
	if distance < 50 and attack_cooldown_timer <= 0:
		_start_charge(direction)


func _start_charge(direction: float) -> void:
	## Start charge attack.
	is_charging = true
	charge_direction = direction
	charge_timer = charge_duration
	change_state(State.ATTACK)
	
	# Boost damage during charge
	contact_damage = 30
	
	print("[Patroller] %s: CHARGING!" % name)


func _state_attack(delta: float) -> void:
	## Override: Charge attack behavior.
	if not is_charging:
		# Normal attack, return to chase
		if state_timer >= 0.3:
			change_state(State.CHASE)
		return
	
	# Charge forward!
	velocity.x = charge_direction * sprint_speed * 1.2
	charge_timer -= delta
	
	# Check for wall collision during charge
	if wall_check and wall_check.is_colliding():
		_end_charge()
		return
	
	# Check for edge during charge
	if ground_check and not ground_check.is_colliding() and is_on_floor():
		_end_charge()
		return
	
	# Charge complete
	if charge_timer <= 0:
		_end_charge()


func _end_charge() -> void:
	## End charge attack.
	is_charging = false
	is_sprinting = false
	contact_damage = 20  # Reset damage
	attack_cooldown_timer = charge_cooldown
	
	# Brief stun after charge
	stun_timer = 0.3
	change_state(State.STUNNED)
	
	print("[Patroller] %s: Charge ended" % name)


func _state_patrol(_delta: float) -> void:
	## Override: Patrol with edge awareness.
	# Use edge detection for patrol
	_patrol_edge_detection(_delta)
	
	# Occasionally pause
	if rng.randf() < 0.002:  # ~0.2% chance per frame
		change_state(State.IDLE)
	
	# Check for player
	if can_see_player:
		change_state(State.CHASE)


func _on_hitbox_body_entered(body: Node2D) -> void:
	## Override: Extra damage during charge.
	if body is Player and not is_dead:
		if is_charging:
			# Bigger knockback during charge
			var player := body as Player
			var knockback_dir := (player.global_position - global_position).normalized()
			knockback_dir.y = -0.5  # More upward knockback
			player.take_damage(contact_damage, knockback_dir * knockback_force * 1.5)
			_end_charge()
		else:
			_deal_contact_damage(body as Player)


func _spawn_death_effect() -> void:
	## Override: Ground explosion.
	# Sparks and debris
	var explosion_scene: PackedScene = load("res://scenes/effects/ExplosionParticles.tscn")
	if explosion_scene:
		var explosion: Node2D = explosion_scene.instantiate()
		explosion.global_position = global_position
		get_parent().add_child(explosion)
	
	# Screen shake on death
	var camera := get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(8.0, 0.2)
