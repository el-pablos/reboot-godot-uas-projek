extends Control
class_name ModernHealthUI
## Stylish health UI with animations, glow effects, and juice.
## Features smooth damage/heal transitions and low health warnings.

# =========================================
# SIGNALS
# =========================================

signal health_depleted
signal low_health_warning

# =========================================
# EXPORTS
# =========================================

@export_group("Health Values")
@export var max_health: int = 100
@export var current_health: int = 100

@export_group("Visual Settings")
@export var bar_color: Color = Color(0.2, 0.8, 0.4, 1.0)
@export var bar_color_low: Color = Color(0.9, 0.2, 0.2, 1.0)
@export var bar_color_damage: Color = Color(1.0, 0.4, 0.2, 1.0)
@export var bar_glow_color: Color = Color(0.3, 1.0, 0.5, 1.0)
@export var low_health_threshold: float = 0.3

@export_group("Animation")
@export var damage_animation_duration: float = 0.3
@export var heal_animation_duration: float = 0.5
@export var shake_intensity: float = 5.0
@export var pulse_speed: float = 3.0

# =========================================
# NODES
# =========================================

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var damage_bar: TextureProgressBar = $DamageBar  # Shows delayed damage
@onready var health_label: Label = $HealthLabel
@onready var health_icon: TextureRect = $HealthIcon
@onready var glow_effect: ColorRect = $GlowEffect
@onready var container: Control = $Container

# =========================================
# VARIABLES
# =========================================

var _target_health: int = 100
var _displayed_health: float = 100.0
var _damage_display: float = 100.0
var _is_low_health: bool = false
var _shake_offset: Vector2 = Vector2.ZERO  # Reserved for future shake animation
var _time: float = 0.0
var _original_position: Vector2

# =========================================
# LIFECYCLE
# =========================================

func _ready() -> void:
	_setup_ui()
	_original_position = container.position if container else Vector2.ZERO
	set_health(current_health, max_health, false)


func _process(delta: float) -> void:
	_time += delta
	_update_animations(delta)
	_update_low_health_effects()


# =========================================
# SETUP
# =========================================

func _setup_ui() -> void:
	"""Initialize UI elements if they don't exist."""
	if not health_bar:
		_create_default_ui()


func _create_default_ui() -> void:
	"""Create a default health bar UI programmatically."""
	# Container
	container = Control.new()
	container.name = "Container"
	container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	container.position = Vector2(20, 20)
	container.size = Vector2(200, 30)
	add_child(container)
	
	# Background
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.size = Vector2(200, 24)
	bg.color = Color(0.1, 0.1, 0.15, 0.9)
	container.add_child(bg)
	
	# Damage bar (behind main bar, shows recent health)
	damage_bar = TextureProgressBar.new()
	damage_bar.name = "DamageBar"
	damage_bar.size = Vector2(196, 20)
	damage_bar.position = Vector2(2, 2)
	damage_bar.max_value = 100
	damage_bar.value = 100
	damage_bar.nine_patch_stretch = true
	container.add_child(damage_bar)
	
	# Main health bar
	health_bar = TextureProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.size = Vector2(196, 20)
	health_bar.position = Vector2(2, 2)
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.nine_patch_stretch = true
	container.add_child(health_bar)
	
	# Health label
	health_label = Label.new()
	health_label.name = "HealthLabel"
	health_label.size = Vector2(200, 24)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_label.text = "100 / 100"
	health_label.add_theme_font_size_override("font_size", 12)
	container.add_child(health_label)
	
	# Glow effect
	glow_effect = ColorRect.new()
	glow_effect.name = "GlowEffect"
	glow_effect.size = Vector2(204, 28)
	glow_effect.position = Vector2(-2, -2)
	glow_effect.color = bar_glow_color
	glow_effect.modulate.a = 0.0  # Start invisible
	container.add_child(glow_effect)
	container.move_child(glow_effect, 0)  # Send to back


# =========================================
# HEALTH MANAGEMENT
# =========================================

func set_health(health: int, max_hp: int = -1, animate: bool = true) -> void:
	"""Set health value with optional animation."""
	if max_hp > 0:
		max_health = max_hp
		if health_bar:
			health_bar.max_value = max_health
		if damage_bar:
			damage_bar.max_value = max_health
	
	var old_health := current_health
	current_health = clampi(health, 0, max_health)
	_target_health = current_health
	
	if animate:
		if current_health < old_health:
			_animate_damage(old_health, current_health)
		elif current_health > old_health:
			_animate_heal(old_health, current_health)
	else:
		_displayed_health = float(current_health)
		_damage_display = float(current_health)
		_update_bar_display()
	
	# Check for death
	if current_health <= 0:
		health_depleted.emit()
	
	# Check for low health
	var health_ratio := float(current_health) / float(max_health)
	if health_ratio <= low_health_threshold and not _is_low_health:
		_is_low_health = true
		low_health_warning.emit()
	elif health_ratio > low_health_threshold:
		_is_low_health = false


func take_damage(amount: int) -> void:
	"""Take damage with full visual feedback."""
	var new_health: int = maxi(0, current_health - amount)
	set_health(new_health, -1, true)
	_trigger_damage_effects()


func heal(amount: int) -> void:
	"""Heal with visual feedback."""
	var new_health: int = mini(max_health, current_health + amount)
	set_health(new_health, -1, true)
	_trigger_heal_effects()


# =========================================
# ANIMATIONS
# =========================================

func _animate_damage(_from: int, to: int) -> void:
	"""Animate health bar going down with damage trail."""
	# Immediate health bar drop
	var tween := create_tween()
	tween.tween_property(self, "_displayed_health", float(to), damage_animation_duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	
	# Delayed damage bar (shows where health was)
	var damage_tween := create_tween()
	damage_tween.tween_interval(0.3)  # Small delay
	damage_tween.tween_property(self, "_damage_display", float(to), damage_animation_duration * 0.8)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)


func _animate_heal(_from: int, to: int) -> void:
	"""Animate health bar going up."""
	var tween := create_tween()
	tween.tween_property(self, "_displayed_health", float(to), heal_animation_duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(self, "_damage_display", float(to), heal_animation_duration * 0.5)


func _trigger_damage_effects() -> void:
	"""Trigger visual effects for taking damage."""
	_shake_bar()
	_flash_bar(bar_color_damage)


func _trigger_heal_effects() -> void:
	"""Trigger visual effects for healing."""
	_pulse_glow(bar_glow_color)


func _shake_bar() -> void:
	"""Shake the health bar container."""
	if not container:
		return
	
	var tween := create_tween()
	var duration := 0.05
	
	for i in range(4):
		var offset := Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity * 0.5, shake_intensity * 0.5)
		)
		tween.tween_property(container, "position", _original_position + offset, duration)
	
	tween.tween_property(container, "position", _original_position, duration)


func _flash_bar(flash_color: Color) -> void:
	"""Flash the health bar a color briefly."""
	if not health_bar:
		return
	
	var original_modulate := health_bar.modulate
	var tween := create_tween()
	tween.tween_property(health_bar, "modulate", flash_color, 0.05)
	tween.tween_property(health_bar, "modulate", original_modulate, 0.15)


func _pulse_glow(glow_color: Color) -> void:
	"""Pulse the glow effect."""
	if not glow_effect:
		return
	
	glow_effect.color = glow_color
	var tween := create_tween()
	tween.tween_property(glow_effect, "modulate:a", 0.5, 0.1)
	tween.tween_property(glow_effect, "modulate:a", 0.0, 0.3)


# =========================================
# UPDATE LOOPS
# =========================================

func _update_animations(_delta: float) -> void:
	"""Update bar display values."""
	_update_bar_display()


func _update_bar_display() -> void:
	"""Update visual bar values."""
	if health_bar:
		health_bar.value = _displayed_health
	
	if damage_bar:
		damage_bar.value = _damage_display
	
	if health_label:
		health_label.text = "%d / %d" % [int(_displayed_health), max_health]


func _update_low_health_effects() -> void:
	"""Pulse effects when health is low."""
	if not _is_low_health:
		return
	
	# Pulse the bar color between normal and warning
	var pulse := (sin(_time * pulse_speed) + 1.0) * 0.5
	if health_bar:
		health_bar.modulate = bar_color.lerp(bar_color_low, pulse)
	
	# Pulse the glow
	if glow_effect:
		glow_effect.color = bar_color_low
		glow_effect.modulate.a = pulse * 0.3


# =========================================
# UTILITY
# =========================================

func get_health_ratio() -> float:
	"""Get current health as a ratio 0-1."""
	return float(current_health) / float(max_health)


func is_alive() -> bool:
	"""Check if still alive."""
	return current_health > 0


func is_full_health() -> bool:
	"""Check if at full health."""
	return current_health >= max_health
