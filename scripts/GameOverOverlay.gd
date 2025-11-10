extends Control

@onready var game_over_label: Label = $VBoxContainer/GameOverLabel
@onready var player: Node2D = null

func _ready():
	# Find the player node
	player = get_node("/root/Main/Player")
	
	if player:
		# Connect to player death signal
		player.player_died.connect(_on_player_died)
	
	# Initially hide the overlay
	visible = false

func _on_player_died():
	# Show the game over overlay
	visible = true
	
	# Pause the game
	get_tree().paused = true
