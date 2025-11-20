extends Control

var points: int = 0
var popup_scene = preload("res://scenes/score_popup.tscn")

@onready var points_label: Label = $Points

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if points_label:
		points_label.text = "Points: " + str(points)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if points_label:
		points_label.text = "Points: " + str(points)

func add_points(amount: int):
	points += amount
	show_score_popup(amount)

func show_score_popup(amount: int):
	# Get UILayer to add popup to
	var ui_layer = get_node("/root/Main/UILayer")
	if not ui_layer:
		return
	
	# Position popup to the right of the points counter
	var popup_position = global_position + Vector2(size.x + 10, size.y / 2)
	
	# Create popup
	var popup = popup_scene.instantiate()
	popup.setup(amount, popup_position)
	ui_layer.add_child(popup)
