extends Node2D

@onready var player = get_node("/root/Main/Player")
@onready var fog_controller = get_node("/root/Main/FogLayer/FogController")
@onready var unexplored_controller = get_node("/root/Main/FogLayer/UnexploredController")

# Radar parameters
var radar_cooldown: float = 10.0
var radar_pulse_duration: float = 2.0  # Time for pulse to expand and contract
var radar_detection_duration: float = 5.0  # How long zombies stay visible
var radar_max_radius: float = 500.0

var radar_active: bool = false
var radar_on_cooldown: bool = false
var detected_zombies: Array[Dictionary] = []

# Visual components
var radar_tween: Tween = null

signal radar_activated
signal radar_deactivated
signal cooldown_started
signal cooldown_finished
signal zombie_detected(zombie: Node2D)

func _ready():
	# Create visual radar circle
	_create_radar_visual()

func _create_radar_visual():
	# We'll draw the radar circle directly on this node
	visible = false

func _draw():
	if radar_active:
		# Draw expanding green circle
		var current_radius = get_meta("current_radius", 0.0)
		if current_radius > 0:
			# Draw semi-transparent green circle outline
			draw_arc(Vector2.ZERO, current_radius, 0, TAU, 64, Color.GREEN, 3.0)
			# Draw fading fill
			var alpha = 0.1 * (1.0 - current_radius / radar_max_radius)
			draw_circle(Vector2.ZERO, current_radius, Color(0, 1, 0, alpha))

func activate_radar():
	if radar_active or radar_on_cooldown:
		return false
	
	radar_active = true
	radar_on_cooldown = true
	radar_activated.emit()
	cooldown_started.emit()
	
	# Position radar at player location (world coordinates)
	if player:
		global_position = player.global_position
	
	# Start radar pulse animation
	_start_radar_pulse()
	
	# Wait for pulse duration, then start cooldown
	await get_tree().create_timer(radar_pulse_duration).timeout
	
	radar_active = false
	radar_deactivated.emit()
	
	# Start detection phase - zombies remain visible for detection duration
	await get_tree().create_timer(radar_detection_duration).timeout
	
	# Clear detected zombies
	_clear_detected_zombies()
	
	# Continue cooldown
	var remaining_cooldown = radar_cooldown - radar_pulse_duration - radar_detection_duration
	if remaining_cooldown > 0:
		await get_tree().create_timer(remaining_cooldown).timeout
	
	radar_on_cooldown = false
	cooldown_finished.emit()
	
	return true

func _start_radar_pulse():
	visible = true
	set_meta("current_radius", 0.0)
	
	# Create tween for radar expansion and contraction
	if radar_tween:
		radar_tween.kill()
	
	radar_tween = create_tween()
	radar_tween.set_loops(1)
	
	# Expand out to max radius, then contract back
	radar_tween.tween_method(_update_radar_radius, 0.0, radar_max_radius, radar_pulse_duration * 0.6)
	radar_tween.tween_method(_update_radar_radius, radar_max_radius, 0.0, radar_pulse_duration * 0.4)
	
	# Hide radar circle when done
	radar_tween.tween_callback(func(): visible = false)

func _update_radar_radius(radius: float):
	set_meta("current_radius", radius)
	queue_redraw()
	
	# Reveal unexplored area around player as pulse expands
	if player and unexplored_controller:
		# Reveal area around player with the current pulse radius
		# Use a reasonable reveal radius (e.g., 60 pixels around each point)
		var reveal_radius = 60.0
		unexplored_controller._reveal_area(player.global_position, reveal_radius)
	
	# Check for zombie detection when pulse passes through
	_check_zombie_detection(radius)

func _check_zombie_detection(current_radius: float):
	if not player:
		return
	
	# Get all zombies in the scene
	var zombies = get_tree().get_nodes_in_group("zombies")
	if zombies.is_empty():
		# Try alternative method - look for Zombie nodes
		zombies = []
		_find_zombies_recursive(get_tree().root, zombies)
	
	for zombie in zombies:
		if not is_instance_valid(zombie):
			continue
		
		var distance_to_zombie = player.global_position.distance_to(zombie.global_position)
		
		# Check if pulse is currently passing through zombie (within a tolerance)
		# Use a larger tolerance to ensure zombies are detected
		var tolerance = 30.0
		if distance_to_zombie <= current_radius + tolerance and distance_to_zombie >= current_radius - tolerance:
			# Check if zombie is not already detected
			var already_detected = false
			for detected in detected_zombies:
				if detected.zombie == zombie:
					already_detected = true
					break
			
			if not already_detected:
				_detect_zombie(zombie)

func _find_zombies_recursive(node: Node, zombie_list: Array):
	# Recursively find all zombie nodes
	if node.name.begins_with("Zombie") and node.has_method("take_damage"):
		zombie_list.append(node)
	
	for child in node.get_children():
		_find_zombies_recursive(child, zombie_list)

func _detect_zombie(zombie: Node2D):
	# Add zombie to detected list
	var detection_data = {
		"zombie": zombie,
		"detection_time": Time.get_ticks_msec() / 1000.0
	}
	detected_zombies.append(detection_data)
	
	# Play sound effect (placeholder - to be added later)
	# TODO: Add sound effect here
	
	# Make zombie visible through fog by adding it as a light source
	if fog_controller and fog_controller.has_method("add_light_source"):
		fog_controller.add_light_source(zombie, 60.0, Vector2.ZERO, 1.0)  # 60 pixel radius around zombie (circular)
	
	# Emit detection signal
	zombie_detected.emit(zombie)
	
	# Schedule removal after detection duration
	get_tree().create_timer(radar_detection_duration).timeout.connect(func(): _remove_zombie_detection(zombie))

func _remove_zombie_detection(zombie: Node2D):
	# Remove from detected list
	for i in range(detected_zombies.size() - 1, -1, -1):
		if detected_zombies[i].zombie == zombie:
			detected_zombies.remove_at(i)
			break
	
	# Remove from fog light sources
	if fog_controller and fog_controller.has_method("remove_light_source"):
		fog_controller.remove_light_source(zombie)

func _clear_detected_zombies():
	# Clear all detected zombies from fog
	for detection_data in detected_zombies:
		if is_instance_valid(detection_data.zombie) and fog_controller:
			fog_controller.remove_light_source(detection_data.zombie)
	
	detected_zombies.clear()

func is_radar_available() -> bool:
	return not radar_active and not radar_on_cooldown

func _process(_delta):
	# Clean up invalid zombie references
	detected_zombies = detected_zombies.filter(func(data): return is_instance_valid(data.zombie))
	
	# Continuously reveal unexplored areas around detected zombies while spell is active
	if unexplored_controller:
		var reveal_radius = 60.0  # Same radius as the fog clearing
		for detection_data in detected_zombies:
			if is_instance_valid(detection_data.zombie):
				unexplored_controller._reveal_area(detection_data.zombie.global_position, reveal_radius)
