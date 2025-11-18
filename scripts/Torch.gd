extends Node2D

@onready var interaction_area = $InteractionArea
@onready var animated_sprite = $AnimatedSprite2D
@onready var light_2d = $Light2D
@onready var interaction_button = $InteractionButton

var is_lit: bool = false
var fog_controller: Node = null
const LIGHT_RADIUS: float = 150.0
var player_nearby: bool = false
var toggle_cooldown: float = 0.0
const TOGGLE_COOLDOWN_TIME: float = 0.3

signal torch_toggled(lit: bool)

func _ready():
	fog_controller = get_node("/root/Main/FogLayer/FogController")
	
	# Start unlit
	set_lit(false)
	
	# Connect interaction signal
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
	
	# Setup button
	if interaction_button:
		interaction_button.visible = false
		interaction_button.pressed.connect(_on_button_pressed)
		_update_button_text()

func _process(delta):
	# Update cooldown
	if toggle_cooldown > 0:
		toggle_cooldown -= delta
	
	# Update button visibility
	if interaction_button:
		interaction_button.visible = player_nearby

func _on_body_entered(body):
	if body.is_in_group("player") or body.name == "Player":
		body.nearby_torch = self
		player_nearby = true

func _on_body_exited(body):
	if body.is_in_group("player") or body.name == "Player":
		if body.nearby_torch == self:
			body.nearby_torch = null
		player_nearby = false

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
	
	_update_button_text()
	torch_toggled.emit(lit)

func toggle():
	# Prevent rapid toggling
	if toggle_cooldown > 0:
		return
	
	set_lit(not is_lit)
	toggle_cooldown = TOGGLE_COOLDOWN_TIME

func _on_button_pressed():
	toggle()

func _update_button_text():
	if interaction_button:
		var label = interaction_button.get_node_or_null("Label")
		if label:
			if is_lit:
				label.text = "Turn Off"
			else:
				label.text = "Light"
