extends Control

@export var pause_menu_path: NodePath
@onready var pause_menu: Control = get_node_or_null(pause_menu_path)

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # still receives input while paused

func open():
	visible = true

func close():
	visible = false

func _on_resume_pressed():
	# Close both menus and unpause
	close()
	if pause_menu:
		pause_menu.close()

func _on_restart_pressed():
	var counters = get_tree().get_nodes_in_group("kill_counter")
	if counters.size() > 0:
		counters[0].zombies_killed = 0
	get_tree().paused = false
	get_tree().reload_current_scene()
