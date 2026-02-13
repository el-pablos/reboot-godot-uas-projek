# Mock boss for unit testing BossBrain attack flow
extends CharacterBody2D

var is_attacking: bool = false
var is_dead: bool = false
var sprite: Node = null
var target_player: Node = null
var gravity: float = 980.0

# Health properties (used by BossBrain._is_aggressive_phase)
var current_health: int = 100
var max_health: int = 100
