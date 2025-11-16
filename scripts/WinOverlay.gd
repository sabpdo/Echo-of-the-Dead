extends Control

@onready var win_label: Label = $VBoxContainer/WinLabel
@onready var play_again_button: Button = $VBoxContainer/PlayAgainButton
@onready var return_home_button: Button = $VBoxContainer/ReturnHomeButton

var home_icon: Button = null
var pause_icon: Button = null
var settings_icon: Button = null

func _ready():
	# Set process mode to always so buttons work when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Find the top right buttons
	home_icon = get_node("/root/Main/UILayer/HomeIcon")
	pause_icon = get_node("/root/Main/UILayer/PauseIcon")
	settings_icon = get_node("/root/Main/UILayer/SettingsIcon")
	
	# Connect button signals
	if play_again_button:
		play_again_button.process_mode = Node.PROCESS_MODE_ALWAYS
		play_again_button.pressed.connect(_on_play_again_pressed)
	if return_home_button:
		return_home_button.process_mode = Node.PROCESS_MODE_ALWAYS
		return_home_button.pressed.connect(_on_return_home_pressed)
	
	# Initially hide the overlay
	visible = false

func show_win_screen():
	# Hide the top right buttons
	if home_icon:
		home_icon.visible = false
	if pause_icon:
		pause_icon.visible = false
	if settings_icon:
		settings_icon.visible = false
	
	# Ensure buttons are set up and connected
	if play_again_button:
		play_again_button.process_mode = Node.PROCESS_MODE_ALWAYS
		if not play_again_button.pressed.is_connected(_on_play_again_pressed):
			play_again_button.pressed.connect(_on_play_again_pressed)
	if return_home_button:
		return_home_button.process_mode = Node.PROCESS_MODE_ALWAYS
		if not return_home_button.pressed.is_connected(_on_return_home_pressed):
			return_home_button.pressed.connect(_on_return_home_pressed)
	
	# Show the win overlay
	visible = true
	
	# Pause the game
	get_tree().paused = true

func _on_play_again_pressed():
	print("Play Again pressed")
	# Reset kill counter
	var counters = get_tree().get_nodes_in_group("kill_counter")
	if counters.size() > 0:
		counters[0].zombies_killed = 0
	
	# Unpause and reload the scene
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_return_home_pressed():
	print("Return Home pressed")
	# Unpause if paused
	if get_tree().paused:
		get_tree().paused = false
	
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

