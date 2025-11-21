extends Control

const MAIN_MENU_SCENE = "res://scenes/MainMenu.tscn"
const TEXT_WIDTH_PERCENT = 0.65  # Text should take up 65% of screen width

@onready var title_label = $CenterContainer/TitleLabel

func _ready():
	# Calculate and set dynamic font size based on screen size
	_adjust_font_size()
	
	# Animation will automatically play due to autoplay = "intro"
	pass

func _adjust_font_size():
	var viewport_size = get_viewport_rect().size
	var target_width = viewport_size.x * TEXT_WIDTH_PERCENT
	
	# Calculate font size based on screen width
	# Approximate: "ECHO OF THE DEAD" is about 18 characters
	# Most fonts are roughly 0.6 * font_size in width per character
	var text_length = title_label.text.length()
	var estimated_font_size = int(target_width / (text_length * 0.6))
	
	# Clamp to reasonable values
	estimated_font_size = clamp(estimated_font_size, 30, 200)
	
	# Set the calculated font size
	title_label.add_theme_font_size_override("font_size", estimated_font_size)
	
	# Wait a frame to get accurate size
	await get_tree().process_frame
	
	# Update pivot offset to center of label for proper scaling
	title_label.pivot_offset = title_label.size / 2

func _on_animation_finished():
	# Transition to main menu after animation completes
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

