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
var fractional_damage: float = 0.0  # Track fractional damage

# Difficulty multipliers (set by spawner)
var speed_multiplier: float = 1.0
var health_multiplier: float = 1.0
var terrain_speed_multiplier: float = 1.0

var player: Node2D = null
var attack_timer: float = 0.0
var target_gate: Node2D = null
var gate_update_timer: float = 0.0
const GATE_UPDATE_INTERVAL = 0.5  # Update gate target every 0.5 seconds

# Freeze state
var is_frozen: bool = false
var freeze_timer: float = 0.0

@onready var health_bar_container: Control = $HealthBarContainer
@onready var health_bar: ColorRect = $HealthBarContainer/HealthBar
@onready var monster_audio = $MonsterAudio
@onready var pain_audio = $PainAudio
@onready var death_audio = $DeathAudio
@onready var freeze_effect = $FreezeEffect

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

func take_damage(amount):
	# Accept both int and float for damage
	var damage_float: float = float(amount)
	var points_counters = get_tree().get_nodes_in_group("points_counter")
	
	# Add to fractional damage
	fractional_damage += damage_float
	
	# Apply whole damage when fractional damage >= 1.0
	var whole_damage: int = int(fractional_damage)
	if whole_damage > 0:
		fractional_damage -= float(whole_damage)
		current_health = max(0, current_health - whole_damage)
		health_changed.emit(current_health, max_health)
	
	# Play pain sound when taking damage (but not when dying)
	if current_health > 0 and pain_audio:
		if pain_audio.has_method("play_cue"):
			pain_audio.play_cue()
		elif pain_audio.stream:
			pain_audio.play()
	
	if current_health <= 0:
		# Play death sound before freeing the zombie
		if death_audio:
			# Detach death audio so it can finish playing after zombie is freed
			var parent_node = get_parent()
			if parent_node:
				remove_child(death_audio)
				parent_node.add_child(death_audio)
				death_audio.global_position = global_position
				
				if death_audio.has_method("play_cue"):
					death_audio.play_cue()
				elif death_audio.stream:
					death_audio.play()
				
				# Auto-remove the audio player after it finishes playing
				# Use a timer to clean up the audio player
				var cleanup_timer = Timer.new()
				cleanup_timer.wait_time = 3.0  # Give enough time for the sound to play
				cleanup_timer.one_shot = true
				cleanup_timer.timeout.connect(func(): death_audio.queue_free(); cleanup_timer.queue_free())
				parent_node.add_child(cleanup_timer)
				cleanup_timer.start()
		
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
	
	# Update freeze timer
	if is_frozen:
		freeze_timer -= delta
		if freeze_timer <= 0.0:
			_unfreeze()
		else:
			# Stop movement when frozen
			velocity = Vector2.ZERO
			move_and_slide()
			_update_freeze_effect()
			return
	
	attack_timer -= delta
	gate_update_timer -= delta
	
	# Update target gate periodically
	if gate_update_timer <= 0.0:
		target_gate = _find_nearest_gate()
		gate_update_timer = GATE_UPDATE_INTERVAL
	
	# Determine movement target: gate first, then player
	var target_position = _get_movement_target()
	
	# Move towards target (with speed multiplier)
	var direction = (target_position - global_position).normalized()
	velocity = direction * SPEED * speed_multiplier * terrain_speed_multiplier
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

func set_terrain_speed_multiplier(multiplier: float):
	terrain_speed_multiplier = multiplier

func reset_terrain_speed_multiplier():
	terrain_speed_multiplier = 1.0

func freeze(duration: float):
	is_frozen = true
	freeze_timer = duration
	_update_freeze_effect()

func _unfreeze():
	is_frozen = false
	freeze_timer = 0.0
	_update_freeze_effect()

func _update_freeze_effect():
	if freeze_effect:
		freeze_effect.visible = is_frozen
		if is_frozen:
			# Add a subtle pulsing effect
			var time = Time.get_ticks_msec() / 1000.0
			var pulse = 0.7 + 0.3 * sin(time * 3.0)
			freeze_effect.modulate = Color(1, 1, 1, pulse)

func _find_nearest_gate() -> Node2D:
	# Get all gates in the scene
	var gates = get_tree().get_nodes_in_group("gates")
	if gates.is_empty() or not player:
		return null
	
	# Find the gate nearest to the player (not the zombie)
	var nearest_gate: Node2D = null
	var nearest_distance: float = INF
	
	for gate in gates:
		if not is_instance_valid(gate):
			continue
		var distance = player.global_position.distance_to(gate.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_gate = gate
	
	return nearest_gate

func _get_movement_target() -> Vector2:
	# If no gate found, go directly to player
	if not target_gate or not is_instance_valid(target_gate):
		return player.global_position
	
	# Check if zombie has passed through the gate (is on player's side)
	# We consider the zombie past the gate if:
	# 1. The zombie is closer to the player than the gate is, OR
	# 2. The zombie is on the same side of the gate as the player
	var gate_pos = target_gate.global_position
	var zombie_pos = global_position
	var player_pos = player.global_position
	
	# Calculate distances
	var zombie_to_gate = zombie_pos.distance_to(gate_pos)
	var zombie_to_player = zombie_pos.distance_to(player_pos)
	var gate_to_player = gate_pos.distance_to(player_pos)
	
	# If zombie is closer to player than gate is, we've passed the gate
	# Or if the zombie is very close to the gate (within 30 units), consider it passed
	if zombie_to_player < gate_to_player or zombie_to_gate < 30.0:
		return player_pos
	
	# Otherwise, move towards the gate
	return gate_pos

