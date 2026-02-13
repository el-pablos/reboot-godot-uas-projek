# Standalone SceneTree runner for test_boss_attack.gd
extends SceneTree

func _init() -> void:
	var test_script: GDScript = load("res://test/test_boss_attack.gd")
	if test_script == null:
		print("ERROR: Cannot load test_boss_attack.gd")
		quit(1)
		return
	var test_node: Node = test_script.new()
	root.add_child(test_node)
	# Wait a frame then gather results
	await root.get_tree().create_timer(1.0).timeout
	var exit_code: int = test_node.tests_failed
	quit(exit_code)
