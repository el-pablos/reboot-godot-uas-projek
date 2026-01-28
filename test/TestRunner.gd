# =============================================================================
# TestRunner.gd - Main Test Runner untuk Project: REBOOT
# =============================================================================
# Jalankan scene ini untuk eksekusi semua unit test.
# Set sebagai main scene atau run langsung dari editor.
# =============================================================================

extends Node

# Test scripts
var test_scripts: Array[String] = [
	"res://test/test_player_movement.gd",
	"res://test/test_game_logic.gd",
	"res://test/test_enemy_boss.gd"
]

var current_test_index: int = 0
var total_passed: int = 0
var total_failed: int = 0
var total_tests: int = 0


func _ready() -> void:
	print("\n")
	print("╔══════════════════════════════════════════════════════════════╗")
	print("║       PROJECT: REBOOT - AUTOMATED TEST SUITE                 ║")
	print("║                    Version 0.1.0                              ║")
	print("╚══════════════════════════════════════════════════════════════╝")
	print("")
	
	# Run tests sequentially
	await run_next_test()


func run_next_test() -> void:
	if current_test_index >= test_scripts.size():
		# Semua test selesai
		print_final_results()
		return
	
	var script_path: String = test_scripts[current_test_index]
	var script = load(script_path)
	
	if script == null:
		print("❌ ERROR: Cannot load %s" % script_path)
		current_test_index += 1
		await run_next_test()
		return
	
	# Instance test script
	var test_node = script.new()
	add_child(test_node)
	
	# Wait for test to complete (wait beberapa frame)
	await get_tree().create_timer(0.5).timeout
	
	# Collect results dari test node
	if test_node.has_method("get") or "tests_passed" in test_node:
		total_passed += test_node.tests_passed
		total_failed += test_node.tests_failed
		total_tests += test_node.tests_total
	
	# Cleanup
	test_node.queue_free()
	
	# Run next
	current_test_index += 1
	await run_next_test()


func print_final_results() -> void:
	print("\n")
	print("╔══════════════════════════════════════════════════════════════╗")
	print("║                    FINAL TEST RESULTS                        ║")
	print("╠══════════════════════════════════════════════════════════════╣")
	print("║  ✅ PASSED:  %-46d  ║" % total_passed)
	print("║  ❌ FAILED:  %-46d  ║" % total_failed)
	print("║  📝 TOTAL:   %-46d  ║" % total_tests)
	print("╠══════════════════════════════════════════════════════════════╣")
	
	if total_failed == 0:
		print("║            🎉 ALL TESTS PASSED! 🎉                           ║")
	else:
		print("║            ⚠️  SOME TESTS FAILED ⚠️                           ║")
	
	print("╚══════════════════════════════════════════════════════════════╝")
	print("")
	
	# Optional: quit after tests
	# get_tree().quit(total_failed)
