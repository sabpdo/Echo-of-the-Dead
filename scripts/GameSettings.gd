extends Node

# Singleton to store game settings

enum Difficulty {
	EASY,
	MEDIUM,
	HARD
}

var current_difficulty: Difficulty = Difficulty.MEDIUM

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

