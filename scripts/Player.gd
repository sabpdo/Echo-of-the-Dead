extends CharacterBody2D

const SPEED = 300.0

# Attack system
const ATTACK_COOLDOWN = 0.2
const ATTACK_OFFSET = 20.0
var attack_timer: float = 0.0
var attack_scene = preload("res://scenes/attack_effect.tscn")

# Torch interaction
var nearby_torch: Node = null
var previous_nearby_torch: Node = null
var torch_interact_timer: float = 0.0
const TORCH_INTERACT_COOLDOWN: float = 0.3

# Generator interaction
var nearby_generator: Node = null
var previous_nearby_generator: Node = null
var generator_interact_timer: float = 0.0
const GENERATOR_INTERACT_COOLDOWN: float = 0.3

# Door interaction
var nearby_door: Node = null
var previous_nearby_door: Node = null
var door_interact_timer: float = 0.0
const DOOR_INTERACT_COOLDOWN: float = 0.3


# Health system - Heart based (5 hearts = 10 half-hearts)
const MAX_HEARTS = 5
const HALF_HEARTS_PER_HEART = 2
var max_half_hearts: int = MAX_HEARTS * HALF_HEARTS_PER_HEART
var current_half_hearts: int = MAX_HEARTS * HALF_HEARTS_PER_HEART

# Health regeneration
const HEALTH_REGEN_INTERVAL = 10.0  # Regenerate every 10 seconds
const HEALTH_REGEN_AMOUNT = 0.5  # Half a heart per regen
var health_regen_timer: float = 0.0

signal health_changed(current_half_hearts, max_half_hearts)
signal player_died
signal attack_performed
signal torch_proximity_changed(has_torch: bool)
signal generator_proximity_changed(has_generator: bool)
signal door_proximity_changed(has_door: bool)

@onready var spell_audio = $SpellAudio

func _ready():
	current_half_hearts = max_half_hearts
	health_changed.emit(current_half_hearts, max_half_hearts)
	health_regen_timer = HEALTH_REGEN_INTERVAL  # Start with full timer

func take_damage(amount: float = 0.5):
	# Each damage is half a heart (0.5 hearts)
	var half_heart_damage = int(amount * HALF_HEARTS_PER_HEART)
	current_half_hearts = max(0, current_half_hearts - half_heart_damage)
	health_changed.emit(current_half_hearts, max_half_hearts)
	
	if current_half_hearts <= 0:
		player_died.emit()

func heal(amount: float = 0.5):
	# Each heal is half a heart (0.5 hearts)
	var half_heart_heal = int(amount * HALF_HEARTS_PER_HEART)
	current_half_hearts = min(max_half_hearts, current_half_hearts + half_heart_heal)
	health_changed.emit(current_half_hearts, max_half_hearts)

func _physics_process(delta):
	# Health regeneration
	health_regen_timer -= delta
	if health_regen_timer <= 0.0:
		# Regenerate health if not at max
		if current_half_hearts < max_half_hearts:
			heal(HEALTH_REGEN_AMOUNT)
		health_regen_timer = HEALTH_REGEN_INTERVAL  # Reset timer
	
	# Check if torch proximity changed
	if nearby_torch != previous_nearby_torch:
		torch_proximity_changed.emit(nearby_torch != null)
		previous_nearby_torch = nearby_torch
	
	# Check if generator proximity changed
	if nearby_generator != previous_nearby_generator:
		generator_proximity_changed.emit(nearby_generator != null)
		previous_nearby_generator = nearby_generator
	
	# Check if door proximity changed
	if nearby_door != previous_nearby_door:
		door_proximity_changed.emit(nearby_door != null)
		previous_nearby_door = nearby_door
	
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
	
	# Attack (Left Mouse Click)
	attack_timer -= delta
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and attack_timer <= 0.0:
		perform_attack()
		attack_timer = ATTACK_COOLDOWN
	
	# Update interaction timers
	generator_interact_timer -= delta
	torch_interact_timer -= delta
	door_interact_timer -= delta
	
	# Interact with generator (F key) - prioritize generator over door and torch
	if Input.is_key_pressed(KEY_F) and nearby_generator and generator_interact_timer <= 0.0:
		nearby_generator.toggle()
		generator_interact_timer = GENERATOR_INTERACT_COOLDOWN
	# Interact with door (F key) - prioritize door over torch
	elif Input.is_key_pressed(KEY_F) and nearby_door:
		if not nearby_door.is_unlocked:  # Only unlock if not already unlocked
			nearby_door.unlock()
		# Reset timer to allow immediate interaction with other doors
		door_interact_timer = DOOR_INTERACT_COOLDOWN
	# Interact with torch (F key) - only if no generator or door nearby
	elif Input.is_key_pressed(KEY_F) and nearby_torch and torch_interact_timer <= 0.0:
		nearby_torch.toggle()
		# Reset timer to allow immediate interaction with other torches
		torch_interact_timer = TORCH_INTERACT_COOLDOWN
		
func perform_attack():	
	var attack = attack_scene.instantiate()
	
	# direction of attack from cursor
	var dir = (get_global_mouse_position() - global_position).normalized()
	attack.direction = dir

	# Spawn attack in front of player
	attack.global_position = global_position + dir * ATTACK_OFFSET
	get_parent().add_child(attack)
	
	attack_performed.emit()
	
	if spell_audio and spell_audio.has_method("play_cue"):
		spell_audio.play_cue()
