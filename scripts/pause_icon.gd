extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _pressed():
	var pause_menu = get_parent().get_node("PauseMenu")
	var settings_menu = get_parent().get_node("SettingsMenu")
	
	# Don't open pause menu if settings is open
	if settings_menu and settings_menu.visible:
		return
	
	pause_menu.open()
