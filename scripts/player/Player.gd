# ===================================================
# Player.gd - Script Utama untuk Karakter Bip
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Kontrol player dengan State Machine, physics-based movement,
# dan kemampuan unlockable (Dash, Double Jump, Glide).
# ===================================================

extends CharacterBody2D
class_name Player

# --- SIGNALS ---
signal health_changed(new_health: int, max_health: int)
signal died
signal ability_used(ability_name: String)
signal landed

# === EXPORT VARIABLES (Tunable di Inspector) ===

@export_group("Movement")
## Kecepatan gerak horizontal maksimal
@export var move_speed: float = 200.0
## Alias untuk kompatibilitas testing
@export var speed: float = 200.0
## Akselerasi saat mulai bergerak
@export var acceleration: float = 1200.0
## Perlambatan saat berhenti (friction)
@export var friction: float = 1000.0
## Perlambatan di udara
@export var air_friction: float = 400.0

@export_group("Jump Physics - Kinematic Math")
## Tinggi lompatan dalam pixel (digunakan untuk kalkulasi)
@export var jump_height: float = 96.0
## Waktu mencapai puncak lompatan (detik) - mempengaruhi feel "floaty" vs "snappy"
@export var jump_time_to_peak: float = 0.4
## Waktu turun dari puncak (detik) - lebih kecil = lebih "snappy"
@export var jump_time_to_descent: float = 0.35
## Waktu toleransi setelah meninggalkan platform (Coyote Time)
@export var coyote_time: float = 0.12
## Waktu buffer input jump sebelum mendarat
@export var jump_buffer_time: float = 0.1
## Velocity maksimal saat jatuh
@export var max_fall_speed: float = 800.0
## Jumlah maksimal lompatan (2 = Double Jump)
@export var max_jumps: int = 2

# === CALCULATED PHYSICS (Rumus Kinematika) ===
# Rumus: v = 2h / t  (initial velocity untuk mencapai tinggi h dalam waktu t)
# Rumus: g = 2h / t² (gravitasi yang dibutuhkan)
#
# Dengan rumus ini, lompatan SELALU konsisten tingginya,
# tidak peduli frame rate atau delta time.

## Velocity lompat (dihitung dari jump_height dan jump_time_to_peak)
## Rumus: v₀ = (2 × h) / t → arah atas = negatif
@onready var jump_velocity: float = -((2.0 * jump_height) / jump_time_to_peak)
## Alias untuk kompatibilitas
@onready var jump_force: float = jump_velocity
## Gravity saat naik (dihitung dari kinematika)
## Rumus: g = (2 × h) / t²
@onready var jump_gravity: float = (2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
## Gravity saat turun - lebih besar agar jatuh lebih cepat (snappy feel)
## Rumus: g = (2 × h) / t²
@onready var fall_gravity: float = (2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)

# Jump counter untuk Double Jump
var jump_count: int = 0

@export_group("Dash Ability")
## Kecepatan dash
@export var dash_speed: float = 400.0
## Durasi dash
@export var dash_duration: float = 0.15
## Cooldown setelah dash
@export var dash_cooldown: float = 0.5

@export_group("Glide Ability")
## Gravity saat glide (lebih lambat jatuh)
@export var glide_gravity: float = 200.0
## Kecepatan jatuh maksimal saat glide
@export var glide_max_fall_speed: float = 100.0
## Multiplier gravity untuk glide (untuk testing, < 1.0)
@export var glide_gravity_multiplier: float = 0.25

@export_group("Combat")
## HP maksimal
@export var max_health: int = 100
## Durasi invincibility setelah kena hit
@export var invincibility_time: float = 1.5

@export_group("Visual Effects")
## Skala squash saat mendarat
@export var land_squash_scale: Vector2 = Vector2(1.2, 0.8)
## Skala stretch saat lompat
@export var jump_stretch_scale: Vector2 = Vector2(0.8, 1.2)
## Durasi efek squash/stretch
@export var squash_duration: float = 0.1

# === INTERNAL VARIABLES ===

# Health
var current_health: int = 100
var is_invincible: bool = false

# Ability unlock status (dikontrol oleh GameManager)
var can_dash: bool = false
var can_double_jump: bool = false
var can_glide: bool = false

# Jump tracking
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var has_double_jumped: bool = false  # Legacy, sekarang pakai jump_count

# Dash tracking
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: float = 0.0

# Glide tracking
var is_gliding: bool = false

# Facing direction
var facing_right: bool = true

# State Machine
var state_machine: PlayerStateMachine

# Node References
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var coyote_timer_node: Timer = $CoyoteTimer if has_node("CoyoteTimer") else null


func _ready() -> void:
	# Setup state machine
	state_machine = PlayerStateMachine.new()
	add_child(state_machine)
	state_machine.setup(self)
	
	# Inisialisasi health
	current_health = max_health
	
	# Sync dengan GameManager
	_sync_abilities_from_game_manager()
	
	# Connect ke GameManager signals
	if GameManager:
		GameManager.ability_unlocked.connect(_on_ability_unlocked)
	
	print("[Player] Bip siap beraksi!")


func _physics_process(delta: float) -> void:
	# Update timers
	_update_timers(delta)
	
	# Handle input & physics berdasarkan state
	if not is_dashing:
		_handle_gravity(delta)
		_handle_movement(delta)
		_handle_jump()
		_handle_dash()
		_handle_glide()
	else:
		_process_dash(delta)
	
	# Apply movement
	move_and_slide()
	
	# Update state machine
	_update_state()
	
	# Handle landing
	_check_landing()


# === GRAVITY (Variable Jump Height Algorithm) ===
# Menggunakan gravitasi berbeda untuk naik vs turun
# Ini membuat lompatan terasa lebih "game-like" dan responsive
func _handle_gravity(delta: float) -> void:
	if is_on_floor():
		# Reset jump counter saat menyentuh tanah
		jump_count = 0
		has_double_jumped = false
		return
	
	var gravity: float
	
	if is_gliding and velocity.y > 0:
		# Glide: gunakan gravity yang jauh lebih ringan
		gravity = glide_gravity
		velocity.y = min(velocity.y + gravity * delta, glide_max_fall_speed)
	elif velocity.y < 0:
		# ASCENDING (naik): gunakan jump_gravity
		# Rumus: v = v₀ + g×t dimana g = 2h/t²
		gravity = jump_gravity
		velocity.y += gravity * delta
	else:
		# DESCENDING (turun): gunakan fall_gravity yang lebih besar
		# Ini membuat karakter jatuh lebih cepat = feel lebih "snappy"
		gravity = fall_gravity
		velocity.y = min(velocity.y + gravity * delta, max_fall_speed)


# === MOVEMENT ===
func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_axis("move_left", "move_right")
	
	if input_dir != 0:
		# Akselerasi ke arah input
		var target_speed := input_dir * move_speed
		var accel := acceleration if is_on_floor() else acceleration * 0.7
		velocity.x = move_toward(velocity.x, target_speed, accel * delta)
		
		# Update facing direction
		facing_right = input_dir > 0
		if sprite:
			sprite.flip_h = not facing_right
	else:
		# Friction / perlambatan
		var fric := friction if is_on_floor() else air_friction
		velocity.x = move_toward(velocity.x, 0, fric * delta)


# === JUMP (dengan Double Jump Support) ===
func _handle_jump() -> void:
	# Jump buffer - simpan input jump untuk toleransi timing
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	
	# Reset jump count saat di tanah
	if is_on_floor():
		jump_count = 0
	
	# Execute jump jika buffer aktif
	if jump_buffer_timer > 0:
		# Kondisi 1: Lompat dari tanah (atau coyote time)
		if is_on_floor() or coyote_timer > 0:
			_execute_jump()
			jump_count = 1
			jump_buffer_timer = 0
			coyote_timer = 0
			print("[Player] Jump #1 (ground)")
		# Kondisi 2: Double jump di udara (jika unlocked dan masih ada sisa)
		elif can_double_jump and jump_count < max_jumps:
			_execute_jump()
			jump_count += 1
			has_double_jumped = true
			jump_buffer_timer = 0
			print("[Player] Jump #%d (AIR - double jump!)" % jump_count)
			AudioManager.play_sfx("double_jump")
			ability_used.emit("double_jump")


func _execute_jump() -> void:
	velocity.y = jump_force
	is_gliding = false
	
	# Visual feedback - stretch
	_apply_squash_stretch(jump_stretch_scale)
	
	# Update state
	state_machine.change_state(PlayerStateMachine.State.JUMP)


# === DASH ===
func _handle_dash() -> void:
	if not can_dash:
		return
	
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0 and not is_dashing:
		_execute_dash()


func _execute_dash() -> void:
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	is_gliding = false
	
	# Arah dash (sesuai facing atau input)
	var input_dir := Input.get_axis("move_left", "move_right")
	dash_direction = input_dir if input_dir != 0 else (1.0 if facing_right else -1.0)
	
	# Velocity dash
	velocity.x = dash_direction * dash_speed
	velocity.y = 0  # Cancel vertical velocity
	
	state_machine.change_state(PlayerStateMachine.State.DASH)
	ability_used.emit("dash")


func _process_dash(delta: float) -> void:
	dash_timer -= delta
	
	# Maintain dash velocity
	velocity.x = dash_direction * dash_speed
	velocity.y = 0
	
	if dash_timer <= 0:
		is_dashing = false
		# Kembalikan ke velocity normal
		velocity.x = dash_direction * move_speed * 0.5


# === GLIDE ===
func _handle_glide() -> void:
	if not can_glide:
		is_gliding = false
		return
	
	# Glide hanya saat jatuh dan hold jump
	if velocity.y > 0 and not is_on_floor() and Input.is_action_pressed("jump"):
		if not is_gliding:
			is_gliding = true
			state_machine.change_state(PlayerStateMachine.State.GLIDE)
			ability_used.emit("glide")
	else:
		is_gliding = false


# === TIMERS ===
func _update_timers(delta: float) -> void:
	# Coyote time
	if is_on_floor():
		coyote_timer = coyote_time
		has_double_jumped = false
	else:
		coyote_timer = max(0, coyote_timer - delta)
	
	# Jump buffer
	jump_buffer_timer = max(0, jump_buffer_timer - delta)
	
	# Dash cooldown
	dash_cooldown_timer = max(0, dash_cooldown_timer - delta)


# === STATE UPDATE ===
func _update_state() -> void:
	if is_dashing:
		return  # State sudah di-handle di dash
	
	if is_gliding:
		return  # State sudah di-handle di glide
	
	if is_on_floor():
		if abs(velocity.x) > 10:
			state_machine.change_state(PlayerStateMachine.State.RUN)
		else:
			state_machine.change_state(PlayerStateMachine.State.IDLE)
	else:
		if velocity.y < 0:
			state_machine.change_state(PlayerStateMachine.State.JUMP)
		else:
			state_machine.change_state(PlayerStateMachine.State.FALL)


# === LANDING DETECTION ===
var was_on_floor: bool = false

func _check_landing() -> void:
	if is_on_floor() and not was_on_floor:
		_on_land()
	was_on_floor = is_on_floor()


func _on_land() -> void:
	"""Dipanggil saat mendarat."""
	# Visual feedback - squash
	_apply_squash_stretch(land_squash_scale)
	landed.emit()


# === VISUAL EFFECTS ===
func _apply_squash_stretch(target_scale: Vector2) -> void:
	if not sprite:
		return
	
	# Tween untuk squash/stretch
	var tween := create_tween()
	tween.tween_property(sprite, "scale", target_scale, squash_duration * 0.5)
	tween.tween_property(sprite, "scale", Vector2.ONE, squash_duration * 0.5)


# === COMBAT ===
func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	"""Dipanggil saat player kena damage."""
	if is_invincible:
		return
	
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	# Knockback
	if knockback_dir != Vector2.ZERO:
		velocity = knockback_dir * 200
	
	# Invincibility frames
	is_invincible = true
	state_machine.change_state(PlayerStateMachine.State.HURT)
	
	# Flash effect (sederhana)
	_flash_sprite()
	
	# Timer untuk reset invincibility
	await get_tree().create_timer(invincibility_time).timeout
	is_invincible = false
	
	# Cek kematian
	if current_health <= 0:
		_die()


func heal(amount: int) -> void:
	"""Heal player."""
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)


func _flash_sprite() -> void:
	"""Efek flash saat kena damage."""
	if not sprite:
		return
	
	for i in range(5):
		sprite.modulate.a = 0.3
		await get_tree().create_timer(0.1).timeout
		sprite.modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout


func _die() -> void:
	"""Player mati."""
	state_machine.change_state(PlayerStateMachine.State.DEAD)
	died.emit()
	
	# Notify GameManager
	if GameManager:
		GameManager.player_died.emit()


# === ABILITY SYNC ===
func _sync_abilities_from_game_manager() -> void:
	"""Sync status ability dari GameManager.
	
	PENTING: Fungsi ini memastikan Player instance baru
	mendapatkan semua ability yang sudah di-unlock.
	"""
	if GameManager:
		can_dash = GameManager.can_dash
		can_double_jump = GameManager.can_double_jump
		can_glide = GameManager.can_glide
		
		# CRITICAL: Sync max_jumps berdasarkan double jump status!
		if can_double_jump:
			max_jumps = 2
			jump_height = 110.0  # Buff untuk double jump
			# Recalculate physics karena jump_height berubah
			jump_velocity = -((2.0 * jump_height) / jump_time_to_peak)
			jump_force = jump_velocity
			jump_gravity = (2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
			fall_gravity = (2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)
			print("[Player] Double Jump SYNCED: max_jumps=%d, jump_height=%.1f" % [max_jumps, jump_height])
		else:
			max_jumps = 1
		
		print("[Player] Abilities synced: dash=%s, double_jump=%s, glide=%s" % [can_dash, can_double_jump, can_glide])


func _on_ability_unlocked(ability_name: String) -> void:
	"""Dipanggil saat ability baru di-unlock."""
	match ability_name:
		"dash":
			can_dash = true
		"double_jump":
			can_double_jump = true
		"glide":
			can_glide = true
	print("[Player] Ability unlocked: %s" % ability_name)


# === PUBLIC METHODS (untuk testing) ===
func get_current_state() -> String:
	return state_machine.get_state_name()


func is_ability_unlocked(ability_name: String) -> bool:
	match ability_name:
		"dash":
			return can_dash
		"double_jump":
			return can_double_jump
		"glide":
			return can_glide
		_:
			return false


func unlock_ability(ability_name: String) -> void:
	"""Unlock ability (untuk testing)."""
	match ability_name:
		"dash":
			can_dash = true
		"double_jump":
			can_double_jump = true
		"glide":
			can_glide = true


func get_health() -> int:
	return current_health


func get_max_health() -> int:
	return max_health


func reset_player() -> void:
	"""Reset player ke kondisi awal."""
	current_health = max_health
	velocity = Vector2.ZERO
	is_invincible = false
	is_dashing = false
	is_gliding = false
	has_double_jumped = false
	state_machine.reset()
	health_changed.emit(current_health, max_health)
