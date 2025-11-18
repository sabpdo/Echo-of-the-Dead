extends StaticBody2D

@onready var visual = $Visual
@onready var collision_shape = $CollisionShape2D
@onready var zombie_detection_area = $ZombieDetectionArea

var zombies_inside: int = 0

func _ready():
	# Gate now uses mesh.png sprite
	# Gate is set to collision_layer = 1 (player layer only)
	# Zombies should be on collision layer 2, so they can pass through gates
	# The gate will always block players (layer 1) but allow zombies (layer 2) through
	# No need to dynamically change collision - zombies on layer 2 won't collide with gates on layer 1
	pass

