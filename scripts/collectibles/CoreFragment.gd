# ===================================================
# CoreFragment.gd - Pecahan Core yang bisa dikumpulkan
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Collectible utama game - ada 5 total untuk menang.
# ===================================================

extends Area2D
class_name CoreFragment

@export_group("Visual")
## ID core (1-5)
@export var core_id: int = 1
## Warna glow
@export var glow_color: Color = Color(1, 0.9, 0.2)

@export_group("Animation")
## Kecepatan rotasi
@export var rotation_speed: float = 2.0
## Amplitudo hover
@export var hover_amplitude: float = 5.0
## Kecepatan hover
@export var hover_speed: float = 3.0

# Internal
var start_position: Vector2
var time_passed: float = 0.0
var is_collected: bool = false


func _ready() -> void:
	start_position = position
	
	# Setup collision
	collision_layer = 16  # Layer 5: Collectible
	collision_mask = 1    # Mask 1: Player
	
	# Connect signal
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if is_collected:
		return
	
	time_passed += delta
	
	# Rotasi
	rotation += rotation_speed * delta
	
	# Hover naik-turun
	position.y = start_position.y + sin(time_passed * hover_speed) * hover_amplitude


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_collected:
		_collect()


func _collect() -> void:
	is_collected = true
	
	# 1. Play sound effect (AudioManager supports String names)
	if AudioManager:
		AudioManager.play_sfx("collect")
	
	# 2. Disable collision agar tidak trigger 2x
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", true)
	
	# 3. Efek visual collect
	_collect_effect()
	
	# 4. Notify GameManager dan trigger level transition
	if GameManager:
		GameManager.collect_core_and_advance()


func _collect_effect() -> void:
	# Scale up dan fade out
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2, 2), 0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	queue_free()
