extends Control

@onready var current_difficulty_label = $CenterContainer/Panel/VBoxContainer/CurrentDifficultyLabel
@onready var easy_button = $CenterContainer/Panel/VBoxContainer/EasyButton
@onready var medium_button = $CenterContainer/Panel/VBoxContainer/MediumButton
@onready var hard_button = $CenterContainer/Panel/VBoxContainer/HardButton

const MAIN_MENU_SCENE = "res://scenes/MainMenu.tscn"
const MAIN_GAME_SCENE = "res://scenes/Main.tscn"

# Track where we came from
var return_to_game: bool = false

func _ready():
	# Check if we should return to game (if there's a saved state)
	if GameSettings.has_meta("came_from_game"):
		return_to_game = GameSettings.get_meta("came_from_game")
		GameSettings.remove_meta("came_from_game")
	
	_update_current_difficulty()
	_highlight_selected_button()

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
	GameSettings.set_difficulty(GameSettings.Difficulty.EASY)
	_update_current_difficulty()
	_highlight_selected_button()

func _on_medium_pressed():
	GameSettings.set_difficulty(GameSettings.Difficulty.MEDIUM)
	_update_current_difficulty()
	_highlight_selected_button()

func _on_hard_pressed():
	GameSettings.set_difficulty(GameSettings.Difficulty.HARD)
	_update_current_difficulty()
	_highlight_selected_button()

func _on_back_pressed():
	if return_to_game:
		get_tree().change_scene_to_file(MAIN_GAME_SCENE)
	else:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)

