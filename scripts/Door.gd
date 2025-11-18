extends StaticBody2D

@onready var interaction_area = $InteractionArea
@onready var closed_sprite = $ClosedDoorSprite
@onready var open_sprite = $OpenDoorSprite
@onready var interaction_button = $InteractionButton

var is_unlocked: bool = false
var player_nearby: bool = false
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
	
	# Setup button
	if interaction_button:
		interaction_button.visible = false
		interaction_button.pressed.connect(_on_button_pressed)
		_update_button_text()

func _process(_delta):
	# Update button visibility
	if interaction_button:
		# Only show button when player is nearby and door is locked
		interaction_button.visible = player_nearby and not is_unlocked

func _on_body_entered(body):
	if body.is_in_group("player") or body.name == "Player":
		body.nearby_door = self
		player_nearby = true

func _on_body_exited(body):
	if body.is_in_group("player") or body.name == "Player":
		if body.nearby_door == self:
			body.nearby_door = null
		player_nearby = false

func set_unlocked(unlocked: bool):
	is_unlocked = unlocked
	
	# Disable collision when unlocked
	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = unlocked
	
	# Change visual appearance when unlocked
	if closed_sprite and open_sprite:
		closed_sprite.visible = not unlocked
		open_sprite.visible = unlocked
	
	_update_button_text()
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

func _on_button_pressed():
	unlock()

func _update_button_text():
	if interaction_button:
		var label = interaction_button.get_node_or_null("Label")
		if label:
			if is_unlocked:
				label.text = "Open"
			else:
				label.text = "Unlock ($" + str(COST_POINTS) + ")"
