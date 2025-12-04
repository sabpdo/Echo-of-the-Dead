extends Control

var points: int = 99999
var popup_scene = preload("res://scenes/score_popup.tscn")

# Time survived tracking (in seconds)
var time_survived: float = 0.0
var show_time_survived: bool = false

@onready var points_label: Label = $Points

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if points_label:
		points_label.text = "Points: " + str(points)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Always track time from the start of the run
	time_survived += delta
	
	if points_label:
		if show_time_survived:
			var total_seconds: int = int(time_survived)
			var minutes: int = total_seconds / 60
			var seconds: int = total_seconds % 60
			var time_text := str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2)
			points_label.text = "Points: " + str(points) + "\nTime survived: " + time_text
		else:
			points_label.text = "Points: " + str(points)

func enable_time_survived_display():
	show_time_survived = true

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
