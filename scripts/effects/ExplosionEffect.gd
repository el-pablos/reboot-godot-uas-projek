# ===================================================
# ExplosionEffect.gd - Explosion Particles Manager
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Handles explosion visual and audio effects.
# Auto-destroys after animation completes.
# ===================================================

extends Node2D
class_name ExplosionEffect

# === EXPORTS ===
@export var explosion_color: Color = Color(1, 0.5, 0.2)
@export var explosion_size: float = 1.0
@export var screen_shake_intensity: float = 10.0
@export var screen_shake_duration: float = 0.2

# Node references
@onready var particles: GPUParticles2D = $GPUParticles2D if has_node("GPUParticles2D") else null
@onready var light: PointLight2D = $PointLight2D if has_node("PointLight2D") else null


func _ready() -> void:
	# Setup particles if not exists
	if not particles:
		_create_particles()
	
	# Setup light flash
	if not light:
		_create_light()
	
	# Apply scale
	scale = Vector2(explosion_size, explosion_size)
	
	# Play sound
	AudioManager.play_sfx("explosion")
	
	# Screen shake
	var camera := get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(screen_shake_intensity, screen_shake_duration)
	
	# Start explosion
	_start_explosion()


func _create_particles() -> void:
	## Create GPUParticles2D for explosion.
	particles = GPUParticles2D.new()
	particles.name = "GPUParticles2D"
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.amount = 24
	particles.lifetime = 0.6
	
	# Create particle material
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 100.0
	mat.initial_velocity_max = 200.0
	mat.gravity = Vector3(0, 300, 0)
	mat.scale_min = 4.0
	mat.scale_max = 8.0
	mat.color = explosion_color
	
	# Color gradient (orange to transparent)
	var gradient := Gradient.new()
	gradient.add_point(0.0, explosion_color)
	gradient.add_point(0.5, Color(1, 0.3, 0.1, 0.8))
	gradient.add_point(1.0, Color(0.3, 0.1, 0.0, 0.0))
	
	var gradient_tex := GradientTexture1D.new()
	gradient_tex.gradient = gradient
	mat.color_ramp = gradient_tex
	
	particles.process_material = mat
	
	add_child(particles)


func _create_light() -> void:
	## Create flash light for explosion.
	light = PointLight2D.new()
	light.color = explosion_color
	light.energy = 3.0
	light.texture_scale = 2.0
	
	var light_tex := load("res://assets/sprites/effects/light_radial.png")
	if light_tex:
		light.texture = light_tex
	
	add_child(light)


func _start_explosion() -> void:
	## Start explosion animation.
	# Start particles
	if particles:
		particles.emitting = true
	
	# Flash and fade light
	if light:
		var tween := create_tween()
		tween.tween_property(light, "energy", 5.0, 0.05)
		tween.tween_property(light, "energy", 0.0, 0.4)
	
	# Auto-destroy after particles finish
	await get_tree().create_timer(1.0).timeout
	queue_free()
