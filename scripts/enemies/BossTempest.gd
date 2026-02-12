# ===================================================
# BossTempest.gd - Boss Level 4: Tempest
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Boss badai - terbang, tembak proyektil petir dari atas.
# Reward: Glide
# ===================================================

extends BossBase
class_name BossTempest

@export_group("Tempest Attacks")
## Kecepatan proyektil petir
@export var lightning_speed: float = 300.0
## Damage proyektil
@export var lightning_damage: int = 25
## Jumlah proyektil per burst
@export var projectile_count: int = 3
## Spread angle proyektil (degrees)
@export var spread_angle: float = 30.0

# Internal
var projectiles: Array = []
var base_height: float = 0.0


func _on_ready() -> void:
	super._on_ready()
	
	boss_name = "Tempest"
	total_phases = 2
	phase_health = [100, 130]
	reward_ability = "glide"
	
	max_health = phase_health[0]
	current_health = max_health
	
	contact_damage = 20
	move_speed = 100.0
	gravity = 0  # Terbang
	
	base_height = global_position.y


func _setup_brain() -> void:
	var config := BossConfig.create_tempest_config()
	config.arena_center = Vector2.ZERO
	_create_brain(config)


func _on_brain_attack_requested(attack_type: String) -> void:
	var roll := randf()
	if attack_type == "close":
		_attack_dive_strike()
	elif roll < 0.5:
		_attack_lightning_bolt()
	elif roll < 0.8:
		_attack_lightning_burst()
	else:
		_attack_dive_strike()


func _process_chase(_delta: float) -> void:
	if not target_player or is_attacking:
		return
	
	# Terbang di atas player
	var target_pos := target_player.global_position + Vector2(0, -150)
	var dir := (target_pos - global_position).normalized()
	
	velocity = dir * move_speed
	
	# Clamp height
	if global_position.y > base_height + 50:
		velocity.y = -50
	elif global_position.y < base_height - 100:
		velocity.y = 50


func _choose_attack() -> void:
	if not target_player:
		return
	
	var attack_roll := randf()
	
	if attack_roll < 0.5:
		_attack_lightning_bolt()
	elif attack_roll < 0.8:
		_attack_lightning_burst()
	else:
		_attack_dive_strike()


func _attack_lightning_bolt() -> void:
	## Tembak satu petir ke arah player.
	if not _is_valid_for_attack():
		return
	_start_attack("lightning_bolt")
	
	if not target_player or not is_instance_valid(target_player):
		_end_attack()
		return
	
	# Charge
	if sprite:
		sprite.modulate = Color(0.7, 0.7, 1)
	
	if not await _safe_await_timer(0.3):
		return
	
	if not _is_valid_for_attack():
		return
	
	# Fire!
	if sprite:
		sprite.modulate = Color.WHITE
	
	if target_player and is_instance_valid(target_player):
		_spawn_lightning(target_player.global_position)
	
	if not await _safe_await_timer(0.2):
		return
	_end_attack()


func _attack_lightning_burst() -> void:
	## Tembak multiple petir spread.
	if not _is_valid_for_attack():
		return
	_start_attack("lightning_burst")
	
	if not target_player or not is_instance_valid(target_player):
		_end_attack()
		return
	
	# Charge
	if sprite:
		sprite.modulate = Color(1, 1, 0.5)
		var tween := create_tween()
		if tween:
			tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.4)
			await tween.finished
			sprite.scale = Vector2.ONE
	else:
		if not await _safe_await_timer(0.4):
			return
	
	if not _is_valid_for_attack():
		return
	
	# Fire burst!
	if sprite:
		sprite.modulate = Color.WHITE
	
	if not target_player or not is_instance_valid(target_player):
		_end_attack()
		return
	
	var base_dir := (target_player.global_position - global_position).normalized()
	var base_angle := base_dir.angle()  # Direction toward the player
	
	# Spawn multiple projectiles in a spread around the player direction
	var count := projectile_count if current_phase == 1 else projectile_count + 2
	var angle_step: float = deg_to_rad(spread_angle) / (count - 1) if count > 1 else 0.0
	var start_angle := -deg_to_rad(spread_angle) / 2
	
	for i in range(count):
		if not _is_valid_for_attack():
			return
		var angle: float = start_angle + angle_step * float(i)
		var direction := Vector2.from_angle(base_angle + angle)
		var target_pos := global_position + direction * 500
		_spawn_lightning(target_pos)
		if not await _safe_await_timer(0.05):
			return
	
	if not await _safe_await_timer(0.3):
		return
	_end_attack()


func _attack_dive_strike() -> void:
	## Dive ke bawah dengan lightning trail.
	if not _is_valid_for_attack():
		return
	_start_attack("dive_strike")
	
	if not target_player or not is_instance_valid(target_player):
		_end_attack()
		return
	
	# Naik dulu
	var tween := create_tween()
	if tween:
		tween.tween_property(self, "global_position:y", global_position.y - 80, 0.3)
		await tween.finished
	else:
		if not await _safe_await_timer(0.3):
			return
	
	if not _is_valid_for_attack():
		return
	
	# Warning
	if sprite:
		sprite.modulate = Color(1, 0.5, 0)
	
	if not await _safe_await_timer(0.3):
		return
	
	if not _is_valid_for_attack():
		return
	
	# DIVE!
	if sprite:
		sprite.modulate = Color(1, 1, 0)
	
	if not target_player or not is_instance_valid(target_player):
		_end_attack()
		return
	
	var dive_target := target_player.global_position
	var dive_dir := (dive_target - global_position).normalized()
	
	velocity = dive_dir * 350
	
	# Spawn lightning trail
	var dive_time := 0.0
	while dive_time < 0.6:
		if not await _safe_await_timer(0.1):
			break
		if not _is_valid_for_attack():
			break
		dive_time += 0.1
		
		# Trail
		_spawn_trail_effect()
		
		# Check hit
		if target_player and is_instance_valid(target_player) and global_position.distance_to(target_player.global_position) < 40:
			var knockback := dive_dir
			target_player.take_damage(30, knockback * 250)
			break
	
	velocity = Vector2.ZERO
	
	# Post-dive: recover altitude toward base_height to avoid getting stuck below
	var height_diff := base_height - global_position.y
	if absf(height_diff) > 30.0:
		var recover_tween := create_tween()
		if recover_tween:
			recover_tween.tween_property(self, "global_position:y",
				base_height + randf_range(-20.0, 20.0), 0.4)
			await recover_tween.finished
	
	if sprite:
		sprite.modulate = Color.WHITE
	
	if not await _safe_await_timer(0.5):
		return
	_end_attack()


func _spawn_lightning(target_pos: Vector2) -> void:
	## Spawn proyektil petir.
	if not is_inside_tree():
		return
	
	var projectile := Area2D.new()
	projectile.global_position = global_position
	
	# Visual
	var visual := ColorRect.new()
	visual.size = Vector2(10, 20)
	visual.position = Vector2(-5, -10)
	visual.color = Color(1, 1, 0.5)
	projectile.add_child(visual)
	
	# Collision
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 8
	col.shape = shape
	projectile.add_child(col)
	
	projectile.collision_layer = 32  # Layer 6: Projectile
	projectile.collision_mask = 1    # Player
	
	if is_inside_tree():
		get_parent().add_child(projectile)
		projectiles.append(projectile)
	else:
		projectile.queue_free()
		return
	
	# Movement
	var direction := (target_pos - global_position).normalized()
	
	# Move projectile
	var move_time := 0.0
	while move_time < 3.0 and is_instance_valid(projectile):
		if not await _safe_await_frame():
			break
		move_time += get_process_delta_time()
		
		if not is_instance_valid(projectile):
			break
		
		projectile.global_position += direction * lightning_speed * get_process_delta_time()
		
		# Rotate towards direction
		projectile.rotation = direction.angle() + PI/2
		
		# Check hit player
		if target_player and is_instance_valid(target_player) and projectile.global_position.distance_to(target_player.global_position) < 20:
			target_player.take_damage(lightning_damage, direction * 100)
			break
	
	# Cleanup
	if is_instance_valid(projectile):
		projectiles.erase(projectile)
		projectile.queue_free()


func _spawn_trail_effect() -> void:
	## Spawn efek trail saat dive.
	var trail := ColorRect.new()
	trail.size = Vector2(15, 15)
	trail.position = global_position - Vector2(7.5, 7.5)
	trail.color = Color(1, 1, 0.5, 0.7)
	get_parent().add_child(trail)
	
	# Fade out
	var tween := create_tween()
	tween.tween_property(trail, "modulate:a", 0.0, 0.3)
	tween.tween_callback(trail.queue_free)


func _phase_transition_effect() -> void:
	# Phase 2 - faster, more projectiles
	if not _is_valid_for_attack():
		return
	
	if sprite:
		for i in range(6):
			if not _is_valid_for_attack():
				return
			sprite.modulate = Color(1, 1, 0) if i % 2 == 0 else Color.WHITE
			if not await _safe_await_timer(0.12):
				return
	
	move_speed = 130.0
	lightning_speed = 350.0
	min_attack_cooldown = 0.8
	max_attack_cooldown = 1.5


func _boss_defeated() -> void:
	# Clean up projectiles
	for proj in projectiles:
		if is_instance_valid(proj):
			proj.queue_free()
	projectiles.clear()
	
	super._boss_defeated()
