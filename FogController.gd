extends Control

@onready var fog_material = $FogRect.material as ShaderMaterial
@onready var player = get_node("/root/Main/Player")

var view_radius: float = 150.0
var soft_edge: float = 50.0

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

