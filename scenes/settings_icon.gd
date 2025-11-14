extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _pressed():
	var settings_menu = get_parent().get_node("SettingsMenu")
	var pause_menu = get_parent().get_node("PauseMenu")
	
	# Don't open settings menu if pause menu is open
	if pause_menu and pause_menu.visible:
		return
	
	settings_menu.open()
