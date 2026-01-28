# ===================================================
# EnemyBase.gd - Base Class untuk Semua Musuh
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Semua musuh mewarisi class ini. Berisi:
# - Health system
# - Damage dealing
# - State machine dasar
# - Deteksi player
# ===================================================

extends CharacterBody2D
class_name EnemyBase

# --- SIGNALS ---
signal died
signal health_changed(current: int, max_health: int)
signal player_detected(player: Player)
signal player_lost

# === EXPORT VARIABLES ===

@export_group("Health")
## HP maksimal musuh
@export var max_health: int = 50
## Drop health pickup saat mati?
@export var drops_health: bool = false

@export_group("Combat")
## Damage yang diberikan ke player saat kontak
@export var contact_damage: int = 15
## Knockback yang diberikan ke player
@export var knockback_force: float = 200.0
## Cooldown antara hit
@export var attack_cooldown: float = 1.0

@export_group("Movement")
## Kecepatan gerak dasar
@export var move_speed: float = 80.0
## Gravitasi (untuk ground enemies)
@export var gravity: float = 800.0

@export_group("Detection")
## Jarak deteksi player
@export var detection_range: float = 200.0
## Jarak kehilangan player
@export var lose_range: float = 300.0

# === ENUM STATE ===
enum State {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	HURT,
	DEAD
}

# === INTERNAL VARIABLES ===
var current_health: int
var current_state: State = State.IDLE
var facing_right: bool = true
var can_attack: bool = true
var target_player: Player = null
var is_dead: bool = false

# Node references
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var hitbox: Area2D = $Hitbox if has_node("Hitbox") else null
@onready var detection_area: Area2D = $DetectionArea if has_node("DetectionArea") else null


func _ready() -> void:
	current_health = max_health
	
	# Setup hitbox
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)
	
	# Setup detection
	if detection_area:
		detection_area.body_entered.connect(_on_detection_body_entered)
		detection_area.body_exited.connect(_on_detection_body_exited)
	
	# Collision setup
	collision_layer = 2  # Layer 2: Enemy
	collision_mask = 5   # Mask 1+4: Player + Environment
	
	_on_ready()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# State-based behavior
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.PATROL:
			_process_patrol(delta)
		State.CHASE:
			_process_chase(delta)
		State.ATTACK:
			_process_attack(delta)
		State.HURT:
			_process_hurt(delta)
	
	move_and_slide()
	_update_facing()


# === VIRTUAL METHODS (Override di subclass) ===

func _on_ready() -> void:
	"""Override untuk setup tambahan di subclass."""
	pass


func _process_idle(_delta: float) -> void:
	"""Override untuk behavior idle."""
	velocity.x = 0


func _process_patrol(_delta: float) -> void:
	"""Override untuk behavior patrol."""
	pass


func _process_chase(_delta: float) -> void:
	"""Override untuk behavior chase player."""
	pass


func _process_attack(_delta: float) -> void:
	"""Override untuk behavior attack."""
	pass


func _process_hurt(_delta: float) -> void:
	"""Override untuk behavior saat kena hit."""
	velocity.x = move_toward(velocity.x, 0, 200 * _delta)


# === DAMAGE & HEALTH ===

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	"""Musuh menerima damage."""
	if is_dead:
		return
	
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	# Knockback
	if knockback_dir != Vector2.ZERO:
		velocity = knockback_dir * 150
	
	# State change
	current_state = State.HURT
	_flash_damage()
	
	# Check death
	if current_health <= 0:
		_die()
	else:
		# Return to chase after hurt
		await get_tree().create_timer(0.3).timeout
		if not is_dead:
			current_state = State.CHASE if target_player else State.PATROL


func _flash_damage() -> void:
	"""Flash merah saat kena damage."""
	if not sprite:
		return
	
	sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	if sprite:
		sprite.modulate = Color.WHITE


func _die() -> void:
	"""Musuh mati."""
	is_dead = true
	current_state = State.DEAD
	velocity = Vector2.ZERO
	
	died.emit()
	
	# Death animation
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)
	else:
		queue_free()


# === CONTACT DAMAGE ===

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is Player and can_attack:
		_deal_damage_to_player(body as Player)


func _deal_damage_to_player(player: Player) -> void:
	if not can_attack:
		return
	
	# Hitung knockback direction
	var knockback_dir := (player.global_position - global_position).normalized()
	knockback_dir.y = -0.5
	knockback_dir = knockback_dir.normalized()
	
	player.take_damage(contact_damage, knockback_dir * knockback_force)
	
	# Cooldown
	can_attack = false
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


# === DETECTION ===

func _on_detection_body_entered(body: Node2D) -> void:
	if body is Player:
		target_player = body as Player
		current_state = State.CHASE
		player_detected.emit(target_player)


func _on_detection_body_exited(body: Node2D) -> void:
	if body is Player:
		target_player = null
		current_state = State.PATROL
		player_lost.emit()


# === FACING ===

func _update_facing() -> void:
	if velocity.x > 0:
		facing_right = true
	elif velocity.x < 0:
		facing_right = false
	
	if sprite:
		sprite.flip_h = not facing_right


# === STATE HELPERS ===

func change_state(new_state: State) -> void:
	current_state = new_state


func get_direction_to_player() -> Vector2:
	if target_player:
		return (target_player.global_position - global_position).normalized()
	return Vector2.ZERO
