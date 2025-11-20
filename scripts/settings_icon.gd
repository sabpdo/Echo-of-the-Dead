extends Button

func _ready() -> void:
	# Allow button to work even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func _pressed():
	GameSettings.play_click_sound()
	var settings_menu = get_parent().get_node("SettingsMenu")
	var pause_menu = get_parent().get_node("PauseMenu")
	
	# Don't open settings menu if pause menu is open
	if pause_menu and pause_menu.visible:
		return
	
	settings_menu.open()
