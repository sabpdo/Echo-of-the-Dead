extends Control

@onready var button: Button = $RadarButton
@onready var cooldown_overlay: ColorRect = $RadarButton/CooldownOverlay
@onready var radar_controller = get_node("/root/Main/RadarController")

var cooldown_tween: Tween = null
var stored_button_height: float = 0.0

func _ready():
	if button:
		button.pressed.connect(_on_button_pressed)
	
	# Connect to radar controller signals to update button state
	if radar_controller:
		radar_controller.cooldown_started.connect(_on_cooldown_started)
		radar_controller.cooldown_finished.connect(_on_cooldown_finished)
		radar_controller.radar_activated.connect(_on_radar_activated)
		radar_controller.radar_deactivated.connect(_on_radar_deactivated)
	
	# Initialize cooldown overlay as hidden
	if cooldown_overlay:
		cooldown_overlay.visible = false

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_try_activate_radar()

func _on_button_pressed():
	_try_activate_radar()

func _try_activate_radar():
	if radar_controller and radar_controller.is_radar_available():
		radar_controller.activate_radar()

func _on_cooldown_started():
	if button:
		button.disabled = true
	
	# Show and animate cooldown overlay
	if cooldown_overlay and button:
		await get_tree().process_frame  # Wait for layout to update
		var button_size = button.size
		
		cooldown_overlay.visible = true
		cooldown_overlay.size.x = button_size.x
		cooldown_overlay.size.y = button_size.y
		
		# Reset overlay to full height (covering entire button)
		cooldown_overlay.position = Vector2(0, 0)
		
		# Store the button height for animation
		stored_button_height = button_size.y
		
		# Animate the overlay from top to bottom (clears from top to bottom)
		if cooldown_tween:
			cooldown_tween.kill()
		
		# Total cooldown duration (10s cooldown)
		var total_cooldown_duration = 10.0
		cooldown_tween = create_tween()
		cooldown_tween.set_ease(Tween.EASE_OUT)
		cooldown_tween.set_trans(Tween.TRANS_LINEAR)
		
		# Animate from full coverage to no coverage, clearing from top to bottom
		cooldown_tween.tween_method(_update_cooldown_overlay, 1.0, 0.0, total_cooldown_duration)

func _update_cooldown_overlay(progress: float):
	# progress goes from 1.0 (full gray) to 0.0 (no gray)
	# To clear from top to bottom: overlay anchored at bottom, shrinks upward
	# As progress decreases, overlay moves up and shrinks, revealing from top
	if cooldown_overlay and button:
		cooldown_overlay.size.x = button.size.x
		cooldown_overlay.size.y = stored_button_height * progress
		# Position moves up as overlay shrinks, keeping bottom edge at button bottom
		# This makes it clear from top to bottom
		cooldown_overlay.position.y = stored_button_height - (stored_button_height * progress)

func _on_cooldown_finished():
	if button:
		button.disabled = false
	
	if cooldown_overlay:
		cooldown_overlay.visible = false
	
	if cooldown_tween:
		cooldown_tween.kill()
		cooldown_tween = null

func _on_radar_activated():
	if button:
		button.disabled = true

func _on_radar_deactivated():
	# Don't enable here - wait for cooldown to finish
	pass
