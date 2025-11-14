extends Control

@onready var fog_material = $FogRect.material as ShaderMaterial
@onready var player = get_node("/root/Main/Player")

var view_radius: float = 150.0
var soft_edge: float = 50.0

# Light sources for clearing fog
var light_sources: Array[Dictionary] = []
const MAX_LIGHTS = 16

# Echolocation parameters
var base_view_radius: float = 150.0
var echolocation_view_radius: float = 400.0
var echolocation_duration: float = 10.0
var echolocation_cooldown: float = 30.0
var echolocation_active: bool = false
var echolocation_on_cooldown: bool = false
var echolocation_tween: Tween = null
var cooldown_tween: Tween = null

signal echolocation_activated
signal echolocation_deactivated
signal cooldown_started
signal cooldown_finished

func _ready():
	# Set initial shader parameters
	if fog_material:
		fog_material.set_shader_parameter("view_radius", view_radius)
		fog_material.set_shader_parameter("soft_edge", soft_edge)
		_update_viewport_size()

func _update_viewport_size():
	if fog_material:
		var viewport = get_viewport()
		if viewport:
			var size = viewport.get_visible_rect().size
			fog_material.set_shader_parameter("viewport_size", size)

func _process(_delta):
	if player and fog_material:
		var viewport = get_viewport()
		if viewport:
			var viewport_size = viewport.get_visible_rect().size
			# The camera centers on the player, so player is always at screen center
			var player_screen_pos = viewport_size / 2.0
			fog_material.set_shader_parameter("player_position", player_screen_pos)
			fog_material.set_shader_parameter("viewport_size", viewport_size)
			
			# Update light sources
			_update_light_sources(viewport_size)

func _update_light_sources(viewport_size: Vector2):
	# Convert world positions to screen positions
	var light_positions: Array[Vector2] = []
	var light_radii: Array[float] = []
	var light_directions: Array[Vector2] = []
	var light_aspects: Array[float] = []
	
	# Get camera to convert world to screen coordinates
	var camera = get_viewport().get_camera_2d()
	if not camera or not player:
		return
	
	var player_world_pos = player.global_position
	
	# Clean up invalid nodes and collect valid light sources
	var valid_lights: Array[Dictionary] = []
	for light_data in light_sources:
		if not is_instance_valid(light_data.node):
			continue
		valid_lights.append(light_data)
		
		var world_pos = light_data.node.global_position
		# Convert world position to screen position
		# Since camera follows player, screen center = player position
		var offset = world_pos - player_world_pos
		var screen_pos = viewport_size / 2.0 + offset
		
		light_positions.append(screen_pos)
		light_radii.append(light_data.radius)
		
		# Get direction for oval shape (convert to screen space)
		var direction = light_data.get("direction", Vector2.ZERO)
		if direction.length() > 0.1:
			light_directions.append(direction.normalized())
		else:
			light_directions.append(Vector2(1.0, 0.0))
		
		# Get aspect ratio (how much to stretch in direction of travel)
		var aspect = light_data.get("aspect", 2.0) # Default 2:1 oval
		light_aspects.append(aspect)
	
	# Update light_sources array to remove invalid entries
	light_sources = valid_lights
	
	# Pad arrays to max size with default values
	while light_positions.size() < MAX_LIGHTS:
		light_positions.append(Vector2.ZERO)
		light_radii.append(100.0)
		light_directions.append(Vector2(1.0, 0.0))
		light_aspects.append(2.0)
	
	# Update shader
	fog_material.set_shader_parameter("light_count", min(light_sources.size(), MAX_LIGHTS))
	fog_material.set_shader_parameter("light_positions", light_positions)
	fog_material.set_shader_parameter("light_radii", light_radii)
	fog_material.set_shader_parameter("light_directions", light_directions)
	fog_material.set_shader_parameter("light_aspects", light_aspects)

func add_light_source(node: Node2D, radius: float = 100.0, direction: Vector2 = Vector2.ZERO, aspect: float = 2.0):
	# Remove if already exists
	remove_light_source(node)
	
	if light_sources.size() >= MAX_LIGHTS:
		return false
	
	light_sources.append({
		"node": node,
		"radius": radius,
		"direction": direction,
		"aspect": aspect
	})
	return true

func remove_light_source(node: Node2D):
	for i in range(light_sources.size() - 1, -1, -1):
		if light_sources[i].node == node:
			light_sources.remove_at(i)
			break

func activate_echolocation():
	if echolocation_active or echolocation_on_cooldown:
		return false
	
	echolocation_active = true
	echolocation_on_cooldown = true
	echolocation_activated.emit()
	cooldown_started.emit()
	
	# Start cooldown immediately (cooldown includes the active duration)
	var total_cooldown_time = echolocation_duration + echolocation_cooldown
	
	# Create tween for smooth transition to larger view radius
	if echolocation_tween:
		echolocation_tween.kill()
	
	echolocation_tween = create_tween()
	echolocation_tween.set_ease(Tween.EASE_IN_OUT)
	echolocation_tween.set_trans(Tween.TRANS_SINE)
	
	# Smoothly increase view radius
	echolocation_tween.tween_method(set_view_radius, view_radius, echolocation_view_radius, 0.5)
	
	# Wait for duration
	await get_tree().create_timer(echolocation_duration).timeout
	
	# Smoothly decrease view radius back to normal
	echolocation_tween = create_tween()
	echolocation_tween.set_ease(Tween.EASE_IN_OUT)
	echolocation_tween.set_trans(Tween.TRANS_SINE)
	echolocation_tween.tween_method(set_view_radius, echolocation_view_radius, base_view_radius, 0.5)
	
	echolocation_active = false
	echolocation_deactivated.emit()
	
	# Continue cooldown (already started, just wait for remaining time)
	await get_tree().create_timer(echolocation_cooldown).timeout
	
	echolocation_on_cooldown = false
	cooldown_finished.emit()
	
	return true

func set_view_radius(radius: float):
	view_radius = radius
	if fog_material:
		fog_material.set_shader_parameter("view_radius", view_radius)

func start_cooldown():
	# This function is no longer used - cooldown is handled in activate_echolocation
	pass

func is_echolocation_available() -> bool:
	return not echolocation_active and not echolocation_on_cooldown
