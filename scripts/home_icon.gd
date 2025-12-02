extends Button

func _ready():
	# Allow button to work even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Ensure button captures input properly
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Ensure button is on top for input handling
	z_index = 10

func _pressed():
	GameSettings.play_click_sound()
	# Unpause if paused
	if get_tree().paused:
		get_tree().paused = false
	
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
