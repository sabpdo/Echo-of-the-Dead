extends AudioStreamPlayer2D

const AudioLibrary = preload("res://scripts/AudioLibrary.gd")

@export var audio_key: StringName
@export var autoplay_on_ready: bool = false
@export var restart_on_trigger: bool = true

func _ready():
	_ensure_stream()
	if autoplay_on_ready and stream:
		play()

func play_cue():
	_ensure_stream()
	if not stream:
		return
	if restart_on_trigger and playing:
		stop()
	play()

func _ensure_stream():
	if stream or audio_key.is_empty():
		return
	stream = AudioLibrary.get_stream(audio_key)

