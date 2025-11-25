extends Control

@onready var hearts_container: HBoxContainer = $HeartsContainer

var player: Node2D = null
var heart_textures: Array[TextureRect] = []

# Preload heart textures
var empty_heart_texture: Texture2D = preload("res://assets/hearts/empty.png")
var half_heart_texture: Texture2D = preload("res://assets/hearts/half.png")
var full_heart_texture: Texture2D = preload("res://assets/hearts/full.png")

func _ready():
	# Find the player node
	player = get_node("/root/Main/Player")
	
	if player:
		# Connect to player health signals
		player.health_changed.connect(_on_health_changed)
		# Initialize hearts
		_create_hearts()
		# Initialize health display
		_on_health_changed(player.current_half_hearts, player.max_half_hearts)

func _create_hearts():
	if not hearts_container:
		return
	
	# Clear existing hearts
	for child in hearts_container.get_children():
		child.queue_free()
	heart_textures.clear()
	
	# Create heart displays using PNG images
	for i in range(player.MAX_HEARTS):
		var heart_texture_rect = TextureRect.new()
		heart_texture_rect.texture = empty_heart_texture
		heart_texture_rect.custom_minimum_size = Vector2(32, 32)
		heart_texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		heart_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		hearts_container.add_child(heart_texture_rect)
		heart_textures.append(heart_texture_rect)

func _on_health_changed(current_half_hearts: int, max_half_hearts: int):
	if heart_textures.is_empty():
		_create_hearts()
	
	# Update each heart based on half-hearts
	for i in range(heart_textures.size()):
		var heart_start_half = i * 2  # Each heart is 2 half-hearts
		var heart_end_half = heart_start_half + 2
		
		if current_half_hearts >= heart_end_half:
			# Full heart - show full heart texture
			heart_textures[i].texture = full_heart_texture
		elif current_half_hearts > heart_start_half:
			# Half heart - show half heart texture
			heart_textures[i].texture = half_heart_texture
		else:
			# Empty heart - show empty heart texture
			heart_textures[i].texture = empty_heart_texture
