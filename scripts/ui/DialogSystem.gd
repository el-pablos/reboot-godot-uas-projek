# ===================================================
# DialogSystem.gd - Sistem Dialog Oracle
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Menampilkan dialog dari Oracle dan NPC lainnya.
# ===================================================

extends CanvasLayer
class_name DialogSystem

# --- SIGNALS ---
signal dialog_started
signal dialog_finished
signal dialog_advanced

# === EXPORT VARIABLES ===

@export_group("Timing")
## Kecepatan typing (karakter per detik)
@export var typing_speed: float = 50.0
## Delay sebelum auto-advance (0 = manual only)
@export var auto_advance_delay: float = 0.0

@export_group("Audio")
## Sound effect per karakter
@export var typing_sound: AudioStream

# === INTERNAL ===
var dialog_queue: Array[Dictionary] = []
var current_dialog: Dictionary = {}
var is_dialog_active: bool = false
var is_typing: bool = false
var full_text: String = ""
var displayed_text: String = ""

# Node references
@onready var dialog_box: PanelContainer = $DialogBox
@onready var speaker_label: Label = $DialogBox/MarginContainer/VBoxContainer/SpeakerLabel
@onready var text_label: Label = $DialogBox/MarginContainer/VBoxContainer/TextLabel
@onready var continue_indicator: Label = $DialogBox/MarginContainer/VBoxContainer/ContinueIndicator


func _ready() -> void:
	# Sembunyikan dialog box di awal
	dialog_box.visible = false
	
	# Pause mode agar dialog tetap jalan saat game pause
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if not is_dialog_active:
		return
	
	if event.is_action_pressed("jump") or event.is_action_pressed("interact"):
		if is_typing:
			# Skip typing, tampilkan full text
			_complete_typing()
		else:
			# Advance ke dialog berikutnya
			_advance_dialog()
		get_viewport().set_input_as_handled()


# === PUBLIC API ===

func show_dialog(dialogs: Array[Dictionary]) -> void:
	"""
	Tampilkan rangkaian dialog.
	Format dialog: { "speaker": "Oracle", "text": "Selamat datang, Bip..." }
	"""
	if dialogs.is_empty():
		return
	
	dialog_queue = dialogs.duplicate()
	is_dialog_active = true
	dialog_started.emit()
	
	# Optional: pause game
	# get_tree().paused = true
	
	_show_next_dialog()


func show_single_dialog(speaker: String, text: String) -> void:
	"""Shortcut untuk satu dialog."""
	show_dialog([{"speaker": speaker, "text": text}])


func show_oracle_intro() -> void:
	"""Dialog intro dari Oracle."""
	var intro_dialogs: Array[Dictionary] = [
		{
			"speaker": "ORACLE",
			"text": "Selamat datang kembali, Bip..."
		},
		{
			"speaker": "ORACLE",
			"text": "Kamu adalah satu-satunya Maintenance Bot yang sistemnya masih bersih setelah Reboot."
		},
		{
			"speaker": "ORACLE",
			"text": "Overlord telah merusak Geo-Core, memecah Arcadia menjadi pulau-pulau melayang."
		},
		{
			"speaker": "ORACLE",
			"text": "Tugasmu: Kumpulkan 5 Pecahan Core yang tersebar untuk menyatukan kembali Arcadia!"
		},
		{
			"speaker": "ORACLE",
			"text": "Hati-hati, Bip. Robot lain telah terkorupsi dan akan menyerangmu."
		},
		{
			"speaker": "ORACLE",
			"text": "Semoga berhasil. Nasib Arcadia ada di tanganmu!"
		}
	]
	
	show_dialog(intro_dialogs)


func close_dialog() -> void:
	"""Tutup dialog secara paksa."""
	dialog_queue.clear()
	_finish_dialog()


# === INTERNAL METHODS ===

func _show_next_dialog() -> void:
	"""Tampilkan dialog berikutnya dari queue."""
	if dialog_queue.is_empty():
		_finish_dialog()
		return
	
	current_dialog = dialog_queue.pop_front()
	
	# Show dialog box
	dialog_box.visible = true
	
	# Set speaker
	if speaker_label:
		speaker_label.text = current_dialog.get("speaker", "???")
		
		# Warna speaker berdasarkan siapa
		match current_dialog.get("speaker", ""):
			"ORACLE":
				speaker_label.modulate = Color(0.5, 0.8, 1)
			"BIP":
				speaker_label.modulate = Color(0.3, 0.9, 0.5)
			_:
				speaker_label.modulate = Color.WHITE
	
	# Start typing
	full_text = current_dialog.get("text", "")
	displayed_text = ""
	is_typing = true
	
	if continue_indicator:
		continue_indicator.visible = false
	
	_type_text()


func _type_text() -> void:
	"""Typing effect untuk teks."""
	while displayed_text.length() < full_text.length() and is_typing:
		displayed_text += full_text[displayed_text.length()]
		
		if text_label:
			text_label.text = displayed_text
		
		# Typing sound
		# if typing_sound and AudioManager:
		#     AudioManager.play_sfx(typing_sound, 0.3)
		
		await get_tree().create_timer(1.0 / typing_speed).timeout
	
	_complete_typing()


func _complete_typing() -> void:
	"""Selesaikan typing, tampilkan full text."""
	is_typing = false
	displayed_text = full_text
	
	if text_label:
		text_label.text = full_text
	
	if continue_indicator:
		continue_indicator.visible = true
		# Animate indicator
		_animate_continue_indicator()


func _animate_continue_indicator() -> void:
	"""Animasi blink untuk continue indicator."""
	while is_dialog_active and not is_typing and continue_indicator:
		continue_indicator.modulate.a = 1.0
		await get_tree().create_timer(0.5).timeout
		if not is_dialog_active:
			break
		continue_indicator.modulate.a = 0.3
		await get_tree().create_timer(0.5).timeout


func _advance_dialog() -> void:
	"""Pindah ke dialog berikutnya."""
	dialog_advanced.emit()
	_show_next_dialog()


func _finish_dialog() -> void:
	"""Selesai semua dialog."""
	is_dialog_active = false
	is_typing = false
	
	dialog_box.visible = false
	
	# Unpause game jika dipause
	# get_tree().paused = false
	
	dialog_finished.emit()
