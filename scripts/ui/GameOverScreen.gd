# =============================================================================
# GameOverScreen.gd - Layar game over saat player mati
# =============================================================================
# Menampilkan pesan game over dengan opsi retry atau kembali ke menu
# =============================================================================

extends CanvasLayer

## Sinyal saat player pilih retry
signal retry_requested
## Sinyal saat player pilih main menu
signal main_menu_requested


# -----------------------------------------------------------------------------
# REFERENSI NODE
# -----------------------------------------------------------------------------
@onready var retry_button: Button = $GameOverPanel/MarginContainer/VBoxContainer/RetryButton
@onready var main_menu_button: Button = $GameOverPanel/MarginContainer/VBoxContainer/MainMenuButton
@onready var death_message_label: Label = $GameOverPanel/MarginContainer/VBoxContainer/DeathMessageLabel


# -----------------------------------------------------------------------------
# DAFTAR PESAN KEMATIAN
# -----------------------------------------------------------------------------
## Variasi pesan kematian untuk menambah flavor text
const DEATH_MESSAGES: Array[String] = [
	"Sistem BIP mengalami kerusakan fatal...",
	"Koneksi terputus...",
	"Core energy depleted...",
	"BIP needs a reboot...",
	"Critical failure detected...",
	"Misi gagal. Coba lagi?",
	"Overlord masih berkuasa...",
	"BIP: \"Aku... akan... kembali...\"",
]


# -----------------------------------------------------------------------------
# LIFECYCLE
# -----------------------------------------------------------------------------
func _ready() -> void:
	# Sembunyikan saat pertama load
	hide_screen()
	
	# Setup koneksi button
	_setup_button_connections()
	
	print("[GameOverScreen] Siap digunakan")


# -----------------------------------------------------------------------------
# KONEKSI BUTTON
# -----------------------------------------------------------------------------
## Setup signal connections untuk semua button
func _setup_button_connections() -> void:
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
	
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)


# -----------------------------------------------------------------------------
# TAMPILAN
# -----------------------------------------------------------------------------
## Tampilkan layar game over dengan animasi fade in
func show_screen() -> void:
	# Set pesan kematian random
	if death_message_label:
		death_message_label.text = DEATH_MESSAGES.pick_random()
	
	# Tampilkan
	visible = true
	
	# Pause game
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Focus ke retry button
	if retry_button:
		retry_button.grab_focus()
	
	print("[GameOverScreen] Ditampilkan - player mati")


## Sembunyikan layar game over
func hide_screen() -> void:
	visible = false
	
	# Unpause game
	get_tree().paused = false


# -----------------------------------------------------------------------------
# BUTTON HANDLERS
# -----------------------------------------------------------------------------
## Handler saat retry button ditekan
func _on_retry_pressed() -> void:
	print("[GameOverScreen] Retry dipilih")
	
	# Sembunyikan screen
	hide_screen()
	
	# Emit signal
	retry_requested.emit()
	
	# Reload current level via GameManager
	if has_node("/root/GameManager"):
		var game_manager = get_node("/root/GameManager")
		# Reset player state
		game_manager.reset_player_health()
		# Reload level
		game_manager.reload_current_level()


## Handler saat main menu button ditekan
func _on_main_menu_pressed() -> void:
	print("[GameOverScreen] Main menu dipilih")
	
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


# -----------------------------------------------------------------------------
# API PUBLIK
# -----------------------------------------------------------------------------
## Tampilkan game over dengan custom message
func show_with_message(custom_message: String) -> void:
	if death_message_label:
		death_message_label.text = custom_message
	
	show_screen()
