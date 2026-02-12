# ===================================================
# PlayerProjectile.gd - Projectile Player (Energy Bolt)
# Project: REBOOT
# ===================================================
# Tembakan energy yang bisa merusak enemy/boss.
# Spawn dari Player saat attack + aim directional.
# ===================================================

extends Area2D
class_name PlayerProjectile

@export var speed: float = 400.0
@export var damage: int = 15
@export var knockback_force: float = 100.0
@export var lifetime: float = 2.0

var direction: Vector2 = Vector2.RIGHT
var _timer: float = 0.0


func _ready() -> void:
	# Setup collision jika belum ada (skip jika sudah di-create dari Player._shoot_projectile)
	if not _has_collision_child():
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 6.0
		shape.shape = circle
		add_child(shape)

	# Setup visual jika belum ada
	if not _has_visual_child():
		var visual := ColorRect.new()
		visual.size = Vector2(12, 6)
		visual.position = Vector2(-6, -3)
		visual.color = Color(0.3, 0.9, 1.0, 0.9)  # Cyan energy
		add_child(visual)

	# Connect signals
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	# Auto-cleanup
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_timer += delta

	# Keluar viewport → hapus
	if _timer > 0.5:  # Grace period supaya tidak hilang saat baru spawn
		var viewport_rect := get_viewport_rect()
		var cam := get_viewport().get_camera_2d()
		if cam:
			var cam_pos := cam.global_position
			var margin := 100.0
			var screen_rect := Rect2(
				cam_pos - viewport_rect.size / 2 - Vector2(margin, margin),
				viewport_rect.size + Vector2(margin * 2, margin * 2)
			)
			if not screen_rect.has_point(global_position):
				queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		var kb_dir := direction.normalized()
		body.take_damage(damage, kb_dir * knockback_force)
		queue_free()
	elif body.is_in_group("environment") or body.collision_layer & 4:
		# Hit wall/platform
		queue_free()


func _on_area_entered(_area: Area2D) -> void:
	pass  # Bisa ditambahkan untuk hit shield/deflect


func _has_collision_child() -> bool:
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			return true
	return false


func _has_visual_child() -> bool:
	for child in get_children():
		if child is Sprite2D or child is ColorRect:
			return true
	return false
