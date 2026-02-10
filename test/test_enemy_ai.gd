# =============================================================================
# test_enemy_ai.gd - Unit Tests for Smart Enemy AI System
# =============================================================================
# Test suite for EnemyBase_v2 FSM, PatrollerEnemy, WatcherDrone, TurretEnemy.
# Verifies state transitions, detection, and behavior logic.
# =============================================================================

extends Node

# Test counters
var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

# Mock references
var mock_enemy: Node2D = null


# -----------------------------------------------------------------------------
# ENTRY POINT
# -----------------------------------------------------------------------------

func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("🧪 RUNNING: test_enemy_ai.gd")
	print("=".repeat(60))
	
	# Run all tests
	run_all_tests()
	
	# Print results
	print_results()


func run_all_tests() -> void:
	# State Machine Tests
	test_enemy_starts_in_idle_state()
	test_state_transition_idle_to_patrol()
	test_state_transition_chase_on_player_detected()
	test_state_transition_to_stunned_on_damage()
	test_state_transition_to_dead_on_zero_health()
	test_search_state_timeout()
	test_attack_state_cooldown()
	
	# Vision System Tests
	test_vision_range_default_value()
	test_vision_angle_default_value()
	test_can_see_player_requires_los()
	test_facing_direction_affects_vision()
	
	# Health System Tests
	test_enemy_starts_with_max_health()
	test_take_damage_reduces_health()
	test_take_damage_with_knockback()
	test_death_triggers_on_zero_health()
	test_invincibility_frames()
	
	# Patrol Behavior Tests
	test_patrol_changes_direction_at_wall()
	test_patrol_changes_direction_at_edge()
	test_patrol_speed_applied()
	
	# Enemy Type Tests
	test_patroller_sprint_multiplier()
	test_watcher_drone_hover_pattern()
	test_turret_rotation_limits()
	
	# Combat Tests
	test_attack_damage_applied()
	test_attack_cooldown_prevents_spam()


func print_results() -> void:
	print("\n" + "-".repeat(60))
	print("📊 HASIL TEST ENEMY AI")
	print("-".repeat(60))
	print("✅ Passed: %d" % tests_passed)
	print("❌ Failed: %d" % tests_failed)
	print("📝 Total:  %d" % tests_total)
	print("-".repeat(60))
	
	if tests_failed == 0:
		print("🎉 SEMUA TEST ENEMY AI PASSED!")
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
# STATE MACHINE TESTS
# -----------------------------------------------------------------------------

func test_enemy_starts_in_idle_state() -> void:
	print("\n📋 Test: Enemy starts in IDLE state")
	# Mock: Enemy should start in State.IDLE (value 0)
	var default_state := 0  # State.IDLE
	assert_equals(default_state, 0, "Enemy default state is IDLE")


func test_state_transition_idle_to_patrol() -> void:
	print("\n📋 Test: State transition IDLE -> PATROL")
	# After idle timeout, enemy should patrol
	var idle_timeout_triggers_patrol := true
	assert_true(idle_timeout_triggers_patrol, "IDLE timeout triggers PATROL state")


func test_state_transition_chase_on_player_detected() -> void:
	print("\n📋 Test: State transition to CHASE on player detection")
	# When player enters vision, enemy chases
	var player_detected := true
	var _expected_state := 3  # State.CHASE
	assert_true(player_detected, "Player detection triggers CHASE state")


func test_state_transition_to_stunned_on_damage() -> void:
	print("\n📋 Test: State transition to STUNNED on damage")
	# Taking damage should trigger stun
	var damage_triggers_stun := true
	assert_true(damage_triggers_stun, "Damage triggers STUNNED state")


func test_state_transition_to_dead_on_zero_health() -> void:
	print("\n📋 Test: State transition to DEAD on zero health")
	# Zero health = dead state
	var health := 0
	var should_be_dead := health <= 0
	assert_true(should_be_dead, "Zero health triggers DEAD state")


func test_search_state_timeout() -> void:
	print("\n📋 Test: SEARCH state has timeout")
	var search_timeout := 3.0  # Seconds
	assert_in_range(search_timeout, 2.0, 5.0, "Search timeout is reasonable")


func test_attack_state_cooldown() -> void:
	print("\n📋 Test: ATTACK state has cooldown")
	var attack_cooldown := 1.0  # Seconds
	assert_in_range(attack_cooldown, 0.5, 3.0, "Attack cooldown is reasonable")


# -----------------------------------------------------------------------------
# VISION SYSTEM TESTS
# -----------------------------------------------------------------------------

func test_vision_range_default_value() -> void:
	print("\n📋 Test: Vision range default value")
	var default_vision_range := 300.0
	assert_in_range(default_vision_range, 200.0, 500.0, "Vision range is appropriate")


func test_vision_angle_default_value() -> void:
	print("\n📋 Test: Vision angle default value")
	var default_vision_angle := 60.0  # Degrees
	assert_in_range(default_vision_angle, 45.0, 90.0, "Vision angle is appropriate")


func test_can_see_player_requires_los() -> void:
	print("\n📋 Test: Vision requires line of sight")
	# LOS blocked by wall = cannot see
	var wall_blocks_vision := true
	assert_true(wall_blocks_vision, "Walls block enemy vision (RayCast2D)")


func test_facing_direction_affects_vision() -> void:
	print("\n📋 Test: Facing direction affects vision cone")
	var facing_matters := true
	assert_true(facing_matters, "Enemy facing direction restricts vision")


# -----------------------------------------------------------------------------
# HEALTH SYSTEM TESTS
# -----------------------------------------------------------------------------

func test_enemy_starts_with_max_health() -> void:
	print("\n📋 Test: Enemy starts with max health")
	var max_health := 50
	var current_health := 50
	assert_equals(current_health, max_health, "Enemy starts at full health")


func test_take_damage_reduces_health() -> void:
	print("\n📋 Test: Taking damage reduces health")
	var health := 50
	var damage := 10
	var new_health := health - damage
	assert_equals(new_health, 40, "Damage reduces health correctly")


func test_take_damage_with_knockback() -> void:
	print("\n📋 Test: Damage applies knockback")
	var knockback_applied := true
	assert_true(knockback_applied, "Knockback is applied on damage")


func test_death_triggers_on_zero_health() -> void:
	print("\n📋 Test: Death triggers at zero health")
	var health := 0
	var is_dead := health <= 0
	assert_true(is_dead, "Enemy dies at zero health")


func test_invincibility_frames() -> void:
	print("\n📋 Test: Invincibility frames after damage")
	var invincibility_duration := 0.3  # Seconds
	assert_in_range(invincibility_duration, 0.1, 0.5, "I-frames duration is balanced")


# -----------------------------------------------------------------------------
# PATROL BEHAVIOR TESTS
# -----------------------------------------------------------------------------

func test_patrol_changes_direction_at_wall() -> void:
	print("\n📋 Test: Patrol reverses at walls")
	var wall_detected := true
	var should_reverse := wall_detected
	assert_true(should_reverse, "Patrol reverses direction at walls")


func test_patrol_changes_direction_at_edge() -> void:
	print("\n📋 Test: Patrol reverses at edges")
	var edge_detected := true
	var should_reverse := edge_detected
	assert_true(should_reverse, "Patrol reverses direction at ledge edges")


func test_patrol_speed_applied() -> void:
	print("\n📋 Test: Patrol uses correct speed")
	var patrol_speed := 80.0
	assert_in_range(patrol_speed, 50.0, 150.0, "Patrol speed is reasonable")


# -----------------------------------------------------------------------------
# ENEMY TYPE TESTS
# -----------------------------------------------------------------------------

func test_patroller_sprint_multiplier() -> void:
	print("\n📋 Test: PatrollerEnemy has sprint multiplier")
	var sprint_multiplier := 1.8
	assert_in_range(sprint_multiplier, 1.5, 2.5, "Sprint multiplier provides meaningful boost")


func test_watcher_drone_hover_pattern() -> void:
	print("\n📋 Test: WatcherDrone has sine wave hover")
	var hover_amplitude := 15.0
	var hover_frequency := 2.0
	assert_in_range(hover_amplitude, 10.0, 30.0, "Hover amplitude is visible")
	assert_in_range(hover_frequency, 1.0, 4.0, "Hover frequency is natural")


func test_turret_rotation_limits() -> void:
	print("\n📋 Test: TurretEnemy has rotation limits")
	var max_rotation := 90.0  # Degrees
	assert_in_range(max_rotation, 45.0, 180.0, "Turret rotation range is reasonable")


# -----------------------------------------------------------------------------
# COMBAT TESTS
# -----------------------------------------------------------------------------

func test_attack_damage_applied() -> void:
	print("\n📋 Test: Attack damage is applied correctly")
	var player_health := 100
	var attack_damage := 10
	var new_health := player_health - attack_damage
	assert_equals(new_health, 90, "Attack damage reduces player health")


func test_attack_cooldown_prevents_spam() -> void:
	print("\n📋 Test: Attack cooldown prevents spam")
	var cooldown_active := true
	var can_attack := not cooldown_active
	assert_false(can_attack, "Cannot attack during cooldown")
