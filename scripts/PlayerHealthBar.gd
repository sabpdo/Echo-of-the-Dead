extends Control

@onready var hearts_container: HBoxContainer = $HeartsContainer

var player: Node2D = null
var heart_containers: Array[Control] = []

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
	heart_containers.clear()
	
	# Create 5 heart containers, each with left and right halves
	for i in range(player.MAX_HEARTS):
		var heart_container = Control.new()
		heart_container.custom_minimum_size = Vector2(50, 50)
		heart_container.clip_contents = true
		
		# Empty heart outline (background)
		var empty_heart = Label.new()
		empty_heart.text = "♡"
		empty_heart.add_theme_font_size_override("font_size", 50)
		empty_heart.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_heart.modulate = Color(0.5, 0.5, 0.5, 0.5)  # Gray outline
		empty_heart.position = Vector2(0, 0)
		heart_container.add_child(empty_heart)
		
		# Left half (filled - red) - clipped to show only left side
		var left_half_container = Control.new()
		left_half_container.position = Vector2(0, 0)
		left_half_container.size = Vector2(25, 50)  # Half width
		left_half_container.clip_contents = true
		left_half_container.name = "LeftHalfContainer"
		
		var left_half = Label.new()
		left_half.text = "♥"
		left_half.add_theme_font_size_override("font_size", 50)
		left_half.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		left_half.modulate = Color(1, 0, 0, 1)  # Red
		left_half.position = Vector2(0, 0)
		left_half_container.add_child(left_half)
		heart_container.add_child(left_half_container)
		
		# Right half (filled - red) - clipped to show only right side
		var right_half_container = Control.new()
		right_half_container.position = Vector2(25, 0)  # Start from middle
		right_half_container.size = Vector2(25, 50)  # Half width
		right_half_container.clip_contents = true
		right_half_container.name = "RightHalfContainer"
		
		var right_half = Label.new()
		right_half.text = "♥"
		right_half.add_theme_font_size_override("font_size", 50)
		right_half.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		right_half.modulate = Color(1, 0, 0, 1)  # Red
		right_half.position = Vector2(-25, 0)  # Shift left to show right half
		right_half_container.add_child(right_half)
		heart_container.add_child(right_half_container)
		
		hearts_container.add_child(heart_container)
		heart_containers.append(heart_container)

func _on_health_changed(current_half_hearts: int, max_half_hearts: int):
	if heart_containers.is_empty():
		_create_hearts()
	
	# Update each heart based on half-hearts
	for i in range(heart_containers.size()):
		var heart_container = heart_containers[i]
		var heart_index = i
		var heart_start_half = heart_index * 2  # Each heart is 2 half-hearts
		var heart_end_half = heart_start_half + 2
		
		var left_half_container = heart_container.get_node("LeftHalfContainer")
		var right_half_container = heart_container.get_node("RightHalfContainer")
		
		if current_half_hearts >= heart_end_half:
			# Full heart - show both halves
			left_half_container.visible = true
			right_half_container.visible = true
		elif current_half_hearts > heart_start_half:
			# Half heart - show only left half (first half)
			left_half_container.visible = true
			right_half_container.visible = false
		else:
			# Empty heart - hide both halves (only show gray outline)
			left_half_container.visible = false
			right_half_container.visible = false
