extends Area2D

const TERRAIN_CONFIG := {
	"wooden_planks": {
		"player_multiplier": 1.1,
		"zombie_multiplier": 1.1,
		"color": Color(0.58, 0.45, 0.28, 0.85)
	},
	"leaves": {
		"player_multiplier": 1.0,
		"zombie_multiplier": 1.0,
		"color": Color(0.29, 0.45, 0.24, 0.75)
	},
	"cobblestone": {
		"player_multiplier": 1.1,
		"zombie_multiplier": 1.1,
		"color": Color(0.5, 0.5, 0.5, 0.8)
	},
	"dirt_mud": {
		"player_multiplier": 1.0,
		"zombie_multiplier": 0.7,
		"color": Color(0.35, 0.2, 0.1, 0.8)
	},
	"grass": {
		"player_multiplier": 0.8,
		"zombie_multiplier": 1.0,
		"color": Color(0.18, 0.5, 0.18, 0.75)
	},
	"puddle": {
		"player_multiplier": 1.0,
		"zombie_multiplier": 0.6,
		"color": Color(0.15, 0.35, 0.65, 0.8)
	}
}

var terrain_type: String = "leaves"
var _current_config: Dictionary = TERRAIN_CONFIG["leaves"]
var _tracked_bodies: Dictionary = {}
var _tile_size: float = 50.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var polygon: Polygon2D = $Polygon2D

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	collision_mask = 3  # Player (layer 1) + Zombies (layer 2)
	set_terrain_type(terrain_type)
	_update_visuals()

func configure(size: float, type_name: String):
	set_tile_size(size)
	set_terrain_type(type_name)

func set_tile_size(size: float):
	_tile_size = size
	var half = size / 2.0
	if collision_shape and collision_shape.shape and collision_shape.shape is RectangleShape2D:
		collision_shape.shape.extents = Vector2(half, half)
	if polygon:
		polygon.polygon = PackedVector2Array([
			Vector2(-half, -half),
			Vector2(half, -half),
			Vector2(half, half),
			Vector2(-half, half)
		])

func set_terrain_type(type_name: String):
	if not TERRAIN_CONFIG.has(type_name):
		type_name = "leaves"
	terrain_type = type_name
	_current_config = TERRAIN_CONFIG[terrain_type]
	_update_visuals()

func _update_visuals():
	if polygon and _current_config.has("color"):
		polygon.color = _current_config["color"]

func _on_body_entered(body: Node):
	var applied := false
	if body.is_in_group("player"):
		applied = _apply_modifier(body, _current_config.get("player_multiplier", 1.0)) or applied
	if body.is_in_group("zombies"):
		applied = _apply_modifier(body, _current_config.get("zombie_multiplier", 1.0)) or applied
	if applied:
		_tracked_bodies[body] = true

func _on_body_exited(body: Node):
	if not _tracked_bodies.has(body):
		return
	if body.has_method("reset_terrain_speed_multiplier"):
		body.reset_terrain_speed_multiplier()
	_tracked_bodies.erase(body)

func _apply_modifier(body: Node, multiplier: float) -> bool:
	if is_equal_approx(multiplier, 1.0):
		return false
	if body.has_method("set_terrain_speed_multiplier"):
		body.set_terrain_speed_multiplier(multiplier)
		return true
	return false

