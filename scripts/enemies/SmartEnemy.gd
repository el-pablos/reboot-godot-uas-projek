# ===================================================
# SmartEnemy.gd - SMART ENEMY SYSTEM (THE GRAND OVERHAUL)
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Advanced AI Architecture using Finite State Machine (FSM):
# - States: IDLE, PATROL, SEARCH, CHASE, ATTACK, STUNNED, DEAD
# - RayCast2D for line-of-sight detection (no magic knowing)
# - Area2D for hearing (footsteps, gunfire)
# - Random behavior variations for organic feel
# - Knockback and stun mechanics
# ===================================================

extends CharacterBody2D
class_name SmartEnemy

# === SIGNALS ===
signal died
signal health_changed(current: int, maximum: int)
signal player_spotted(player: Node)  # Use Node to avoid circular dependency with Player class
signal player_lost
signal state_changed(new_state: State)
signal took_damage(amount: int, from_direction: Vector2)

# === AI STATES ===
enum State {
	IDLE,       # Diam, menunggu/istirahat
	PATROL,     # Berpatroli di jalur
	SEARCH,     # Mencari player yang hilang
	CHASE,      # Mengejar player
	ATTACK,     # Menyerang player
	STUNNED,    # Terkena knockback/stun
	DEAD        # Mati
}

# === EXPORT: STATS ===
@export_group("Stats")
@export var max_health: int = 50
@export var contact_damage: int = 15
@export var knockback_force: float = 250.0

# === EXPORT: MOVEMENT ===
@export_group("Movement")
@export var patrol_speed: float = 60.0
@export var chase_speed: float = 120.0
@export var sprint_speed: float = 180.0  # For aggressive chase
@export var gravity: float = 980.0
@export var turn_delay: float = 0.2  # Delay before turning (more realistic)

# === EXPORT: DETECTION (AI SENSES) ===
@export_group("AI Senses")
## Visual detection range (RayCast length)
@export var vision_range: float = 250.0
## Vision cone angle (degrees from forward)
@export var vision_angle: float = 45.0
## Hearing range (Area2D radius) - detects player actions
@export var hearing_range: float = 150.0
## How long to search after losing sight (seconds)
@export var search_duration: float = 3.0
## Time to lose interest and return to patrol
@export var attention_span: float = 5.0

# === EXPORT: BEHAVIOR RANDOMIZATION ===
@export_group("Behavior RNG")
## Min time spent idle before patrol
@export var idle_time_min: float = 1.0
## Max time spent idle
@export var idle_time_max: float = 4.0
## Chance to look around during idle (0-1)
@export var idle_look_chance: float = 0.3

# === EXPORT: PATROL ===
@export_group("Patrol")
## Patrol waypoints (if empty, uses edge detection)
@export var patrol_points: Array[Vector2] = []
## Current patrol point index
@export var use_edge_detection: bool = true

# === INTERNAL STATE ===
var current_health: int = 0
var current_state: State = State.IDLE
var previous_state: State = State.IDLE
var target_player: Player = null
var last_known_player_pos: Vector2 = Vector2.ZERO
var facing_right: bool = true
var is_dead: bool = false

# Timers
var state_timer: float = 0.0
var stun_timer: float = 0.0
var attack_cooldown_timer: float = 0.0
var search_timer: float = 0.0
var idle_duration: float = 2.0  # Randomized

# Patrol state
var patrol_index: int = 0
var patrol_direction: int = 1

# Detection state
var can_see_player: bool = false
var heard_player: bool = false
var alert_level: float = 0.0  # 0-1, increases when hearing player

# RNG
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# === NODE REFERENCES ===
@onready var sprite: Node2D = _find_sprite()
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var hitbox: Area2D = $Hitbox if has_node("Hitbox") else null
@onready var vision_raycast: RayCast2D = $VisionRayCast if has_node("VisionRayCast") else null
@onready var ground_check: RayCast2D = $GroundCheck if has_node("GroundCheck") else null
@onready var wall_check: RayCast2D = $WallCheck if has_node("WallCheck") else null
@onready var hearing_area: Area2D = $HearingArea if has_node("HearingArea") else null
@onready var eye_light: PointLight2D = $EyeLight if has_node("EyeLight") else null


# =========================================
# INITIALIZATION
# =========================================

func _ready() -> void:
	# Initialize RNG
	rng.randomize()
	
	# Initialize health
	current_health = max_health
	
	# Setup collision layers
	collision_layer = 4  # Layer 3: Enemy (bit 2 = 4)
	collision_mask = 3   # Mask: World (1) + Player (2)
	
	# Add to enemy group
	add_to_group("enemies")
	
	# Connect signals
	_setup_hitbox()
	_setup_hearing()
	_create_vision_raycast()
	_create_edge_detection()
	
	# Start with random idle duration
	idle_duration = rng.randf_range(idle_time_min, idle_time_max)
	
	# Call virtual ready
	_on_enemy_ready()
	
	print("[Enemy] %s spawned with %d HP" % [name, max_health])


func _find_sprite() -> Node2D:
	## Find sprite node (Sprite2D or AnimatedSprite2D).
	if has_node("AnimatedSprite2D"):
		return $AnimatedSprite2D
	elif has_node("Sprite2D"):
		return $Sprite2D
	return null


func _setup_hitbox() -> void:
	## Setup hitbox for dealing contact damage.
	if hitbox:
		if not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
			hitbox.body_entered.connect(_on_hitbox_body_entered)


func _setup_hearing() -> void:
	## Setup hearing area for detecting player sounds.
	if hearing_area:
		if not hearing_area.body_entered.is_connected(_on_hearing_body_entered):
			hearing_area.body_entered.connect(_on_hearing_body_entered)
		if not hearing_area.body_exited.is_connected(_on_hearing_body_exited):
			hearing_area.body_exited.connect(_on_hearing_body_exited)
	else:
		_create_hearing_area()


func _create_vision_raycast() -> void:
	## Create RayCast2D for line-of-sight detection if not exists.
	if not vision_raycast:
		vision_raycast = RayCast2D.new()
		vision_raycast.name = "VisionRayCast"
		vision_raycast.enabled = true
		vision_raycast.target_position = Vector2(vision_range, 0)
		vision_raycast.collision_mask = 3  # Player + World
		add_child(vision_raycast)


func _create_edge_detection() -> void:
	## Create raycasts for edge/wall detection if not exists.
	if not ground_check and use_edge_detection:
		ground_check = RayCast2D.new()
		ground_check.name = "GroundCheck"
		ground_check.enabled = true
		ground_check.target_position = Vector2(20, 30)  # Ahead and down
		ground_check.collision_mask = 1  # World only
		add_child(ground_check)
	
	if not wall_check:
		wall_check = RayCast2D.new()
		wall_check.name = "WallCheck"
		wall_check.enabled = true
		wall_check.target_position = Vector2(15, 0)  # Ahead
		wall_check.collision_mask = 1  # World only
		add_child(wall_check)


func _create_hearing_area() -> void:
	## Create hearing area for detecting nearby player.
	hearing_area = Area2D.new()
	hearing_area.name = "HearingArea"
	
	var hearing_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = hearing_range
	hearing_shape.shape = circle
	
	hearing_area.add_child(hearing_shape)
	add_child(hearing_area)
	
	hearing_area.body_entered.connect(_on_hearing_body_entered)
	hearing_area.body_exited.connect(_on_hearing_body_exited)


# =========================================
# PHYSICS PROCESS (MAIN LOOP)
# =========================================

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Update timers
	_update_timers(delta)
	
	# Apply gravity for ground enemies
	_apply_gravity(delta)
	
	# Vision check (RayCast line-of-sight)
	_update_vision()
	
	# Process current state
	_process_state(delta)
	
	# Apply movement
	move_and_slide()
	
	# Update visual facing
	_update_facing()
	
	# Update eye light color based on state
	_update_eye_light()


func _update_timers(delta: float) -> void:
	## Update all internal timers.
	state_timer += delta
	
	if stun_timer > 0:
		stun_timer -= delta
	
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	
	if search_timer > 0:
		search_timer -= delta


func _apply_gravity(delta: float) -> void:
	## Apply gravity. Override in flying enemies.
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 800.0)
	else:
		velocity.y = 0


# =========================================
# VISION SYSTEM (LINE OF SIGHT)
# =========================================

func _update_vision() -> void:
	## Check if player is visible via RayCast.
	if not vision_raycast:
		return
	
	# Update raycast direction based on facing
	var look_direction := Vector2(vision_range if facing_right else -vision_range, 0)
	vision_raycast.target_position = look_direction
	
	# Also update edge detection direction
	if ground_check:
		ground_check.target_position = Vector2(20 if facing_right else -20, 30)
	if wall_check:
		wall_check.target_position = Vector2(15 if facing_right else -15, 0)
	
	# Force raycast update
	vision_raycast.force_raycast_update()
	
	var old_can_see := can_see_player
	can_see_player = false
	
	if vision_raycast.is_colliding():
		var collider := vision_raycast.get_collider()
		if collider is Player:
			# Check if player is within vision angle
			var to_player: Vector2 = (collider.global_position - global_position).normalized()
			var forward := Vector2(1 if facing_right else -1, 0)
			var angle := rad_to_deg(forward.angle_to(to_player))
			
			if absf(angle) <= vision_angle:
				can_see_player = true
				target_player = collider as Player
				last_known_player_pos = target_player.global_position
				
				# First time spotting player
				if not old_can_see:
					player_spotted.emit(target_player)
					_on_player_spotted()
	
	# Lost sight of player
	if old_can_see and not can_see_player:
		_on_player_lost_sight()


func _on_player_spotted() -> void:
	## Called when player is first spotted.
	if current_state in [State.IDLE, State.PATROL, State.SEARCH]:
		change_state(State.CHASE)
		alert_level = 1.0
		print("[Enemy] %s: Player spotted! Engaging." % name)


func _on_player_lost_sight() -> void:
	## Called when player is no longer visible.
	if current_state == State.CHASE:
		change_state(State.SEARCH)
		search_timer = search_duration
		print("[Enemy] %s: Lost visual. Searching..." % name)


# =========================================
# STATE MACHINE
# =========================================

func _process_state(delta: float) -> void:
	## Process behavior based on current state.
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.PATROL:
			_state_patrol(delta)
		State.SEARCH:
			_state_search(delta)
		State.CHASE:
			_state_chase(delta)
		State.ATTACK:
			_state_attack(delta)
		State.STUNNED:
			_state_stunned(delta)
		State.DEAD:
			_state_dead(delta)


func change_state(new_state: State) -> void:
	## Change to a new state.
	if current_state == new_state:
		return
	
	previous_state = current_state
	current_state = new_state
	state_timer = 0.0
	
	# State exit logic
	_on_state_exit(previous_state)
	
	# State enter logic
	_on_state_enter(new_state)
	
	state_changed.emit(new_state)


func _on_state_enter(state: State) -> void:
	## Called when entering a state. Override for custom behavior.
	match state:
		State.IDLE:
			velocity.x = 0
			idle_duration = rng.randf_range(idle_time_min, idle_time_max)
		State.PATROL:
			pass
		State.SEARCH:
			search_timer = search_duration
		State.CHASE:
			pass
		State.ATTACK:
			velocity.x = 0
		State.STUNNED:
			pass
		State.DEAD:
			is_dead = true
			velocity = Vector2.ZERO


func _on_state_exit(_state: State) -> void:
	## Called when exiting a state. Override for custom behavior.
	pass


# =========================================
# STATE BEHAVIORS
# =========================================

func _state_idle(delta: float) -> void:
	## IDLE: Standing still, waiting, occasionally looking around.
	velocity.x = move_toward(velocity.x, 0, patrol_speed * delta * 5)
	
	# Random look around
	if rng.randf() < idle_look_chance * delta:
		facing_right = not facing_right
	
	# Check if player is visible while idle
	if can_see_player:
		change_state(State.CHASE)
		return
	
	# Heard something?
	if heard_player:
		change_state(State.SEARCH)
		return
	
	# Transition to patrol after idle duration
	if state_timer >= idle_duration:
		change_state(State.PATROL)


func _state_patrol(delta: float) -> void:
	## PATROL: Walk back and forth or between waypoints.
	# Use waypoints if defined
	if patrol_points.size() > 0:
		_patrol_waypoints(delta)
	else:
		_patrol_edge_detection(delta)
	
	# Check for player
	if can_see_player:
		change_state(State.CHASE)
		return
	
	# Random pause
	if rng.randf() < 0.001:  # Small chance per frame
		change_state(State.IDLE)


func _patrol_waypoints(_delta: float) -> void:
	## Patrol using predefined waypoints.
	if patrol_points.size() == 0:
		return
	
	var target: Vector2 = patrol_points[patrol_index]
	var direction: float = sign(target.x - global_position.x)
	
	velocity.x = direction * patrol_speed
	
	# Reached waypoint?
	if absf(global_position.x - target.x) < 10:
		patrol_index = (patrol_index + 1) % patrol_points.size()


func _patrol_edge_detection(_delta: float) -> void:
	## Patrol using edge/wall detection (turn at edges).
	velocity.x = patrol_direction * patrol_speed
	
	# Check for wall
	if wall_check and wall_check.is_colliding():
		patrol_direction *= -1
		velocity.x = patrol_direction * patrol_speed
	
	# Check for edge (no ground ahead)
	if ground_check and not ground_check.is_colliding() and is_on_floor():
		patrol_direction *= -1
		velocity.x = patrol_direction * patrol_speed


func _state_search(_delta: float) -> void:
	## SEARCH: Looking for player after losing sight.
	# Move toward last known position
	if last_known_player_pos != Vector2.ZERO:
		var direction: float = sign(last_known_player_pos.x - global_position.x)
		velocity.x = direction * patrol_speed
		
		# Reached last known position?
		if absf(global_position.x - last_known_player_pos.x) < 20:
			last_known_player_pos = Vector2.ZERO
	else:
		# Look around
		velocity.x = 0
		if rng.randf() < 0.02:
			facing_right = not facing_right
	
	# Found player again!
	if can_see_player:
		change_state(State.CHASE)
		return
	
	# Give up searching
	if search_timer <= 0:
		change_state(State.PATROL)
		alert_level = 0.0
		player_lost.emit()
		print("[Enemy] %s: Lost interest. Resuming patrol." % name)


func _state_chase(_delta: float) -> void:
	## CHASE: Actively pursuing player.
	if not target_player or not can_see_player:
		# Lost sight - go to search
		if search_timer <= 0:
			change_state(State.SEARCH)
		return
	
	# Move toward player
	var direction: float = sign(target_player.global_position.x - global_position.x)
	velocity.x = direction * chase_speed
	
	# Close enough to attack?
	var distance: float = global_position.distance_to(target_player.global_position)
	if distance < 40 and attack_cooldown_timer <= 0:
		change_state(State.ATTACK)


func _state_attack(_delta: float) -> void:
	## ATTACK: Performing attack. Override in subclasses.
	velocity.x = 0
	
	# Default: quick attack then return to chase
	if state_timer >= 0.3:
		attack_cooldown_timer = 1.0
		change_state(State.CHASE)


func _state_stunned(delta: float) -> void:
	## STUNNED: Recovering from hit.
	velocity.x = move_toward(velocity.x, 0, 400 * delta)
	
	if stun_timer <= 0:
		# Return to appropriate state
		if can_see_player:
			change_state(State.CHASE)
		else:
			change_state(State.PATROL)


func _state_dead(_delta: float) -> void:
	## DEAD: Waiting for death animation.
	velocity = Vector2.ZERO


# =========================================
# DAMAGE & HEALTH
# =========================================

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	## Receive damage and knockback.
	if is_dead:
		return
	
	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	took_damage.emit(amount, knockback_dir)
	
	# Apply knockback
	if knockback_dir != Vector2.ZERO:
		velocity = knockback_dir.normalized() * knockback_force
		stun_timer = 0.3
		change_state(State.STUNNED)
	
	# Visual feedback
	_flash_damage()
	
	# Audio
	AudioManager.play_sfx("enemy_hit")
	
	print("[Enemy] %s took %d damage. HP: %d/%d" % [name, amount, current_health, max_health])
	
	# Check death
	if current_health <= 0:
		_die()


func _flash_damage() -> void:
	## Flash white/red when taking damage.
	if not sprite:
		return
	
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3), 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)


func _die() -> void:
	## Handle death.
	is_dead = true
	change_state(State.DEAD)
	
	# Disable collision
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if hitbox:
		hitbox.set_deferred("monitoring", false)
	
	# Emit signal
	died.emit()
	
	# Audio
	AudioManager.play_sfx("enemy_death")
	
	# Spawn death particles (override in subclass)
	_spawn_death_effect()
	
	# Death animation then remove
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		tween.parallel().tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.5)
		tween.tween_callback(queue_free)
	else:
		queue_free()
	
	print("[Enemy] %s defeated!" % name)


func _spawn_death_effect() -> void:
	## Spawn death particles. Override in subclass.
	# Default: try to spawn explosion particles
	var explosion_scene: PackedScene = load("res://scenes/effects/ExplosionParticles.tscn")
	if explosion_scene:
		var explosion: Node2D = explosion_scene.instantiate()
		explosion.global_position = global_position
		get_parent().add_child(explosion)


# =========================================
# CONTACT DAMAGE
# =========================================

func _on_hitbox_body_entered(body: Node2D) -> void:
	## Deal contact damage to player.
	if body is Player and not is_dead:
		_deal_contact_damage(body as Player)


func _deal_contact_damage(player: Player) -> void:
	## Apply contact damage and knockback to player.
	if attack_cooldown_timer > 0:
		return
	
	var knockback_dir := (player.global_position - global_position).normalized()
	knockback_dir.y = -0.3  # Slight upward knockback
	knockback_dir = knockback_dir.normalized()
	
	player.take_damage(contact_damage, knockback_dir * knockback_force)
	attack_cooldown_timer = 0.5


# =========================================
# HEARING SYSTEM
# =========================================

func _on_hearing_body_entered(body: Node2D) -> void:
	## Player entered hearing range.
	if body is Player:
		heard_player = true
		if current_state == State.IDLE:
			# Investigate the sound
			change_state(State.SEARCH)
			last_known_player_pos = body.global_position


func _on_hearing_body_exited(body: Node2D) -> void:
	## Player left hearing range.
	if body is Player:
		heard_player = false


# =========================================
# VISUAL UPDATES
# =========================================

func _update_facing() -> void:
	## Update sprite facing direction.
	if velocity.x > 5:
		facing_right = true
	elif velocity.x < -5:
		facing_right = false
	
	if sprite:
		if sprite is Sprite2D:
			(sprite as Sprite2D).flip_h = not facing_right
		elif sprite is AnimatedSprite2D:
			(sprite as AnimatedSprite2D).flip_h = not facing_right


func _update_eye_light() -> void:
	## Update eye light color based on alert state.
	if not eye_light:
		return
	
	match current_state:
		State.IDLE, State.PATROL:
			eye_light.color = Color(0.2, 0.8, 0.2)  # Green - calm
		State.SEARCH:
			eye_light.color = Color(1.0, 0.8, 0.0)  # Yellow - alert
		State.CHASE, State.ATTACK:
			eye_light.color = Color(1.0, 0.2, 0.2)  # Red - aggressive
		State.STUNNED:
			eye_light.color = Color(0.5, 0.5, 1.0)  # Blue - stunned
		State.DEAD:
			eye_light.energy = 0.0


# =========================================
# VIRTUAL METHODS (Override in subclasses)
# =========================================

func _on_enemy_ready() -> void:
	## Called at end of _ready(). Override for subclass setup.
	pass


func get_state_name() -> String:
	## Get current state as string.
	return State.keys()[current_state]
