# =============================================================================
# VictoryScreen.gd - Layar kemenangan saat menyelesaikan level atau game
# =============================================================================
# Menampilkan statistik level dan opsi melanjutkan
# =============================================================================

extends CanvasLayer

## Sinyal saat next level dipilih
signal next_level_requested
## Sinyal saat main menu dipilih
signal main_menu_requested


# -----------------------------------------------------------------------------
# REFERENSI NODE
# -----------------------------------------------------------------------------
@onready var title_label: Label = $VictoryPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var message_label: Label = $VictoryPanel/MarginContainer/VBoxContainer/MessageLabel
@onready var cores_label: Label = $VictoryPanel/MarginContainer/VBoxContainer/StatsContainer/CoresLabel
@onready var next_button: Button = $VictoryPanel/MarginContainer/VBoxContainer/NextButton
@onready var main_menu_button: Button = $VictoryPanel/MarginContainer/VBoxContainer/MainMenuButton


# -----------------------------------------------------------------------------
# STATE
# -----------------------------------------------------------------------------
## Apakah ini final victory (semua level clear)?
var is_final_victory: bool = false


# -----------------------------------------------------------------------------
# LIFECYCLE
# -----------------------------------------------------------------------------
func _ready() -> void:
	# Sembunyikan saat pertama load
	hide_screen()
	
	# Setup koneksi button
	_setup_button_connections()
	
	print("[VictoryScreen] Siap digunakan")


# -----------------------------------------------------------------------------
# KONEKSI BUTTON
# -----------------------------------------------------------------------------
## Setup signal connections untuk semua button
func _setup_button_connections() -> void:
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)


# -----------------------------------------------------------------------------
# TAMPILAN
# -----------------------------------------------------------------------------
## Tampilkan layar victory untuk level clear
func show_level_complete(level_name: String, cores_collected: int, total_cores: int) -> void:
	is_final_victory = false
	
	# Set judul
	if title_label:
		title_label.text = "LEVEL SELESAI!"
	
	# Set pesan
	if message_label:
		message_label.text = level_name + " berhasil diselesaikan"
	
	# Set stats
	if cores_label:
		cores_label.text = "Cores: " + str(cores_collected) + "/" + str(total_cores)
	
	# Update button text
	if next_button:
		next_button.text = "LEVEL BERIKUTNYA"
		next_button.visible = true
	
	_show_common()


## Tampilkan layar final victory (semua level clear)
func show_final_victory(total_cores: int) -> void:
	is_final_victory = true
	
	# Set judul
	if title_label:
		title_label.text = "KEMENANGAN!"
	
	# Set pesan
	if message_label:
		message_label.text = "Overlord telah dikalahkan!\nBIP berhasil mengembalikan kedamaian ke Arcadia."
	
	# Set stats
	if cores_label:
		cores_label.text = "Total Cores: " + str(total_cores) + "/5"
	
	# Sembunyikan next button karena tidak ada level lagi
	if next_button:
		next_button.text = "MAIN LAGI"
		next_button.visible = true
	
	_show_common()


## Tampilkan dengan setup umum
func _show_common() -> void:
	# Tampilkan
	visible = true
	
	# Pause game
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Focus ke next button
	if next_button and next_button.visible:
		next_button.grab_focus()
	elif main_menu_button:
		main_menu_button.grab_focus()
	
	print("[VictoryScreen] Ditampilkan - victory!")


## Sembunyikan layar victory
func hide_screen() -> void:
	visible = false
	
	# Unpause game
	get_tree().paused = false


# -----------------------------------------------------------------------------
# BUTTON HANDLERS
# -----------------------------------------------------------------------------
## Handler saat next button ditekan
func _on_next_pressed() -> void:
	print("[VictoryScreen] Next dipilih")
	
	# Sembunyikan screen
	hide_screen()
	
	# Emit signal
	next_level_requested.emit()
	
	if is_final_victory:
		# Kembali ke main menu dan reset game
		if has_node("/root/GameManager"):
			var game_manager = get_node("/root/GameManager")
			game_manager.reset_game()
			game_manager.go_to_main_menu()
	else:
		# Lanjut ke next level via GameManager
		if has_node("/root/GameManager"):
			var game_manager = get_node("/root/GameManager")
			game_manager.load_next_level()


## Handler saat main menu button ditekan
func _on_main_menu_pressed() -> void:
	print("[VictoryScreen] Main menu dipilih")
	
	# Sembunyikan screen
	hide_screen()
	
	# Emit signal
	main_menu_requested.emit()
	
	# Kembali ke main menu via GameManager
	if has_node("/root/GameManager"):
		var game_manager = get_node("/root/GameManager")
		game_manager.go_to_main_menu()
	else:
		# Fallback langsung change scene
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
