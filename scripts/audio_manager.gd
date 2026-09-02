extends Node

var _players: Dictionary = {}
var _streams: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_streams = {
		"attack": _beep(220.0, 0.07, 0.22),
		"critical": _beep(520.0, 0.12, 0.28),
		"enemy_death": _beep(140.0, 0.16, 0.25),
		"coin": _beep(880.0, 0.08, 0.2),
		"upgrade": _beep(660.0, 0.1, 0.22),
		"boss": _beep(90.0, 0.22, 0.3),
		"level_up": _beep(740.0, 0.14, 0.24),
		"prestige": _beep(320.0, 0.28, 0.26),
		"button_click": _beep(400.0, 0.04, 0.16),
		"hero_down": _beep(110.0, 0.2, 0.28),
		"pause_open": _beep(280.0, 0.08, 0.18),
		"pause_close": _beep(180.0, 0.08, 0.16),
	}
	for id in _streams.keys():
		var player := AudioStreamPlayer.new()
		player.stream = _streams[id]
		player.volume_db = -8.0
		player.bus = "SFX"
		add_child(player)
		_players[id] = player


func play(id: String) -> void:
	if not _players.has(id):
		return
	var player: AudioStreamPlayer = _players[id]
	if player.playing:
		player.stop()
	player.play()


func _beep(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var frames := maxi(2, int(sample_rate * duration))
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var t := float(i) / float(sample_rate)
		var env := 1.0 - t / duration
		var sample := int(clampf(sin(t * freq * TAU) * volume * env, -1.0, 1.0) * 32767.0)
		var unsigned := sample if sample >= 0 else sample + 65536
		data[i * 2] = unsigned & 0xFF
		data[i * 2 + 1] = (unsigned >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream
