extends Node2D

@onready var interaction_area = $InteractionArea
@onready var animated_sprite = $AnimatedSprite2D
@onready var light_2d = $Light2D

var is_lit: bool = false
var fog_controller: Node = null
const LIGHT_RADIUS: float = 150.0

signal torch_toggled(lit: bool)

func _ready():
	fog_controller = get_node("/root/Main/FogLayer/FogController")
	
	# Start unlit
	set_lit(false)
	
	# Connect interaction signal
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player") or body.name == "Player":
		body.nearby_torch = self

func _on_body_exited(body):
	if body.is_in_group("player") or body.name == "Player":
		if body.nearby_torch == self:
			body.nearby_torch = null

func set_lit(lit: bool):
	is_lit = lit
	
	if animated_sprite:
		# Always visible, but show different animation based on state
		animated_sprite.visible = true
		if lit:
			animated_sprite.play("lit")
			animated_sprite.modulate = Color(1, 1, 1, 1)  # Full brightness when lit
		else:
			# Show first frame of lit animation but darkened
			animated_sprite.play("lit")
			animated_sprite.frame = 0
			animated_sprite.stop()
			animated_sprite.modulate = Color(0.3, 0.3, 0.3, 1)  # Darkened when unlit
	
	if light_2d:
		light_2d.enabled = lit
	
	# Update fog clearing
	if fog_controller:
		if lit:
			fog_controller.add_light_source(self, LIGHT_RADIUS, Vector2.ZERO, 1.0)
		else:
			fog_controller.remove_light_source(self)
	
	torch_toggled.emit(lit)

func toggle():
	set_lit(not is_lit)
