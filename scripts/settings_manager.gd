extends Node

const SETTINGS_PATH := "user://settings.cfg"

const DEFAULT_MASTER_VOLUME := 1.0
const DEFAULT_MUSIC_VOLUME := 1.0
const DEFAULT_SFX_VOLUME := 1.0
const DEFAULT_MUTE_ALL := false
const DEFAULT_DAMAGE_NUMBERS := true
const DEFAULT_SCREEN_SHAKE := true
const DEFAULT_AUTO_ADVANCE := true
const DEFAULT_FULLSCREEN := false
const DEFAULT_VSYNC := true
const DEFAULT_RESOLUTION := Vector2i(1280, 720)

const RESOLUTION_PRESETS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

var master_volume: float = DEFAULT_MASTER_VOLUME
var music_volume: float = DEFAULT_MUSIC_VOLUME
var sfx_volume: float = DEFAULT_SFX_VOLUME
var mute_all: bool = DEFAULT_MUTE_ALL
var damage_numbers: bool = DEFAULT_DAMAGE_NUMBERS
var screen_shake: bool = DEFAULT_SCREEN_SHAKE
var auto_advance: bool = DEFAULT_AUTO_ADVANCE
var fullscreen: bool = DEFAULT_FULLSCREEN
var vsync: bool = DEFAULT_VSYNC
var resolution: Vector2i = DEFAULT_RESOLUTION

var _saved: Dictionary = {}


func _ready() -> void:
	load_settings()
	apply_all()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)
	if err != OK:
		_apply_defaults_to_fields()
		_capture_saved()
		return
	master_volume = clampf(float(cfg.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)), 0.0, 1.0)
	music_volume = clampf(float(cfg.get_value("audio", "music_volume", DEFAULT_MUSIC_VOLUME)), 0.0, 1.0)
	sfx_volume = clampf(float(cfg.get_value("audio", "sfx_volume", DEFAULT_SFX_VOLUME)), 0.0, 1.0)
	mute_all = bool(cfg.get_value("audio", "mute_all", DEFAULT_MUTE_ALL))
	damage_numbers = bool(cfg.get_value("gameplay", "damage_numbers", DEFAULT_DAMAGE_NUMBERS))
	screen_shake = bool(cfg.get_value("gameplay", "screen_shake", DEFAULT_SCREEN_SHAKE))
	auto_advance = bool(cfg.get_value("gameplay", "auto_advance", DEFAULT_AUTO_ADVANCE))
	fullscreen = bool(cfg.get_value("video", "fullscreen", DEFAULT_FULLSCREEN))
	vsync = bool(cfg.get_value("video", "vsync", DEFAULT_VSYNC))
	resolution = Vector2i(
		int(cfg.get_value("video", "resolution_x", DEFAULT_RESOLUTION.x)),
		int(cfg.get_value("video", "resolution_y", DEFAULT_RESOLUTION.y))
	)
	resolution = _clamped_resolution(resolution)
	_capture_saved()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "mute_all", mute_all)
	cfg.set_value("gameplay", "damage_numbers", damage_numbers)
	cfg.set_value("gameplay", "screen_shake", screen_shake)
	cfg.set_value("gameplay", "auto_advance", auto_advance)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "vsync", vsync)
	cfg.set_value("video", "resolution_x", resolution.x)
	cfg.set_value("video", "resolution_y", resolution.y)
	var err := cfg.save(SETTINGS_PATH)
	if err != OK:
		push_error("Could not save settings: %s" % error_string(err))
		return
	_capture_saved()


func is_dirty() -> bool:
	return _snapshot() != _saved


func discard_changes() -> void:
	_restore(_saved)
	apply_all()


func reset_to_defaults() -> void:
	_apply_defaults_to_fields()
	apply_all()
	save_settings()


func apply_all() -> void:
	_apply_audio()
	_apply_video()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_audio()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_audio()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_audio()


func set_mute_all(value: bool) -> void:
	mute_all = value
	_apply_audio()


func set_damage_numbers(value: bool) -> void:
	damage_numbers = value


func set_screen_shake(value: bool) -> void:
	screen_shake = value


func set_auto_advance(value: bool) -> void:
	auto_advance = value


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_video()


func set_vsync(value: bool) -> void:
	vsync = value
	_apply_video()


func set_resolution(value: Vector2i) -> void:
	resolution = _clamped_resolution(value)
	_apply_video()


func get_available_resolutions() -> Array[Vector2i]:
	var screen := DisplayServer.screen_get_size()
	var result: Array[Vector2i] = []
	for preset in RESOLUTION_PRESETS:
		if preset.x <= screen.x and preset.y <= screen.y:
			result.append(preset)
	if result.is_empty():
		result.append(Vector2i(mini(DEFAULT_RESOLUTION.x, screen.x), mini(DEFAULT_RESOLUTION.y, screen.y)))
	var current := _clamped_resolution(resolution)
	if not result.has(current):
		result.append(current)
	return result


func _apply_audio() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)
	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_mute(master_idx, mute_all)


func _apply_video() -> void:
	var window := get_window()
	if window == null:
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	if fullscreen:
		window.mode = Window.MODE_FULLSCREEN
		return
	window.mode = Window.MODE_WINDOWED
	var size := _clamped_resolution(resolution)
	window.size = size
	var screen_index := window.current_screen
	var screen_pos := DisplayServer.screen_get_position(screen_index)
	var screen_size := DisplayServer.screen_get_size(screen_index)
	window.position = screen_pos + (screen_size - size) / 2


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	if linear <= 0.001:
		AudioServer.set_bus_volume_db(idx, -80.0)
	else:
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))


func _apply_defaults_to_fields() -> void:
	master_volume = DEFAULT_MASTER_VOLUME
	music_volume = DEFAULT_MUSIC_VOLUME
	sfx_volume = DEFAULT_SFX_VOLUME
	mute_all = DEFAULT_MUTE_ALL
	damage_numbers = DEFAULT_DAMAGE_NUMBERS
	screen_shake = DEFAULT_SCREEN_SHAKE
	auto_advance = DEFAULT_AUTO_ADVANCE
	fullscreen = DEFAULT_FULLSCREEN
	vsync = DEFAULT_VSYNC
	resolution = DEFAULT_RESOLUTION


func _snapshot() -> Dictionary:
	return {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"mute_all": mute_all,
		"damage_numbers": damage_numbers,
		"screen_shake": screen_shake,
		"auto_advance": auto_advance,
		"fullscreen": fullscreen,
		"vsync": vsync,
		"resolution_x": resolution.x,
		"resolution_y": resolution.y,
	}


func _capture_saved() -> void:
	_saved = _snapshot()


func _restore(data: Dictionary) -> void:
	if data.is_empty():
		_apply_defaults_to_fields()
		return
	master_volume = float(data.get("master_volume", DEFAULT_MASTER_VOLUME))
	music_volume = float(data.get("music_volume", DEFAULT_MUSIC_VOLUME))
	sfx_volume = float(data.get("sfx_volume", DEFAULT_SFX_VOLUME))
	mute_all = bool(data.get("mute_all", DEFAULT_MUTE_ALL))
	damage_numbers = bool(data.get("damage_numbers", DEFAULT_DAMAGE_NUMBERS))
	screen_shake = bool(data.get("screen_shake", DEFAULT_SCREEN_SHAKE))
	auto_advance = bool(data.get("auto_advance", DEFAULT_AUTO_ADVANCE))
	fullscreen = bool(data.get("fullscreen", DEFAULT_FULLSCREEN))
	vsync = bool(data.get("vsync", DEFAULT_VSYNC))
	resolution = Vector2i(int(data.get("resolution_x", DEFAULT_RESOLUTION.x)), int(data.get("resolution_y", DEFAULT_RESOLUTION.y)))


func _clamped_resolution(value: Vector2i) -> Vector2i:
	var screen := DisplayServer.screen_get_size()
	var width := maxi(640, mini(value.x, screen.x))
	var height := maxi(360, mini(value.y, screen.y))
	if width <= 0 or height <= 0:
		return DEFAULT_RESOLUTION
	return Vector2i(width, height)
