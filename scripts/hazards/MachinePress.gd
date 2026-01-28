# ===================================================
# MachinePress.gd - Mesin Press untuk Level Factory
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Hazard yang bergerak naik-turun, instant kill saat menekan.
# ===================================================

extends Node2D
class_name MachinePress

@export_group("Movement")
## Jarak press ke bawah
@export var press_distance: float = 150.0
## Kecepatan turun (cepat)
@export var press_speed: float = 400.0
## Kecepatan naik (lambat)
@export var retract_speed: float = 100.0
## Delay sebelum press
@export var press_delay: float = 1.5
## Delay di posisi bawah
@export var hold_delay: float = 0.3

@export_group("Damage")
## Instant kill?
@export var instant_kill: bool = true

# Internal
var start_position: Vector2
var is_pressing: bool = false
var press_body: StaticBody2D
var hazard_area: Area2D


func _ready() -> void:
	start_position = position
	
	# Setup nodes
	press_body = $PressBody if has_node("PressBody") else null
	hazard_area = $HazardArea if has_node("HazardArea") else null
	
	if hazard_area:
		hazard_area.body_entered.connect(_on_body_entered)
	
	# Mulai cycle
	_start_press_cycle()


func _start_press_cycle() -> void:
	while true:
		# Tunggu delay
		await get_tree().create_timer(press_delay).timeout
		
		# Press down (cepat)
		is_pressing = true
		var tween := create_tween()
		tween.tween_property(self, "position:y", start_position.y + press_distance, press_distance / press_speed)
		await tween.finished
		
		# Hold di bawah
		await get_tree().create_timer(hold_delay).timeout
		
		# Retract (lambat)
		is_pressing = false
		var retract_tween := create_tween()
		retract_tween.tween_property(self, "position:y", start_position.y, press_distance / retract_speed)
		await retract_tween.finished


func _on_body_entered(body: Node2D) -> void:
	if body is Player and is_pressing:
		var player := body as Player
		if instant_kill:
			player.take_damage(player.max_health)
		else:
			player.take_damage(50)
