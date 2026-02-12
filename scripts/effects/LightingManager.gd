extends Node2D
class_name LightingManager
## Manages dynamic lighting effects for the Neon Ruins aesthetic.
## Handles ambient lighting, player lights, and environmental glow.

# =========================================
# EXPORTS
# =========================================

@export_group("Ambient Lighting")
@export var ambient_color: Color = Color(0.15, 0.2, 0.3, 1.0)
@export var ambient_energy: float = 0.3

@export_group("Glow Settings")
@export var glow_intensity: float = 0.8
@export var glow_bloom: float = 0.3

@export_group("Hazard Lighting")
@export var hazard_color: Color = Color(1.0, 0.3, 0.1, 1.0)
@export var hazard_pulse_speed: float = 2.0

@export_group("Collectible Lighting")
@export var collectible_color: Color = Color(0.3, 1.0, 0.5, 1.0)
@export var collectible_pulse_speed: float = 3.0

# =========================================
# NODES
# =========================================

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

# =========================================
# VARIABLES
# =========================================

var _time: float = 0.0
var _active_lights: Array[PointLight2D] = []

# =========================================
# LIFECYCLE
# =========================================

func _ready() -> void:
	# Create WorldEnvironment if not present
	if not world_environment:
		world_environment = WorldEnvironment.new()
		world_environment.name = "WorldEnvironment"
		add_child(world_environment)
		
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.05, 0.05, 0.1, 1)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = ambient_color
		env.ambient_light_energy = ambient_energy
		env.glow_enabled = true
		env.glow_intensity = glow_intensity
		env.glow_bloom = glow_bloom
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
		env.glow_hdr_threshold = 0.8
		world_environment.environment = env
	
	# Create CanvasModulate for 2D darkness if not present
	if not canvas_modulate:
		canvas_modulate = CanvasModulate.new()
		canvas_modulate.name = "CanvasModulate"
		canvas_modulate.color = Color(0.3, 0.35, 0.5, 1.0)  # Slight blue tint darkness
		add_child(canvas_modulate)
	
	# Find all lights in scene
	_find_scene_lights()


func _process(delta: float) -> void:
	_time += delta
	_update_pulsing_lights()


# =========================================
# LIGHT MANAGEMENT
# =========================================

func _find_scene_lights() -> void:
	## Find and categorize all PointLight2D nodes in the scene.
	_active_lights.clear()
	var lights := get_tree().get_nodes_in_group("dynamic_lights")
	for light in lights:
		if light is PointLight2D:
			_active_lights.append(light)


func _update_pulsing_lights() -> void:
	## Update pulsing effects for hazard and collectible lights.
	for light in _active_lights:
		if light.is_in_group("hazard_lights"):
			var pulse := (sin(_time * hazard_pulse_speed) + 1.0) * 0.5
			light.energy = 0.6 + pulse * 0.4
		elif light.is_in_group("collectible_lights"):
			var pulse := (sin(_time * collectible_pulse_speed) + 1.0) * 0.5
			light.energy = 0.8 + pulse * 0.3


func register_light(light: PointLight2D) -> void:
	## Register a new dynamic light.
	if light not in _active_lights:
		_active_lights.append(light)
		light.add_to_group("dynamic_lights")


func unregister_light(light: PointLight2D) -> void:
	## Unregister a dynamic light.
	_active_lights.erase(light)


# =========================================
# VISUAL EFFECTS
# =========================================

func flash_screen(color: Color = Color.WHITE, duration: float = 0.1) -> void:
	## Flash the screen briefly (for impacts, damage, etc.).
	if canvas_modulate:
		var original := canvas_modulate.color
		var tween := create_tween()
		tween.tween_property(canvas_modulate, "color", color, duration * 0.3)
		tween.tween_property(canvas_modulate, "color", original, duration * 0.7)


func set_danger_mode(enabled: bool, transition_time: float = 0.5) -> void:
	## Shift lighting to danger/alert mode.
	if canvas_modulate:
		var target_color := Color(0.5, 0.2, 0.2, 1.0) if enabled else Color(0.3, 0.35, 0.5, 1.0)
		var tween := create_tween()
		tween.tween_property(canvas_modulate, "color", target_color, transition_time)


func pulse_light_at(pos: Vector2, color: Color = Color.WHITE, radius: float = 100.0, duration: float = 0.3) -> void:
	## Create a temporary light pulse at a position.
	var light := PointLight2D.new()
	light.global_position = pos
	light.color = color
	light.energy = 2.0
	light.texture_scale = radius / 100.0
	
	# Use a gradient texture for the light
	var gradient := GradientTexture2D.new()
	gradient.width = 128
	gradient.height = 128
	gradient.fill = GradientTexture2D.FILL_RADIAL
	gradient.fill_from = Vector2(0.5, 0.5)
	gradient.fill_to = Vector2(0.5, 0.0)
	var g := Gradient.new()
	g.set_color(0, Color.WHITE)
	g.set_color(1, Color.TRANSPARENT)
	gradient.gradient = g
	light.texture = gradient
	
	get_tree().current_scene.add_child(light)
	
	var tween := create_tween()
	tween.tween_property(light, "energy", 0.0, duration)
	tween.tween_callback(light.queue_free)


# =========================================
# ENVIRONMENT TRANSITIONS
# =========================================

func transition_to_area(area_type: String, duration: float = 1.0) -> void:
	## Transition lighting based on area type.
	var target_ambient := ambient_color
	var target_modulate := Color(0.3, 0.35, 0.5, 1.0)
	
	match area_type:
		"ruins":
			target_ambient = Color(0.15, 0.2, 0.3, 1.0)
			target_modulate = Color(0.3, 0.35, 0.5, 1.0)
		"factory":
			target_ambient = Color(0.25, 0.15, 0.1, 1.0)
			target_modulate = Color(0.4, 0.3, 0.2, 1.0)
		"core":
			target_ambient = Color(0.3, 0.1, 0.15, 1.0)
			target_modulate = Color(0.5, 0.2, 0.3, 1.0)
		"surface":
			target_ambient = Color(0.4, 0.45, 0.5, 1.0)
			target_modulate = Color(0.7, 0.75, 0.8, 1.0)
	
	if world_environment and world_environment.environment:
		var tween := create_tween()
		tween.tween_property(world_environment.environment, "ambient_light_color", target_ambient, duration)
	
	if canvas_modulate:
		var tween := create_tween()
		tween.tween_property(canvas_modulate, "color", target_modulate, duration)
