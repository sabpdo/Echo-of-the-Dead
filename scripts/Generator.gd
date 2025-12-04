extends Node2D

@onready var interaction_area = $InteractionArea
@onready var color_rect = $ColorRect
@onready var texture_rect = $TextureRect
@onready var label = $Label
@onready var electricity_audio = $ElectricityAudio

var is_on: bool = false
const INTERACTION_RADIUS: float = 80.0
const COST_POINTS: int = 2000

# Generator reveal / ring effect
var ring_active: bool = false
var ring_elapsed: float = 0.0
var ring_duration: float = 10.0
var ring_radius: float = 0.0
var generator_reveal_running: bool = false
var ring_effect_node: Node = null

var active_generator = null

signal generator_toggled(on: bool)

func _ready():
	# Start off
	set_on(false)
	
	# Get reference to ring effect node
	ring_effect_node = get_node_or_null("/root/Main/FogLayer/GeneratorRingEffect")
	
	# Connect interaction signal
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
	
	active_generator = load("res://assets/crystal/active.png")


func _process(delta: float) -> void:
	# Update ring timer and update ring effect node while active
	if ring_active and ring_effect_node:
		ring_elapsed += delta
		if ring_effect_node.has_method("set_ring_state"):
			ring_effect_node.set_ring_state(true, ring_radius, global_position)

func _on_body_entered(body):
	if body.is_in_group("player") or body.name == "Player":
		body.nearby_generator = self

func _on_body_exited(body):
	if body.is_in_group("player") or body.name == "Player":
		if body.nearby_generator == self:
			body.nearby_generator = null

func set_on(on: bool):
	var was_on = is_on
	is_on = on
	
	# Play electricity sound when generator is turned on
	if on and not was_on and electricity_audio:
		if electricity_audio.has_method("play_cue"):
			electricity_audio.play_cue()
		elif electricity_audio.stream:
			electricity_audio.play()
	
	if texture_rect and on:
		texture_rect.texture = active_generator
	
	if color_rect:
		if on:
			color_rect.color = Color(0.2, 1, 0.2, 1)  # Green when on
		else:
			color_rect.color = Color(0.2, 0.4, 1, 1)  # Blue when off
	
	generator_toggled.emit(on)

func toggle():
	# Don't allow toggling if already on
	if is_on:
		return
	
	# Check if player has enough points
	var points_counters = get_tree().get_nodes_in_group("points_counter")
	if points_counters.size() > 0:
		var points_counter = points_counters[0]
		if points_counter.points >= COST_POINTS:
			# Deduct points (using negative amount to subtract)
			points_counter.add_points(-COST_POINTS)
			
			# Turn on generator
			set_on(true)
			
			# Trigger win sequence
			_trigger_win_sequence()
		else:
			# Not enough points - could show a message here
			print("Not enough points! Need ", COST_POINTS, " points.")

func _trigger_win_sequence():
	# Start generator reveal effect instead of instantly removing fog
	var unexplored_controller = get_node_or_null("/root/Main/FogLayer/UnexploredController")
	if unexplored_controller and not generator_reveal_running:
		_start_generator_reveal(unexplored_controller)
	
	# Stop zombie spawning and kill all zombies
	var zombie_spawner = get_node("/root/Main/ZombieSpawner")
	if zombie_spawner:
		zombie_spawner.stop_spawning_and_kill_all()
	
	# Wait a few seconds then show win screen
	await get_tree().create_timer(3.0).timeout
	
	# Show win screen (this will signal the reveal to stop)
	var win_overlay = get_node("/root/Main/UILayer/WinOverlay")
	if win_overlay:
		win_overlay.show_win_screen()


func _start_generator_reveal(unexplored_controller: Node) -> void:
	# Fire-and-forget async reveal
	generator_reveal_running = true
	ring_active = true
	ring_elapsed = 0.0
	ring_radius = 0.0
	# Run the async part
	_run_generator_reveal(unexplored_controller)


func _run_generator_reveal(unexplored_controller: Node) -> void:
	# Async coroutine to reveal unexplored area over time until win screen appears
	var win_overlay = get_node_or_null("/root/Main/UILayer/WinOverlay")
	
	# Try to use map size from UnexploredController to choose a large enough radius
	var max_radius: float = 2000.0
	if unexplored_controller.has_method("_reveal_area"):
		# Access MAP_WIDTH and MAP_HEIGHT constants directly
		var map_width: float = float(unexplored_controller.MAP_WIDTH)
		var map_height: float = float(unexplored_controller.MAP_HEIGHT)
		max_radius = max(map_width, map_height) * 0.7
	
	# Expansion speed: reach max radius in ring_duration seconds
	var expansion_rate: float = max_radius / ring_duration
	var current_radius: float = 0.0
	var step_duration: float = 0.05  # Update every 50ms for smooth expansion
	
	# Reveal in expanding circles until win screen appears
	while ring_active:
		# Check if win screen is visible
		if win_overlay and win_overlay.visible:
			break
		
		# Increase radius over time
		current_radius += expansion_rate * step_duration
		if current_radius > max_radius:
			current_radius = max_radius
		
		ring_radius = current_radius
		
		# Reveal unexplored area around generator
		if unexplored_controller.has_method("_reveal_area"):
			unexplored_controller._reveal_area(global_position, current_radius)
		
		# Update ring effect node
		if ring_effect_node and ring_effect_node.has_method("set_ring_state"):
			ring_effect_node.set_ring_state(true, current_radius, global_position)
		
		# Wait for the next step
		await get_tree().create_timer(step_duration).timeout
	
	# Stop ring and hide unexplored layer entirely
	ring_active = false
	if ring_effect_node and ring_effect_node.has_method("set_ring_state"):
		ring_effect_node.set_ring_state(false, 0.0, global_position)
	
	if unexplored_controller is CanvasItem:
		(unexplored_controller as CanvasItem).hide()
	
	generator_reveal_running = false
