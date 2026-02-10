# ===================================================
# TexturePatcher.gd - Tool untuk Replace Placeholder Textures
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Script ini membantu mengganti texture placeholder (greybox)
# dengan texture asli. Run di Editor untuk auto-patch.
# ===================================================

@tool
extends EditorScript

# === TEXTURE MAPPING ===
# Format: "placeholder_texture_path": "real_texture_path"
const TEXTURE_MAP: Dictionary = {
	# Player sprites
	"res://assets/sprites/player/placeholder_idle.png": "res://assets/sprites/player/satria_idle.png",
	"res://assets/sprites/player/placeholder_run.png": "res://assets/sprites/player/satria_run.png",
	"res://assets/sprites/player/placeholder_jump.png": "res://assets/sprites/player/satria_jump.png",
	"res://assets/sprites/player/placeholder_fall.png": "res://assets/sprites/player/satria_fall.png",
	"res://assets/sprites/player/placeholder_dash.png": "res://assets/sprites/player/satria_dash.png",
	
	# Kenshi Pack (alienGreen, etc.)
	"res://assets/sprites/player/alienGreen_stand.png": "res://assets/sprites/player/satria_idle.png",
	
	# Enemy sprites
	"res://assets/sprites/enemies/placeholder_drone.png": "res://assets/sprites/enemies/drone.png",
	"res://assets/sprites/enemies/placeholder_turret.png": "res://assets/sprites/enemies/turret.png",
	"res://assets/sprites/enemies/spinner_half.png": "res://assets/sprites/enemies/drone.png",
	
	# Boss sprites
	"res://assets/sprites/bosses/placeholder_scrapper.png": "res://assets/sprites/bosses/scrapper.png",
	"res://assets/sprites/bosses/placeholder_sporebot.png": "res://assets/sprites/bosses/sporebot.png",
	"res://assets/sprites/bosses/placeholder_tempest.png": "res://assets/sprites/bosses/tempest.png",
	"res://assets/sprites/bosses/placeholder_overlord.png": "res://assets/sprites/bosses/overlord.png",
	"res://assets/sprites/bosses/shipBlue_manned.png": "res://assets/sprites/bosses/scrapper.png",
	
	# Tiles & environment
	"res://assets/sprites/tiles/placeholder_tile.png": "res://assets/sprites/tiles/metal_tile.png",
	"res://assets/sprites/tiles/placeholder_platform.png": "res://assets/sprites/tiles/platform.png",
}


func _run() -> void:
	"""Entry point untuk EditorScript. Run dari Script > Run (Ctrl+Shift+X)"""
	print("=" .repeat(60))
	print("TEXTURE PATCHER - Project: REBOOT")
	print("=" .repeat(60))
	
	var scenes_patched := 0
	var textures_replaced := 0
	
	# Get all scene files
	var scene_files := _get_all_files("res://", [".tscn"])
	print("Found %d scene files to check..." % scene_files.size())
	
	for scene_path in scene_files:
		var result := _patch_scene(scene_path)
		if result > 0:
			scenes_patched += 1
			textures_replaced += result
	
	print("-" .repeat(60))
	print("PATCH COMPLETE!")
	print("Scenes patched: %d" % scenes_patched)
	print("Textures replaced: %d" % textures_replaced)
	print("=" .repeat(60))


func _patch_scene(scene_path: String) -> int:
	"""Patch satu scene. Return jumlah texture yang diganti."""
	var file := FileAccess.open(scene_path, FileAccess.READ)
	if not file:
		return 0
	
	var content := file.get_as_text()
	file.close()
	
	var replacements := 0
	var new_content := content
	
	for placeholder_path in TEXTURE_MAP.keys():
		var real_path: String = TEXTURE_MAP[placeholder_path]
		
		# Check if placeholder exists in content
		if placeholder_path in new_content:
			# Only replace if real file exists
			if ResourceLoader.exists(real_path):
				new_content = new_content.replace(placeholder_path, real_path)
				replacements += 1
				print("  [%s] Replaced: %s -> %s" % [scene_path.get_file(), placeholder_path.get_file(), real_path.get_file()])
			else:
				print("  [%s] SKIP (target not found): %s" % [scene_path.get_file(), real_path.get_file()])
	
	if replacements > 0:
		# Write modified content
		var write_file := FileAccess.open(scene_path, FileAccess.WRITE)
		if write_file:
			write_file.store_string(new_content)
			write_file.close()
		else:
			push_error("Failed to write: %s" % scene_path)
	
	return replacements


func _get_all_files(path: String, extensions: Array) -> Array:
	"""Rekursif ambil semua file dengan extension tertentu."""
	var files := []
	var dir := DirAccess.open(path)
	
	if not dir:
		return files
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		var full_path := path.path_join(file_name)
		
		if dir.current_is_dir():
			if file_name != "." and file_name != ".." and not file_name.begins_with("."):
				files.append_array(_get_all_files(full_path, extensions))
		else:
			for ext in extensions:
				if file_name.ends_with(ext):
					files.append(full_path)
					break
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return files


# === RUNTIME PATCHER (untuk scene yang sudah loaded) ===
static func patch_sprite(sprite: Sprite2D) -> bool:
	"""Patch single sprite jika menggunakan placeholder texture."""
	if not sprite or not sprite.texture:
		return false
	
	var current_path := sprite.texture.resource_path
	
	if TEXTURE_MAP.has(current_path):
		var real_path: String = TEXTURE_MAP[current_path]
		if ResourceLoader.exists(real_path):
			sprite.texture = load(real_path)
			print("[TexturePatcher] Runtime patch: %s" % real_path.get_file())
			return true
	
	return false


static func patch_all_sprites_in_tree(root: Node) -> int:
	"""Patch semua Sprite2D dalam subtree."""
	var count := 0
	
	for child in root.get_children():
		if child is Sprite2D:
			if patch_sprite(child):
				count += 1
		
		count += patch_all_sprites_in_tree(child)
	
	return count
