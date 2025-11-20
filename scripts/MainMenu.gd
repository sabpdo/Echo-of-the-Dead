extends Control

@onready var play_button = $VBoxContainer/PlayButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var info_button = $InfoButtonContainer/InfoButton
@onready var info_button_container = $InfoButtonContainer

const MAIN_SCENE = preload("res://scenes/Main.tscn")
const HOW_TO_PLAY_SCENE = preload("res://scenes/HowToPlay.tscn")
const SETTINGS_PAGE_SCENE = "res://scenes/SettingsPage.tscn"
const INFO_SCENE = "res://scenes/InfoScreen.tscn"


func _ready():
	# Connect button signals
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	info_button.pressed.connect(_on_info_button_pressed)
	
	# Set info button container size relative to viewport
	_update_info_button_size()
	
	# Update on viewport size changes
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _on_viewport_size_changed():
	_update_info_button_size()

func _update_info_button_size():
	if info_button_container:
		var viewport_size = get_viewport().get_visible_rect().size
		var button_size = viewport_size * 0.03  # 3% of screen size
		var margin = viewport_size * 0.02  # 2% margin from edges
		
		info_button_container.offset_left = -button_size.x - margin.x
		info_button_container.offset_top = margin.y
		info_button_container.offset_right = -margin.x
		info_button_container.offset_bottom = margin.y + button_size.y
		
		# Scale font size relative to button size
		var font_size = max(20, button_size.y * 0.7)
		info_button.add_theme_font_size_override("font_size", int(font_size))

func _on_play_pressed():
	GameSettings.play_click_sound()
	# Transition to the main game scene
	get_tree().change_scene_to_packed(MAIN_SCENE)

func _on_settings_pressed():
	GameSettings.play_click_sound()
	# Navigate to settings page
	get_tree().change_scene_to_file(SETTINGS_PAGE_SCENE)


func _on_how_to_play_button_pressed() -> void:
	GameSettings.play_click_sound()
	# Replace with function body.
	get_tree().change_scene_to_packed(HOW_TO_PLAY_SCENE)

func _on_info_button_pressed() -> void:
	GameSettings.play_click_sound()
	get_tree().change_scene_to_file(INFO_SCENE)
