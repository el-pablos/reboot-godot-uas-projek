# ===================================================
# WalkingEnemy.gd - Musuh yang Berjalan di Ground
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Musuh tipe walker - patrol di platform, chase player.
# Menggunakan RayCast untuk deteksi jurang/dinding.
# ===================================================

extends EnemyBase
class_name WalkingEnemy

@export_group("Patrol")
## Jarak patrol dari posisi awal
@export var patrol_distance: float = 100.0
## Waktu tunggu di ujung patrol
@export var patrol_wait_time: float = 1.0

# Internal
var start_position: Vector2
var patrol_direction: float = 1.0
var is_waiting: bool = false

# Raycasts
@onready var floor_check_left: RayCast2D = $FloorCheckLeft if has_node("FloorCheckLeft") else null
@onready var floor_check_right: RayCast2D = $FloorCheckRight if has_node("FloorCheckRight") else null
@onready var wall_check: RayCast2D = $WallCheck if has_node("WallCheck") else null


func _on_ready() -> void:
	start_position = global_position
	current_state = State.PATROL


func _process_patrol(_delta: float) -> void:
	if is_waiting:
		velocity.x = 0
		return
	
	# Gerak ke arah patrol
	velocity.x = patrol_direction * move_speed
	
	# Cek batas patrol
	var distance_from_start := global_position.x - start_position.x
	if abs(distance_from_start) > patrol_distance:
		_turn_around()
		return
	
	# Cek jurang di depan
	if _is_cliff_ahead():
		_turn_around()
		return
	
	# Cek dinding di depan
	if _is_wall_ahead():
		_turn_around()


func _process_chase(_delta: float) -> void:
	if not target_player:
		current_state = State.PATROL
		return
	
	# Arah ke player
	var dir_to_player := get_direction_to_player()
	
	# Gerak ke arah player
	if abs(dir_to_player.x) > 0.1:
		velocity.x = sign(dir_to_player.x) * move_speed * 1.3  # Lebih cepat saat chase
		patrol_direction = sign(dir_to_player.x)
	else:
		velocity.x = 0
	
	# Jangan jatuh ke jurang saat chase
	if _is_cliff_ahead():
		velocity.x = 0


func _is_cliff_ahead() -> bool:
	"""Cek apakah ada jurang di depan."""
	if patrol_direction > 0 and floor_check_right:
		return not floor_check_right.is_colliding()
	elif patrol_direction < 0 and floor_check_left:
		return not floor_check_left.is_colliding()
	return false


func _is_wall_ahead() -> bool:
	"""Cek apakah ada dinding di depan."""
	if wall_check:
		# Update arah raycast
		wall_check.target_position.x = 20 * patrol_direction
		return wall_check.is_colliding()
	return false


func _turn_around() -> void:
	"""Berbalik arah."""
	patrol_direction *= -1
	
	# Tunggu sebentar
	is_waiting = true
	await get_tree().create_timer(patrol_wait_time).timeout
	is_waiting = false
