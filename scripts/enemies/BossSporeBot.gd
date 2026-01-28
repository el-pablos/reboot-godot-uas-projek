# ===================================================
# BossSporeBot.gd - Boss Level 3: Spore-Bot
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Boss laboratorium - spawn minion jamur, area poison damage.
# Reward: Double Jump
# ===================================================

extends BossBase
class_name BossSporeBot

@export_group("Spore Attacks")
## Jumlah maksimal minion aktif
@export var max_minions: int = 3
## Damage poison area
@export var poison_damage: int = 10
## Radius poison area
@export var poison_radius: float = 120.0
## Durasi poison effect
@export var poison_duration: float = 3.0

# Internal
var active_minions: Array = []
var poison_zones: Array = []


func _on_ready() -> void:
	super._on_ready()
	
	boss_name = "Spore-Bot"
	total_phases = 2
	phase_health = [120, 150]
	reward_ability = "double_jump"
	
	max_health = phase_health[0]
	current_health = max_health
	
	contact_damage = 20
	move_speed = 40.0
	gravity = 0  # Spore-Bot melayang


func _process_chase(_delta: float) -> void:
	if not target_player or is_attacking:
		return
	
	# Hover movement - tetap jaga jarak
	var dir := get_direction_to_player()
	var distance := global_position.distance_to(target_player.global_position)
	
	if distance < 150:
		# Mundur
		velocity.x = -sign(dir.x) * move_speed
	elif distance > 250:
		# Mendekat
		velocity.x = sign(dir.x) * move_speed * 0.5
	else:
		velocity.x = 0
	
	# Hover up-down
	velocity.y = sin(Time.get_ticks_msec() * 0.003) * 30


func _choose_attack() -> void:
	if not target_player:
		return
	
	# Pilih attack random
	var attack_roll := randf()
	
	if attack_roll < 0.4 and active_minions.size() < max_minions:
		_attack_spawn_minion()
	elif attack_roll < 0.7:
		_attack_poison_cloud()
	else:
		_attack_spore_burst()


func _attack_spawn_minion() -> void:
	"""Spawn minion jamur kecil."""
	_start_attack("spawn_minion")
	
	# Animation spawn
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.2, 0.8), 0.2)
		tween.tween_property(sprite, "scale", Vector2.ONE, 0.2)
		await tween.finished
	else:
		await get_tree().create_timer(0.4).timeout
	
	# Spawn minion (simplified - just visual)
	var minion := _create_minion()
	if minion:
		active_minions.append(minion)
		get_parent().add_child(minion)
		minion.global_position = global_position + Vector2(randf_range(-30, 30), 50)
	
	print("[Spore-Bot] Spawned minion! Total: %d" % active_minions.size())
	
	await get_tree().create_timer(0.3).timeout
	_end_attack()


func _create_minion() -> Node2D:
	"""Buat minion sederhana."""
	# Simplified minion - gunakan scene jika ada
	var minion := CharacterBody2D.new()
	minion.name = "SporeMinion"
	
	# Visual
	var minion_sprite := ColorRect.new()
	minion_sprite.size = Vector2(20, 20)
	minion_sprite.position = Vector2(-10, -10)
	minion_sprite.color = Color(0.4, 0.8, 0.3)
	minion.add_child(minion_sprite)
	
	# Collision
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10
	col.shape = shape
	minion.add_child(col)
	
	minion.collision_layer = 2
	minion.collision_mask = 5
	
	# Simple AI script bisa ditambahkan
	
	# Auto destroy after time
	get_tree().create_timer(10.0).timeout.connect(func():
		if is_instance_valid(minion):
			active_minions.erase(minion)
			minion.queue_free()
	)
	
	return minion


func _attack_poison_cloud() -> void:
	"""Buat area poison di sekitar player."""
	_start_attack("poison_cloud")
	
	if not target_player:
		_end_attack()
		return
	
	# Telegraf - tunjukkan area yang akan kena
	var target_pos := target_player.global_position
	
	# Create poison zone visual
	var poison_zone := Area2D.new()
	poison_zone.global_position = target_pos
	
	var visual := ColorRect.new()
	visual.size = Vector2(poison_radius * 2, poison_radius * 2)
	visual.position = Vector2(-poison_radius, -poison_radius)
	visual.color = Color(0.2, 0.8, 0.2, 0.3)
	poison_zone.add_child(visual)
	
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = poison_radius
	col.shape = shape
	poison_zone.add_child(col)
	
	poison_zone.collision_layer = 8
	poison_zone.collision_mask = 1
	
	get_parent().add_child(poison_zone)
	poison_zones.append(poison_zone)
	
	# Poison tick damage
	var time := 0.0
	while time < poison_duration:
		await get_tree().create_timer(0.5).timeout
		time += 0.5
		
		if target_player and poison_zone:
			if target_player.global_position.distance_to(poison_zone.global_position) < poison_radius:
				target_player.take_damage(poison_damage)
	
	# Remove poison zone
	if is_instance_valid(poison_zone):
		poison_zones.erase(poison_zone)
		poison_zone.queue_free()
	
	_end_attack()


func _attack_spore_burst() -> void:
	"""Burst spore ke segala arah - damage jika kena."""
	_start_attack("spore_burst")
	
	# Charge up
	if sprite:
		sprite.modulate = Color(0.5, 1, 0.5)
		var tween := create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.5)
		await tween.finished
	else:
		await get_tree().create_timer(0.5).timeout
	
	# BURST!
	if sprite:
		sprite.scale = Vector2.ONE
		sprite.modulate = Color.WHITE
	
	# Create burst visual (particles bisa ditambahkan)
	# Check damage ke player dalam radius
	if target_player:
		var distance := global_position.distance_to(target_player.global_position)
		if distance < 150:
			var knockback := (target_player.global_position - global_position).normalized()
			target_player.take_damage(25, knockback * 200)
	
	await get_tree().create_timer(0.5).timeout
	_end_attack()


func _phase_transition_effect() -> void:
	# Phase 2 - more aggressive, more minions
	if sprite:
		for i in range(6):
			sprite.modulate = Color(0.3, 1, 0.3) if i % 2 == 0 else Color.WHITE
			await get_tree().create_timer(0.15).timeout
	
	max_minions = 5
	poison_radius = 150.0
	min_attack_cooldown = 0.8
	max_attack_cooldown = 1.5


func _boss_defeated() -> void:
	# Clean up minions
	for minion in active_minions:
		if is_instance_valid(minion):
			minion.queue_free()
	active_minions.clear()
	
	# Clean up poison zones
	for zone in poison_zones:
		if is_instance_valid(zone):
			zone.queue_free()
	poison_zones.clear()
	
	super._boss_defeated()
