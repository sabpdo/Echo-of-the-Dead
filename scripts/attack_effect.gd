extends Area2D

# speed of the attack
const SPEED = 400.0
# duration of the attack
const DURATION = 0.4
# how much the zombie is damaged
const DAMAGE = 25

var direction: Vector2 = Vector2.ZERO

var time_left := DURATION

#func _ready():
	#await get_tree().create_timer(DURATION).timeout
	#queue_free()

func _physics_process(delta):
	# Freeze attack when paused
	if get_tree().paused:
		return
	# Move the attack
	position += direction * SPEED * delta
	# Count down timer
	time_left -= delta
	if time_left <= 0:
		queue_free()

func _on_attack_effect_body_entered(body):
	# don't hit player
	if body.name == "Player":
		return

	# if it hits a zombie, damage
	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)
		queue_free()
		return

	# if it hits a wall, stop 
	if body.is_in_group("walls"):
		queue_free()
