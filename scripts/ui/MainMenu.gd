# ===================================================
# MainMenu.gd - Script untuk Main Menu
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Tampilan menu utama dengan navigasi ke game, settings, dll.
# ===================================================

extends Control


# --- PATHS ---
const LEVEL_1_PATH: String = "res://scenes/levels/Level_01_GoldenIsles.tscn"


func _ready() -> void:
	# Cek apakah ada save file untuk enable/disable tombol continue
	var continue_btn := $VBoxContainer/ContinueButton as Button
	continue_btn.disabled = not SaveManager.has_save_file()
	
	print("[MainMenu] Menu utama loaded!")


func _on_start_pressed() -> void:
	"""Mulai game baru - reset semua progress."""
	print("[MainMenu] New Game dimulai!")
	GameManager.new_game()
	SaveManager.delete_save()
	
	# TODO: Ganti ke level 1 setelah scene dibuat
	# GameManager.change_level(LEVEL_1_PATH)
	print("[MainMenu] Level 1 belum dibuat, stay di menu.")


func _on_continue_pressed() -> void:
	"""Lanjutkan game dari save terakhir."""
	if SaveManager.load_game():
		print("[MainMenu] Melanjutkan game...")
		if GameManager.current_level != "":
			GameManager.change_level(GameManager.current_level)
	else:
		print("[MainMenu] Gagal load save!")


func _on_settings_pressed() -> void:
	"""Buka menu pengaturan."""
	print("[MainMenu] Settings menu (belum diimplementasikan)")
	# TODO: Implement settings menu


func _on_quit_pressed() -> void:
	"""Keluar dari game."""
	print("[MainMenu] Keluar game...")
	get_tree().quit()
