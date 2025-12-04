extends Node2D

@onready var background_music = $BackgroundMusic

func _ready():
	# Start background music when Main scene loads
	# This ensures music continues from menu to game
	if background_music:
		if background_music.has_method("play_cue"):
			background_music.play_cue()
		elif not background_music.playing:
			background_music.play()
