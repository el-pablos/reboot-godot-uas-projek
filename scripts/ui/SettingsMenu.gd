# ===================================================
# SettingsMenu.gd - UI Settings Menu
# Project: REBOOT
# ===================================================

extends Control

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var master_label: Label = %MasterLabel
@onready var music_label: Label = %MusicLabel
@onready var sfx_label: Label = %SFXLabel
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var vsync_check: CheckButton = %VsyncCheck
@onready var shake_check: CheckButton = %ShakeCheck
@onready var hitstop_option: OptionButton = %HitStopOption
@onready var back_button: Button = %BackButton

# Input mapping display
@onready var input_container: VBoxContainer = %InputContainer

var _is_from_pause: bool = false


func _ready() -> void:
	_load_from_settings()
	_setup_input_display()
	_connect_signals()


func set_from_pause(value: bool) -> void:
	_is_from_pause = value


# === LOAD CURRENT SETTINGS ===
func _load_from_settings() -> void:
	var sm = _get_settings_manager()
	if not sm:
		return
	master_slider.value = sm.master_volume
	music_slider.value = sm.music_volume
	sfx_slider.value = sm.sfx_volume
	_update_volume_labels()
	fullscreen_check.button_pressed = sm.fullscreen
	vsync_check.button_pressed = sm.vsync
	shake_check.button_pressed = sm.screen_shake
	hitstop_option.selected = sm.hit_stop_level


# === INPUT DISPLAY ===
func _setup_input_display() -> void:
	if not input_container:
		return
	# Clear existing
	for child in input_container.get_children():
		child.queue_free()

	var actions := {
		"move_left": "Gerak Kiri",
		"move_right": "Gerak Kanan",
		"jump": "Lompat",
		"dash": "Dash",
		"attack": "Serang",
		"pause": "Pause",
		"interact": "Interaksi"
	}

	for action_name in actions:
		var display_name: String = actions[action_name]
		var keys := ""
		if InputMap.has_action(action_name):
			var events := InputMap.action_get_events(action_name)
			var key_names: Array[String] = []
			for event in events:
				if event is InputEventKey:
					key_names.append(event.as_text())
			keys = ", ".join(key_names) if key_names.size() > 0 else "(tidak ada)"
		else:
			keys = "(tidak terdaftar)"

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var lbl_name := Label.new()
		lbl_name.text = display_name
		lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_name.add_theme_font_size_override("font_size", 10)

		var lbl_keys := Label.new()
		lbl_keys.text = keys
		lbl_keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_keys.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_keys.add_theme_font_size_override("font_size", 10)

		row.add_child(lbl_name)
		row.add_child(lbl_keys)
		input_container.add_child(row)


# === SIGNALS ===
func _connect_signals() -> void:
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	shake_check.toggled.connect(_on_shake_toggled)
	hitstop_option.item_selected.connect(_on_hitstop_selected)
	back_button.pressed.connect(_on_back_pressed)


func _on_master_changed(value: float) -> void:
	var sm = _get_settings_manager()
	if sm:
		sm.master_volume = value
		sm.apply_all()
	_update_volume_labels()


func _on_music_changed(value: float) -> void:
	var sm = _get_settings_manager()
	if sm:
		sm.music_volume = value
		sm.apply_all()
	_update_volume_labels()


func _on_sfx_changed(value: float) -> void:
	var sm = _get_settings_manager()
	if sm:
		sm.sfx_volume = value
		sm.apply_all()
	_update_volume_labels()
	# Play preview SFX
	AudioManager.play_sfx("menu_select")


func _on_fullscreen_toggled(pressed: bool) -> void:
	var sm = _get_settings_manager()
	if sm:
		sm.fullscreen = pressed
		sm.apply_all()


func _on_vsync_toggled(pressed: bool) -> void:
	var sm = _get_settings_manager()
	if sm:
		sm.vsync = pressed
		sm.apply_all()


func _on_shake_toggled(pressed: bool) -> void:
	var sm = _get_settings_manager()
	if sm:
		sm.screen_shake = pressed


func _on_hitstop_selected(index: int) -> void:
	var sm = _get_settings_manager()
	if sm:
		sm.hit_stop_level = index


func _on_back_pressed() -> void:
	# Save on exit
	var sm = _get_settings_manager()
	if sm:
		sm.save_settings()
	AudioManager.play_sfx("menu_confirm")
	if _is_from_pause:
		queue_free()
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")


func _update_volume_labels() -> void:
	if master_label:
		master_label.text = "%d%%" % int(master_slider.value * 100)
	if music_label:
		music_label.text = "%d%%" % int(music_slider.value * 100)
	if sfx_label:
		sfx_label.text = "%d%%" % int(sfx_slider.value * 100)


func _get_settings_manager():
	return get_node_or_null("/root/SettingsManager")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
