# ===================================================
# FlyingEnemy.gd - Musuh Terbang
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Musuh tipe flying - bergerak di udara, hover, dive ke player.
# ===================================================

extends EnemyBase
class_name FlyingEnemy

@export_group("Flight")
## Kecepatan hover naik-turun
@export var hover_speed: float = 2.0
## Amplitudo hover
@export var hover_amplitude: float = 20.0
## Kecepatan terbang ke player
@export var fly_speed: float = 120.0

@export_group("Attack")
## Jarak untuk mulai dive attack
@export var dive_distance: float = 150.0
## Kecepatan dive
@export var dive_speed: float = 250.0
## Cooldown setelah dive
@export var dive_cooldown: float = 2.0

# Internal
var start_position: Vector2
var time_passed: float = 0.0
var is_diving: bool = false
var can_dive: bool = true


func _on_ready() -> void:
	start_position = global_position
	current_state = State.PATROL
	# Flying enemy tidak kena gravity
	gravity = 0


func _process_patrol(delta: float) -> void:
	time_passed += delta
	
	# Hover movement
	var hover_offset := sin(time_passed * hover_speed) * hover_amplitude
	velocity.y = hover_offset
	
	# Gerak horizontal pelan
	velocity.x = sin(time_passed * 0.5) * move_speed * 0.5


func _process_chase(delta: float) -> void:
	if not target_player:
		current_state = State.PATROL
		return
	
	if is_diving:
		return
	
	time_passed += delta
	
	var dir_to_player := get_direction_to_player()
	var distance := global_position.distance_to(target_player.global_position)
	
	# Cek apakah bisa dive
	if distance < dive_distance and can_dive:
		_start_dive()
		return
	
	# Terbang mendekati player tapi tetap di atas
	var target_pos := target_player.global_position + Vector2(0, -80)
	var move_dir := (target_pos - global_position).normalized()
	
	velocity = move_dir * fly_speed
	
	# Tambah hover sedikit
	velocity.y += sin(time_passed * hover_speed) * 30


func _process_attack(_delta: float) -> void:
	# Dive attack sedang berlangsung
	pass


func _start_dive() -> void:
	"""Mulai dive attack ke player."""
	if not target_player or is_diving:
		return
	
	is_diving = true
	can_dive = false
	current_state = State.ATTACK
	
	# Hitung arah dive
	var dive_dir := (target_player.global_position - global_position).normalized()
	velocity = dive_dir * dive_speed
	
	# Durasi dive
	await get_tree().create_timer(0.5).timeout
	
	# Kembali ke chase
	is_diving = false
	current_state = State.CHASE
	
	# Cooldown dive
	await get_tree().create_timer(dive_cooldown).timeout
	can_dive = true


func _process_hurt(_delta: float) -> void:
	# Cancel dive jika kena hit
	is_diving = false
	velocity = velocity * 0.5
