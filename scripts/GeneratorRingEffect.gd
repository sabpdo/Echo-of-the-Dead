extends Control

# This node draws the purple ring effect on top of fog layers
var ring_active: bool = false
var ring_radius: float = 0.0
var generator_world_pos: Vector2 = Vector2.ZERO

func _ready():
	# Make sure this renders on top
	z_index = 10
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw():
	# Draw a blurry purple ring while the generator reveal is active
	if not ring_active:
		return
	
	if ring_radius <= 0.0:
		return
	
	# Get camera to convert world position to screen position
	var viewport = get_viewport()
	var camera = viewport.get_camera_2d()
	if not camera:
		return
	
	# Convert world position to screen position
	var viewport_size = viewport.get_visible_rect().size
	var player = get_node_or_null("/root/Main/Player")
	if not player:
		return
	
	var player_world_pos = player.global_position
	var camera_zoom = camera.zoom.x
	var offset = (generator_world_pos - player_world_pos) * camera_zoom
	var screen_center = viewport_size / 2.0
	var ring_center = screen_center + offset
	
	# Convert radius to screen space
	var screen_radius = ring_radius * camera_zoom
	
	var base_color := Color(0.7, 0.3, 1.0, 0.35)  # Purple with some transparency
	var segments := 64
	
	# Draw multiple arcs with slightly different radii and alpha for a soft, blurry look
	var line_width := 12.0
	for i in range(3):
		var offset_ring := float(i - 1) * 4.0
		var alpha_scale: float = 1.0 - abs(float(i - 1)) * 0.4
		var color := Color(base_color.r, base_color.g, base_color.b, base_color.a * alpha_scale)
		draw_arc(ring_center, screen_radius + offset_ring, 0.0, TAU, segments, color, line_width)

func set_ring_state(active: bool, radius: float, world_pos: Vector2):
	ring_active = active
	ring_radius = radius
	generator_world_pos = world_pos
	queue_redraw()

