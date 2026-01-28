# ===================================================
# PlayerStateMachine.gd - State Machine untuk Player
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Mengelola transisi state player: Idle, Run, Jump, Fall, Dash, Glide.
# ===================================================

extends Node
class_name PlayerStateMachine

# --- SIGNALS ---
signal state_changed(old_state: String, new_state: String)

# --- ENUM STATE ---
enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
	DASH,
	GLIDE,
	HURT,
	DEAD
}

# --- STATE NAMES (untuk debugging) ---
const STATE_NAMES: Dictionary = {
	State.IDLE: "IDLE",
	State.RUN: "RUN",
	State.JUMP: "JUMP",
	State.FALL: "FALL",
	State.DASH: "DASH",
	State.GLIDE: "GLIDE",
	State.HURT: "HURT",
	State.DEAD: "DEAD"
}

# --- CURRENT STATE ---
var current_state: State = State.IDLE
var previous_state: State = State.IDLE

# --- REFERENCE KE PLAYER ---
var player: CharacterBody2D


func _ready() -> void:
	pass


func setup(player_ref: CharacterBody2D) -> void:
	"""Inisialisasi dengan referensi ke player."""
	player = player_ref
	print("[StateMachine] Setup selesai, state awal: %s" % get_state_name())


func get_state_name() -> String:
	"""Ambil nama state sekarang."""
	return STATE_NAMES.get(current_state, "UNKNOWN")


func get_previous_state_name() -> String:
	"""Ambil nama state sebelumnya."""
	return STATE_NAMES.get(previous_state, "UNKNOWN")


func change_state(new_state: State) -> void:
	"""Ganti ke state baru."""
	if current_state == new_state:
		return  # Sudah di state yang sama
	
	# Jangan bisa ganti state kalau dead
	if current_state == State.DEAD and new_state != State.IDLE:
		return
	
	previous_state = current_state
	current_state = new_state
	
	var old_name: String = STATE_NAMES.get(previous_state, "UNKNOWN")
	var new_name: String = STATE_NAMES.get(new_state, "UNKNOWN")
	
	state_changed.emit(old_name, new_name)
	# print("[StateMachine] State: %s -> %s" % [old_name, new_name])


func is_state(check_state: State) -> bool:
	"""Cek apakah sedang di state tertentu."""
	return current_state == check_state


func is_grounded_state() -> bool:
	"""Cek apakah state sekarang adalah grounded (Idle/Run)."""
	return current_state in [State.IDLE, State.RUN]


func is_air_state() -> bool:
	"""Cek apakah state sekarang adalah di udara."""
	return current_state in [State.JUMP, State.FALL, State.GLIDE]


func can_jump() -> bool:
	"""Cek apakah bisa lompat dari state sekarang."""
	return current_state in [State.IDLE, State.RUN, State.FALL]


func can_dash() -> bool:
	"""Cek apakah bisa dash dari state sekarang."""
	return current_state in [State.IDLE, State.RUN, State.JUMP, State.FALL]


func can_glide() -> bool:
	"""Cek apakah bisa glide dari state sekarang."""
	return current_state in [State.JUMP, State.FALL]


func reset() -> void:
	"""Reset state ke IDLE."""
	previous_state = current_state
	current_state = State.IDLE
