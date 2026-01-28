# ===================================================
# BouncePlatform.gd - Platform Memantul untuk Level Lab
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Platform dengan physics material yang memantulkan player.
# ===================================================

extends StaticBody2D
class_name BouncePlatform

@export_group("Bounce Settings")
## Kekuatan pantulan (velocity.y yang diberikan)
@export var bounce_force: float = -500.0
## Apakah memantul horizontal juga?
@export var horizontal_bounce: bool = false
## Multiplier horizontal bounce
@export var horizontal_multiplier: float = 0.3

@export_group("Visual")
## Warna platform
@export var platform_color: Color = Color(0.6, 0.2, 0.8)  # Ungu

var area: Area2D


func _ready() -> void:
	# Setup detection area
	area = Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 1  # Player
	add_child(area)
	
	# Copy collision shape dari StaticBody
	for child in get_children():
		if child is CollisionShape2D:
			var shape_copy := child.duplicate() as CollisionShape2D
			area.add_child(shape_copy)
			break
	
	# Connect signal
	area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var player := body as Player
		
		# Hanya bounce jika player jatuh dari atas
		if player.velocity.y > 0:
			# Apply bounce
			player.velocity.y = bounce_force
			
			if horizontal_bounce:
				player.velocity.x *= horizontal_multiplier
			
			# Visual feedback
			_bounce_effect()


func _bounce_effect() -> void:
	# Scale effect
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 0.9), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)
