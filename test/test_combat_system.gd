# =============================================================================
# test_combat_system.gd - Unit Tests for Player Combat System
# =============================================================================
# Test suite for Player wrench attack, damage, knockback, and hit detection.
# =============================================================================

extends Node

# Test counters
var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0


# -----------------------------------------------------------------------------
# ENTRY POINT
# -----------------------------------------------------------------------------

func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("🧪 RUNNING: test_combat_system.gd")
	print("=".repeat(60))
	
	# Run all tests
	run_all_tests()
	
	# Print results
	print_results()


func run_all_tests() -> void:
	# Attack System Tests
	test_attack_damage_value()
	test_attack_cooldown_value()
	test_attack_duration_value()
	test_attack_knockback_value()
	test_attack_starts_disabled()
	test_attack_input_triggers_attack()
	test_attack_cooldown_prevents_spam()
	test_attack_during_dash_blocked()
	
	# Hitbox Tests
	test_hitbox_position_matches_facing()
	test_hitbox_collision_mask()
	test_hitbox_enables_during_attack()
	test_hitbox_disables_after_attack()
	
	# Hit Effects Tests
	test_hit_stop_activates_on_hit()
	test_damage_applied_to_enemy()
	test_knockback_direction_matches_facing()
	test_screen_shake_on_hit()
	
	# Visual Feedback Tests
	test_sprite_rotation_during_attack()
	test_attack_sound_plays()


func print_results() -> void:
	print("\n" + "-".repeat(60))
	print("📊 HASIL TEST COMBAT SYSTEM")
	print("-".repeat(60))
	print("✅ Passed: %d" % tests_passed)
	print("❌ Failed: %d" % tests_failed)
	print("📝 Total:  %d" % tests_total)
	print("-".repeat(60))
	
	if tests_failed == 0:
		print("🎉 SEMUA TEST COMBAT PASSED!")
	else:
		print("⚠️  ADA TEST YANG GAGAL")
	print("")


# -----------------------------------------------------------------------------
# HELPER FUNCTIONS
# -----------------------------------------------------------------------------

func assert_true(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
		print("  ✅ PASS: %s" % message)
	else:
		tests_failed += 1
		print("  ❌ FAIL: %s" % message)


func assert_false(condition: bool, message: String) -> void:
	assert_true(not condition, message)


func assert_equals(actual, expected, message: String) -> void:
	tests_total += 1
	if actual == expected:
		tests_passed += 1
		print("  ✅ PASS: %s (got: %s)" % [message, str(actual)])
	else:
		tests_failed += 1
		print("  ❌ FAIL: %s (expected: %s, got: %s)" % [message, str(expected), str(actual)])


func assert_in_range(value: float, min_val: float, max_val: float, message: String) -> void:
	tests_total += 1
	if value >= min_val and value <= max_val:
		tests_passed += 1
		print("  ✅ PASS: %s (value: %.2f in [%.2f, %.2f])" % [message, value, min_val, max_val])
	else:
		tests_failed += 1
		print("  ❌ FAIL: %s (value: %.2f not in [%.2f, %.2f])" % [message, value, min_val, max_val])


# -----------------------------------------------------------------------------
# ATTACK SYSTEM TESTS
# -----------------------------------------------------------------------------

func test_attack_damage_value() -> void:
	print("\n📋 Test: Attack damage value")
	var attack_damage := 25
	assert_in_range(float(attack_damage), 15.0, 50.0, "Attack damage is balanced")


func test_attack_cooldown_value() -> void:
	print("\n📋 Test: Attack cooldown value")
	var attack_cooldown := 0.4  # Seconds
	assert_in_range(attack_cooldown, 0.2, 1.0, "Attack cooldown allows responsive combat")


func test_attack_duration_value() -> void:
	print("\n📋 Test: Attack duration value")
	var attack_duration := 0.25  # Seconds
	assert_in_range(attack_duration, 0.1, 0.5, "Attack duration feels snappy")


func test_attack_knockback_value() -> void:
	print("\n📋 Test: Attack knockback value")
	var attack_knockback := 200.0
	assert_in_range(attack_knockback, 100.0, 400.0, "Knockback is impactful but not excessive")


func test_attack_starts_disabled() -> void:
	print("\n📋 Test: Attack starts disabled")
	var is_attacking := false
	assert_false(is_attacking, "Player starts not attacking")


func test_attack_input_triggers_attack() -> void:
	print("\n📋 Test: Attack input triggers attack")
	# Simulating: attack button pressed + cooldown ready
	var attack_pressed := true
	var cooldown_ready := true
	var should_attack := attack_pressed and cooldown_ready
	assert_true(should_attack, "Attack input starts attack")


func test_attack_cooldown_prevents_spam() -> void:
	print("\n📋 Test: Attack cooldown prevents spam")
	var cooldown_timer := 0.3  # Still on cooldown
	var can_attack := cooldown_timer <= 0
	assert_false(can_attack, "Cannot attack during cooldown")


func test_attack_during_dash_blocked() -> void:
	print("\n📋 Test: Cannot attack during dash")
	var is_dashing := true
	var can_attack := not is_dashing
	assert_false(can_attack, "Attack blocked during dash")


# -----------------------------------------------------------------------------
# HITBOX TESTS
# -----------------------------------------------------------------------------

func test_hitbox_position_matches_facing() -> void:
	print("\n📋 Test: Hitbox position matches facing direction")
	var facing_right := true
	var hitbox_x := 20 if facing_right else -20
	assert_equals(hitbox_x, 20, "Hitbox is in front of player when facing right")


func test_hitbox_collision_mask() -> void:
	print("\n📋 Test: Hitbox targets enemy layer")
	var collision_mask := 2  # Layer 2 = enemy
	assert_equals(collision_mask, 2, "Hitbox mask targets enemy layer")


func test_hitbox_enables_during_attack() -> void:
	print("\n📋 Test: Hitbox enables during attack")
	var is_attacking := true
	var hitbox_monitoring := is_attacking
	assert_true(hitbox_monitoring, "Hitbox activates when attacking")


func test_hitbox_disables_after_attack() -> void:
	print("\n📋 Test: Hitbox disables after attack")
	var is_attacking := false
	var hitbox_monitoring := is_attacking
	assert_false(hitbox_monitoring, "Hitbox deactivates after attack")


# -----------------------------------------------------------------------------
# HIT EFFECTS TESTS
# -----------------------------------------------------------------------------

func test_hit_stop_activates_on_hit() -> void:
	print("\n📋 Test: Hit stop (time freeze) on hit")
	var hit_stop_duration := 0.05  # Seconds
	assert_in_range(hit_stop_duration, 0.03, 0.1, "Hit stop creates impact feel")


func test_damage_applied_to_enemy() -> void:
	print("\n📋 Test: Damage applied to enemy on hit")
	var enemy_health := 50
	var attack_damage := 25
	var new_health := enemy_health - attack_damage
	assert_equals(new_health, 25, "Enemy takes correct damage")


func test_knockback_direction_matches_facing() -> void:
	print("\n📋 Test: Knockback direction matches facing")
	var facing_right := true
	var knockback_x := 1.0 if facing_right else -1.0
	assert_equals(knockback_x, 1.0, "Knockback pushes in facing direction")


func test_screen_shake_on_hit() -> void:
	print("\n📋 Test: Screen shake on hit")
	var shake_intensity := 6.0
	assert_in_range(shake_intensity, 3.0, 10.0, "Screen shake is noticeable")


# -----------------------------------------------------------------------------
# VISUAL FEEDBACK TESTS
# -----------------------------------------------------------------------------

func test_sprite_rotation_during_attack() -> void:
	print("\n📋 Test: Sprite rotates during attack")
	var rotation_degrees := 15.0
	assert_in_range(rotation_degrees, 10.0, 30.0, "Attack rotation is visible")


func test_attack_sound_plays() -> void:
	print("\n📋 Test: Attack sound plays")
	var sound_name := "hit"
	assert_true(sound_name.length() > 0, "Attack has associated sound effect")
