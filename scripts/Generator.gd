extends Node2D

@onready var interaction_area = $InteractionArea
@onready var color_rect = $ColorRect
@onready var label = $Label

var is_on: bool = false
const INTERACTION_RADIUS: float = 80.0
const COST_KILLS: int = 10

signal generator_toggled(on: bool)

func _ready():
	# Start off
	set_on(false)
	
	# Connect interaction signal
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player") or body.name == "Player":
		body.nearby_generator = self

func _on_body_exited(body):
	if body.is_in_group("player") or body.name == "Player":
		if body.nearby_generator == self:
			body.nearby_generator = null

func set_on(on: bool):
	is_on = on
	
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
	
	# Check if player has enough kills
	var counters = get_tree().get_nodes_in_group("kill_counter")
	if counters.size() > 0:
		var kill_counter = counters[0]
		if kill_counter.zombies_killed >= COST_KILLS:
			# Deduct kills
			kill_counter.zombies_killed -= COST_KILLS
			
			# Turn on generator
			set_on(true)
			
			# Trigger win sequence
			_trigger_win_sequence()
		else:
			# Not enough kills - could show a message here
			print("Not enough kills! Need ", COST_KILLS, " kills.")

func _trigger_win_sequence():
	# Remove all fog
	var fog_controller = get_node("/root/Main/FogLayer/FogController")
	if fog_controller:
		fog_controller.remove_all_fog()
	
	# Stop zombie spawning and kill all zombies
	var zombie_spawner = get_node("/root/Main/ZombieSpawner")
	if zombie_spawner:
		zombie_spawner.stop_spawning_and_kill_all()
	
	# Wait a few seconds then show win screen
	await get_tree().create_timer(3.0).timeout
	
	# Show win screen
	var win_overlay = get_node("/root/Main/UILayer/WinOverlay")
	if win_overlay:
		win_overlay.show_win_screen()

