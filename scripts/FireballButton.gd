extends Control

@onready var button: Button = $FireballButton
@onready var cooldown_overlay: ColorRect = $FireballButton/CooldownOverlay
@onready var player = get_node("/root/Main/Player")

var cooldown_tween: Tween = null
var stored_button_height: float = 0.0
var attack_timer: float = 0.0
const ATTACK_COOLDOWN = 0.2

func _ready():
	if button:
		button.pressed.connect(_on_button_pressed)
	
	# Connect to player signal to sync cooldown
	if player:
		player.attack_performed.connect(_on_player_attack_performed)
	
	# Initialize cooldown overlay as hidden
	if cooldown_overlay:
		cooldown_overlay.visible = false

func _process(delta):
	# Update attack timer
	if attack_timer > 0.0:
		attack_timer -= delta
		
		# Update button state based on cooldown
		if attack_timer <= 0.0:
			if button:
				button.disabled = false
			_stop_cooldown()

func _on_button_pressed():
	_try_activate_fireball()

func _try_activate_fireball():
	if player and attack_timer <= 0.0:
		player.perform_attack()

func _on_player_attack_performed():
	# Sync cooldown when player performs attack (either from button or E key)
	attack_timer = ATTACK_COOLDOWN
	if button:
		button.disabled = true
	_start_cooldown()

func _start_cooldown():
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
		
		cooldown_tween = create_tween()
		cooldown_tween.set_ease(Tween.EASE_OUT)
		cooldown_tween.set_trans(Tween.TRANS_LINEAR)
		
		# Animate from full coverage to no coverage, clearing from top to bottom
		cooldown_tween.tween_method(_update_cooldown_overlay, 1.0, 0.0, ATTACK_COOLDOWN)

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

func _stop_cooldown():
	if cooldown_overlay:
		cooldown_overlay.visible = false
	
	if cooldown_tween:
		cooldown_tween.kill()
		cooldown_tween = null

