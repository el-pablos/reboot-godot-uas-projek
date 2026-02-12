# ===================================================
# BossGate.gd - Barrier yang block player sampai boss kalah
# Project: REBOOT
# Author: el-pablos
# ===================================================
# StaticBody2D yang menghalangi akses ke core/area berikutnya.
# Otomatis terbuka saat boss di level yang sama dikalahkan.
# ===================================================

extends StaticBody2D
class_name BossGate

@export_group("Gate Visual")
## Warna gate saat aktif
@export var gate_color: Color = Color(1, 0.3, 0.2, 0.7)
## Warna gate saat mau terbuka
@export var opening_color: Color = Color(0.3, 1, 0.3, 0.5)

# Internal
var is_open: bool = false
var boss_ref: Node = null


func _ready() -> void:
	# Setup collision layer - same as environment
	collision_layer = 4  # Environment
	collision_mask = 0

	# Defer boss connection to ensure all nodes ready
	call_deferred("_connect_to_boss")


func _connect_to_boss() -> void:
	## Cari boss di scene dan connect ke signal boss_defeated.
	var bosses := get_tree().get_nodes_in_group("bosses")
	for boss in bosses:
		if boss.has_signal("boss_defeated"):
			boss.boss_defeated.connect(_on_boss_defeated)
			boss_ref = boss
			print("[BossGate] Connected ke boss: %s" % boss.name)
			return

	push_warning("[BossGate] Tidak ada boss ditemukan di scene!")


func _on_boss_defeated() -> void:
	## Boss kalah - buka gate.
	if is_open:
		return

	is_open = true
	print("[BossGate] Gate terbuka! Boss dikalahkan.")

	# Visual: flash hijau lalu fade out
	for child in get_children():
		if child is Sprite2D or child is ColorRect:
			child.modulate = opening_color

	# Disable collision
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", true)

	# Fade out dan hapus
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)


func is_gate_open() -> bool:
	return is_open
