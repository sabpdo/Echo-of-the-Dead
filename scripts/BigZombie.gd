extends CharacterBody2D

const SPEED = 120.0  # Slower than regular zombies
const DAMAGE = 1  # 1 hearts per attack (2x normal)
const ATTACK_COOLDOWN = 1.2  # Slightly longer cooldown
const MONSTER_AUDIO_MAX_DISTANCE = 900.0
const MONSTER_AUDIO_MIN_DB = -32.0
const MONSTER_AUDIO_MAX_DB = 3.0

# Health system - Big zombies are much tankier
var base_max_health: int = 125  # 1.25x regular zombie health
var max_health: int = 125
var current_health: int = 125

# Difficulty multipliers (set by spawner)
var speed_multiplier: float = 1.0
var health_multiplier: float = 1.0

var player: Node2D = null
var attack_timer: float = 0.0

@onready var health_bar_container: Control = $HealthBarContainer
@onready var health_bar: ColorRect = $HealthBarContainer/HealthBar
@onready var monster_audio = $MonsterAudio

signal health_changed(current_health, max_health)
signal zombie_died

func _ready():
	# Add to zombies group for radar detection
	add_to_group("zombies")
	add_to_group("big_zombies")  # Special group for big zombies
	
	# Apply health multiplier
	max_health = int(base_max_health * health_multiplier)
	current_health = max_health
	health_changed.emit(current_health, max_health)
	
	# Hide health bar (user preference - no green bar)
	if health_bar_container:
		health_bar_container.visible = false
	
	# Find the player
	player = get_node("/root/Main/Player")
	
	# Connect health changed signal to update visual
	health_changed.connect(_on_health_changed)

func _on_health_changed(current: int, max_hp: int):
	# Health bar is hidden, no need to update
	pass

func take_damage(amount: int):
	var points_counters = get_tree().get_nodes_in_group("points_counter")
	
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		var counters = get_tree().get_nodes_in_group("kill_counter")
		if counters.size() > 0:
			counters[0].zombies_killed += 1
		
		# Award 300 points for killing a big zombie (3x normal)
		if points_counters.size() > 0:
			points_counters[0].add_points(300)
		
		zombie_died.emit()
		queue_free()
	else:
		# Award 30 points for hitting a big zombie (2x normal)
		if points_counters.size() > 0:
			points_counters[0].add_points(30)

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
		var attack_range = 60.0  # Slightly larger attack range due to size
		
		if hit_player or distance_to_player <= attack_range:
			# Attack the player with more damage
			if player.has_method("take_damage"):
				player.take_damage(DAMAGE)
			attack_timer = ATTACK_COOLDOWN
	
	_update_monster_audio()

func _update_monster_audio():
	if not monster_audio or not player:
		return
	
	# Keep looping ambience alive for each zombie
	if monster_audio.stream and not monster_audio.playing:
		monster_audio.play()
	
	var distance = global_position.distance_to(player.global_position)
	var proximity = clamp(1.0 - distance / MONSTER_AUDIO_MAX_DISTANCE, 0.0, 1.0)
	monster_audio.volume_db = lerp(MONSTER_AUDIO_MIN_DB, MONSTER_AUDIO_MAX_DB, proximity)

