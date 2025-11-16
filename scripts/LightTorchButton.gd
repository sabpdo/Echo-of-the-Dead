extends Control

@onready var button: Button = $LightTorchButton
@onready var torch_label: Label = $LightTorchButton/VBoxContainer/TorchLabel
@onready var player = get_node("/root/Main/Player")

var current_torch: Node = null

func _ready():
	if button:
		button.pressed.connect(_on_button_pressed)
	
	# Connect to player signal to update visibility
	if player:
		player.torch_proximity_changed.connect(_on_torch_proximity_changed)
		# Check initial state
		_update_visibility()
	
	# Start hidden
	visible = false

func _on_button_pressed():
	_try_activate_torch()

func _try_activate_torch():
	if player and player.nearby_torch and player.torch_interact_timer <= 0.0:
		player.nearby_torch.toggle()
		player.torch_interact_timer = player.TORCH_INTERACT_COOLDOWN

func _on_torch_proximity_changed(has_torch: bool):
	_update_visibility()

func _on_torch_toggled(lit: bool):
	_update_label_text()

func _update_visibility():
	if player:
		var has_torch = player.nearby_torch != null
		visible = has_torch
		if button:
			button.visible = has_torch
		
		# Always update current_torch to match player.nearby_torch
		# Connect to torch signals when near a torch
		if has_torch:
			# Disconnect from previous torch if it's different
			if current_torch and current_torch != player.nearby_torch:
				if current_torch.has_signal("torch_toggled"):
					current_torch.torch_toggled.disconnect(_on_torch_toggled)
			
			# Connect to new torch if it's different
			if player.nearby_torch != current_torch:
				current_torch = player.nearby_torch
				if current_torch and current_torch.has_signal("torch_toggled"):
					# Make sure we're not already connected
					if current_torch.torch_toggled.is_connected(_on_torch_toggled):
						current_torch.torch_toggled.disconnect(_on_torch_toggled)
					current_torch.torch_toggled.connect(_on_torch_toggled)
				# Update label immediately with current state
				_update_label_text()
		elif not has_torch and current_torch:
			# Disconnect when leaving torch
			if current_torch.has_signal("torch_toggled"):
				if current_torch.torch_toggled.is_connected(_on_torch_toggled):
					current_torch.torch_toggled.disconnect(_on_torch_toggled)
			current_torch = null

func _update_label_text():
	if torch_label and current_torch:
		if current_torch.is_lit:
			torch_label.text = "Unlight Torch"
		else:
			torch_label.text = "Light Torch"

