extends CharacterBody2D

const SPEED = 300.0

func _physics_process(delta):
	# Get input direction
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_dir.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_dir.y -= 1
	
	# Normalize diagonal movement
	input_dir = input_dir.normalized()
	
	# Set velocity
	velocity = input_dir * SPEED
	
	# Move the player
	move_and_slide()
	
	# Face the cursor
	var mouse_pos = get_global_mouse_position()
	look_at(mouse_pos)

