extends Node2D

@onready var interaction_area = $InteractionArea
@onready var animated_sprite = $AnimatedSprite2D
@onready var light_2d = $Light2D
@onready var interaction_button = $InteractionButton
@onready var glow_effect = $GlowEffect
@onready var light_switch_on_audio = $LightSwitchOnAudio
@onready var light_switch_off_audio = $LightSwitchOffAudio

var is_lit: bool = false
var fog_controller: Node = null
var unexplored_controller: Node = null
const LIGHT_RADIUS: float = 150.0
var player_nearby: bool = false
var toggle_cooldown: float = 0.0
const TOGGLE_COOLDOWN_TIME: float = 0.3
var _initialized: bool = false

signal torch_toggled(lit: bool)

func _ready():
	fog_controller = get_node("/root/Main/FogLayer/FogController")
	unexplored_controller = get_node("/root/Main/FogLayer/UnexploredController")
	
	# Start unlit (without playing sound)
	set_lit(false, false)
	_initialized = true
	
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
	
	# Continuously reveal unexplored areas around torch when lit
	if is_lit and unexplored_controller:
		unexplored_controller._reveal_area(global_position, LIGHT_RADIUS)
	
	# Update glow effect pulsing when lit
	if is_lit and glow_effect:
		var time = Time.get_ticks_msec() / 1000.0
		# Add more variability with multiple sine waves at different frequencies
		var pulse1 = sin(time * 2.5) * 0.15
		var pulse2 = sin(time * 4.3) * 0.08
		var pulse3 = sin(time * 1.7) * 0.05
		# Add some noise-based flickering for more natural variation
		var noise = sin(time * 7.2 + 1.3) * sin(time * 11.7 + 2.1) * 0.04
		var pulse = 1.0 + pulse1 + pulse2 + pulse3 + noise
		var glow_material = glow_effect.material as ShaderMaterial
		if glow_material:
			# Larger radius - ColorRect is now 480x480, so 0.4 gives ~192 pixels
			glow_material.set_shader_parameter("radius", 0.4 * pulse)

func _on_body_entered(body):
	if body.is_in_group("player") or body.name == "Player":
		body.nearby_torch = self
		player_nearby = true

func _on_body_exited(body):
	if body.is_in_group("player") or body.name == "Player":
		if body.nearby_torch == self:
			body.nearby_torch = null
		player_nearby = false

func set_lit(lit: bool, play_sound: bool = true):
	var was_lit = is_lit
	is_lit = lit
	
	# Play light switch sound when state changes (but not on initial setup)
	if _initialized and play_sound and was_lit != lit:
		if lit and light_switch_on_audio:
			if light_switch_on_audio.has_method("play_cue"):
				light_switch_on_audio.play_cue()
			elif light_switch_on_audio.stream:
				light_switch_on_audio.play()
		elif not lit and light_switch_off_audio:
			if light_switch_off_audio.has_method("play_cue"):
				light_switch_off_audio.play_cue()
			elif light_switch_off_audio.stream:
				light_switch_off_audio.play()
	
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
	
	# Update glow effect visibility
	if glow_effect:
		if lit:
			glow_effect.modulate = Color(1, 1, 1, 1)
		else:
			glow_effect.modulate = Color(1, 1, 1, 0)
	
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
