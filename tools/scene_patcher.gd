# =============================================================================
# scene_patcher.gd - SCENE INJECTION TOOL
# =============================================================================
# Tool script untuk memperbaiki scene yang belum memiliki visual overhaul.
# Jalankan dari Godot Editor: buat scene kosong, attach script ini, lalu Run.
# =============================================================================

extends Node

# Path ke folder levels
const LEVELS_FOLDER := "res://scenes/levels/"
const PLAYER_SCENE_PATH := "res://scenes/player/Player.tscn"
const HUD_SCENE_PATH := "res://scenes/ui/HUD.tscn"

# Script paths
const BACKGROUND_MANAGER_SCRIPT := "res://scripts/effects/BackgroundManager.gd"
const SMART_ENEMY_SCRIPT := "res://scripts/enemies/SmartEnemy.gd"
const MODERN_HEALTH_UI_SCRIPT := "res://scripts/ui/ModernHealthUI.gd"
const LIGHTING_MANAGER_SCRIPT := "res://scripts/effects/LightingManager.gd"
const NEON_ENVIRONMENT_PATH := "res://resources/environments/neon_ruins_environment.tres"

# Warna untuk visual overhaul
const CANVAS_MODULATE_COLOR := Color(0.35, 0.4, 0.55, 1.0)  # Kegelapan biru
const PLAYER_LIGHT_COLOR := Color(0.4, 0.85, 1.0, 1.0)  # Cyan glow
const AMBIENT_LIGHT_COLOR := Color(0.15, 0.2, 0.3, 1.0)

var patched_files: Array[String] = []
var errors: Array[String] = []


func _ready() -> void:
	print("\n")
	print("╔══════════════════════════════════════════════════════════════╗")
	print("║         SCENE PATCHER - VISUAL OVERHAUL INJECTION            ║")
	print("╚══════════════════════════════════════════════════════════════╝")
	print("")
	
	# Jalankan semua patch
	_patch_player_scene()
	_patch_all_levels()
	_patch_hud_scene()
	
	# Laporan hasil
	_print_results()
	
	# Auto quit setelah selesai
	print("\n[Patcher] Selesai! Restart Godot Editor untuk melihat perubahan.")
	await get_tree().create_timer(3.0).timeout
	get_tree().quit()


# =============================================================================
# PLAYER SCENE PATCHER
# =============================================================================

func _patch_player_scene() -> void:
	print("\n🔧 Patching Player Scene...")
	
	var scene := load(PLAYER_SCENE_PATH) as PackedScene
	if not scene:
		errors.append("GAGAL load Player.tscn")
		return
	
	var player := scene.instantiate()
	var modified := false
	
	# 1. Cek dan perbaiki PlayerLight
	var light := player.get_node_or_null("PlayerLight") as PointLight2D
	if light:
		# Light ada, tapi cek apakah ada texture
		if not light.texture:
			print("  → Menambahkan texture ke PlayerLight...")
			light.texture = _create_light_gradient_texture()
			light.texture_scale = 2.0
			light.color = PLAYER_LIGHT_COLOR
			light.energy = 1.2
			modified = true
	else:
		# Buat PlayerLight baru
		print("  → Membuat PlayerLight baru...")
		light = PointLight2D.new()
		light.name = "PlayerLight"
		light.texture = _create_light_gradient_texture()
		light.texture_scale = 2.0
		light.color = PLAYER_LIGHT_COLOR
		light.energy = 1.2
		light.shadow_enabled = true
		light.position = Vector2(0, -5)
		player.add_child(light)
		light.owner = player
		modified = true
	
	# 2. Cek AttackHitbox
	var hitbox := player.get_node_or_null("AttackHitbox")
	if not hitbox:
		print("  → Membuat AttackHitbox...")
		hitbox = Area2D.new()
		hitbox.name = "AttackHitbox"
		hitbox.collision_layer = 0
		hitbox.collision_mask = 2  # Enemy layer
		hitbox.monitoring = false
		hitbox.position = Vector2(20, -2)
		
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var rect := RectangleShape2D.new()
		rect.size = Vector2(32, 24)
		shape.shape = rect
		
		hitbox.add_child(shape)
		shape.owner = player
		player.add_child(hitbox)
		hitbox.owner = player
		modified = true
	
	# 3. Simpan jika ada perubahan
	if modified:
		var packed := PackedScene.new()
		packed.pack(player)
		var err := ResourceSaver.save(packed, PLAYER_SCENE_PATH)
		if err == OK:
			patched_files.append("Player.tscn")
			print("  ✅ Player.tscn berhasil dipatch!")
		else:
			errors.append("GAGAL save Player.tscn: Error %d" % err)
	else:
		print("  ℹ️ Player.tscn sudah lengkap, tidak ada perubahan.")
	
	player.queue_free()


# =============================================================================
# LEVEL SCENES PATCHER
# =============================================================================

func _patch_all_levels() -> void:
	print("\n🔧 Patching Level Scenes...")
	
	var dir := DirAccess.open(LEVELS_FOLDER)
	if not dir:
		errors.append("GAGAL buka folder: %s" % LEVELS_FOLDER)
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tscn") and file_name.begins_with("Level_"):
			var path := LEVELS_FOLDER + file_name
			_patch_level_scene(path)
		file_name = dir.get_next()
	
	dir.list_dir_end()


func _patch_level_scene(path: String) -> void:
	print("\n  📂 Processing: %s" % path.get_file())
	
	var scene := load(path) as PackedScene
	if not scene:
		errors.append("GAGAL load: %s" % path)
		return
	
	var level := scene.instantiate()
	var modified := false
	
	# 1. Tambahkan CanvasModulate jika belum ada
	var canvas_mod := _find_node_by_type(level, "CanvasModulate")
	if not canvas_mod:
		print("    → Menambahkan CanvasModulate...")
		canvas_mod = CanvasModulate.new()
		canvas_mod.name = "CanvasModulate"
		canvas_mod.color = CANVAS_MODULATE_COLOR
		level.add_child(canvas_mod)
		canvas_mod.owner = level
		# Pindahkan ke urutan pertama agar di-render pertama
		level.move_child(canvas_mod, 0)
		modified = true
	
	# 2. Tambahkan WorldEnvironment jika belum ada
	var world_env := _find_node_by_type(level, "WorldEnvironment")
	if not world_env:
		print("    → Menambahkan WorldEnvironment dengan Glow...")
		world_env = WorldEnvironment.new()
		world_env.name = "WorldEnvironment"
		
		# Buat Environment dengan Glow
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.05, 0.05, 0.1, 1)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = AMBIENT_LIGHT_COLOR
		env.ambient_light_energy = 0.4
		
		# GLOW SETTINGS - Ini yang bikin visual pop!
		env.glow_enabled = true
		env.glow_intensity = 1.0
		env.glow_strength = 1.2
		env.glow_bloom = 0.3
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
		env.glow_hdr_threshold = 0.8
		env.glow_hdr_scale = 2.0
		env.glow_hdr_luminance_cap = 12.0
		
		# Sedikit adjustment
		env.adjustment_enabled = true
		env.adjustment_brightness = 1.0
		env.adjustment_contrast = 1.1
		env.adjustment_saturation = 1.15
		
		world_env.environment = env
		level.add_child(world_env)
		world_env.owner = level
		level.move_child(world_env, 1)  # Setelah CanvasModulate
		modified = true
	
	# 3. Tambahkan ambient lights ke environment
	modified = _add_environment_lights(level) or modified
	
	# 4. Upgrade enemies ke SmartEnemy
	modified = _upgrade_enemies(level) or modified
	
	# 5. Simpan jika ada perubahan
	if modified:
		var packed := PackedScene.new()
		packed.pack(level)
		var err := ResourceSaver.save(packed, path)
		if err == OK:
			patched_files.append(path.get_file())
			print("    ✅ %s berhasil dipatch!" % path.get_file())
		else:
			errors.append("GAGAL save: %s (Error %d)" % [path, err])
	else:
		print("    ℹ️ %s sudah lengkap." % path.get_file())
	
	level.queue_free()


func _add_environment_lights(level: Node) -> bool:
	"""Tambahkan lampu ambient ke level untuk visual yang lebih baik."""
	var modified := false
	
	# Cari node Environment jika ada
	var env_node := level.get_node_or_null("Environment")
	if not env_node:
		return false
	
	# Cek apakah sudah ada AmbientLights
	if level.get_node_or_null("AmbientLights"):
		return false
	
	print("    → Menambahkan AmbientLights...")
	
	var lights_container := Node2D.new()
	lights_container.name = "AmbientLights"
	level.add_child(lights_container)
	lights_container.owner = level
	
	# Tambahkan beberapa point lights untuk atmosfer
	var light_positions := [
		Vector2(200, 250),
		Vector2(600, 200),
		Vector2(1000, 280),
		Vector2(1400, 230),
		Vector2(1800, 260),
	]
	
	var light_colors := [
		Color(0.3, 0.8, 1.0, 1.0),   # Cyan
		Color(1.0, 0.5, 0.8, 1.0),   # Magenta
		Color(0.5, 1.0, 0.6, 1.0),   # Green
		Color(1.0, 0.8, 0.3, 1.0),   # Yellow
		Color(0.7, 0.5, 1.0, 1.0),   # Purple
	]
	
	for i in range(light_positions.size()):
		var light := PointLight2D.new()
		light.name = "AmbientLight_%d" % i
		light.position = light_positions[i]
		light.texture = _create_light_gradient_texture()
		light.texture_scale = 3.0 + randf() * 2.0
		light.color = light_colors[i]
		light.energy = 0.4 + randf() * 0.3
		light.shadow_enabled = false
		
		lights_container.add_child(light)
		light.owner = level
	
	modified = true
	return modified


func _upgrade_enemies(level: Node) -> bool:
	"""Upgrade musuh lama ke SmartEnemy."""
	var modified := false
	
	# Cari semua node enemy
	var enemies := _find_nodes_by_group_or_name(level, "enemies", ["WalkingEnemy", "FlyingEnemy", "Enemy"])
	
	for enemy in enemies:
		# Skip jika sudah menggunakan SmartEnemy
		if enemy.get_script() and enemy.get_script().resource_path == SMART_ENEMY_SCRIPT:
			continue
		
		# Coba load script baru
		var new_script := load(SMART_ENEMY_SCRIPT)
		if new_script and enemy.get_script():
			print("    → Upgrading enemy: %s" % enemy.name)
			# Simpan posisi dan properti penting
			var pos: Vector2 = enemy.position if "position" in enemy else Vector2.ZERO
			
			# Set script baru
			enemy.set_script(new_script)
			enemy.position = pos
			modified = true
	
	return modified


# =============================================================================
# HUD SCENE PATCHER
# =============================================================================

func _patch_hud_scene() -> void:
	print("\n🔧 Patching HUD Scene...")
	
	if not FileAccess.file_exists(HUD_SCENE_PATH):
		print("  ℹ️ HUD.tscn tidak ditemukan, membuat baru...")
		_create_new_hud()
		return
	
	var scene := load(HUD_SCENE_PATH) as PackedScene
	if not scene:
		errors.append("GAGAL load HUD.tscn")
		return
	
	var hud := scene.instantiate()
	var modified := false
	
	# Cek apakah sudah ada ModernHealthUI
	var health_ui := hud.get_node_or_null("ModernHealthUI")
	if not health_ui:
		print("  → Menambahkan ModernHealthUI...")
		
		# Buat node Control untuk health UI
		health_ui = Control.new()
		health_ui.name = "ModernHealthUI"
		health_ui.set_anchors_preset(Control.PRESET_TOP_LEFT)
		
		# Load dan attach script
		var script := load(MODERN_HEALTH_UI_SCRIPT)
		if script:
			health_ui.set_script(script)
		
		hud.add_child(health_ui)
		health_ui.owner = hud
		modified = true
	
	if modified:
		var packed := PackedScene.new()
		packed.pack(hud)
		var err := ResourceSaver.save(packed, HUD_SCENE_PATH)
		if err == OK:
			patched_files.append("HUD.tscn")
			print("  ✅ HUD.tscn berhasil dipatch!")
		else:
			errors.append("GAGAL save HUD.tscn: Error %d" % err)
	else:
		print("  ℹ️ HUD.tscn sudah lengkap.")
	
	hud.queue_free()


func _create_new_hud() -> void:
	"""Buat HUD scene baru dengan ModernHealthUI."""
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	hud.layer = 10
	
	# Modern Health UI
	var health_ui := Control.new()
	health_ui.name = "ModernHealthUI"
	health_ui.set_anchors_preset(Control.PRESET_TOP_LEFT)
	
	var script := load(MODERN_HEALTH_UI_SCRIPT)
	if script:
		health_ui.set_script(script)
	
	hud.add_child(health_ui)
	health_ui.owner = hud
	
	# Save
	var packed := PackedScene.new()
	packed.pack(hud)
	var err := ResourceSaver.save(packed, HUD_SCENE_PATH)
	if err == OK:
		patched_files.append("HUD.tscn (BARU)")
		print("  ✅ HUD.tscn berhasil dibuat!")
	else:
		errors.append("GAGAL create HUD.tscn: Error %d" % err)
	
	hud.queue_free()


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

func _create_light_gradient_texture() -> GradientTexture2D:
	"""Buat texture gradient untuk PointLight2D."""
	var texture := GradientTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color.TRANSPARENT)
	texture.gradient = gradient
	
	return texture


func _find_node_by_type(root: Node, type_name: String) -> Node:
	"""Cari node berdasarkan class name."""
	for child in root.get_children():
		if child.get_class() == type_name:
			return child
		var found := _find_node_by_type(child, type_name)
		if found:
			return found
	return null


func _find_nodes_by_group_or_name(root: Node, group: String, name_patterns: Array) -> Array[Node]:
	"""Cari semua node dalam group atau dengan nama tertentu."""
	var result: Array[Node] = []
	
	for child in root.get_children():
		var matches := false
		
		# Cek group
		if child.is_in_group(group):
			matches = true
		
		# Cek nama
		for pattern in name_patterns:
			if pattern in child.name:
				matches = true
				break
		
		if matches:
			result.append(child)
		
		# Rekursif
		result.append_array(_find_nodes_by_group_or_name(child, group, name_patterns))
	
	return result


# =============================================================================
# RESULTS
# =============================================================================

func _print_results() -> void:
	print("\n")
	print("╔══════════════════════════════════════════════════════════════╗")
	print("║                    PATCH RESULTS                             ║")
	print("╠══════════════════════════════════════════════════════════════╣")
	
	if patched_files.size() > 0:
		print("║  ✅ FILES PATCHED:                                           ║")
		for f in patched_files:
			print("║    - %-54s ║" % f)
	else:
		print("║  ℹ️  Tidak ada file yang perlu dipatch                        ║")
	
	if errors.size() > 0:
		print("╠══════════════════════════════════════════════════════════════╣")
		print("║  ❌ ERRORS:                                                   ║")
		for e in errors:
			print("║    - %-54s ║" % e)
	
	print("╚══════════════════════════════════════════════════════════════╝")
