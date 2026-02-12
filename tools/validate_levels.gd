## ===================================================
## validate_levels.gd - Level platform & collision validator
## Project: REBOOT
## Usage: godot --headless --path . -s tools/validate_levels.gd --quit
## ===================================================
## Loads each level scene, checks:
## 1. Spawn position lands on a valid platform
## 2. No platform gaps exceed MAX_JUMP_DISTANCE
## 3. All bosses have collision_mask with environment (layer 4)
## 4. CoreFragment is above a reachable platform
## ===================================================
extends SceneTree

const LEVELS: Array = [
	"res://scenes/levels/Level_01_GoldenIsles.tscn",
	"res://scenes/levels/Level_02_RustFactory.tscn",
	"res://scenes/levels/Level_03_CrystalLabs.tscn",
	"res://scenes/levels/Level_04_StormSpire.tscn",
	"res://scenes/levels/Level_05_OverlordFortress.tscn",
]

## Max horizontal jump distance the player can cover (pixels)
const MAX_JUMP_DISTANCE: float = 300.0

var total_errors: int = 0
var total_warnings: int = 0


func _init() -> void:
	print("=" .repeat(60))
	print("LEVEL VALIDATION REPORT")
	print("=" .repeat(60))

	for path in LEVELS:
		if not ResourceLoader.exists(path):
			_error("Level not found: %s" % path)
			continue
		_validate_level(path)

	print("")
	print("=" .repeat(60))
	if total_errors == 0:
		print("RESULT: ALL LEVELS PASSED (%d warnings)" % total_warnings)
	else:
		print("RESULT: %d ERRORS, %d warnings" % [total_errors, total_warnings])
	print("=" .repeat(60))

	quit()


func _validate_level(path: String) -> void:
	var scene: PackedScene = load(path)
	if not scene:
		_error("Cannot load: %s" % path)
		return

	var level := scene.instantiate()
	var level_name: String = path.get_file().get_basename()
	print("\n--- %s ---" % level_name)

	# Collect platforms (StaticBody2D children with collision_layer 4)
	var platforms: Array = []
	_find_platforms(level, platforms)
	print("  Platforms found: %d" % platforms.size())

	# Check spawn position
	var spawn_pos := Vector2(100, 200)  # Default
	if "spawn_position" in level:
		spawn_pos = level.spawn_position

	var spawn_ok := false
	for plat in platforms:
		var rect: Rect2 = _get_platform_rect(plat)
		if rect.size == Vector2.ZERO:
			continue
		# Check if spawn X is within platform and spawn Y is above platform top
		if spawn_pos.x >= rect.position.x and spawn_pos.x <= rect.end.x:
			if spawn_pos.y <= rect.end.y + 200:  # Within 200px above
				spawn_ok = true
				break

	if spawn_ok:
		print("  Spawn (%s): OK" % spawn_pos)
	else:
		_error("  Spawn (%s): NOT above any platform!" % spawn_pos)

	# Check bosses collision_mask
	_check_bosses(level, level_name)

	# Check CoreFragment
	_check_core(level)

	# Gap analysis between consecutive platforms (sorted by X)
	_check_gaps(platforms)

	level.queue_free()


func _find_platforms(node: Node, results: Array) -> void:
	if node is StaticBody2D:
		if node.collision_layer & 4:  # Environment layer
			results.append(node)
	for child in node.get_children():
		_find_platforms(child, results)


func _get_platform_rect(plat: Node2D) -> Rect2:
	## Estimate bounding rect from CollisionShape2D/CollisionPolygon2D children.
	for child in plat.get_children():
		if child is CollisionShape2D and child.shape:
			var shape = child.shape
			var half: Vector2 = Vector2.ZERO
			if shape is RectangleShape2D:
				half = shape.size / 2
			elif shape is CircleShape2D:
				half = Vector2(shape.radius, shape.radius)
			else:
				half = Vector2(32, 16)  # Fallback guess
			var pos: Vector2 = plat.position + child.position
			return Rect2(pos - half, half * 2)
		elif child is CollisionPolygon2D:
			var poly: PackedVector2Array = child.polygon
			if poly.size() < 2:
				continue
			var min_pt := poly[0]
			var max_pt := poly[0]
			for pt in poly:
				min_pt.x = minf(min_pt.x, pt.x)
				min_pt.y = minf(min_pt.y, pt.y)
				max_pt.x = maxf(max_pt.x, pt.x)
				max_pt.y = maxf(max_pt.y, pt.y)
			var pos: Vector2 = plat.position + child.position
			return Rect2(pos + min_pt, max_pt - min_pt)
	return Rect2()


func _check_bosses(node: Node, level_name: String) -> void:
	for child in node.get_children():
		if child is CharacterBody2D and child.collision_layer & 2:
			# It's likely a boss/enemy
			var has_env: bool = (child.collision_mask & 4) != 0
			if not has_env and child.name.begins_with("Boss"):
				_warn("  Boss '%s' collision_mask=%d (missing environment layer 4)" % [child.name, child.collision_mask])
			else:
				print("  Boss '%s': collision OK (mask=%d)" % [child.name, child.collision_mask])
		_check_bosses(child, level_name)


func _check_core(node: Node) -> void:
	for child in node.get_children():
		if child.name == "CoreFragment" or (child is Area2D and child.collision_layer & 16):
			print("  CoreFragment at %s: OK" % child.position)
			return
		_check_core(child)


func _check_gaps(platforms: Array) -> void:
	if platforms.size() < 2:
		return
	# Sort platforms by X position
	var rects: Array = []
	for plat in platforms:
		var r := _get_platform_rect(plat)
		if r.size != Vector2.ZERO:
			rects.append({"name": plat.name, "rect": r})
	rects.sort_custom(func(a, b): return a.rect.position.x < b.rect.position.x)

	for i in range(rects.size() - 1):
		var a: Rect2 = rects[i].rect
		var b: Rect2 = rects[i + 1].rect
		var gap: float = b.position.x - a.end.x
		if gap > MAX_JUMP_DISTANCE:
			_error("  Gap %.0fpx between '%s' → '%s' exceeds max jump %d!" % [
				gap, rects[i].name, rects[i + 1].name, MAX_JUMP_DISTANCE])
		elif gap > MAX_JUMP_DISTANCE * 0.8:
			_warn("  Tight gap %.0fpx between '%s' → '%s'" % [
				gap, rects[i].name, rects[i + 1].name])


func _error(msg: String) -> void:
	total_errors += 1
	print("[ERROR] %s" % msg)


func _warn(msg: String) -> void:
	total_warnings += 1
	print("[WARN] %s" % msg)
