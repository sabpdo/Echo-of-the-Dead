extends StaticBody2D

@onready var interaction_area = $InteractionArea
@onready var closed_sprite = $ClosedDoorSprite
@onready var open_sprite = $OpenDoorSprite
@onready var interaction_button = $InteractionButton

var is_unlocked: bool = false
var player_nearby: bool = false
const INTERACTION_RADIUS: float = 80.0
const COST_POINTS: int = 500
var world_ui_container: Control = null
var fog_controller: Node = null
const BUTTON_GLOW_RADIUS: float = 80.0
var button_glow_active: bool = false

signal door_unlocked

func _ready():
	# Start locked
	set_unlocked(false)
	
	# Get fog controller for glow effect
	fog_controller = get_node_or_null("/root/Main/FogLayer/FogController")
	
	# Get the WorldUIContainer to reparent button
	world_ui_container = get_node_or_null("/root/Main/WorldUILayer/WorldUIContainer")
	if world_ui_container and interaction_button:
		# Reparent button to WorldUILayer so it renders above fog
		var button_parent = interaction_button.get_parent()
		button_parent.remove_child(interaction_button)
		world_ui_container.add_child(interaction_button)
		# Set high z_index to ensure it renders on top
		interaction_button.z_index = 100
	
	# Connect interaction signal
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
	
	# Setup button
	if interaction_button:
		interaction_button.visible = false
		interaction_button.pressed.connect(_on_button_pressed)
		_update_button_text()

func _process(_delta):
	# Update button position to match world position
	if interaction_button and world_ui_container:
		var viewport = get_viewport()
		if viewport:
			var camera = viewport.get_camera_2d()
			var player = get_node_or_null("/root/Main/Player")
			if camera and player:
				# Convert world position to screen position
				# Camera follows player, so player is always at screen center
				var viewport_size = viewport.get_visible_rect().size
				var player_world_pos = player.global_position
				var camera_zoom = camera.zoom.x
				var offset = (global_position - player_world_pos) * camera_zoom
				var screen_center = viewport_size / 2.0
				var screen_pos = screen_center + offset
				interaction_button.position = screen_pos + Vector2(-50, -80)
	
	# Update button visibility and fog glow
	var should_show = player_nearby and not is_unlocked
	if interaction_button:
		# Only show button when player is nearby and door is locked
		interaction_button.visible = should_show
	
	# Add/remove fog glow effect based on button visibility
	if fog_controller and fog_controller.has_method("add_light_source") and fog_controller.has_method("remove_light_source"):
		if should_show and not button_glow_active:
			# Add glow effect when button becomes visible
			fog_controller.add_light_source(self, BUTTON_GLOW_RADIUS, Vector2.ZERO, 1.0)
			button_glow_active = true
		elif not should_show and button_glow_active:
			# Remove glow effect when button becomes hidden
			fog_controller.remove_light_source(self)
			button_glow_active = false

func _on_body_entered(body):
	if body.is_in_group("player") or body.name == "Player":
		body.nearby_door = self
		player_nearby = true

func _on_body_exited(body):
	if body.is_in_group("player") or body.name == "Player":
		if body.nearby_door == self:
			body.nearby_door = null
		player_nearby = false

func set_unlocked(unlocked: bool):
	is_unlocked = unlocked
	
	# Disable collision when unlocked
	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = unlocked
	
	# Change visual appearance when unlocked
	if closed_sprite and open_sprite:
		closed_sprite.visible = not unlocked
		open_sprite.visible = unlocked
	
	_update_button_text()
	door_unlocked.emit()

func unlock():
	# Don't allow unlocking if already unlocked
	if is_unlocked:
		return
	
	# Check if player has enough points
	var points_counters = get_tree().get_nodes_in_group("points_counter")
	if points_counters.size() > 0:
		var points_counter = points_counters[0]
		if points_counter.points >= COST_POINTS:
			# Deduct points (using negative amount to subtract)
			points_counter.add_points(-COST_POINTS)
			
			# Unlock door
			set_unlocked(true)
		else:
			# Not enough points - could show a message here
			print("Not enough points! Need ", COST_POINTS, " points.")

func _on_button_pressed():
	unlock()

func _update_button_text():
	if interaction_button:
		var label = interaction_button.get_node_or_null("Label")
		if label:
			if is_unlocked:
				label.text = "Open"
			else:
				label.text = "Unlock ($" + str(COST_POINTS) + ")"
