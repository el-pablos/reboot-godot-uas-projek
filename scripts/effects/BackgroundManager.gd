extends ParallaxBackground
class_name BackgroundManager
## Manages layered parallax backgrounds for the Neon Ruins aesthetic.
## Creates depth through multiple scrolling layers with procedural generation.

# =========================================
# EXPORTS
# =========================================

@export_group("Background Colors")
@export var sky_color_top: Color = Color(0.02, 0.03, 0.08, 1.0)
@export var sky_color_bottom: Color = Color(0.1, 0.15, 0.25, 1.0)

@export_group("Layer Settings")
@export var num_distant_layers: int = 3
@export var num_midground_layers: int = 2
@export var num_foreground_layers: int = 1

@export_group("Scrolling")
@export var base_scroll_speed: float = 0.1
@export var auto_scroll: bool = false
@export var auto_scroll_speed: float = 10.0

@export_group("Fog")
@export var fog_enabled: bool = true
@export var fog_color: Color = Color(0.1, 0.15, 0.2, 0.5)

# =========================================
# VARIABLES
# =========================================

var _layers: Array[ParallaxLayer] = []
var _time: float = 0.0
var _viewport_size: Vector2

# =========================================
# LAYER PRESETS
# =========================================

const LAYER_PRESETS := {
	"distant_buildings": {
		"motion_scale": Vector2(0.1, 0.05),
		"color": Color(0.15, 0.18, 0.25, 1.0),
		"glow_chance": 0.3,
	},
	"mid_structures": {
		"motion_scale": Vector2(0.3, 0.15),
		"color": Color(0.2, 0.22, 0.28, 1.0),
		"glow_chance": 0.5,
	},
	"near_debris": {
		"motion_scale": Vector2(0.6, 0.3),
		"color": Color(0.25, 0.27, 0.32, 1.0),
		"glow_chance": 0.7,
	},
	"foreground": {
		"motion_scale": Vector2(1.2, 0.8),
		"color": Color(0.1, 0.12, 0.15, 0.7),
		"glow_chance": 0.2,
	}
}

# =========================================
# LIFECYCLE
# =========================================

func _ready() -> void:
	_viewport_size = get_viewport().get_visible_rect().size
	_generate_background_layers()


func _process(delta: float) -> void:
	_time += delta
	
	if auto_scroll:
		scroll_offset.x += auto_scroll_speed * delta
	
	_update_dynamic_elements(delta)


# =========================================
# LAYER GENERATION
# =========================================

func _generate_background_layers() -> void:
	"""Generate all parallax layers procedurally."""
	
	# Clear existing layers
	for p_layer in _layers:
		p_layer.queue_free()
	_layers.clear()
	
	# Create gradient background
	_create_gradient_layer()
	
	# Create distant city silhouettes
	for i in range(num_distant_layers):
		var depth := float(i) / float(num_distant_layers)
		_create_building_layer("distant_buildings", depth, i)
	
	# Create mid-ground structures
	for i in range(num_midground_layers):
		var depth := float(i) / float(num_midground_layers)
		_create_building_layer("mid_structures", depth, num_distant_layers + i)
	
	# Create fog layer
	if fog_enabled:
		_create_fog_layer()
	
	# Create foreground debris (optional)
	for i in range(num_foreground_layers):
		_create_foreground_layer(i)


func _create_gradient_layer() -> void:
	"""Create the background gradient layer."""
	var p_layer := ParallaxLayer.new()
	p_layer.name = "SkyGradient"
	p_layer.motion_scale = Vector2(0.0, 0.0)  # Static background
	
	var sprite := ColorRect.new()
	sprite.name = "GradientRect"
	sprite.size = _viewport_size * 4  # Large enough to cover scroll
	sprite.position = -_viewport_size * 2
	sprite.color = sky_color_bottom
	
	# Use a shader for gradient (or just solid color for simplicity)
	p_layer.add_child(sprite)
	add_child(p_layer)
	_layers.append(p_layer)


func _create_building_layer(preset_name: String, depth: float, z_index: int) -> void:
	"""Create a layer with procedural building silhouettes."""
	var preset: Dictionary = LAYER_PRESETS.get(preset_name, LAYER_PRESETS["distant_buildings"])
	
	var p_layer := ParallaxLayer.new()
	p_layer.name = "BuildingLayer_%d" % z_index
	p_layer.motion_scale = preset["motion_scale"] * (1.0 - depth * 0.5)
	p_layer.motion_mirroring = Vector2(_viewport_size.x * 2, 0)  # Infinite horizontal scroll
	
	var container := Node2D.new()
	container.name = "Buildings"
	container.modulate = preset["color"]
	
	# Generate building rectangles
	var num_buildings: int = randi_range(8, 15)
	var x_pos: float = -_viewport_size.x
	
	for i in range(num_buildings):
		var building := _create_building_silhouette(preset, depth)
		building.position.x = x_pos
		building.position.y = _viewport_size.y * 0.3  # Position from bottom
		container.add_child(building)
		
		x_pos += randf_range(50, 150)
	
	p_layer.add_child(container)
	add_child(p_layer)
	_layers.append(p_layer)


func _create_building_silhouette(preset: Dictionary, depth: float) -> Node2D:
	"""Create a single building silhouette with optional glow windows."""
	var building := Node2D.new()
	
	# Main building body
	var body := ColorRect.new()
	body.name = "Body"
	
	var width := randf_range(30, 80) * (1.0 - depth * 0.5)
	var height := randf_range(100, 300) * (1.0 - depth * 0.3)
	
	body.size = Vector2(width, height)
	body.position = Vector2(-width / 2, -height)
	body.color = Color.WHITE  # Will be tinted by container modulate
	building.add_child(body)
	
	# Add glowing windows
	if randf() < preset.get("glow_chance", 0.3):
		var num_windows := randi_range(2, 8)
		for w in range(num_windows):
			var window := ColorRect.new()
			window.name = "Window_%d" % w
			window.size = Vector2(randf_range(3, 8), randf_range(3, 8))
			window.position = Vector2(
				randf_range(5, width - 10) - width / 2,
				randf_range(-height + 10, -20)
			)
			
			# Random neon colors
			var colors := [
				Color(0.3, 0.8, 1.0, 1.0),   # Cyan
				Color(1.0, 0.4, 0.8, 1.0),   # Magenta
				Color(0.5, 1.0, 0.5, 1.0),   # Green
				Color(1.0, 0.8, 0.3, 1.0),   # Yellow
			]
			window.color = colors[randi() % colors.size()]
			building.add_child(window)
	
	return building


func _create_fog_layer() -> void:
	"""Create a fog/mist layer for atmosphere."""
	var p_layer := ParallaxLayer.new()
	p_layer.name = "FogLayer"
	p_layer.motion_scale = Vector2(0.4, 0.2)
	
	var fog := ColorRect.new()
	fog.name = "Fog"
	fog.size = _viewport_size * 3
	fog.position = -_viewport_size
	fog.color = fog_color
	
	p_layer.add_child(fog)
	p_layer.z_index = 5  # In front of buildings
	add_child(p_layer)
	_layers.append(p_layer)


func _create_foreground_layer(index: int) -> void:
	"""Create foreground debris particles."""
	var p_layer := ParallaxLayer.new()
	p_layer.name = "ForegroundLayer_%d" % index
	p_layer.motion_scale = LAYER_PRESETS["foreground"]["motion_scale"]
	
	var container := Node2D.new()
	container.name = "Debris"
	container.modulate = LAYER_PRESETS["foreground"]["color"]
	
	# Create floating debris particles
	for i in range(randi_range(5, 10)):
		var debris := ColorRect.new()
		debris.name = "Debris_%d" % i
		debris.size = Vector2(randf_range(2, 6), randf_range(2, 6))
		debris.position = Vector2(
			randf_range(-_viewport_size.x, _viewport_size.x * 2),
			randf_range(0, _viewport_size.y)
		)
		debris.color = Color.WHITE
		container.add_child(debris)
	
	p_layer.add_child(container)
	p_layer.z_index = 10
	add_child(p_layer)
	_layers.append(p_layer)


# =========================================
# DYNAMIC UPDATES
# =========================================

func _update_dynamic_elements(_delta: float) -> void:
	"""Update any animated elements in the background."""
	# Could add floating particles, flickering lights, etc.
	pass


# =========================================
# THEME TRANSITIONS
# =========================================

func set_theme(theme_name: String, duration: float = 1.0) -> void:
	"""Transition to a different background theme."""
	var tween := create_tween()
	
	match theme_name:
		"ruins":
			tween.tween_property(self, "sky_color_top", Color(0.02, 0.03, 0.08, 1.0), duration)
			tween.tween_property(self, "sky_color_bottom", Color(0.1, 0.15, 0.25, 1.0), duration)
		"factory":
			tween.tween_property(self, "sky_color_top", Color(0.08, 0.03, 0.02, 1.0), duration)
			tween.tween_property(self, "sky_color_bottom", Color(0.25, 0.12, 0.1, 1.0), duration)
		"core":
			tween.tween_property(self, "sky_color_top", Color(0.1, 0.02, 0.05, 1.0), duration)
			tween.tween_property(self, "sky_color_bottom", Color(0.3, 0.1, 0.15, 1.0), duration)
		"surface":
			tween.tween_property(self, "sky_color_top", Color(0.4, 0.5, 0.6, 1.0), duration)
			tween.tween_property(self, "sky_color_bottom", Color(0.6, 0.65, 0.7, 1.0), duration)


func add_weather_effect(effect_type: String) -> void:
	"""Add weather/environmental effects."""
	match effect_type:
		"rain":
			# Could add particle system for rain
			pass
		"sparks":
			# Could add occasional electrical sparks
			pass
		"ash":
			# Could add falling ash particles
			pass
