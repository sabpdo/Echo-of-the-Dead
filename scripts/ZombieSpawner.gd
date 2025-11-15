extends Node2D

# Map boundaries (matching WallGenerator)
const MAP_LEFT = -1085.0
const MAP_RIGHT = 1157.0
const MAP_TOP = -640.0
const MAP_BOTTOM = 640.0

# Spawn settings
@export var spawn_point_count: int = 10  # Number of spawn points to generate
@export var min_distance_from_player: float = 300.0  # Minimum distance from player to spawn

var zombie_scene = preload("res://scenes/Zombie.tscn")
var spawn_points: Array[Vector2] = []
var player: Node2D = null
var spawn_timer: float = 0.0
var active_zombies: Array[Node2D] = []

func _ready():
	# Find the player
	player = get_node("/root/Main/Player")
	
	# Generate random spawn points
	_generate_spawn_points()
	
	# Start spawning immediately based on difficulty
	spawn_timer = GameSettings.get_zombie_spawn_interval()

func _generate_spawn_points():
	spawn_points.clear()
	
	# Margin from edges to avoid spawning too close to boundaries
	var margin = 100.0
	var spawn_area_left = MAP_LEFT + margin
	var spawn_area_right = MAP_RIGHT - margin
	var spawn_area_top = MAP_TOP + margin
	var spawn_area_bottom = MAP_BOTTOM - margin
	
	# Generate random spawn points
	for i in range(spawn_point_count):
		var attempts = 0
		var max_attempts = 50
		var valid_position = false
		var spawn_pos: Vector2
		
		while not valid_position and attempts < max_attempts:
			attempts += 1
			
			# Generate random position
			spawn_pos = Vector2(
				randf_range(spawn_area_left, spawn_area_right),
				randf_range(spawn_area_top, spawn_area_bottom)
			)
			
			# Check if position is far enough from player
			if player:
				var distance_to_player = spawn_pos.distance_to(player.global_position)
				if distance_to_player >= min_distance_from_player:
					# Check if position is not too close to other spawn points
					var too_close = false
					for existing_pos in spawn_points:
						if spawn_pos.distance_to(existing_pos) < 200.0:
							too_close = true
							break
					
					if not too_close:
						valid_position = true
			else:
				valid_position = true
		
		if valid_position:
			spawn_points.append(spawn_pos)

func _process(delta):
	if spawn_points.is_empty():
		return
	
	spawn_timer -= delta
	
	# Get difficulty-based settings
	var max_zombies = GameSettings.get_max_zombies()
	var spawn_interval = GameSettings.get_zombie_spawn_interval()
	
	# Spawn zombie if timer is up and we haven't reached max zombies
	if spawn_timer <= 0.0 and active_zombies.size() < max_zombies:
		_spawn_zombie()
		spawn_timer = spawn_interval
	
	# Clean up dead zombies from the array
	active_zombies = active_zombies.filter(func(zombie): return is_instance_valid(zombie))

func _spawn_zombie():
	if spawn_points.is_empty():
		return
	
	# Select a random spawn point
	var spawn_index = randi() % spawn_points.size()
	var spawn_pos = spawn_points[spawn_index]
	
	# Check if spawn point is still far enough from player
	if player:
		var distance_to_player = spawn_pos.distance_to(player.global_position)
		if distance_to_player < min_distance_from_player:
			# Try to find a better spawn point
			var best_spawn = spawn_pos
			var best_distance = distance_to_player
			
			for point in spawn_points:
				var dist = point.distance_to(player.global_position)
				if dist > best_distance and dist >= min_distance_from_player:
					best_spawn = point
					best_distance = dist
			
			spawn_pos = best_spawn
	
	# Instantiate zombie
	var zombie = zombie_scene.instantiate()
	zombie.global_position = spawn_pos
	
	# Apply difficulty modifiers
	zombie.speed_multiplier = GameSettings.get_zombie_speed_multiplier()
	zombie.health_multiplier = GameSettings.get_zombie_health_multiplier()
	
	get_parent().add_child(zombie)
	
	# Track the zombie
	active_zombies.append(zombie)
	
	# Connect to zombie death signal to remove from tracking
	if zombie.has_signal("zombie_died"):
		zombie.zombie_died.connect(func(): _on_zombie_died(zombie))

func _on_zombie_died(zombie: Node2D):
	# Remove from active zombies list
	var index = active_zombies.find(zombie)
	if index >= 0:
		active_zombies.remove_at(index)
