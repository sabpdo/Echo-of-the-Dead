extends Control

@onready var button: Button = $DoorButton
@onready var door_label: Label = $DoorButton/VBoxContainer/DoorLabel
@onready var player = get_node("/root/Main/Player")

var current_door: Node = null

func _ready():
	if button:
		button.pressed.connect(_on_button_pressed)
	
	# Connect to player signal to update visibility
	if player:
		player.door_proximity_changed.connect(_on_door_proximity_changed)
		# Check initial state
		_update_visibility()
	
	# Start hidden
	visible = false

func _on_button_pressed():
	_try_unlock_door()

func _try_unlock_door():
	if player and player.nearby_door and player.door_interact_timer <= 0.0:
		player.nearby_door.unlock()
		player.door_interact_timer = player.DOOR_INTERACT_COOLDOWN

func _on_door_proximity_changed(has_door: bool):
	_update_visibility()

func _on_door_unlocked():
	_update_visibility()
	_update_label_text()

func _update_visibility():
	if player:
		var has_door = player.nearby_door != null
		visible = has_door and not (player.nearby_door.is_unlocked if player.nearby_door else false)
		if button:
			button.visible = has_door and not (player.nearby_door.is_unlocked if player.nearby_door else false)
		
		# Always update current_door to match player.nearby_door
		# Connect to door signals when near a door
		if has_door:
			# Disconnect from previous door if it's different
			if current_door and current_door != player.nearby_door:
				if current_door.has_signal("door_unlocked"):
					current_door.door_unlocked.disconnect(_on_door_unlocked)
			
			# Connect to new door if it's different
			if player.nearby_door != current_door:
				current_door = player.nearby_door
				if current_door and current_door.has_signal("door_unlocked"):
					# Make sure we're not already connected
					if current_door.door_unlocked.is_connected(_on_door_unlocked):
						current_door.door_unlocked.disconnect(_on_door_unlocked)
					current_door.door_unlocked.connect(_on_door_unlocked)
				# Update label immediately with current state
				_update_label_text()
		elif not has_door and current_door:
			# Disconnect when leaving door
			if current_door.has_signal("door_unlocked"):
				if current_door.door_unlocked.is_connected(_on_door_unlocked):
					current_door.door_unlocked.disconnect(_on_door_unlocked)
			current_door = null

func _update_label_text():
	if current_door and not current_door.is_unlocked:
		# Show cost in label
		var points_counters = get_tree().get_nodes_in_group("points_counter")
		var points = 0
		if points_counters.size() > 0:
			points = points_counters[0].points
		door_label.text = "Unlock Door\n(" + str(current_door.COST_POINTS) + " points)"
		
		# Disable button if not enough points
		if button:
			button.disabled = points < current_door.COST_POINTS

func _process(_delta):
	# Update button state and label text in real-time to reflect current points
	if current_door and not current_door.is_unlocked:
		var points_counters = get_tree().get_nodes_in_group("points_counter")
		var points = 0
		if points_counters.size() > 0:
			points = points_counters[0].points
		if button:
			button.disabled = points < current_door.COST_POINTS
		# Update label text to show current points
		if door_label:
			door_label.text = "Unlock Door\n(" + str(current_door.COST_POINTS) + " points)"
