# ===================================================
# BossScrapper.gd - Boss Level 2: The Scrapper
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Boss pabrik - robot besar dengan serangan lambat tapi kuat.
# Reward: Air Dash
# ===================================================

extends BossBase
class_name BossScrapper

@export_group("Scrapper Attacks")
## Damage slam attack
@export var slam_damage: int = 40
## Jarak slam
@export var slam_range: float = 100.0
## Kecepatan dash attack
@export var dash_attack_speed: float = 350.0
## Damage dash attack
@export var dash_damage: int = 30

# Internal
var dash_target: Vector2 = Vector2.ZERO


func _on_ready() -> void:
	super._on_ready()
	
	boss_name = "The Scrapper"
	total_phases = 2
	phase_health = [150, 200]
	reward_ability = "dash"
	
	max_health = phase_health[0]
	current_health = max_health
	
	contact_damage = 25
	move_speed = 60.0


func _process_chase(_delta: float) -> void:
	if not target_player or is_attacking:
		velocity.x = 0
		return
	
	# Gerak pelan mendekati player
	var dir := get_direction_to_player()
	var distance := global_position.distance_to(target_player.global_position)
	
	if distance > slam_range * 1.5:
		velocity.x = sign(dir.x) * move_speed
	else:
		velocity.x = 0


func _choose_attack() -> void:
	if not target_player:
		return
	
	var distance := global_position.distance_to(target_player.global_position)
	
	# Pilih attack berdasarkan jarak dan phase
	if distance <= slam_range:
		_attack_slam()
	elif current_phase >= 2 and randf() > 0.5:
		_attack_dash()
	elif distance > slam_range * 2:
		_attack_dash()


func _attack_slam() -> void:
	"""Slam attack - area damage di depan."""
	_start_attack("slam")
	
	# Windup
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "position:y", -20, 0.3)
		await tween.finished
	else:
		await get_tree().create_timer(0.3).timeout
	
	# Slam down
	if sprite:
		var slam_tween := create_tween()
		slam_tween.tween_property(sprite, "position:y", 10, 0.1)
		slam_tween.tween_property(sprite, "position:y", 0, 0.2)
	
	# Check hit
	if target_player:
		var distance := global_position.distance_to(target_player.global_position)
		if distance <= slam_range:
			var knockback := (target_player.global_position - global_position).normalized()
			target_player.take_damage(slam_damage, knockback * 250)
	
	# Shake effect (bisa ditambahkan camera shake)
	
	await get_tree().create_timer(0.5).timeout
	_end_attack()


func _attack_dash() -> void:
	"""Dash attack - melesat ke arah player."""
	_start_attack("dash")
	
	if not target_player:
		_end_attack()
		return
	
	# Windup - mundur sedikit
	var dash_dir: float = sign(target_player.global_position.x - global_position.x)
	velocity.x = -dash_dir * 50
	
	# Flash warning
	if sprite:
		sprite.modulate = Color(1, 0.5, 0)
	
	await get_tree().create_timer(0.5).timeout
	
	# DASH!
	if sprite:
		sprite.modulate = Color.WHITE
	
	dash_target = target_player.global_position
	velocity.x = dash_dir * dash_attack_speed
	
	# Dash duration
	var dash_time := 0.0
	while dash_time < 0.8:
		await get_tree().process_frame
		dash_time += get_process_delta_time()
		
		# Cek hit player
		if target_player and global_position.distance_to(target_player.global_position) < 50:
			var knockback := Vector2(dash_dir, -0.5).normalized()
			target_player.take_damage(dash_damage, knockback * 300)
			break
	
	velocity.x = 0
	
	await get_tree().create_timer(0.3).timeout
	_end_attack()


func _phase_transition_effect() -> void:
	# Scrapper rage mode di phase 2
	if sprite:
		sprite.modulate = Color(1, 0.3, 0.3)
		
		for i in range(8):
			sprite.rotation_degrees = 5 if i % 2 == 0 else -5
			await get_tree().create_timer(0.1).timeout
		
		sprite.rotation_degrees = 0
		sprite.modulate = Color(1.2, 0.8, 0.8)  # Slightly red tint
	
	# Increase speed di phase 2
	move_speed = 80.0
	min_attack_cooldown = 1.0
	max_attack_cooldown = 2.0
