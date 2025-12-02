extends Node
class_name AudioLibrary

## Central list of placeholder audio paths used across the project.
## These can be swapped for finished assets later without touching gameplay code.
const AUDIO_PATHS := {
	"background_music": "res://audio/background_music.wav",
	"monster_growl": "res://audio/monster.ogg",
	"spell_cast": "res://audio/spell.wav",
	"echolocation_ping": "res://audio/echolocation.wav",
	"fireball_cast": "res://audio/fireball.wav",
	"click": "res://audio/click.wav"
}

static var _cache: Dictionary = {}
static var _preload_complete: bool = false

## Preload all audio files at once for web export compatibility
## Call this early in the game (e.g., from GameSettings._ready())
static func preload_all() -> void:
	if _preload_complete:
		return
	
	print("Preloading audio files...")
	var loaded_count: int = 0
	var failed_count: int = 0
	
	for key in AUDIO_PATHS.keys():
		var stream = get_stream(key, false)  # Preload without warnings
		if stream:
			loaded_count += 1
		else:
			failed_count += 1
			print("  Failed to preload: %s" % key)
	
	_preload_complete = true
	print("Audio preload complete. Loaded: %d, Failed: %d" % [loaded_count, failed_count])
	
	# Diagnostic: List what's available in the audio directory (for debugging)
	if failed_count > 0:
		_diagnose_audio_directory()

static func get_stream(key: StringName, warn_if_missing: bool = true) -> AudioStream:
	if _cache.has(key):
		return _cache[key]
	
	var path: String = AUDIO_PATHS.get(String(key), "")
	if path.is_empty():
		if warn_if_missing:
			push_warning("No audio path configured for key '%s'." % key)
		_cache[key] = null
		return null
	
	# Web export workaround: Strip .import extension if present
	# (Sometimes paths can get corrupted with .import extensions)
	if path.ends_with(".import"):
		path = path.replace(".import", "")
	
	# Try multiple loading strategies for web export compatibility
	var stream: AudioStream = null
	var error_msg: String = ""
	
	# Strategy 1: Try ResourceLoader.load() (preferred for web exports)
	if ResourceLoader.exists(path):
		stream = ResourceLoader.load(path) as AudioStream
		if stream:
			_cache[key] = stream
			return stream
		else:
			error_msg += "ResourceLoader.load() failed for %s. " % path
	
	# Strategy 2: Try load() directly (fallback for web exports)
	# Sometimes ResourceLoader.exists() returns false but load() still works
	stream = load(path) as AudioStream
	if stream:
		_cache[key] = stream
		return stream
	else:
		error_msg += "load() failed for %s. " % path
	
	# Strategy 3: Check if .import file exists (indicates file should be loadable)
	var import_path: String = path + ".import"
	if ResourceLoader.exists(import_path):
		# Try loading again with both methods
		stream = ResourceLoader.load(path) as AudioStream
		if not stream:
			stream = load(path) as AudioStream
		if stream:
			_cache[key] = stream
			return stream
		else:
			error_msg += ".import file exists but loading failed. "
	
	# Strategy 4: Try without checking exists() first (web export workaround)
	# Some web exports don't report exists() correctly but can still load
	# Just try load() one more time without exists check
	stream = load(path) as AudioStream
	if stream:
		_cache[key] = stream
		return stream
	
	if warn_if_missing:
		var full_error: String = "Failed to load audio '%s' from %s. " % [key, path]
		full_error += error_msg
		full_error += "Check export settings to ensure audio files are included."
		push_error(full_error)
		print("AudioLibrary: ", full_error)
	
	_cache[key] = null
	return null

static func get_audio_path(key: StringName) -> String:
	return AUDIO_PATHS.get(String(key), "")

## Diagnostic function to help debug web export audio issues
static func _diagnose_audio_directory() -> void:
	print("=== Audio Library Diagnostic ===")
	print("Checking audio directory contents...")
	
	# Try to list directory contents (works in editor, may not work in web export)
	var audio_dir: String = "res://audio"
	if ResourceLoader.exists(audio_dir):
		# Try using ResourceLoader to see what's available
		print("Audio directory exists: %s" % audio_dir)
	else:
		print("WARNING: Audio directory not found: %s" % audio_dir)
	
	# Check each audio path
	for key in AUDIO_PATHS.keys():
		var path: String = AUDIO_PATHS[key]
		var exists: bool = ResourceLoader.exists(path)
		var import_exists: bool = ResourceLoader.exists(path + ".import")
		print("  %s: path=%s, exists=%s, .import exists=%s" % [key, path, exists, import_exists])
	
	print("=== End Diagnostic ===")
