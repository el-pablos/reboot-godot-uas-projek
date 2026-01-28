# ===================================================
# PauseMenu.gd - Menu Pause
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Menu yang muncul saat game di-pause.
# ===================================================

extends CanvasLayer
class_name PauseMenu

# Node references
@onready var pause_panel: PanelContainer = $PausePanel
@onready var resume_button: Button = $PausePanel/MarginContainer/VBoxContainer/ResumeButton
@onready var settings_button: Button = $PausePanel/MarginContainer/VBoxContainer/SettingsButton
@onready var main_menu_button: Button = $PausePanel/MarginContainer/VBoxContainer/MainMenuButton
@onready var quit_button: Button = $PausePanel/MarginContainer/VBoxContainer/QuitButton


func _ready() -> void:
	# Sembunyikan di awal
	pause_panel.visible = false
	
	# Pause mode - tetap jalan saat game pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect buttons
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	"""Toggle pause state."""
	if get_tree().paused:
		resume_game()
	else:
		pause_game()


func pause_game() -> void:
	"""Pause game dan tampilkan menu."""
	get_tree().paused = true
	pause_panel.visible = true
	
	# Focus resume button
	if resume_button:
		resume_button.grab_focus()
	
	print("[PauseMenu] Game PAUSED")


func resume_game() -> void:
	"""Resume game dan sembunyikan menu."""
	get_tree().paused = false
	pause_panel.visible = false
	
	print("[PauseMenu] Game RESUMED")


func _on_resume_pressed() -> void:
	resume_game()


func _on_settings_pressed() -> void:
	# TODO: Buka settings menu
	print("[PauseMenu] Settings (belum diimplementasikan)")


func _on_main_menu_pressed() -> void:
	# Konfirmasi dulu
	resume_game()
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
