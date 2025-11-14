extends Control

@export var pause_menu_path: NodePath
@onready var pause_menu: Control = get_node_or_null(pause_menu_path)

func _ready():
	visible = false
	# receives input while paused
	process_mode = Node.PROCESS_MODE_ALWAYS  

func open():
	visible = true
	get_tree().paused = true 

func close():
	visible = false

func _on_resume_pressed():
	# Close both menus and unpause
	close()
	if pause_menu:
		pause_menu.close()
	get_tree().paused = false

func _on_restart_pressed():
	var counters = get_tree().get_nodes_in_group("kill_counter")
	if counters.size() > 0:
		counters[0].zombies_killed = 0

	get_tree().paused = false
	get_tree().reload_current_scene()
