extends Control

@onready var fog_material = $FogRect.material as ShaderMaterial
@onready var player = get_node("/root/Main/Player")

var view_radius: float = 150.0
var soft_edge: float = 50.0

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

