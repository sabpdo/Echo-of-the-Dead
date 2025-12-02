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
const DOOR_SCENE = preload("res://scenes/Door.tscn")
const GATE_SCENE = preload("res://scenes/Gate.tscn")
const TORCH_SCENE = preload("res://scenes/Torch.tscn")
const GENERATOR_SCENE = preload("res://scenes/Generator.tscn")
const TERRAIN_TILE_SCENE = preload("res://scenes/TerrainTile.tscn")

# Hardcoded map layout
# Edit this array to design your map!
# Legend:
#   'W' = Wall
#   'D' = Door
#   'G' = Gate
#   'T' = Torch
#   'P' = Generator
#   'Z' = Zombie spawn point
#   'S' = Player spawn point
#   '.' = Empty space
#   'B' = Boundary wall (automatically placed, but you can mark them here too)
#   'H' = Wooden planks (walkable speed boost)
#   'L' = Leaves (walkable, no change)
#   'C' = Cobblestone (walkable speed boost)
#   'M' = Dirt/Mud (walkable, slows zombies)
#   'R' = Grass (walkable, slows player)
#   'U' = Puddles (walkable, slows zombies)
#   'Y' = Hay bale (furniture wall)
#   'A' = Barrel (furniture wall)
#   'V' = Graves (furniture wall)
#   'O' = Bones (furniture wall)
#   'N' = Bushes (furniture wall)
#   'E' = Rubble (furniture wall)
#   'F' = Fallen soldier (furniture wall)
var map_layout = [
	"................................................",
	"............Z..........Z..........Z.............",
	"............Z..........Z..........Z.............",
	"................................................",
	".......WWWWGGGWWWWWWWWGGGWWWWWWWWGGGWWWWW.......",
	".......W..........W..........W..........W.......",
	".......W..........W..........W..........W.......",
	".......W..........W..........W..........W.......",
	".......W....S.....D..........D....P.....W.......",
	".......W..........W.......T..W..........W.......",
	".......W.....T....W..........W..........W.......",
	".......W..........W..........W......T...W.......",
	".......WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW.......",
	"................................................",
	"................................................",
	"................................................",
	"................................................",
	"................................................",
	"................................................",
	"................................................"
]




# Grid settings
var grid_width: int = 0
var grid_height: int = 0
var cell_size: float = WALL_SIZE

const TERRAIN_CHAR_MAP := {
	'H': "wooden_planks",
	'L': "leaves",
	'C': "cobblestone",
	'M': "dirt_mud",
	'R': "grass",
	'U': "puddle"
}

const FURNITURE_CHAR_MAP := {
	'Y': "hay_bale",
	'A': "barrel",
	'V': "graves",
	'O': "bones",
	'N': "bushes",
	'E': "rubble",
	'F': "fallen_soldier"
}

# Spawn point storage
var zombie_spawn_points: Array[Vector2] = []
var player_spawn_point: Vector2 = Vector2.ZERO
var has_player_spawn: bool = false

func _ready():
	# Calculate grid dimensions
	if map_layout.size() > 0:
		grid_height = map_layout.size()
		grid_width = map_layout[0].length()
	
	spawn_boundary_walls()
	spawn_map_objects()

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

func spawn_map_objects():
	# Spawn objects based on the hardcoded map layout
	if map_layout.size() == 0:
		return
	
	# Calculate the center of the map
	var map_center_x = (MAP_LEFT + MAP_RIGHT) / 2.0
	var map_center_y = (MAP_TOP + MAP_BOTTOM) / 2.0
	
	# Calculate grid cell size to fit the map
	var available_width = MAP_WIDTH
	var available_height = MAP_HEIGHT
	var cell_width = available_width / grid_width
	var cell_height = available_height / grid_height
	cell_size = min(cell_width, cell_height)
	
	# Calculate starting position (top-left of grid)
	var grid_start_x = map_center_x - (grid_width * cell_size) / 2.0
	var grid_start_y = map_center_y - (grid_height * cell_size) / 2.0
	
	# Iterate through the map layout
	for row in range(grid_height):
		if row >= map_layout.size():
			continue
		
		var row_string = map_layout[row]
		for col in range(min(row_string.length(), grid_width)):
			var cell_char = row_string[col]
			
			# Calculate world position for this cell
			var world_x = grid_start_x + col * cell_size + cell_size / 2.0
			var world_y = grid_start_y + row * cell_size + cell_size / 2.0
			var world_pos = Vector2(world_x, world_y)
			
			# Spawn object based on character
			match cell_char:
				'W':
					spawn_wall(world_pos)
				'D':
					spawn_door(world_pos)
				'G':
					spawn_gate(world_pos)
				'T':
					spawn_torch(world_pos)
				'P':
					spawn_generator_at(world_pos)
				'Z':
					# Store zombie spawn point
					zombie_spawn_points.append(world_pos)
				'S':
					# Store player spawn point
					player_spawn_point = world_pos
					has_player_spawn = true
					set_player_spawn(world_pos)
				'B':
					# Boundary walls are handled separately, but you can mark them here too
					pass
				'.':
					# Empty space, do nothing
					pass
				_:
					if FURNITURE_CHAR_MAP.has(cell_char):
						spawn_furniture_wall(world_pos, FURNITURE_CHAR_MAP[cell_char])
					elif TERRAIN_CHAR_MAP.has(cell_char):
						spawn_terrain_tile(world_pos, TERRAIN_CHAR_MAP[cell_char])
	
	# Pass zombie spawn points to ZombieSpawner if it exists
	pass_zombie_spawn_points_to_spawner()

func spawn_wall(position: Vector2):
	var wall = WALL_SCENE.instantiate()
	wall.global_position = position
	# Set wall to collision layers 1 and 2 (blocks both players and zombies)
	# Layer 1 = 1, Layer 2 = 2, so 1 + 2 = 3
	wall.collision_layer = 3  # Binary: 11 = layer 1 (player) + layer 2 (zombie)
	add_child(wall)

func spawn_furniture_wall(position: Vector2, furniture_type: String):
	# Spawns a furniture wall that functions exactly like a wall but is distinguishable in code
	var wall = WALL_SCENE.instantiate()
	wall.global_position = position
	# Set wall to collision layers 1 and 2 (blocks both players and zombies)
	# Layer 1 = 1, Layer 2 = 2, so 1 + 2 = 3
	wall.collision_layer = 3  # Binary: 11 = layer 1 (player) + layer 2 (zombie)
	# Set name and metadata to distinguish this furniture type in code
	# Format name: convert "hay_bale" to "HayBale" for readability
	var name_parts = furniture_type.split("_")
	var formatted_name = ""
	for part in name_parts:
		if part.length() > 0:
			formatted_name += part[0].to_upper() + part.substr(1)
	wall.name = formatted_name
	wall.set_meta("furniture_type", furniture_type)
	# Add to furniture group for easy identification
	wall.add_to_group("furniture")
	add_child(wall)

func spawn_door(position: Vector2):
	var door = DOOR_SCENE.instantiate()
	door.global_position = position
	# Set door to collision layers 1 and 2 (blocks both players and zombies when locked)
	door.collision_layer = 3  # Binary: 11 = layer 1 (player) + layer 2 (zombie)
	add_child(door)

func spawn_gate(position: Vector2):
	var gate = GATE_SCENE.instantiate()
	gate.global_position = position
	add_child(gate)

func spawn_torch(position: Vector2):
	var torch = TORCH_SCENE.instantiate()
	torch.global_position = position
	add_child(torch)

func spawn_generator_at(position: Vector2):
	var generator = GENERATOR_SCENE.instantiate()
	generator.global_position = position
	add_child(generator)

func spawn_terrain_tile(position: Vector2, terrain_type: String):
	var tile = TERRAIN_TILE_SCENE.instantiate()
	tile.global_position = position
	if tile.has_method("configure"):
		tile.configure(cell_size, terrain_type)
	add_child(tile)

func set_player_spawn(position: Vector2):
	# Set the player's position if player exists
	var player = get_node_or_null("/root/Main/Player")
	if player:
		player.global_position = position
		print("Player spawn set to: ", position)
	else:
		# If player doesn't exist yet, try again next frame
		await get_tree().process_frame
		player = get_node_or_null("/root/Main/Player")
		if player:
			player.global_position = position
			print("Player spawn set to: ", position)
		else:
			pass

func pass_zombie_spawn_points_to_spawner():
	# Pass zombie spawn points to ZombieSpawner if it exists
	# Wait a frame to ensure ZombieSpawner is ready
	await get_tree().process_frame
	var zombie_spawner = get_node_or_null("/root/Main/ZombieSpawner")
	if zombie_spawner and zombie_spawn_points.size() > 0:
		# Check if ZombieSpawner has a method to set spawn points
		if zombie_spawner.has_method("set_spawn_points"):
			zombie_spawner.set_spawn_points(zombie_spawn_points)
		else:
			# Directly set the spawn_points array if it exists
			zombie_spawner.spawn_points = zombie_spawn_points
		print("Set ", zombie_spawn_points.size(), " zombie spawn points from map layout")
