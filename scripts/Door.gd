extends StaticBody2D

@onready var interaction_area = $InteractionArea
@onready var visual = $Visual

var is_unlocked: bool = false
const INTERACTION_RADIUS: float = 80.0
const COST_POINTS: int = 100

signal door_unlocked

func _ready():
	# Start locked
	set_unlocked(false)
	
	# Connect interaction signal
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player") or body.name == "Player":
		body.nearby_door = self

func _on_body_exited(body):
	if body.is_in_group("player") or body.name == "Player":
		if body.nearby_door == self:
			body.nearby_door = null

func set_unlocked(unlocked: bool):
	is_unlocked = unlocked
	
	# Disable collision when unlocked
	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = unlocked
	
	# Change visual appearance when unlocked
	if visual:
		if unlocked:
			visual.color = Color(0.2, 0.6, 0.2, 0.5)  # Green, semi-transparent when unlocked
		else:
			visual.color = Color(0.6, 0.4, 0.2, 1)  # Brown when locked
	
	door_unlocked.emit()

func unlock():
	# Don't allow unlocking if already unlocked
	if is_unlocked:
		return
	
	# Check if player has enough points
	var points_counters = get_tree().get_nodes_in_group("points_counter")
	if points_counters.size() > 0:
		var points_counter = points_counters[0]
		if points_counter.points >= COST_POINTS:
			# Deduct points (using negative amount to subtract)
			points_counter.add_points(-COST_POINTS)
			
			# Unlock door
			set_unlocked(true)
		else:
			# Not enough points - could show a message here
			print("Not enough points! Need ", COST_POINTS, " points.")
