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

# === BOSS BRAIN ===
var brain: BossBrain = null


# === NULL SAFETY HELPERS ===
# Use these instead of raw await to prevent crashes when boss dies mid-animation

func _safe_await_timer(duration: float) -> bool:
	"""Safely await a timer. Returns false if node was freed/removed."""
	if not is_inside_tree() or is_queued_for_deletion():
		return false
	var tree := get_tree()
	if tree == null:
		return false
	await tree.create_timer(duration).timeout
	return is_inside_tree() and not is_queued_for_deletion()


func _safe_await_frame() -> bool:
	"""Safely await next frame. Returns false if node was freed/removed."""
	if not is_inside_tree() or is_queued_for_deletion():
		return false
	var tree := get_tree()
	if tree == null:
		return false
	await tree.process_frame
	return is_inside_tree() and not is_queued_for_deletion()


func _is_valid_for_attack() -> bool:
	"""Check if boss can continue attacking."""
	return is_inside_tree() and not is_queued_for_deletion() and not is_dead and get_tree() != null


func _on_ready() -> void:
	# Setup phase health
	if phase_health.size() > 0:
		phase_hp = phase_health[0]
		max_health = phase_hp
		current_health = phase_hp
	
	current_state = State.IDLE
	
	# Setup BossBrain jika ada
	_setup_brain()
	
	print("[Boss] %s muncul! Script: %s | Phase: %d/%d | Brain: %s" % [
		boss_name, get_script().resource_path.get_file(),
		current_phase, total_phases,
		"aktif" if brain else "tidak ada"
	])


func _setup_brain() -> void:
	"""Setup BossBrain AI. Override di subclass untuk config spesifik."""
	# Subclass harus override dan call _create_brain(config)
	pass


func _create_brain(config: BossConfig) -> void:
	"""Buat BossBrain dengan config tertentu."""
	brain = BossBrain.new()
	brain.name = "BossBrain"
	brain.config = config
	add_child(brain)
	
	# Connect BossBrain signals
	brain.attack_requested.connect(_on_brain_attack_requested)
	brain.telegraph_started.connect(_on_brain_telegraph)


func _on_brain_attack_requested(attack_type: String) -> void:
	"""BossBrain minta serangan. Override di subclass."""
	_choose_attack()


func _on_brain_telegraph(duration: float) -> void:
	"""BossBrain mulai telegraph. Override untuk custom effect."""
	pass


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if is_dead:
		return
	
	# Attack cooldown (hanya jika tidak pakai BossBrain)
	if not brain:
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
	
	# Notify BossBrain
	if brain:
		brain.notify_phase_change()


func _phase_transition_effect() -> void:
	"""Override untuk efek transisi phase."""
	# Default: flash dan pause
	if sprite:
		for i in range(5):
			if not _is_valid_for_attack():
				return
			sprite.modulate = Color(1, 1, 0)
			if not await _safe_await_timer(0.1):
				return
			sprite.modulate = Color.WHITE
			if not await _safe_await_timer(0.1):
				return


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
	
	# Death effect (with safety check)
	if _is_valid_for_attack():
		await _death_effect()
	
	if is_inside_tree():
		queue_free()


func _death_effect() -> void:
	"""Override untuk efek kematian boss."""
	if not _is_valid_for_attack():
		return
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "scale", Vector2(2, 2), 0.5)
		tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.5)
		if tween:
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
	if brain:
		brain.end_attack()
	else:
		attack_cooldown_timer = randf_range(min_attack_cooldown, max_attack_cooldown)


# === HELPER METHODS ===

func get_phase() -> int:
	return current_phase


func is_final_phase() -> bool:
	return current_phase >= total_phases
