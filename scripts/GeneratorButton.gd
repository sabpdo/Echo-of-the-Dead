extends Control

@onready var button: Button = $GeneratorButton
@onready var generator_label: Label = $GeneratorButton/VBoxContainer/GeneratorLabel
@onready var player = get_node("/root/Main/Player")

var current_generator: Node = null

func _ready():
	if button:
		button.pressed.connect(_on_button_pressed)
	
	# Connect to player signal to update visibility
	if player:
		player.generator_proximity_changed.connect(_on_generator_proximity_changed)
		# Check initial state
		_update_visibility()
	
	# Start hidden
	visible = false

func _on_button_pressed():
	_try_activate_generator()

func _try_activate_generator():
	if player and player.nearby_generator and player.generator_interact_timer <= 0.0:
		player.nearby_generator.toggle()
		player.generator_interact_timer = player.GENERATOR_INTERACT_COOLDOWN

func _on_generator_proximity_changed(has_generator: bool):
	_update_visibility()

func _on_generator_toggled(on: bool):
	_update_label_text()

func _update_visibility():
	if player:
		var has_generator = player.nearby_generator != null
		visible = has_generator
		if button:
			button.visible = has_generator
		
		# Connect to generator signals when near a generator
		if has_generator and player.nearby_generator != current_generator:
			# Disconnect from previous generator if any
			if current_generator and current_generator.has_signal("generator_toggled"):
				current_generator.generator_toggled.disconnect(_on_generator_toggled)
			
			# Connect to new generator
			current_generator = player.nearby_generator
			if current_generator and current_generator.has_signal("generator_toggled"):
				current_generator.generator_toggled.connect(_on_generator_toggled)
				# Update label immediately with current state
				_update_label_text()
		elif not has_generator and current_generator:
			# Disconnect when leaving generator
			if current_generator.has_signal("generator_toggled"):
				current_generator.generator_toggled.disconnect(_on_generator_toggled)
			current_generator = null

func _update_label_text():
	if generator_label and current_generator:
		if current_generator.is_on:
			generator_label.text = "Generator On"
			if button:
				button.disabled = true
		else:
			# Show cost in label
			var counters = get_tree().get_nodes_in_group("kill_counter")
			var kills = 0
			if counters.size() > 0:
				kills = counters[0].zombies_killed
			generator_label.text = "Turn On Generator\n(" + str(current_generator.COST_KILLS) + " kills)"
			
			# Disable button if not enough kills
			if button:
				button.disabled = kills < current_generator.COST_KILLS

func _process(_delta):
	# Update button state and label text in real-time to reflect current kill count
	if current_generator and not current_generator.is_on:
		var counters = get_tree().get_nodes_in_group("kill_counter")
		var kills = 0
		if counters.size() > 0:
			kills = counters[0].zombies_killed
		if button:
			button.disabled = kills < current_generator.COST_KILLS
		# Update label text to show current kills
		if generator_label:
			generator_label.text = "Turn On Generator\n(" + str(current_generator.COST_KILLS) + " kills)"

