# ===================================================
# BossBrain.gd - Smart Boss AI State Machine
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Reusable AI component untuk semua boss.
# Ditambahkan sebagai child node dari BossBase.
# Menggunakan state machine + utility scoring.
#
# States: ROAM, CHASE, ATTACK_CLOSE, ATTACK_FAR,
#         REPOSITION, RECOVER, PHASE_CHANGE
# ===================================================

extends Node
class_name BossBrain

# --- SIGNALS ---
signal state_changed(old_state: int, new_state: int)
signal attack_requested(attack_type: String)
signal telegraph_started(duration: float)
signal reposition_requested(direction: Vector2)

# === AI States ===
enum AIState {
	ROAM,
	CHASE,
	ATTACK_CLOSE,
	ATTACK_FAR,
	REPOSITION,
	RECOVER,
	PHASE_CHANGE
}

# === Config ===
var config: BossConfig

# === References ===
var boss: Node = null  # BossBase parent
var target: Node = null  # Player target
var los_raycast: RayCast2D = null

# === State ===
var current_state: AIState = AIState.ROAM
var previous_state: AIState = AIState.ROAM
var state_timer: float = 0.0

# === Chase ===
var current_chase_speed: float = 0.0  # Accelerated chase speed
var chase_direction: Vector2 = Vector2.ZERO

# === Attack ===
var attack_cooldown_timer: float = 0.0
var is_telegraphing: bool = false
var telegraph_timer: float = 0.0
var last_attack_type: String = ""
var attacks_since_reposition: int = 0

# === Recover ===
var recover_timer: float = 0.0

# === Arena ===
var arena_rect: Rect2 = Rect2()
var initial_position: Vector2 = Vector2.ZERO

# === Roam ===
var roam_direction: float = 1.0
var roam_timer: float = 0.0
var roam_change_interval: float = 2.5

# === Phase tracking ===
var phase_applied: int = 0  # Track which phase modifiers have been applied

# === Unstuck Guard ===
var _last_position: Vector2 = Vector2.ZERO
var _stuck_timer: float = 0.0
var _stuck_threshold: float = 2.0  # detik diam = dianggap stuck
var _stuck_move_threshold: float = 3.0  # px minimum gerak per frame agar tidak stuck
var _unstuck_nudge_force: float = 150.0


func _ready() -> void:
	boss = get_parent()
	if not boss:
		push_warning("[BossBrain] Tidak ada parent boss node!")
		return

	initial_position = boss.global_position

	# Setup arena bounds
	if config:
		var center: Vector2 = initial_position + config.arena_center
		arena_rect = Rect2(
			center - config.arena_size / 2,
			config.arena_size
		)
	else:
		arena_rect = Rect2(initial_position - Vector2(300, 200), Vector2(600, 400))

	# Setup RayCast2D untuk LOS
	_setup_raycast()

	print("[BossBrain] AI aktif untuk: %s | Arena: %s" % [boss.name, arena_rect])


func _physics_process(delta: float) -> void:
	if not boss or not is_instance_valid(boss):
		return
	if boss.get("is_dead") and boss.is_dead:
		return

	_update_target()
	_update_timers(delta)
	_update_state(delta)
	_execute_state(delta)
	_check_unstuck(delta)
	_clamp_to_arena()


# === TARGET ACQUISITION ===

func _update_target() -> void:
	"""Lock/release target player berdasarkan jarak."""
	if not config:
		return

	# Cari player
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		# Fallback: cari node Player di scene
		var player_node = _find_player_in_tree()
		if player_node:
			players = [player_node]

	if players.is_empty():
		if target != null:
			target = null
			_change_state(AIState.ROAM)
		return

	var player: Node = players[0]
	var distance: float = boss.global_position.distance_to(player.global_position)

	if target == null:
		# Coba lock target
		if distance <= config.detect_range:
			target = player
			_change_state(AIState.CHASE)
			# Juga update parent boss target_player
			if boss.has_method("get") and "target_player" in boss:
				boss.target_player = player
	else:
		# Cek apakah masih valid
		if not is_instance_valid(target):
			target = null
			_change_state(AIState.ROAM)
		elif distance > config.lose_range:
			target = null
			if "target_player" in boss:
				boss.target_player = null
			_change_state(AIState.ROAM)


func _find_player_in_tree() -> Node:
	"""Fallback: cari Player node di scene tree."""
	var root := get_tree().current_scene
	if not root:
		return null
	for child in root.get_children():
		if child is CharacterBody2D and child.name == "Player":
			return child
		if child.get_script() and child.get_script().get_global_name() == "Player":
			return child
	return null


# === TIMERS ===

func _update_timers(delta: float) -> void:
	state_timer += delta

	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta

	if is_telegraphing:
		telegraph_timer -= delta
		if telegraph_timer <= 0:
			is_telegraphing = false

	if recover_timer > 0:
		recover_timer -= delta


# === STATE MACHINE ===

func _update_state(_delta: float) -> void:
	"""Transisi state berdasarkan kondisi."""
	if not config:
		return

	# Jangan ubah state saat telegraphing atau recovering
	if is_telegraphing or recover_timer > 0:
		return

	# Jangan ubah state saat boss sedang attacking (dari parent)
	if boss.get("is_attacking") and boss.is_attacking:
		return

	match current_state:
		AIState.ROAM:
			if target and is_instance_valid(target):
				_change_state(AIState.CHASE)

		AIState.CHASE:
			if not target or not is_instance_valid(target):
				_change_state(AIState.ROAM)
				return

			var distance: float = boss.global_position.distance_to(target.global_position)

			# Cek LOS
			if config.use_line_of_sight and not _has_line_of_sight():
				_change_state(AIState.REPOSITION)
				return

			# Cek attack cooldown
			if attack_cooldown_timer <= 0:
				if distance <= config.close_attack_range:
					_change_state(AIState.ATTACK_CLOSE)
				elif distance >= config.far_attack_min_range and distance <= config.far_attack_max_range:
					# Utility scoring: pilih antara ranged dan reposition
					if attacks_since_reposition >= 3 and randf() > 0.4:
						_change_state(AIState.REPOSITION)
					else:
						_change_state(AIState.ATTACK_FAR)
				elif distance > config.far_attack_max_range:
					# Terlalu jauh, tetap chase
					pass

		AIState.ATTACK_CLOSE, AIState.ATTACK_FAR:
			# State ini di-handle oleh boss script yang memanggil end_attack()
			pass

		AIState.REPOSITION:
			if state_timer > 0.8:  # Reposition selesai
				attacks_since_reposition = 0
				if target and is_instance_valid(target):
					_change_state(AIState.CHASE)
				else:
					_change_state(AIState.ROAM)

		AIState.RECOVER:
			if recover_timer <= 0:
				if target and is_instance_valid(target):
					_change_state(AIState.CHASE)
				else:
					_change_state(AIState.ROAM)

		AIState.PHASE_CHANGE:
			if state_timer > 1.5:  # Phase change animation selesai
				_change_state(AIState.CHASE)


func _execute_state(delta: float) -> void:
	"""Eksekusi behavior state saat ini."""
	if not boss:
		return

	match current_state:
		AIState.ROAM:
			_do_roam(delta)
		AIState.CHASE:
			_do_chase(delta)
		AIState.ATTACK_CLOSE:
			_do_attack_close()
		AIState.ATTACK_FAR:
			_do_attack_far()
		AIState.REPOSITION:
			_do_reposition(delta)
		AIState.RECOVER:
			_do_recover(delta)
		AIState.PHASE_CHANGE:
			_do_phase_change(delta)


func _change_state(new_state: AIState) -> void:
	if new_state == current_state:
		return

	previous_state = current_state
	current_state = new_state
	state_timer = 0.0

	state_changed.emit(previous_state, new_state)


# === STATE BEHAVIORS ===

func _do_roam(delta: float) -> void:
	"""Patrol kiri-kanan di arena."""
	roam_timer += delta

	if roam_timer >= roam_change_interval:
		roam_timer = 0.0
		roam_direction *= -1.0

	var roam_speed: float = 30.0
	if config:
		roam_speed = config.chase_speed * 0.3

	boss.velocity.x = roam_direction * roam_speed


func _do_chase(delta: float) -> void:
	"""Kejar player dengan akselerasi (tidak snap kaku)."""
	if not target or not is_instance_valid(target) or not config:
		boss.velocity.x = 0
		return

	# Jangan gerak saat boss lagi attacking
	if boss.get("is_attacking") and boss.is_attacking:
		return

	var to_player: Vector2 = target.global_position - boss.global_position
	var distance: float = to_player.length()
	var dir_x: float = sign(to_player.x)

	# Target speed berdasarkan jarak
	var target_speed: float = config.chase_speed

	# Phase-based speed boost
	if _is_aggressive_phase():
		target_speed *= config.phase_speed_multiplier

	# Jaga jarak preferred (jangan nempel player)
	if distance < config.preferred_distance * 0.5:
		dir_x = -dir_x  # Mundur
		target_speed *= 0.5
	elif distance < config.preferred_distance:
		target_speed *= 0.3

	# Akselerasi smooth (bukan snap)
	var target_vel: float = dir_x * target_speed
	current_chase_speed = move_toward(
		current_chase_speed,
		target_vel,
		config.chase_acceleration * delta
	)

	boss.velocity.x = current_chase_speed

	# Untuk flying boss (gravity = 0), chase vertikal juga
	if boss.get("gravity") != null and boss.gravity == 0:
		var target_y: float = target.global_position.y - 120  # Hover di atas
		var vy: float = sign(target_y - boss.global_position.y) * config.chase_speed * 0.6
		boss.velocity.y = move_toward(boss.velocity.y, vy, config.chase_acceleration * 0.5 * delta)


func _do_attack_close() -> void:
	"""Minta boss lakukan close attack."""
	if boss.get("is_attacking") and boss.is_attacking:
		return  # Sudah attacking

	# Telegraph dulu
	if not is_telegraphing and config and config.telegraph_duration > 0:
		_start_telegraph(config.telegraph_duration * 0.5)  # Telegraph lebih pendek untuk close
		return

	if is_telegraphing:
		return  # Masih telegraph

	attacks_since_reposition += 1
	attack_requested.emit("close")
	_set_attack_cooldown()


func _do_attack_far() -> void:
	"""Minta boss lakukan ranged attack."""
	if boss.get("is_attacking") and boss.is_attacking:
		return

	# Telegraph dulu (lebih lama untuk ranged)
	if not is_telegraphing and config and config.telegraph_duration > 0:
		_start_telegraph(config.telegraph_duration)
		return

	if is_telegraphing:
		return

	attacks_since_reposition += 1
	attack_requested.emit("far")
	_set_attack_cooldown()


func _do_reposition(delta: float) -> void:
	"""Reposition: mundur/dodge dari player."""
	if not target or not is_instance_valid(target) or not config:
		boss.velocity.x = 0
		return

	var away_from_player: Vector2 = (boss.global_position - target.global_position).normalized()

	# Pick reposition direction (mundur atau ke samping)
	var repo_dir: Vector2 = away_from_player
	if randf() > 0.5:
		repo_dir = Vector2(away_from_player.y, -away_from_player.x)  # Perpendicular

	boss.velocity.x = repo_dir.x * config.reposition_speed
	if boss.get("gravity") != null and boss.gravity == 0:
		boss.velocity.y = repo_dir.y * config.reposition_speed * 0.5


func _do_recover(_delta: float) -> void:
	"""Recovery state - boss diam sebentar (vulnerability window)."""
	boss.velocity.x = move_toward(boss.velocity.x, 0, 200 * _delta)
	if boss.get("gravity") != null and boss.gravity == 0:
		boss.velocity.y = move_toward(boss.velocity.y, 0, 100 * _delta)


func _do_phase_change(_delta: float) -> void:
	"""Phase change - boss pause dan berubah."""
	boss.velocity.x = 0
	boss.velocity.y = 0


# === TELEGRAPH ===

func _start_telegraph(duration: float) -> void:
	"""Mulai telegraph sebelum serangan."""
	is_telegraphing = true
	telegraph_timer = duration
	telegraph_started.emit(duration)

	# Visual telegraph: flash boss sprite
	if boss.get("sprite") and boss.sprite:
		boss.sprite.modulate = Color(1, 0.8, 0.3, 1)  # Kuning warning
		var tween := create_tween()
		if tween:
			tween.tween_property(boss.sprite, "modulate", Color.WHITE, duration)


# === ATTACK HELPERS ===

func _set_attack_cooldown() -> void:
	"""Set cooldown setelah attack."""
	if not config:
		attack_cooldown_timer = 2.0
		return

	var cd_min: float = config.attack_cooldown_min
	var cd_max: float = config.attack_cooldown_max

	# Phase-based cooldown reduction
	if _is_aggressive_phase():
		cd_min *= config.phase_cooldown_multiplier
		cd_max *= config.phase_cooldown_multiplier

	attack_cooldown_timer = randf_range(cd_min, cd_max)


func end_attack() -> void:
	"""Dipanggil oleh boss script setelah attack selesai."""
	_set_attack_cooldown()

	# Tentukan state selanjutnya
	if randf() < 0.3:
		recover_timer = config.recover_duration if config else 0.8
		_change_state(AIState.RECOVER)
	elif target and is_instance_valid(target):
		_change_state(AIState.CHASE)
	else:
		_change_state(AIState.ROAM)


func notify_phase_change() -> void:
	"""Dipanggil saat boss masuk phase baru."""
	_change_state(AIState.PHASE_CHANGE)
	attack_cooldown_timer = 0
	is_telegraphing = false


# === PHASE HELPERS ===

func _is_aggressive_phase() -> bool:
	"""Cek apakah boss sudah di fase agresif (HP rendah)."""
	if not boss or not config:
		return false
	var hp_ratio: float = float(boss.current_health) / float(boss.max_health) if boss.max_health > 0 else 1.0
	return hp_ratio <= config.aggression_hp_threshold


func is_extra_pattern_phase() -> bool:
	"""Cek apakah boss sudah di fase tambahan (HP sangat rendah)."""
	if not boss or not config:
		return false
	var hp_ratio: float = float(boss.current_health) / float(boss.max_health) if boss.max_health > 0 else 1.0
	return hp_ratio <= config.extra_pattern_hp_threshold


# === ARENA BOUNDS ===

# === UNSTUCK GUARD ===

func _check_unstuck(delta: float) -> void:
	"""Deteksi boss stuck (posisi hampir tidak berubah) dan nudge keluar."""
	if not boss or not is_instance_valid(boss):
		return

	# Jangan cek saat phase change atau recovering (memang diam)
	if current_state == AIState.PHASE_CHANGE or current_state == AIState.RECOVER:
		_stuck_timer = 0.0
		_last_position = boss.global_position
		return

	# Jangan cek saat attacking (boss bisa diam sebentar saat attack)
	if current_state == AIState.ATTACK_CLOSE or current_state == AIState.ATTACK_FAR:
		_stuck_timer = 0.0
		_last_position = boss.global_position
		return

	var delta_pos: float = boss.global_position.distance_to(_last_position)

	if delta_pos < _stuck_move_threshold:
		_stuck_timer += delta
	else:
		_stuck_timer = 0.0

	_last_position = boss.global_position

	# Kalau stuck terlalu lama, nudge!
	if _stuck_timer >= _stuck_threshold:
		_do_unstuck_nudge()
		_stuck_timer = 0.0


func _do_unstuck_nudge() -> void:
	"""Nudge boss ke arah aman saat terdeteksi stuck."""
	if not boss:
		return

	print("[BossBrain] UNSTUCK: Boss %s stuck, nudging!" % boss.name)

	# Strategi: nudge menuju target jika ada, atau ke arah arena center
	var nudge_dir: Vector2 = Vector2.ZERO

	if target and is_instance_valid(target):
		nudge_dir = (target.global_position - boss.global_position).normalized()
	else:
		# Nudge ke center arena
		var arena_center: Vector2 = arena_rect.position + arena_rect.size / 2
		nudge_dir = (arena_center - boss.global_position).normalized()

	# Untuk flying boss: nudge X dan Y
	if boss.get("gravity") != null and boss.gravity == 0:
		boss.velocity = nudge_dir * _unstuck_nudge_force
		# Juga teleport sedikit untuk keluar collider
		boss.global_position += nudge_dir * 20.0
	else:
		# Ground boss: hanya nudge horizontal + jump
		boss.velocity.x = nudge_dir.x * _unstuck_nudge_force
		boss.velocity.y = -200.0  # Kecil jump


func _clamp_to_arena() -> void:
	"""Pastikan boss tidak keluar arena."""
	if not boss or arena_rect.size == Vector2.ZERO:
		return

	var pos: Vector2 = boss.global_position
	pos.x = clampf(pos.x, arena_rect.position.x, arena_rect.end.x)
	pos.y = clampf(pos.y, arena_rect.position.y, arena_rect.end.y)
	boss.global_position = pos


func set_arena(center: Vector2, size: Vector2) -> void:
	"""Set arena bounds secara eksplisit."""
	arena_rect = Rect2(center - size / 2, size)


# === LINE OF SIGHT ===

func _setup_raycast() -> void:
	"""Setup RayCast2D untuk LOS check."""
	los_raycast = RayCast2D.new()
	los_raycast.name = "LOSRaycast"
	los_raycast.collision_mask = 4  # Environment layer
	los_raycast.enabled = true
	if boss:
		boss.add_child(los_raycast)


func _has_line_of_sight() -> bool:
	"""Cek apakah boss bisa lihat player (tidak terhalang tembok)."""
	if not los_raycast or not target or not is_instance_valid(target):
		return false

	if not config or not config.use_line_of_sight:
		return true  # Skip LOS check

	var to_target: Vector2 = target.global_position - boss.global_position
	los_raycast.target_position = to_target
	los_raycast.force_raycast_update()

	# Jika raycast hit sesuatu (environment), tidak ada LOS
	return not los_raycast.is_colliding()


# === PREDICTIVE AIMING ===

func get_predicted_target_position() -> Vector2:
	"""Hitung posisi player yang di-predict (lead target)."""
	if not target or not is_instance_valid(target):
		return boss.global_position

	var target_pos: Vector2 = target.global_position

	if config and config.use_predictive_aim and target is CharacterBody2D:
		var target_vel: Vector2 = target.velocity
		target_pos += target_vel * config.aim_lead_time

	return target_pos


# === UTILITY ===

func get_distance_to_target() -> float:
	"""Jarak boss ke target."""
	if not target or not is_instance_valid(target):
		return 9999.0
	return boss.global_position.distance_to(target.global_position)


func get_direction_to_target() -> Vector2:
	"""Arah dari boss ke target."""
	if not target or not is_instance_valid(target):
		return Vector2.ZERO
	return (target.global_position - boss.global_position).normalized()


func get_state_name() -> String:
	"""Nama state saat ini (untuk debug)."""
	match current_state:
		AIState.ROAM: return "ROAM"
		AIState.CHASE: return "CHASE"
		AIState.ATTACK_CLOSE: return "ATTACK_CLOSE"
		AIState.ATTACK_FAR: return "ATTACK_FAR"
		AIState.REPOSITION: return "REPOSITION"
		AIState.RECOVER: return "RECOVER"
		AIState.PHASE_CHANGE: return "PHASE_CHANGE"
	return "UNKNOWN"
