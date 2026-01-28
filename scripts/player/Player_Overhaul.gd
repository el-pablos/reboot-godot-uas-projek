# ===================================================
# Player.gd - OVERHAULED Modern Precision Platformer
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Features:
# - Kinematic-based jump physics (Celeste-style)
# - Coyote Time & Jump Buffer
# - Variable Jump Height (tap vs hold)
# - Fast Fall (asymmetric gravity)
# - Squash & Stretch visual feedback
# - Ghost Trail Dash
# - Robust ability sync with GameManager
# ===================================================

extends CharacterBody2D
# Original class_name: Player (removed to avoid conflict)

# === SIGNALS ===
signal health_changed(new_health: int, max_health: int)
signal died
signal ability_used(ability_name: String)
signal landed(impact_velocity: float)
signal jumped(jump_number: int)

# === MOVEMENT PHYSICS ===
@export_group("Movement")
@export var move_speed: float = 220.0
@export var acceleration: float = 1400.0  # Ground acceleration
@export var air_acceleration: float = 1000.0  # Air control
@export var friction: float = 1200.0  # Ground friction
@export var air_friction: float = 200.0  # Air drag (minimal)
@export var turn_speed_multiplier: float = 2.0  # Faster turning

# Alias for compatibility
var speed: float:
	get: return move_speed

# === JUMP PHYSICS (Kinematic Formula) ===
@export_group("Jump Physics")
@export var jump_height: float = 96.0  # Peak height in pixels
@export var jump_time_to_peak: float = 0.38  # Time to reach peak
@export var jump_time_to_descent: float = 0.28  # Time to fall (faster = snappy)
@export var max_fall_speed: float = 900.0
@export var max_jumps: int = 2  # 1 = single, 2 = double jump

# Calculated physics (call _recalculate_jump_physics() after changing)
var jump_velocity: float
var jump_gravity: float  # Gravity while ascending
var fall_gravity: float  # Gravity while descending (heavier)

# Alias
var jump_force: float:
	get: return jump_velocity

# === ADVANCED JUMP MECHANICS ===
@export_group("Advanced Jump")
@export var coyote_time: float = 0.12  # Grace period after leaving platform
@export var jump_buffer_time: float = 0.15  # Pre-land jump input buffer
@export var variable_jump_multiplier: float = 0.4  # Velocity cut when releasing early
@export var apex_gravity_multiplier: float = 0.5  # Floatier at apex

# === DASH ABILITY ===
@export_group("Dash")
@export var dash_speed: float = 450.0
@export var dash_duration: float = 0.12
@export var dash_cooldown: float = 0.3
@export var dash_ghost_count: int = 4  # Number of ghost images

# === GLIDE ABILITY ===
@export_group("Glide")
@export var glide_gravity: float = 150.0
@export var glide_max_fall_speed: float = 80.0
@export var glide_horizontal_boost: float = 1.2  # Slight speed boost while gliding

# === COMBAT ===
@export_group("Combat")
@export var max_health: int = 100
@export var invincibility_duration: float = 1.5
@export var knockback_force: float = 300.0

# === VISUAL FEEDBACK ===
@export_group("Juice")
@export var squash_scale: Vector2 = Vector2(1.25, 0.75)
@export var stretch_scale: Vector2 = Vector2(0.75, 1.25)
@export var squash_duration: float = 0.08
@export var land_particles_threshold: float = 300.0  # Min velocity for dust

# === INTERNAL STATE ===
var current_health: int = 100
var is_invincible: bool = false
var facing_right: bool = true

# Ability flags (synced from GameManager)
var can_dash: bool = false
var can_double_jump: bool = false
var can_glide: bool = false

# Jump tracking
var jumps_left: int = 0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_jump_held: bool = false
var was_on_floor: bool = false

# Dash tracking
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

# Glide tracking
var is_gliding: bool = false

# State machine
var state_machine: PlayerStateMachine

# === NODE REFERENCES ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var dust_particles: GPUParticles2D = $DustParticles if has_node("DustParticles") else null
@onready var ghost_timer: Timer = $GhostTimer if has_node("GhostTimer") else null


# =========================================
# INITIALIZATION
# =========================================

func _ready() -> void:
	# Add to player group
	add_to_group("player")
	
	# Calculate jump physics
	_recalculate_jump_physics()
	
	# Setup state machine
	state_machine = PlayerStateMachine.new()
	add_child(state_machine)
	state_machine.setup(self)
	
	# Initialize health
	current_health = max_health
	
	# CRITICAL: Sync with GameManager (Source of Truth)
	_sync_from_game_manager()
	
	# Connect to ability unlock signal
	if GameManager:
		GameManager.ability_unlocked.connect(_on_ability_unlocked)
		GameManager.player_stats_changed.connect(_sync_from_game_manager)
	
	print("[Player] 🤖 Bip ready! max_jumps=%d, can_double_jump=%s" % [max_jumps, can_double_jump])


func _recalculate_jump_physics() -> void:
	"""Calculate physics values from designer-friendly parameters.
	
	Using kinematic equations:
	- v₀ = 2h / t (initial velocity to reach height h in time t)
	- g = 2h / t² (gravity needed for that trajectory)
	"""
	jump_velocity = -((2.0 * jump_height) / jump_time_to_peak)
	jump_gravity = (2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
	fall_gravity = (2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)
	
	# Debug output
	# print("[Player] Physics: v=%.1f, g_up=%.1f, g_down=%.1f" % [jump_velocity, jump_gravity, fall_gravity])


func _sync_from_game_manager() -> void:
	"""Sync abilities and stats from GameManager (Source of Truth)."""
	if not GameManager:
		return
	
	var stats: Dictionary = GameManager.get_player_stats()
	can_dash = stats.can_dash
	can_double_jump = stats.can_double_jump
	can_glide = stats.can_glide
	max_jumps = stats.max_jumps
	
	# Recalculate physics if jump height changed
	if can_double_jump and jump_height < 110.0:
		jump_height = 110.0
		_recalculate_jump_physics()
	
	print("[Player] 📊 Synced: dash=%s, double_jump=%s (max_jumps=%d), glide=%s" % [
		can_dash, can_double_jump, max_jumps, can_glide
	])


# =========================================
# PHYSICS PROCESS
# =========================================

func _physics_process(delta: float) -> void:
	# Update timers
	_update_timers(delta)
	
	# Store floor state for landing detection
	var on_floor := is_on_floor()
	
	# Process based on current action
	if is_dashing:
		_process_dash(delta)
	else:
		_apply_gravity(delta)
		_handle_movement(delta)
		_handle_jump()
		_handle_dash_input()
		_handle_glide()
	
	# Apply movement
	move_and_slide()
	
	# Update state machine
	_update_state()
	
	# Check for landing
	_check_landing(on_floor)
	
	was_on_floor = on_floor


# =========================================
# GRAVITY (Asymmetric for Snappy Feel)
# =========================================

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		# Reset jumps when grounded
		jumps_left = max_jumps
		return
	
	var gravity: float
	
	if is_gliding and velocity.y > 0:
		# Gliding: very light gravity
		gravity = glide_gravity
		velocity.y = minf(velocity.y + gravity * delta, glide_max_fall_speed)
	elif velocity.y < 0:
		# ASCENDING: Check for variable jump (early release)
		if not is_jump_held and velocity.y < jump_velocity * variable_jump_multiplier:
			# Player released jump early - cut velocity for short hop
			velocity.y = maxf(velocity.y, jump_velocity * variable_jump_multiplier)
		
		# Near apex? Use lighter gravity for floatier feel
		if absf(velocity.y) < 50.0:
			gravity = jump_gravity * apex_gravity_multiplier
		else:
			gravity = jump_gravity
		
		velocity.y += gravity * delta
	else:
		# DESCENDING: Heavier gravity for snappy fall
		gravity = fall_gravity
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)


# =========================================
# MOVEMENT (Acceleration-based)
# =========================================

func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_axis("move_left", "move_right")
	var on_floor := is_on_floor()
	
	if input_dir != 0.0:
		# Determine acceleration based on ground/air and turning
		var accel: float
		var target_speed := input_dir * move_speed
		
		# Boost acceleration when turning (snappier direction changes)
		var is_turning := signf(velocity.x) != signf(input_dir) and absf(velocity.x) > 10.0
		
		if on_floor:
			accel = acceleration * (turn_speed_multiplier if is_turning else 1.0)
		else:
			accel = air_acceleration * (turn_speed_multiplier if is_turning else 1.0)
			# Apply glide horizontal boost
			if is_gliding:
				target_speed *= glide_horizontal_boost
		
		velocity.x = move_toward(velocity.x, target_speed, accel * delta)
		
		# Update facing
		facing_right = input_dir > 0
		if sprite:
			sprite.flip_h = not facing_right
	else:
		# Apply friction
		var fric := friction if on_floor else air_friction
		velocity.x = move_toward(velocity.x, 0.0, fric * delta)


# =========================================
# JUMP (Coyote Time + Buffer + Variable Height)
# =========================================

func _handle_jump() -> void:
	# Track jump button state for variable height
	is_jump_held = Input.is_action_pressed("jump")
	
	# Buffer jump input
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	
	# Can we execute a jump?
	if jump_buffer_timer > 0:
		var on_floor := is_on_floor()
		var has_coyote := coyote_timer > 0
		var can_ground_jump := on_floor or has_coyote
		var can_air_jump := can_double_jump and jumps_left > 0 and not can_ground_jump
		
		if can_ground_jump:
			# Ground jump (or coyote)
			_execute_jump(1)
			coyote_timer = 0
		elif can_air_jump:
			# Air jump (double jump)
			_execute_jump(max_jumps - jumps_left + 1)


func _execute_jump(jump_number: int) -> void:
	velocity.y = jump_velocity
	jumps_left -= 1
	jump_buffer_timer = 0
	is_gliding = false
	
	# Visual feedback
	_apply_stretch()
	
	# State & signals
	state_machine.change_state(PlayerStateMachine.State.JUMP)
	jumped.emit(jump_number)
	
	# Audio
	if jump_number == 1:
		AudioManager.play_sfx("jump")
		print("[Player] 🦘 Jump #1 (ground)")
	else:
		AudioManager.play_sfx("double_jump")
		ability_used.emit("double_jump")
		print("[Player] 🦘 Jump #%d (AIR)" % jump_number)


# =========================================
# DASH (with Ghost Trail)
# =========================================

func _handle_dash_input() -> void:
	if not can_dash:
		return
	
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
		_execute_dash()


func _execute_dash() -> void:
	is_dashing = true
	is_gliding = false
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	
	# Dash direction (input or facing)
	var input := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	
	if input.length() > 0.1:
		dash_direction = input.normalized()
	else:
		dash_direction = Vector2(1.0 if facing_right else -1.0, 0.0)
	
	# Set velocity
	velocity = dash_direction * dash_speed
	
	# Start ghost trail
	_spawn_ghost_trail()
	
	state_machine.change_state(PlayerStateMachine.State.DASH)
	ability_used.emit("dash")
	AudioManager.play_sfx("dash")
	print("[Player] 💨 Dash!")


func _process_dash(delta: float) -> void:
	dash_timer -= delta
	
	# Maintain dash velocity
	velocity = dash_direction * dash_speed
	
	if dash_timer <= 0:
		is_dashing = false
		# Preserve some momentum
		velocity = dash_direction * move_speed * 0.6


func _spawn_ghost_trail() -> void:
	"""Spawn ghost images behind player during dash."""
	if not sprite:
		return
	
	for i in range(dash_ghost_count):
		# Create ghost sprite
		var ghost := Sprite2D.new()
		ghost.texture = sprite.texture
		ghost.flip_h = sprite.flip_h
		ghost.global_position = global_position
		ghost.modulate = Color(0.5, 0.8, 1.0, 0.6)  # Cyan tint
		ghost.z_index = -1
		
		# Add to scene tree (parent of player)
		get_parent().add_child(ghost)
		
		# Fade out and delete
		var tween := ghost.create_tween()
		tween.tween_property(ghost, "modulate:a", 0.0, dash_duration)
		tween.tween_callback(ghost.queue_free)


# =========================================
# GLIDE
# =========================================

func _handle_glide() -> void:
	if not can_glide:
		is_gliding = false
		return
	
	# Glide when falling and holding jump
	if velocity.y > 0 and not is_on_floor() and Input.is_action_pressed("jump"):
		if not is_gliding:
			is_gliding = true
			state_machine.change_state(PlayerStateMachine.State.GLIDE)
			ability_used.emit("glide")
			# print("[Player] 🪂 Gliding!")
	else:
		if is_gliding:
			is_gliding = false


# =========================================
# TIMERS
# =========================================

func _update_timers(delta: float) -> void:
	# Coyote time (grace period after leaving platform)
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)
	
	# Jump buffer
	jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)
	
	# Dash cooldown
	dash_cooldown_timer = maxf(0.0, dash_cooldown_timer - delta)


# =========================================
# STATE UPDATES
# =========================================

func _update_state() -> void:
	if is_dashing or is_gliding:
		return
	
	if is_on_floor():
		if absf(velocity.x) > 10.0:
			state_machine.change_state(PlayerStateMachine.State.RUN)
		else:
			state_machine.change_state(PlayerStateMachine.State.IDLE)
	else:
		if velocity.y < 0:
			state_machine.change_state(PlayerStateMachine.State.JUMP)
		else:
			state_machine.change_state(PlayerStateMachine.State.FALL)


# =========================================
# LANDING DETECTION
# =========================================

func _check_landing(currently_on_floor: bool) -> void:
	if currently_on_floor and not was_on_floor:
		_on_land()


func _on_land() -> void:
	var impact := absf(velocity.y) if was_on_floor == false else 0.0
	
	# Visual feedback
	_apply_squash()
	
	# Particles for hard landings
	if impact > land_particles_threshold:
		_spawn_dust_particles()
	
	# Audio
	AudioManager.play_sfx("land")
	
	landed.emit(impact)


# =========================================
# VISUAL EFFECTS (Squash & Stretch)
# =========================================

func _apply_squash() -> void:
	if not sprite:
		return
	
	var tween := create_tween()
	tween.tween_property(sprite, "scale", squash_scale, squash_duration * 0.4)
	tween.tween_property(sprite, "scale", Vector2.ONE, squash_duration * 0.6)


func _apply_stretch() -> void:
	if not sprite:
		return
	
	var tween := create_tween()
	tween.tween_property(sprite, "scale", stretch_scale, squash_duration * 0.4)
	tween.tween_property(sprite, "scale", Vector2.ONE, squash_duration * 0.6)


func _spawn_dust_particles() -> void:
	if dust_particles:
		dust_particles.restart()
		dust_particles.emitting = true


# =========================================
# COMBAT
# =========================================

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if is_invincible:
		return
	
	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	# Knockback
	if knockback_dir != Vector2.ZERO:
		velocity = knockback_dir.normalized() * knockback_force
	
	# Invincibility frames
	_start_invincibility()
	
	# State
	state_machine.change_state(PlayerStateMachine.State.HURT)
	AudioManager.play_sfx("hurt")
	
	# Check death
	if current_health <= 0:
		_die()


func _start_invincibility() -> void:
	is_invincible = true
	
	# Flash effect
	if sprite:
		var tween := create_tween()
		tween.set_loops(int(invincibility_duration / 0.1))
		tween.tween_property(sprite, "modulate:a", 0.3, 0.05)
		tween.tween_property(sprite, "modulate:a", 1.0, 0.05)
	
	# Timer to end invincibility
	await get_tree().create_timer(invincibility_duration).timeout
	is_invincible = false


func heal(amount: int) -> void:
	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


func _die() -> void:
	state_machine.change_state(PlayerStateMachine.State.DEAD)
	died.emit()
	AudioManager.play_sfx("death")
	
	if GameManager:
		GameManager.damage_player(max_health)  # Trigger game over


# =========================================
# ABILITY CALLBACKS
# =========================================

func _on_ability_unlocked(ability_name: String) -> void:
	match ability_name:
		"dash":
			can_dash = true
		"double_jump":
			can_double_jump = true
			max_jumps = 2
			jump_height = 110.0
			_recalculate_jump_physics()
		"glide":
			can_glide = true
	
	print("[Player] ✨ Ability unlocked: %s" % ability_name)


# =========================================
# PUBLIC API
# =========================================

func get_current_state() -> String:
	return state_machine.get_state_name() if state_machine else "UNKNOWN"

func is_ability_unlocked(ability_name: String) -> bool:
	match ability_name:
		"dash": return can_dash
		"double_jump": return can_double_jump
		"glide": return can_glide
		_: return false
