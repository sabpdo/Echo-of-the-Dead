extends Node2D

# Map boundaries (matching Main scene background)
const MAP_LEFT = -1085.0
const MAP_RIGHT = 1157.0
const MAP_TOP = -640.0
const MAP_BOTTOM = 640.0
const MAP_WIDTH = MAP_RIGHT - MAP_LEFT
const MAP_HEIGHT = MAP_BOTTOM - MAP_TOP

# Wall properties
const WALL_SIZE = 50.0
const WALL_SCENE = preload("res://scenes/Wall.tscn")

# Random wall generation settings
@export var random_wall_count: int = 30
@export var min_wall_spacing: float = 100.0  # Minimum distance between walls

func _ready():
	spawn_boundary_walls()
	spawn_random_walls()

func spawn_boundary_walls():
	# Spawn walls along the four edges of the map
	var wall_positions = []
	
	# Top edge
	var top_y = MAP_TOP
	for x in range(int(MAP_LEFT), int(MAP_RIGHT), int(WALL_SIZE)):
		wall_positions.append(Vector2(x, top_y))
	
	# Bottom edge
	var bottom_y = MAP_BOTTOM - WALL_SIZE
	for x in range(int(MAP_LEFT), int(MAP_RIGHT), int(WALL_SIZE)):
		wall_positions.append(Vector2(x, bottom_y))
	
	# Left edge (skip corners already placed)
	var left_x = MAP_LEFT
	for y in range(int(MAP_TOP) + int(WALL_SIZE), int(MAP_BOTTOM) - int(WALL_SIZE), int(WALL_SIZE)):
		wall_positions.append(Vector2(left_x, y))
	
	# Right edge (skip corners already placed)
	var right_x = MAP_RIGHT - WALL_SIZE
	for y in range(int(MAP_TOP) + int(WALL_SIZE), int(MAP_BOTTOM) - int(WALL_SIZE), int(WALL_SIZE)):
		wall_positions.append(Vector2(right_x, y))
	
	# Spawn all boundary walls
	for pos in wall_positions:
		spawn_wall(pos)

func spawn_random_walls():
	# Spawn random walls inside the map (with some margin from boundaries)
	var margin = WALL_SIZE * 2
	var spawn_area_left = MAP_LEFT + margin
	var spawn_area_right = MAP_RIGHT - margin - WALL_SIZE
	var spawn_area_top = MAP_TOP + margin
	var spawn_area_bottom = MAP_BOTTOM - margin - WALL_SIZE
	
	var spawned_positions = []
	var attempts = 0
	var max_attempts = random_wall_count * 10
	
	while spawned_positions.size() < random_wall_count and attempts < max_attempts:
		attempts += 1
		
		# Generate random position
		var x = randf_range(spawn_area_left, spawn_area_right)
		var y = randf_range(spawn_area_top, spawn_area_bottom)
		
		# Snap to grid for cleaner placement
		x = floor(x / WALL_SIZE) * WALL_SIZE
		y = floor(y / WALL_SIZE) * WALL_SIZE
		var pos = Vector2(x, y)
		
		# Check if position is too close to other walls
		var too_close = false
		for existing_pos in spawned_positions:
			if pos.distance_to(existing_pos) < min_wall_spacing:
				too_close = true
				break
		
		if not too_close:
			spawned_positions.append(pos)
			spawn_wall(pos)

func spawn_wall(position: Vector2):
	var wall = WALL_SCENE.instantiate()
	wall.position = position
	add_child(wall)
