extends Control

@onready var play_button = $VBoxContainer/PlayButton
@onready var settings_button = $VBoxContainer/SettingsButton

const MAIN_SCENE = preload("res://scenes/Main.tscn")
const HOW_TO_PLAY_SCENE = preload("res://scenes/HowToPlay.tscn")
const SETTINGS_PAGE_SCENE = "res://scenes/SettingsPage.tscn"


func _ready():
	# Connect button signals
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

func _on_play_pressed():
	# Transition to the main game scene
	get_tree().change_scene_to_packed(MAIN_SCENE)

func _on_settings_pressed():
	# Navigate to settings page
	get_tree().change_scene_to_file(SETTINGS_PAGE_SCENE)


func _on_how_to_play_button_pressed() -> void:
	# Replace with function body.
	get_tree().change_scene_to_packed(HOW_TO_PLAY_SCENE)
