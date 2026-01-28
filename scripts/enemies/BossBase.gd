# ===================================================
# BossBase.gd - Base Class untuk Semua Boss
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Semua boss mewarisi class ini. Fitur:
# - Multi-phase combat
# - Attack patterns
# - Reward ability setelah kalah
# ===================================================

extends EnemyBase
class_name BossBase

# --- SIGNALS ---
signal phase_changed(new_phase: int)
signal boss_defeated
signal attack_started(attack_name: String)

# === EXPORT VARIABLES ===

@export_group("Boss Info")
## Nama boss untuk display
@export var boss_name: String = "Boss"
## Jumlah phase boss
@export var total_phases: int = 1
## Ability yang di-unlock setelah kalah
@export var reward_ability: String = ""

@export_group("Phase Health")
## HP per phase (array)
@export var phase_health: Array[int] = [100]

@export_group("Attack Patterns")
## Cooldown minimum antara serangan
@export var min_attack_cooldown: float = 1.5
## Cooldown maksimum antara serangan
@export var max_attack_cooldown: float = 3.0

# === INTERNAL ===
var current_phase: int = 1
var phase_hp: int = 0
var is_attacking: bool = false
var attack_cooldown_timer: float = 0.0
var is_invulnerable: bool = false


func _on_ready() -> void:
	# Setup phase health
	if phase_health.size() > 0:
		phase_hp = phase_health[0]
		max_health = phase_hp
		current_health = phase_hp
	
	current_state = State.IDLE
	print("[Boss] %s muncul! Phase: %d/%d" % [boss_name, current_phase, total_phases])


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if is_dead:
		return
	
	# Attack cooldown
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	elif target_player and not is_attacking:
		_choose_attack()


# === PHASE SYSTEM ===

func take_damage(amount: int, _knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if is_invulnerable or is_dead:
		return
	
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	_flash_damage()
	
	# Cek phase transition atau death
	if current_health <= 0:
		if current_phase < total_phases:
			_transition_to_next_phase()
		else:
			_boss_defeated()


func _transition_to_next_phase() -> void:
	"""Pindah ke phase berikutnya."""
	current_phase += 1
	phase_changed.emit(current_phase)
	
	print("[Boss] %s masuk Phase %d!" % [boss_name, current_phase])
	
	# Invulnerable sebentar
	is_invulnerable = true
	is_attacking = false
	
	# Phase transition effect
	await _phase_transition_effect()
	
	# Setup HP phase baru
	if current_phase <= phase_health.size():
		phase_hp = phase_health[current_phase - 1]
	else:
		phase_hp = phase_health[-1]
	
	max_health = phase_hp
	current_health = phase_hp
	
	is_invulnerable = false


func _phase_transition_effect() -> void:
	"""Override untuk efek transisi phase."""
	# Default: flash dan pause
	if sprite:
		for i in range(5):
			sprite.modulate = Color(1, 1, 0)
			await get_tree().create_timer(0.1).timeout
			sprite.modulate = Color.WHITE
			await get_tree().create_timer(0.1).timeout


func _boss_defeated() -> void:
	"""Boss kalah, berikan reward."""
	is_dead = true
	current_state = State.DEAD
	
	print("[Boss] %s DIKALAHKAN!" % boss_name)
	boss_defeated.emit()
	
	# Unlock ability
	if reward_ability != "" and GameManager:
		match reward_ability:
			"dash":
				GameManager.unlock_dash()
			"double_jump":
				GameManager.unlock_double_jump()
			"glide":
				GameManager.unlock_glide()
	
	# Death effect
	await _death_effect()
	queue_free()


func _death_effect() -> void:
	"""Override untuk efek kematian boss."""
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "scale", Vector2(2, 2), 0.5)
		tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.5)
		await tween.finished


# === ATTACK SYSTEM ===

func _choose_attack() -> void:
	"""Override di subclass untuk memilih serangan."""
	pass


func _start_attack(attack_name: String) -> void:
	"""Mulai serangan."""
	is_attacking = true
	attack_started.emit(attack_name)


func _end_attack() -> void:
	"""Akhiri serangan, set cooldown."""
	is_attacking = false
	attack_cooldown_timer = randf_range(min_attack_cooldown, max_attack_cooldown)


# === HELPER METHODS ===

func get_phase() -> int:
	return current_phase


func is_final_phase() -> bool:
	return current_phase >= total_phases
