extends CharacterBody2D

const SPEED = 150.0
const DAMAGE = 0.5  # Half a heart per attack
const ATTACK_COOLDOWN = 1.0

# Health system
var base_max_health: int = 50
var max_health: int = 50
var current_health: int = 50

# Difficulty multipliers (set by spawner)
var speed_multiplier: float = 1.0
var health_multiplier: float = 1.0

var player: Node2D = null
var attack_timer: float = 0.0

@onready var health_bar_container: Control = $HealthBarContainer
@onready var health_bar: ColorRect = $HealthBarContainer/HealthBar

signal health_changed(current_health, max_health)
signal zombie_died

func _ready():
	# Add to zombies group for radar detection
	add_to_group("zombies")
	
	# Apply health multiplier
	max_health = int(base_max_health * health_multiplier)
	current_health = max_health
	health_changed.emit(current_health, max_health)
	_update_health_bar()
	
	# Find the player
	player = get_node("/root/Main/Player")
	
	# Connect health changed signal to update visual
	health_changed.connect(_on_health_changed)

func _on_health_changed(current: int, max_hp: int):
	_update_health_bar()

func _update_health_bar():
	if health_bar and health_bar_container:
		var health_percentage = float(current_health) / float(max_health)
		health_percentage = clamp(health_percentage, 0.0, 1.0)
		
		# Update health bar width based on health percentage
		var container_width = health_bar_container.size.x
		health_bar.size.x = container_width * health_percentage
		health_bar.position.x = 0  # Keep it aligned to the left
		
		# Change color based on health (red when low, green when high)
		if health_percentage > 0.6:
			health_bar.color = Color(0.2, 0.8, 0.2, 1)  # Green
		elif health_percentage > 0.3:
			health_bar.color = Color(0.8, 0.8, 0.2, 1)  # Yellow
		else:
			health_bar.color = Color(0.8, 0.2, 0.2, 1)  # Red

func take_damage(amount: int):
	var points_counters = get_tree().get_nodes_in_group("points_counter")
	
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		var counters = get_tree().get_nodes_in_group("kill_counter")
		if counters.size() > 0:
			counters[0].zombies_killed += 1
		
		# Award 100 points for the kill (only if it dies)
		if points_counters.size() > 0:
			points_counters[0].add_points(100)
		
		zombie_died.emit()
		queue_free()
	else:
		# Award 15 points for the hit (only if it doesn't die)
		if points_counters.size() > 0:
			points_counters[0].add_points(15)

func _physics_process(delta):
	if not player:
		return
	
	attack_timer -= delta
	
	# Move towards player (with speed multiplier)
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * SPEED * speed_multiplier
	move_and_slide()
	
	# Face movement direction
	if velocity.length() > 0:
		look_at(global_position + velocity)
	
	# Check for collision with player and attack
	if attack_timer <= 0.0:
		# Check collisions after movement
		var hit_player = false
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			if collision.get_collider() == player:
				hit_player = true
				break
		
		# Also check distance as fallback (in case collision detection fails)
		var distance_to_player = global_position.distance_to(player.global_position)
		var attack_range = 50.0  # Attack range
		
		if hit_player or distance_to_player <= attack_range:
			# Attack the player
			if player.has_method("take_damage"):
				player.take_damage(DAMAGE)
			attack_timer = ATTACK_COOLDOWN
