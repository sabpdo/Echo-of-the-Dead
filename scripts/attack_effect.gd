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
@onready var trail_particles = $TrailParticles

var fog_controller: Node = null

func _ready():
	# Wait a frame for direction to be set
	await get_tree().process_frame
	
	# Register as light source to clear fog
	fog_controller = get_node("/root/Main/FogLayer/FogController")
	if fog_controller and direction.length() > 0:
		# Use circular fog clearing (aspect ratio 1.0)
		fog_controller.add_light_source(self, 120.0, direction, 1.0)
	
	# Rotate fireball to face movement direction (straight from player)
	if direction.length() > 0:
		# Face the direction of movement
		fireball_sprite.rotation = direction.angle()
		# Rotate particles to emit backwards (opposite to movement)
		trail_particles.rotation = direction.angle() + PI

func _physics_process(delta):
	# Freeze attack when paused
	if get_tree().paused:
		return
	# Move the attack
	position += direction * SPEED * delta
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
