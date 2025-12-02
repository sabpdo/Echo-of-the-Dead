extends Control

@onready var current_difficulty_label = $CenterContainer/Panel/MarginContainer/MainVBox/ScrollContainer/VBoxContainer/CurrentDifficultyLabel
@onready var easy_button = $CenterContainer/Panel/MarginContainer/MainVBox/ScrollContainer/VBoxContainer/EasyButton
@onready var medium_button = $CenterContainer/Panel/MarginContainer/MainVBox/ScrollContainer/VBoxContainer/MediumButton
@onready var hard_button = $CenterContainer/Panel/MarginContainer/MainVBox/ScrollContainer/VBoxContainer/HardButton
@onready var volume_slider = $CenterContainer/Panel/MarginContainer/MainVBox/ScrollContainer/VBoxContainer/VolumeContainer/VolumeSlider
@onready var volume_value_label = $CenterContainer/Panel/MarginContainer/MainVBox/ScrollContainer/VBoxContainer/VolumeContainer/VolumeHeader/VolumeValueLabel
@onready var music_toggle = $CenterContainer/Panel/MarginContainer/MainVBox/ScrollContainer/VBoxContainer/MusicToggleContainer/MusicToggle
@onready var sfx_toggle = $CenterContainer/Panel/MarginContainer/MainVBox/ScrollContainer/VBoxContainer/SFXToggleContainer/SFXToggle
@onready var panel = $CenterContainer/Panel

const MAIN_MENU_SCENE = "res://scenes/MainMenu.tscn"
const MAIN_GAME_SCENE = "res://scenes/Main.tscn"

# Track where we came from
var return_to_game: bool = false

# Hardcoded default height
const DEFAULT_HEIGHT = 900

func _ready():
	# Check if we should return to game (if there's a saved state)
	if GameSettings.has_meta("came_from_game"):
		return_to_game = GameSettings.get_meta("came_from_game")
		GameSettings.remove_meta("came_from_game")
	
	# Set dynamic height for settings panel
	_set_dynamic_height()
	
	_update_current_difficulty()
	_highlight_selected_button()
	_update_audio_controls()
	
	# Connect slider drag events to ensure proper drag behavior
	if volume_slider:
		volume_slider.drag_started.connect(_on_slider_drag_started)
		volume_slider.drag_ended.connect(_on_slider_drag_ended)

func _set_dynamic_height():
	# Get screen height
	var screen_height = get_viewport().get_visible_rect().size.y
	# Use the smaller of screen height or default height
	var panel_height = min(screen_height, DEFAULT_HEIGHT)
	# Set the panel's minimum size height
	if panel:
		panel.custom_minimum_size.y = panel_height

func _on_slider_drag_started():
	# Slider is being dragged
	pass

func _on_slider_drag_ended(value_changed: bool):
	# Slider drag ended
	pass

func _update_current_difficulty():
	var difficulty_name = GameSettings.get_difficulty_name()
	current_difficulty_label.text = "Current: " + difficulty_name

func _highlight_selected_button():
	# Reset all button styles
	easy_button.modulate = Color.WHITE
	medium_button.modulate = Color.WHITE
	hard_button.modulate = Color.WHITE
	
	# Highlight the selected difficulty
	match GameSettings.current_difficulty:
		GameSettings.Difficulty.EASY:
			easy_button.modulate = Color(0.5, 1, 0.5)
		GameSettings.Difficulty.MEDIUM:
			medium_button.modulate = Color(1, 1, 0.5)
		GameSettings.Difficulty.HARD:
			hard_button.modulate = Color(1, 0.5, 0.5)

func _on_easy_pressed():
	GameSettings.play_click_sound()
	GameSettings.set_difficulty(GameSettings.Difficulty.EASY)
	_update_current_difficulty()
	_highlight_selected_button()

func _on_medium_pressed():
	GameSettings.play_click_sound()
	GameSettings.set_difficulty(GameSettings.Difficulty.MEDIUM)
	_update_current_difficulty()
	_highlight_selected_button()

func _on_hard_pressed():
	GameSettings.play_click_sound()
	GameSettings.set_difficulty(GameSettings.Difficulty.HARD)
	_update_current_difficulty()
	_highlight_selected_button()

func _update_audio_controls():
	# Load current audio settings
	volume_slider.value = GameSettings.master_volume
	volume_value_label.text = str(int(GameSettings.master_volume * 100)) + "%"
	music_toggle.button_pressed = GameSettings.music_enabled
	sfx_toggle.button_pressed = GameSettings.sfx_enabled

func _on_volume_slider_value_changed(value: float):
	GameSettings.set_master_volume(value)
	volume_value_label.text = str(int(value * 100)) + "%"

func _on_music_toggle_toggled(button_pressed: bool):
	GameSettings.play_click_sound()
	GameSettings.set_music_enabled(button_pressed)

func _on_sfx_toggle_toggled(button_pressed: bool):
	GameSettings.play_click_sound()
	GameSettings.set_sfx_enabled(button_pressed)

func _on_back_pressed():
	GameSettings.play_click_sound()
	if return_to_game:
		get_tree().change_scene_to_file(MAIN_GAME_SCENE)
	else:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)

