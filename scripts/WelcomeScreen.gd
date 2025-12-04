extends Control

signal welcome_screen_finished

@onready var center_container = $CenterContainer
@onready var welcome_label = $CenterContainer/WelcomeLabel
@onready var skip_button = $SkipContainer/SkipButton
@onready var arrow_texture = $SkipContainer/SkipButton/ArrowTexture

var timer: Timer

func _ready():
	# Set up the welcome text and layout
	if welcome_label:
		# Adjust layout based on screen size (this will also set the text)
		_adjust_layout()
	
	# Set up skip button
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)
	
	# Create and start the timer
	timer = Timer.new()
	timer.wait_time = 7.0
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	timer.start()
	
	# Fade in animation
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _on_skip_pressed():
	GameSettings.play_click_sound()
	_finish_welcome_screen()

func _on_timer_timeout():
	_finish_welcome_screen()

func _finish_welcome_screen():
	if timer:
		timer.stop()
	
	# Fade out animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.finished.connect(_emit_finished_signal)

func _adjust_layout():
	if not welcome_label or not center_container:
		return
	
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Calculate responsive margins by adjusting container offsets
	var horizontal_margin = max(20, int(viewport_size.x * 0.04))  # 4% of screen width
	var vertical_margin = max(30, int(viewport_size.y * 0.06))    # 6% of screen height
	
	center_container.offset_left = horizontal_margin
	center_container.offset_top = vertical_margin
	center_container.offset_right = -horizontal_margin
	center_container.offset_bottom = -(vertical_margin + 60)  # Extra space for skip button
	
	# Calculate and set appropriate minimum size for text wrapping
	var available_width = viewport_size.x - (horizontal_margin * 2)
	var available_height = viewport_size.y - (vertical_margin * 2) - 60
	
	welcome_label.custom_minimum_size = Vector2(available_width, available_height)
	
	# Calculate font size based on screen height and update the BBCode
	var title_font_size = max(32, int(viewport_size.y * 0.055))  # 5.5% for title
	var body_font_size = max(22, int(viewport_size.y * 0.035))   # 3.5% for body
	
	# Clamp to reasonable values
	title_font_size = clamp(title_font_size, 32, 60)
	body_font_size = clamp(body_font_size, 22, 40)
	
	# Update text with dynamic font sizes
	welcome_label.text = """[center][font_size=%d]Welcome to Echo of the Dead![/font_size][/center]

[center][font_size=%d]You are a wizard exploring a dark, zombie-infested castle. Use spells to fight zombies and survive. Use radar spells to send sound waves that reveal nearby zombies.[/font_size][/center]

[center][font_size=%d]Your goal: clear monsters and find the generator. Beware — zombies spawn endlessly until lights are restored, and you have limited vision.[/font_size][/center]""" % [title_font_size, body_font_size, body_font_size]

func _emit_finished_signal():
	welcome_screen_finished.emit()
