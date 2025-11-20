extends Control

const MAIN_MENU = "res://scenes/MainMenu.tscn"

func _ready() -> void:
	pass

func _on_home_page_button_pressed() -> void:
	GameSettings.play_click_sound()
	get_tree().change_scene_to_file(MAIN_MENU)

