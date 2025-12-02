extends Button

func _ready() -> void:
	# Allow button to work even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func _pressed():
	GameSettings.play_click_sound()
	var settings_menu = get_parent().get_node("SettingsMenu")
	
	# Open settings menu even when paused
	settings_menu.open()
