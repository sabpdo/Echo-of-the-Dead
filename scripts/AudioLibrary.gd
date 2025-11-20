extends Node
class_name AudioLibrary

## Central list of placeholder audio paths used across the project.
## These can be swapped for finished assets later without touching gameplay code.
const AUDIO_PATHS := {
	"background_music": "res://audio/background_music.wav",
	"monster_growl": "res://audio/monster.ogg",
	"spell_cast": "res://audio/spell.wav",
	"echolocation_ping": "res://audio/echolocation.wav",
	"fireball_cast": "res://audio/fireball.wav"
}

static var _cache: Dictionary = {}

static func get_stream(key: StringName, warn_if_missing: bool = true) -> AudioStream:
	if _cache.has(key):
		return _cache[key]
	
	var path := AUDIO_PATHS.get(String(key), "")
	if path.is_empty():
		if warn_if_missing:
			push_warning("No audio path configured for key '%s'." % key)
		_cache[key] = null
		return null
	
	if ResourceLoader.exists(path):
		var stream: AudioStream = load(path)
		_cache[key] = stream
		return stream
	
	if warn_if_missing:
		push_warning("Placeholder audio not found at %s. Add the file to enable sound." % path)
	_cache[key] = null
	return null

static func get_audio_path(key: StringName) -> String:
	return AUDIO_PATHS.get(String(key), "")

