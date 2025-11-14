extends Control

@onready var play_button = $VBoxContainer/PlayButton
@onready var settings_button = $VBoxContainer/SettingsButton

const MAIN_SCENE = preload("res://scenes/Main.tscn")

func _ready():
	# Connect button signals
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

func _on_play_pressed():
	# Transition to the main game scene
	get_tree().change_scene_to_packed(MAIN_SCENE)

func _on_settings_pressed():
	# Show a simple settings message
	# TODO: Implement full settings menu
	print("Settings - Coming soon!")
	# For now, you can add a settings dialog here later

