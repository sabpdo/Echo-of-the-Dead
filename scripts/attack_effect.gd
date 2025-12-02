extends Area2D

# speed of the attack
const SPEED = 400.0
# duration of the attack
const DURATION = 0.4
# how much the zombie is damaged
const DAMAGE = 25

var direction: Vector2 = Vector2.ZERO

var time_left := DURATION

@onready var fireball_sprite = $FireballSprite
@onready var glow_sprite = $GlowSprite
@onready var trail_particles = $TrailParticles

var fog_controller: Node = null
var unexplored_controller: Node = null

func _ready():
	# Set collision mask to detect zombies (layer 2) and walls (layers 1+2 = 3)
	# Layer 1 = 1, Layer 2 = 2, so 1 + 2 = 3 detects both layers
	# This allows fireballs to detect zombies and walls, but we'll ignore gates in code
	collision_mask = 3  # Detect layers 1 and 2 (zombies on layer 2, walls on layers 1+2)
	
	# Wait a frame for direction to be set
	await get_tree().process_frame
	
	# Register as light source to clear fog
	fog_controller = get_node("/root/Main/FogLayer/FogController")
	unexplored_controller = get_node("/root/Main/FogLayer/UnexploredController")
	if fog_controller and direction.length() > 0:
		# Use elliptical fog clearing to match fireball shape (wider in direction of travel)
		# Aspect ratio 1.8 makes it wider than tall, matching the fireball's shape
		fog_controller.add_light_source(self, 60.0, direction, 1.8)
	
	# Rotate fireball to face movement direction (straight from player)
	if direction.length() > 0:
		var angle = direction.angle()
		# Face the direction of movement
		fireball_sprite.rotation = angle
		# Rotate glow to match
		if glow_sprite:
			glow_sprite.rotation = angle
		# Rotate particles to emit backwards (opposite to movement)
		trail_particles.rotation = angle + PI

func _physics_process(delta):
	# Freeze attack when paused
	if get_tree().paused:
		return
	# Move the attack
	position += direction * SPEED * delta
	
	# Continuously reveal unexplored areas around fireball
	if unexplored_controller:
		unexplored_controller._reveal_area(global_position, 60.0)
	
	# Count down timer
	time_left -= delta
	if time_left <= 0:
		# Remove from light sources before freeing
		if fog_controller:
			fog_controller.remove_light_source(self)
		queue_free()

func _on_attack_effect_body_entered(body):
	# don't hit player
	if body.name == "Player":
		return
	
	# ignore gates - fireballs pass through them
	if body.is_in_group("gates"):
		return

	# if it hits a zombie, damage
	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)
		# Remove from light sources before freeing
		if fog_controller:
			fog_controller.remove_light_source(self)
		queue_free()
		return

	# if it hits a wall, stop 
	if body.is_in_group("walls"):
		# Remove from light sources before freeing
		if fog_controller:
			fog_controller.remove_light_source(self)
		queue_free()
