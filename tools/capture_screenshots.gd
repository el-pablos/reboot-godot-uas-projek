extends SceneTree
## CLI screenshot capture tool
## Menangkap viewport dari scene-scene tertentu dan simpan ke docs/media/
## Usage: godot --path . -s tools/capture_screenshots.gd

var scenes_to_capture := [
	{
		"path": "res://scenes/main_menu/MainMenu.tscn",
		"output": "docs/media/01-main-menu.png",
		"wait_frames": 10,
		"label": "Main Menu"
	},
	{
		"path": "res://scenes/levels/Level_01_GoldenIsles.tscn",
		"output": "docs/media/02-level-1-golden-isles.png",
		"wait_frames": 30,
		"label": "Level 1 — Golden Isles"
	},
	{
		"path": "res://scenes/levels/Level_04_StormSpire.tscn",
		"output": "docs/media/03-level-4-storm-spire.png",
		"wait_frames": 30,
		"label": "Level 4 — Storm Spire (Boss)"
	},
	{
		"path": "res://scenes/levels/Level_05_OverlordFortress.tscn",
		"output": "docs/media/04-level-5-overlord-fortress.png",
		"wait_frames": 30,
		"label": "Level 5 — Overlord Fortress (Final)"
	},
]

var current_index: int = 0
var frames_waited: int = 0
var active_scene: Node = null
var capture_done: bool = false
var saved_count: int = 0


func _initialize() -> void:
	## Buat folder output kalau belum ada
	var dir := DirAccess.open("res://")
	if dir:
		if not dir.dir_exists("docs"):
			dir.make_dir("docs")
		if not dir.dir_exists("docs/media"):
			dir.make_dir("docs/media")

	print("=== Screenshot Capture Tool ===")
	print("Target: %d scene(s)" % scenes_to_capture.size())
	print("")
	_load_next_scene()


func _load_next_scene() -> void:
	if current_index >= scenes_to_capture.size():
		print("")
		print("=== SELESAI: %d screenshot berhasil disimpan ===" % saved_count)
		capture_done = true
		return

	var info: Dictionary = scenes_to_capture[current_index]
	var scene_path: String = info["path"]
	var label: String = info["label"]

	print("[%d/%d] Loading: %s" % [current_index + 1, scenes_to_capture.size(), label])

	## Cek apakah scene ada
	if not ResourceLoader.exists(scene_path):
		push_warning("SKIP: Scene tidak ditemukan — %s" % scene_path)
		current_index += 1
		_load_next_scene()
		return

	## Hapus scene lama
	if active_scene:
		active_scene.queue_free()
		active_scene = null

	## Load scene baru
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_warning("SKIP: Gagal load — %s" % scene_path)
		current_index += 1
		_load_next_scene()
		return

	active_scene = packed.instantiate()
	root.add_child(active_scene)

	frames_waited = 0


func _process(delta: float) -> bool:
	if capture_done:
		return true  ## true = quit

	if active_scene == null:
		return false

	frames_waited += 1
	var info: Dictionary = scenes_to_capture[current_index]
	var target_frames: int = info["wait_frames"]

	if frames_waited >= target_frames:
		_capture_viewport(info)
		current_index += 1
		_load_next_scene()

	return false


func _capture_viewport(info: Dictionary) -> void:
	var output_path: String = info["output"]
	var label: String = info["label"]

	var img := root.get_texture().get_image()
	if img == null:
		push_warning("SKIP: Image null — %s" % label)
		return

	var err := img.save_png(output_path)
	if err != OK:
		push_warning("ERROR: Gagal simpan %s (code %d)" % [output_path, err])
	else:
		saved_count += 1
		print("       -> Saved: %s (%dx%d)" % [output_path, img.get_width(), img.get_height()])
