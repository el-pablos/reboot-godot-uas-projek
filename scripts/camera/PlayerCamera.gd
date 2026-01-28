# ===================================================
# PlayerCamera.gd - Dynamic Camera with Juice
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Features:
# - Smooth position tracking with look-ahead
# - Screen shake for impacts
# - Zoom transitions
# - Boss fight framing
# ===================================================

extends Camera2D
class_name PlayerCamera

# === TARGET TRACKING ===
@export_group("Tracking")
@export var target: Node2D
@export var smoothing_speed: float = 10.0
@export var look_ahead_distance: float = 50.0  # Look ahead in movement direction
@export var look_ahead_speed: float = 3.0

# === SCREEN SHAKE ===
@export_group("Screen Shake")
@export var default_shake_intensity: float = 8.0
@export var default_shake_duration: float = 0.2
@export var shake_decay: float = 8.0  # How fast shake fades

# === ZOOM ===
@export_group("Zoom")
@export var default_zoom: Vector2 = Vector2(2.0, 2.0)
@export var boss_zoom: Vector2 = Vector2(1.5, 1.5)
@export var zoom_speed: float = 2.0

# === INTERNAL STATE ===
var target_position: Vector2 = Vector2.ZERO
var look_ahead_offset: Vector2 = Vector2.ZERO

# Shake state
var shake_intensity: float = 0.0
var shake_timer: float = 0.0
var current_shake_offset: Vector2 = Vector2.ZERO

# Zoom state
var target_zoom: Vector2 = Vector2(2.0, 2.0)
var is_boss_fight: bool = false

# Random number generator for shake
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	
	# Find player if not set
	if target == null:
		await get_tree().process_frame
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]
	
	# Start at target position
	if target:
		global_position = target.global_position
	
	# Apply default zoom
	zoom = default_zoom
	target_zoom = default_zoom
	
	print("[Camera] 📷 PlayerCamera ready!")


func _physics_process(delta: float) -> void:
	if target == null:
		return
	
	# Calculate look-ahead based on target velocity
	_update_look_ahead(delta)
	
	# Calculate target position
	target_position = target.global_position + look_ahead_offset
	
	# Smooth follow
	global_position = global_position.lerp(target_position, smoothing_speed * delta)
	
	# Apply screen shake
	_process_shake(delta)
	
	# Smooth zoom
	zoom = zoom.lerp(target_zoom, zoom_speed * delta)


# =========================================
# LOOK AHEAD
# =========================================

func _update_look_ahead(delta: float) -> void:
	if not target or not target is CharacterBody2D:
		return
	
	var velocity: Vector2 = (target as CharacterBody2D).velocity
	var target_look_ahead := Vector2.ZERO
	
	# Horizontal look ahead
	if absf(velocity.x) > 50.0:
		target_look_ahead.x = sign(velocity.x) * look_ahead_distance
	
	# Optional: slight vertical look ahead when falling
	if velocity.y > 200.0:
		target_look_ahead.y = look_ahead_distance * 0.3
	
	look_ahead_offset = look_ahead_offset.lerp(target_look_ahead, look_ahead_speed * delta)


# =========================================
# SCREEN SHAKE
# =========================================

func shake(intensity: float = -1.0, duration: float = -1.0) -> void:
	"""Trigger screen shake.
	
	Args:
		intensity: Shake strength in pixels. -1 uses default.
		duration: Shake duration in seconds. -1 uses default.
	"""
	if intensity < 0:
		intensity = default_shake_intensity
	if duration < 0:
		duration = default_shake_duration
	
	shake_intensity = maxf(shake_intensity, intensity)  # Don't reduce ongoing shake
	shake_timer = maxf(shake_timer, duration)
	
	# print("[Camera] 🔫 Shake: intensity=%.1f, duration=%.2f" % [intensity, duration])


func _process_shake(delta: float) -> void:
	if shake_timer <= 0:
		current_shake_offset = Vector2.ZERO
		offset = Vector2.ZERO
		return
	
	shake_timer -= delta
	
	# Calculate shake with decay
	var progress := shake_timer / default_shake_duration
	var current_intensity := shake_intensity * progress
	
	# Random offset
	current_shake_offset = Vector2(
		rng.randf_range(-current_intensity, current_intensity),
		rng.randf_range(-current_intensity, current_intensity)
	)
	
	offset = current_shake_offset
	
	# Reset when done
	if shake_timer <= 0:
		shake_intensity = 0.0


# =========================================
# ZOOM CONTROL
# =========================================

func set_zoom_level(new_zoom: Vector2, instant: bool = false) -> void:
	"""Change camera zoom.
	
	Args:
		new_zoom: Target zoom level.
		instant: If true, skip smooth transition.
	"""
	target_zoom = new_zoom
	if instant:
		zoom = new_zoom


func enter_boss_fight(_boss_position: Vector2 = Vector2.ZERO) -> void:
	"""Zoom out for boss fight visibility."""
	is_boss_fight = true
	target_zoom = boss_zoom
	print("[Camera] 👹 Boss fight mode - zooming out")


func exit_boss_fight() -> void:
	"""Return to normal zoom after boss fight."""
	is_boss_fight = false
	target_zoom = default_zoom
	print("[Camera] ✅ Boss defeated - normal zoom")


# =========================================
# CONVENIENCE PRESETS
# =========================================

func shake_small() -> void:
	"""Small shake - light impact."""
	shake(4.0, 0.1)


func shake_medium() -> void:
	"""Medium shake - hit, dash impact."""
	shake(8.0, 0.2)


func shake_large() -> void:
	"""Large shake - boss hit, explosion."""
	shake(16.0, 0.35)


func shake_epic() -> void:
	"""Epic shake - boss death, major event."""
	shake(24.0, 0.5)
