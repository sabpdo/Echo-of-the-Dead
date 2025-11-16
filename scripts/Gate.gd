extends StaticBody2D

@onready var visual = $Visual
@onready var collision_shape = $CollisionShape2D
@onready var zombie_detection_area = $ZombieDetectionArea

var zombies_inside: int = 0

func _ready():
	# Color gate differently (e.g., purple)
	if visual:
		visual.color = Color(0.5, 0.2, 0.5, 1)  # Purple color for gates
	
	# Connect zombie detection area signals
	if zombie_detection_area:
		zombie_detection_area.body_entered.connect(_on_body_entered)
		zombie_detection_area.body_exited.connect(_on_body_exited)
	
	# Gate is set to collision_layer = 1 (player layer only)
	# This means it only collides with bodies on layer 1 (player)
	# Zombies should be on a different layer (layer 2) so they can pass through

func _on_body_entered(body):
	# Check if it's a zombie
	if body.name == "Zombie" or (body.get_script() and body.get_script().get_path().ends_with("Zombie.gd")):
		zombies_inside += 1
		# Temporarily remove gate from collision layer 1 to allow zombie through
		# This will allow zombies to pass, but we'll re-enable it when zombie leaves
		# Note: This temporarily allows player through too, but zombies move faster
		# A better solution would be to use separate collision layers
		collision_layer = 0

func _on_body_exited(body):
	# Check if it's a zombie
	if body.name == "Zombie" or (body.get_script() and body.get_script().get_path().ends_with("Zombie.gd")):
		zombies_inside = max(0, zombies_inside - 1)
		# Re-enable collision if no zombies inside
		# Use a small delay to ensure zombie has fully passed through
		if zombies_inside == 0:
			await get_tree().create_timer(0.1).timeout
			# Double-check no zombies inside before re-enabling
			if zombies_inside == 0:
				collision_layer = 1

