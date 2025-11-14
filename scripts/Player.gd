extends CharacterBody2D

const SPEED = 300.0

# Attack system
const ATTACK_COOLDOWN = 0.2
const ATTACK_OFFSET = 20.0
var attack_timer: float = 0.0
var attack_scene = preload("res://scenes/attack_effect.tscn")

# Torch interaction
var nearby_torch: Node = null
var torch_interact_timer: float = 0.0
const TORCH_INTERACT_COOLDOWN: float = 0.3


# Health system - Heart based (5 hearts = 10 half-hearts)
const MAX_HEARTS = 5
const HALF_HEARTS_PER_HEART = 2
var max_half_hearts: int = MAX_HEARTS * HALF_HEARTS_PER_HEART
var current_half_hearts: int = MAX_HEARTS * HALF_HEARTS_PER_HEART

signal health_changed(current_half_hearts, max_half_hearts)
signal player_died

func _ready():
	current_half_hearts = max_half_hearts
	health_changed.emit(current_half_hearts, max_half_hearts)

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
	
	# Attack (E key)
	attack_timer -= delta
	if Input.is_key_pressed(KEY_E) and attack_timer <= 0.0:
		perform_attack()
		attack_timer = ATTACK_COOLDOWN
	
	# Interact with torch (T key)
	torch_interact_timer -= delta
	if Input.is_key_pressed(KEY_T) and nearby_torch and torch_interact_timer <= 0.0:
		nearby_torch.toggle()
		torch_interact_timer = TORCH_INTERACT_COOLDOWN
		
func perform_attack():	
	var attack = attack_scene.instantiate()
	
	# direction of attack from cursor
	var dir = (get_global_mouse_position() - global_position).normalized()
	attack.direction = dir

	# Spawn attack in front of player
	attack.global_position = global_position + dir * ATTACK_OFFSET
	get_parent().add_child(attack)
