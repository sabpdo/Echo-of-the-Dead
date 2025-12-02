extends Control

@onready var unexplored_material = $UnexploredRect.material as ShaderMaterial
@onready var player = get_node("/root/Main/Player")
@onready var fog_controller = get_node("/root/Main/FogLayer/FogController")

# Map boundaries (matching WallGenerator)
# Map size is 2.3x larger to accommodate larger map layouts
const MAP_LEFT = -2495.5
const MAP_RIGHT = 2661.1
const MAP_TOP = -1472.0
const MAP_BOTTOM = 1472.0
const MAP_WIDTH = MAP_RIGHT - MAP_LEFT
const MAP_HEIGHT = MAP_BOTTOM - MAP_TOP

# Exploration settings (will sync with FogController view_radius)
const EXPLORE_RADIUS_FACTOR := 0.7
var explore_radius: float = 150.0
var texture_resolution: int = 1024  # Resolution of the explored texture

var explored_image: Image
var explored_texture: ImageTexture
var last_player_world_pos: Vector2 = Vector2.ZERO

func _ready():
	# Create the explored texture (white = explored, black = unexplored)
	explored_image = Image.create(texture_resolution, texture_resolution, false, Image.FORMAT_R8)
	# Start with all black (unexplored)
	explored_image.fill(Color.BLACK)
	
	# Create texture from image
	explored_texture = ImageTexture.create_from_image(explored_image)
	
	# Set shader parameters
	if unexplored_material:
		unexplored_material.set_shader_parameter("explored_texture", explored_texture)
		unexplored_material.set_shader_parameter("map_offset", Vector2(MAP_LEFT, MAP_TOP))
		unexplored_material.set_shader_parameter("map_size", Vector2(MAP_WIDTH, MAP_HEIGHT))
		_update_viewport_size()
	
	# Initialize last position and reveal starting area
	if player:
		if fog_controller:
			explore_radius = fog_controller.view_radius * EXPLORE_RADIUS_FACTOR
		last_player_world_pos = player.global_position
		# Reveal the starting area immediately
		_reveal_area(player.global_position, explore_radius)

func _update_viewport_size():
	if unexplored_material:
		var viewport = get_viewport()
		if viewport:
			var size = viewport.get_visible_rect().size
			unexplored_material.set_shader_parameter("viewport_size", size)

func _process(_delta):
	if player and unexplored_material:
		var viewport = get_viewport()
		if viewport:
			_update_viewport_size()
		
		# Sync explore radius with FogController's view radius
		if fog_controller:
			explore_radius = fog_controller.view_radius * EXPLORE_RADIUS_FACTOR
		
		# Get camera for zoom
		var camera = viewport.get_camera_2d()
		var camera_zoom = 1.0
		if camera:
			camera_zoom = camera.zoom.x
		
		# Update shader parameters
		var player_world_pos = player.global_position
		unexplored_material.set_shader_parameter("player_world_position", player_world_pos)
		unexplored_material.set_shader_parameter("camera_zoom", camera_zoom)
		
		# Update explored areas based on player position
		# Only update if player moved significantly (optimization)
		if player_world_pos.distance_to(last_player_world_pos) > 5.0:
			_reveal_area(player_world_pos, explore_radius)
			last_player_world_pos = player_world_pos

func _reveal_area(world_pos: Vector2, radius: float):
	# Convert world position to texture coordinates
	var tex_x = int((world_pos.x - MAP_LEFT) / MAP_WIDTH * texture_resolution)
	var tex_y = int((world_pos.y - MAP_TOP) / MAP_HEIGHT * texture_resolution)
	
	# Convert radius to texture space
	# To draw a circle in world space, we need to draw an ellipse in texture space
	# because the map is rectangular but the texture is square
	var tex_radius_x = radius / MAP_WIDTH * texture_resolution
	var tex_radius_y = radius / MAP_HEIGHT * texture_resolution
	
	# Draw an ellipse that represents a circle in world space
	var center = Vector2i(tex_x, tex_y)
	var radius_x_squared = tex_radius_x * tex_radius_x
	var radius_y_squared = tex_radius_y * tex_radius_y
	
	# Calculate bounding box for the ellipse
	var max_radius = int(max(tex_radius_x, tex_radius_y))
	
	# Draw ellipse (Godot 4 doesn't require lock/unlock)
	for y in range(max(0, center.y - max_radius), min(texture_resolution, center.y + max_radius + 1)):
		for x in range(max(0, center.x - max_radius), min(texture_resolution, center.x + max_radius + 1)):
			var dx = float(x - center.x)
			var dy = float(y - center.y)
			
			# Check if point is inside ellipse: (dx/radius_x)^2 + (dy/radius_y)^2 <= 1
			var ellipse_test = (dx * dx / radius_x_squared) + (dy * dy / radius_y_squared)
			
			if ellipse_test <= 1.0:
				# Set pixel to white (explored)
				explored_image.set_pixel(x, y, Color.WHITE)
	
	# Update the texture
	explored_texture.update(explored_image)

