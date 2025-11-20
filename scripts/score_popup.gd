extends Control

var score_amount: int = 0
var target_position: Vector2 = Vector2.ZERO

const DURATION = 1.0
const MOVE_DISTANCE = 50.0

@onready var label: Label = $Label

var label_text: String = ""
var label_color: Color = Color.WHITE

func setup(amount: int, position: Vector2):
	score_amount = amount
	target_position = position
	
	# Set label text with + or - sign (store for when label is ready)
	if amount > 0:
		label_text = "+" + str(amount)
		label_color = Color(0.2, 1.0, 0.2, 1.0)  # Green for positive
	else:
		label_text = str(amount)  # Already has - sign
		label_color = Color(1.0, 0.2, 0.2, 1.0)  # Red for negative

func _ready():
	# Set label text now that it's ready
	if label:
		label.text = label_text
		label.modulate = label_color
	
	# Wait a frame for size to be calculated
	await get_tree().process_frame
	
	# Position the popup (in CanvasLayer, use position directly)
	self.position = target_position - size / 2
	
	# Animate the popup
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Move upward
	var start_pos = position
	var end_pos = start_pos + Vector2(0, -MOVE_DISTANCE)
	tween.tween_property(self, "position", end_pos, DURATION)
	
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, DURATION)
	
	# Scale up slightly then back down
	var original_scale = scale
	tween.tween_property(self, "scale", original_scale * 1.2, DURATION * 0.3)
	tween.tween_property(self, "scale", original_scale * 0.8, DURATION * 0.7).set_delay(DURATION * 0.3)
	
	# Remove after animation
	await tween.finished
	queue_free()
