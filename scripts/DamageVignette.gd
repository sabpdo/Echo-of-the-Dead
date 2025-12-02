extends ColorRect

@export var min_base_intensity: float = 0.07
@export var max_base_intensity: float = 1.2
@export var flash_peak_intensity: float = 0.6
@export var flash_fade_time: float = 0.3

var _player: Node = null
var _last_half_hearts: int = -1
var _flash_value: float = 0.0

var _shader_material: ShaderMaterial

func _ready() -> void:
	# Ensure this node covers the whole screen and doesn't block input
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchors_preset = PRESET_FULL_RECT
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH

	color = Color(1, 0, 0, 0) # Fully transparent base, shader controls opacity

	# Set up shader material
	var shader := load("res://damage_vignette.gdshader")
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = shader
	material = _shader_material

	# Find the player and connect to health changes
	if has_node("/root/Main/Player"):
		_player = get_node("/root/Main/Player")
		if _player and _player.has_signal("health_changed"):
			_player.health_changed.connect(_on_health_changed)
			_last_half_hearts = _player.current_half_hearts
			_update_base_intensity(_player.current_half_hearts, _player.max_half_hearts)

func _process(delta: float) -> void:
	# Fade out the hit flash over time
	if _flash_value > 0.0:
		_flash_value = max(0.0, _flash_value - (delta / max(flash_fade_time, 0.001)))
		_shader_material.set_shader_parameter("flash_intensity", _flash_value)

func _on_health_changed(current_half_hearts: int, max_half_hearts: int) -> void:
	# Trigger a flash if health decreased
	if _last_half_hearts >= 0 and current_half_hearts < _last_half_hearts:
		_flash_value = flash_peak_intensity
		_shader_material.set_shader_parameter("flash_intensity", _flash_value)

	_last_half_hearts = current_half_hearts
	_update_base_intensity(current_half_hearts, max_half_hearts)

func _update_base_intensity(current_half_hearts: int, max_half_hearts: int) -> void:
	if max_half_hearts <= 0:
		return

	var health_ratio := float(current_half_hearts) / float(max_half_hearts)
	var missing_ratio := 1.0 - health_ratio

	var base_intensity: float = lerp(min_base_intensity, max_base_intensity, missing_ratio)
	_shader_material.set_shader_parameter("base_intensity", base_intensity)
