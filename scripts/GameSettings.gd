extends Node

# Singleton to store game settings

enum Difficulty {
	EASY,
	MEDIUM,
	HARD
}

var current_difficulty: Difficulty = Difficulty.MEDIUM

# Audio settings
const MASTER_BUS_NAME = "Master"
const MUSIC_BUS_NAME = "Music"
const SFX_BUS_NAME = "SFX"

var master_volume: float = 1.0
var music_enabled: bool = true
var sfx_enabled: bool = true

func _ready():
	_setup_audio_buses()
	_load_audio_settings()

func _setup_audio_buses():
	# Create Music bus if it doesn't exist
	if AudioServer.get_bus_index(MUSIC_BUS_NAME) == -1:
		var music_bus_index = AudioServer.bus_count
		AudioServer.add_bus(music_bus_index)
		AudioServer.set_bus_name(music_bus_index, MUSIC_BUS_NAME)
		AudioServer.set_bus_send(music_bus_index, MASTER_BUS_NAME)
	
	# Create SFX bus if it doesn't exist
	if AudioServer.get_bus_index(SFX_BUS_NAME) == -1:
		var sfx_bus_index = AudioServer.bus_count
		AudioServer.add_bus(sfx_bus_index)
		AudioServer.set_bus_name(sfx_bus_index, SFX_BUS_NAME)
		AudioServer.set_bus_send(sfx_bus_index, MASTER_BUS_NAME)

func _load_audio_settings():
	# Load saved settings or use defaults
	if ConfigFile.new().load("user://settings.cfg") == OK:
		var config = ConfigFile.new()
		config.load("user://settings.cfg")
		master_volume = config.get_value("audio", "master_volume", 1.0)
		music_enabled = config.get_value("audio", "music_enabled", true)
		sfx_enabled = config.get_value("audio", "sfx_enabled", true)
	
	_apply_audio_settings()

func _save_audio_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_enabled", music_enabled)
	config.set_value("audio", "sfx_enabled", sfx_enabled)
	config.save("user://settings.cfg")

func _apply_audio_settings():
	# Apply master volume
	var master_bus_index = AudioServer.get_bus_index(MASTER_BUS_NAME)
	if master_bus_index != -1:
		AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(master_volume))
	
	# Apply music mute
	var music_bus_index = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	if music_bus_index != -1:
		AudioServer.set_bus_mute(music_bus_index, not music_enabled)
	
	# Apply SFX mute
	var sfx_bus_index = AudioServer.get_bus_index(SFX_BUS_NAME)
	if sfx_bus_index != -1:
		AudioServer.set_bus_mute(sfx_bus_index, not sfx_enabled)

func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	_apply_audio_settings()
	_save_audio_settings()

func set_music_enabled(enabled: bool):
	music_enabled = enabled
	_apply_audio_settings()
	_save_audio_settings()

func set_sfx_enabled(enabled: bool):
	sfx_enabled = enabled
	_apply_audio_settings()
	_save_audio_settings()

# Play click sound for UI buttons
var _click_player: AudioStreamPlayer = null

func play_click_sound():
	if not sfx_enabled:
		return
	
	if not _click_player:
		_click_player = AudioStreamPlayer.new()
		_click_player.bus = SFX_BUS_NAME
		_click_player.volume_db = -5.0  # Slightly quieter
		add_child(_click_player)
	
	var click_stream = AudioLibrary.get_stream("click", false)
	if click_stream:
		_click_player.stream = click_stream
		_click_player.play()

# Difficulty settings for zombie spawning
func get_zombie_spawn_interval() -> float:
	match current_difficulty:
		Difficulty.EASY:
			return 5.0  # Spawn every 5 seconds (slower)
		Difficulty.MEDIUM:
			return 3.0  # Spawn every 3 seconds (normal)
		Difficulty.HARD:
			return 1.5  # Spawn every 1.5 seconds (fast!)
		_:
			return 3.0

func get_max_zombies() -> int:
	match current_difficulty:
		Difficulty.EASY:
			return 10  # Fewer zombies
		Difficulty.MEDIUM:
			return 20  # Normal amount
		Difficulty.HARD:
			return 40  # Many zombies!
		_:
			return 20

func get_zombie_speed_multiplier() -> float:
	match current_difficulty:
		Difficulty.EASY:
			return 0.7  # 70% speed
		Difficulty.MEDIUM:
			return 1.0  # Normal speed
		Difficulty.HARD:
			return 1.4  # 140% speed
		_:
			return 1.0

func get_zombie_health_multiplier() -> float:
	match current_difficulty:
		Difficulty.EASY:
			return 0.6  # 60% health
		Difficulty.MEDIUM:
			return 1.0  # Normal health
		Difficulty.HARD:
			return 1.5  # 150% health
		_:
			return 1.0

func set_difficulty(difficulty: Difficulty):
	current_difficulty = difficulty
	print("Difficulty set to: ", Difficulty.keys()[difficulty])

func get_difficulty_name() -> String:
	return Difficulty.keys()[current_difficulty]

