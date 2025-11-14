extends Control

@export var settings_menu_path: NodePath
@onready var settings_menu: Control = get_node_or_null(settings_menu_path)

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS 

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		# Close settings first if it's open
		# didn't work LOL
		if settings_menu and settings_menu.visible:
			settings_menu.close()
			return

		toggle_pause()

func toggle_pause():
	if get_tree().paused:
		close()
	else:
		open()

func open():
	visible = true
	get_tree().paused = true

func close():
	visible = false
	get_tree().paused = false
	
func _on_resume_pressed():
	close()

func _on_restart_pressed():
	var counters = get_tree().get_nodes_in_group("kill_counter")
	if counters.size() > 0:
		counters[0].zombies_killed = 0
	get_tree().paused = false
	get_tree().reload_current_scene()
