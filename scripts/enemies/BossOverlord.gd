# ===================================================
# BossOverlord.gd - Final Boss: The Overlord
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Final boss dengan 2 fase:
# - Fase 1: Robot Raksasa dengan laser horizontal
# - Fase 2: Core Spirit - platforming sambil hindari energy
# ===================================================

extends BossBase
class_name BossOverlord

@export_group("Phase 1 - Robot")
## Damage laser horizontal
@export var laser_damage: int = 35
## Durasi laser aktif
@export var laser_duration: float = 2.0
## Warning time sebelum laser
@export var laser_warning: float = 1.0

@export_group("Phase 2 - Core")
## Jumlah energy orb yang di-spawn
@export var orb_count: int = 5
## Kecepatan orb
@export var orb_speed: float = 150.0
## Damage orb
@export var orb_damage: int = 20

# Internal
var laser_node: Node2D = null
var orbs: Array = []
var phase_2_position: Vector2


func _on_ready() -> void:
	super._on_ready()
	
	boss_name = "The Overlord"
	total_phases = 2
	phase_health = [200, 150]
	reward_ability = ""  # Final boss - no reward, game complete!
	
	max_health = phase_health[0]
	current_health = max_health
	
	contact_damage = 30
	move_speed = 30.0
	
	phase_2_position = global_position + Vector2(0, -200)


func _process_chase(_delta: float) -> void:
	if is_attacking:
		return
	
	if current_phase == 1:
		_process_phase_1(_delta)
	else:
		_process_phase_2(_delta)


func _process_phase_1(_delta: float) -> void:
	"""Phase 1: Robot raksasa - gerak lambat, laser."""
	if not target_player:
		return
	
	# Gerak horizontal saja
	var dir_x: float = sign(target_player.global_position.x - global_position.x)
	velocity.x = dir_x * move_speed
	velocity.y = 0


func _process_phase_2(_delta: float) -> void:
	"""Phase 2: Core Spirit - hover di tengah atas, spawn orbs."""
	# Hover di posisi phase 2
	var move_dir := (phase_2_position - global_position).normalized()
	var distance := global_position.distance_to(phase_2_position)
	
	if distance > 10:
		velocity = move_dir * move_speed * 2
	else:
		velocity = Vector2.ZERO
		# Sedikit hover
		velocity.y = sin(Time.get_ticks_msec() * 0.002) * 20


func _choose_attack() -> void:
	if not target_player:
		return
	
	if current_phase == 1:
		_choose_phase_1_attack()
	else:
		_choose_phase_2_attack()


func _choose_phase_1_attack() -> void:
	"""Pilih serangan fase 1."""
	var attack_roll := randf()
	
	if attack_roll < 0.6:
		_attack_horizontal_laser()
	else:
		_attack_ground_slam()


func _choose_phase_2_attack() -> void:
	"""Pilih serangan fase 2."""
	var attack_roll := randf()
	
	if attack_roll < 0.5:
		_attack_energy_orbs()
	elif attack_roll < 0.8:
		_attack_energy_rain()
	else:
		_attack_pulse_wave()


# === PHASE 1 ATTACKS ===

func _attack_horizontal_laser() -> void:
	"""Laser horizontal yang sweep arena."""
	_start_attack("horizontal_laser")
	
	# Warning - flash dan telegraph
	if sprite:
		sprite.modulate = Color(1, 0.3, 0.3)
	
	# Create laser telegraph
	var telegraph := ColorRect.new()
	telegraph.size = Vector2(2000, 10)
	telegraph.position = Vector2(-1000, -5)
	telegraph.color = Color(1, 0, 0, 0.3)
	add_child(telegraph)
	
	await get_tree().create_timer(laser_warning).timeout
	
	# FIRE LASER!
	if sprite:
		sprite.modulate = Color(1, 0, 0)
	
	telegraph.size.y = 40
	telegraph.position.y = -20
	telegraph.color = Color(1, 0.2, 0.1, 0.9)
	
	# Create laser hitbox
	var laser_area := Area2D.new()
	laser_area.global_position = global_position
	var laser_col := CollisionShape2D.new()
	var laser_shape := RectangleShape2D.new()
	laser_shape.size = Vector2(2000, 40)
	laser_col.shape = laser_shape
	laser_area.add_child(laser_col)
	laser_area.collision_layer = 8
	laser_area.collision_mask = 1
	add_child(laser_area)
	
	# Damage player jika dalam laser
	var laser_time := 0.0
	while laser_time < laser_duration:
		await get_tree().create_timer(0.1).timeout
		laser_time += 0.1
		
		if target_player:
			var player_y := target_player.global_position.y
			var laser_y := global_position.y
			if abs(player_y - laser_y) < 25:
				target_player.take_damage(laser_damage)
	
	# Cleanup
	telegraph.queue_free()
	laser_area.queue_free()
	
	if sprite:
		sprite.modulate = Color.WHITE
	
	await get_tree().create_timer(0.5).timeout
	_end_attack()


func _attack_ground_slam() -> void:
	"""Slam tanah - shockwave."""
	_start_attack("ground_slam")
	
	# Jump up
	var tween := create_tween()
	tween.tween_property(self, "global_position:y", global_position.y - 100, 0.4)
	await tween.finished
	
	await get_tree().create_timer(0.3).timeout
	
	# SLAM DOWN
	var slam_tween := create_tween()
	slam_tween.tween_property(self, "global_position:y", global_position.y + 100, 0.15)
	await slam_tween.finished
	
	# Shockwave damage
	if target_player and target_player.is_on_floor():
		var distance: float = abs(target_player.global_position.x - global_position.x)
		if distance < 300:
			var knockback := Vector2(sign(target_player.global_position.x - global_position.x), -1).normalized()
			target_player.take_damage(25, knockback * 200)
	
	await get_tree().create_timer(0.5).timeout
	_end_attack()


# === PHASE 2 ATTACKS ===

func _attack_energy_orbs() -> void:
	"""Spawn energy orbs yang chase player."""
	_start_attack("energy_orbs")
	
	var spawn_count := orb_count if current_phase == 2 else orb_count - 2
	
	for i in range(spawn_count):
		var orb := _spawn_energy_orb()
		orbs.append(orb)
		await get_tree().create_timer(0.3).timeout
	
	_end_attack()


func _spawn_energy_orb() -> Area2D:
	"""Spawn satu energy orb."""
	var orb := Area2D.new()
	orb.global_position = global_position + Vector2(randf_range(-50, 50), 0)
	
	var visual := ColorRect.new()
	visual.size = Vector2(20, 20)
	visual.position = Vector2(-10, -10)
	visual.color = Color(0.8, 0.2, 1)
	orb.add_child(visual)
	
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12
	col.shape = shape
	orb.add_child(col)
	
	orb.collision_layer = 32
	orb.collision_mask = 1
	
	get_parent().add_child(orb)
	
	# Chase player
	_orb_chase_player(orb)
	
	return orb


func _orb_chase_player(orb: Area2D) -> void:
	"""Orb mengejar player."""
	var lifetime := 0.0
	
	while lifetime < 5.0 and is_instance_valid(orb):
		await get_tree().process_frame
		lifetime += get_process_delta_time()
		
		if not target_player:
			continue
		
		var dir := (target_player.global_position - orb.global_position).normalized()
		orb.global_position += dir * orb_speed * get_process_delta_time()
		
		# Check hit
		if orb.global_position.distance_to(target_player.global_position) < 20:
			target_player.take_damage(orb_damage, dir * 100)
			break
	
	if is_instance_valid(orb):
		orbs.erase(orb)
		orb.queue_free()


func _attack_energy_rain() -> void:
	"""Energy rain dari atas."""
	_start_attack("energy_rain")
	
	if not target_player:
		_end_attack()
		return
	
	# Spawn energy falling from above
	for i in range(8):
		var x_pos := target_player.global_position.x + randf_range(-150, 150)
		_spawn_falling_energy(x_pos)
		await get_tree().create_timer(0.15).timeout
	
	await get_tree().create_timer(1.0).timeout
	_end_attack()


func _spawn_falling_energy(x_pos: float) -> void:
	"""Spawn energy yang jatuh."""
	# Warning indicator
	var warning := ColorRect.new()
	warning.size = Vector2(30, 5)
	warning.global_position = Vector2(x_pos - 15, target_player.global_position.y + 50)
	warning.color = Color(1, 0, 0, 0.5)
	get_parent().add_child(warning)
	
	await get_tree().create_timer(0.5).timeout
	warning.queue_free()
	
	# Actual projectile
	var proj := Area2D.new()
	proj.global_position = Vector2(x_pos, global_position.y - 100)
	
	var visual := ColorRect.new()
	visual.size = Vector2(20, 30)
	visual.position = Vector2(-10, -15)
	visual.color = Color(1, 0.5, 0.8)
	proj.add_child(visual)
	
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 30)
	col.shape = shape
	proj.add_child(col)
	
	get_parent().add_child(proj)
	
	# Fall down
	var fall_time := 0.0
	while fall_time < 2.0 and is_instance_valid(proj):
		await get_tree().process_frame
		fall_time += get_process_delta_time()
		
		proj.global_position.y += 400 * get_process_delta_time()
		
		# Check hit player
		if target_player and proj.global_position.distance_to(target_player.global_position) < 25:
			target_player.take_damage(15, Vector2(0, 1) * 100)
			break
	
	if is_instance_valid(proj):
		proj.queue_free()


func _attack_pulse_wave() -> void:
	"""Expanding pulse wave."""
	_start_attack("pulse_wave")
	
	# Charge
	if sprite:
		sprite.modulate = Color(1, 0.5, 1)
		var tween := create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.5)
		await tween.finished
	else:
		await get_tree().create_timer(0.5).timeout
	
	# PULSE!
	if sprite:
		sprite.scale = Vector2.ONE
		sprite.modulate = Color.WHITE
	
	# Visual pulse (simplified)
	var pulse := ColorRect.new()
	pulse.size = Vector2(50, 50)
	pulse.global_position = global_position - Vector2(25, 25)
	pulse.color = Color(1, 0.5, 1, 0.5)
	get_parent().add_child(pulse)
	
	var pulse_size := 50.0
	while pulse_size < 400:
		await get_tree().process_frame
		pulse_size += 500 * get_process_delta_time()
		
		pulse.size = Vector2(pulse_size, pulse_size)
		pulse.global_position = global_position - Vector2(pulse_size/2, pulse_size/2)
		pulse.color.a = 1.0 - (pulse_size / 400)
		
		# Check hit
		if target_player:
			var dist := global_position.distance_to(target_player.global_position)
			if abs(dist - pulse_size/2) < 30:
				var knockback := (target_player.global_position - global_position).normalized()
				target_player.take_damage(20, knockback * 300)
	
	pulse.queue_free()
	
	await get_tree().create_timer(0.3).timeout
	_end_attack()


func _phase_transition_effect() -> void:
	"""Transisi dramatis ke fase 2."""
	print("[Overlord] TRANSFORMASI KE CORE SPIRIT!")
	
	# Robot hancur efek
	if sprite:
		for i in range(10):
			sprite.modulate = Color(1, randf(), randf())
			sprite.rotation_degrees = randf_range(-10, 10)
			await get_tree().create_timer(0.1).timeout
		
		# Shrink menjadi core
		var tween := create_tween()
		tween.tween_property(sprite, "scale", Vector2(0.5, 0.5), 0.5)
		tween.parallel().tween_property(sprite, "modulate", Color(0.8, 0.2, 1), 0.5)
		await tween.finished
		
		sprite.rotation_degrees = 0
	
	# Move ke posisi phase 2
	global_position = phase_2_position
	gravity = 0
	move_speed = 50.0
	min_attack_cooldown = 0.5
	max_attack_cooldown = 1.2


func _boss_defeated() -> void:
	"""GAME COMPLETE!"""
	# Cleanup orbs
	for orb in orbs:
		if is_instance_valid(orb):
			orb.queue_free()
	orbs.clear()
	
	print("=" .repeat(50))
	print("OVERLORD DIKALAHKAN!")
	print("ARCADIA TELAH DISELAMATKAN!")
	print("TERIMA KASIH TELAH BERMAIN PROJECT: REBOOT!")
	print("=" .repeat(50))
	
	# Emit signal for game completion
	if GameManager:
		# Could trigger ending cutscene/credits
		pass
	
	super._boss_defeated()
