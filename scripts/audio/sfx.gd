extends Node
## Hệ thống âm thanh và nhạc nền toàn game (autoload "Sfx").
## Tạo 2 bus "Music" và "SFX" bằng mã, giới hạn tối đa 8 tiếng SFX phát cùng lúc.

const MAX_VOICES: int = 8
const MIN_INTERVAL_MS: int = 50
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"

const SFX_FILES: Dictionary = {
	"slash": "res://assets/audio/sfx/slash.wav",
	"arrow": "res://assets/audio/sfx/arrow.wav",
	"shoot": "res://assets/audio/sfx/shoot.wav",
	"explode": "res://assets/audio/sfx/explode.wav",
	"player_hurt": "res://assets/audio/sfx/player_hurt.wav",
	"enemy_hurt": "res://assets/audio/sfx/enemy_hurt.wav",
	"enemy_die": "res://assets/audio/sfx/enemy_die.wav",
	"coin": "res://assets/audio/sfx/coin.wav",
	"pickup_weapon": "res://assets/audio/sfx/pickup_weapon.wav",
	"chest_open": "res://assets/audio/sfx/chest_open.wav",
	"buy": "res://assets/audio/sfx/buy.wav",
	"buy_fail": "res://assets/audio/sfx/buy_fail.wav",
	"door_close": "res://assets/audio/sfx/door_close.wav",
	"boss_appear": "res://assets/audio/sfx/boss_appear.wav",
	"boss_morph": "res://assets/audio/sfx/boss_morph.wav",
	"level_clear": "res://assets/audio/sfx/level_clear.wav",
	"ui_click": "res://assets/audio/sfx/ui_click.wav",
	"player_die": "res://assets/audio/sfx/player_die.wav",
	"skill": "res://assets/audio/sfx/skill.wav",
	"hit_flesh": "res://assets/audio/sfx/hit_flesh.wav",
	"hit_bullet": "res://assets/audio/sfx/hit_bullet.wav",
	"hit_metal": "res://assets/audio/sfx/hit_metal.wav",
	"hit_wall": "res://assets/audio/sfx/hit_wall.wav",
	"hit_wood": "res://assets/audio/sfx/hit_wood.wav",
	"hit_crit": "res://assets/audio/sfx/hit_crit.wav",
	"hit_boss": "res://assets/audio/sfx/hit_boss.wav",
	"pickup_material": "res://assets/audio/sfx/pickup_material.wav",
	"forge": "res://assets/audio/sfx/forge.wav",
}

const MUSIC_FILES: Dictionary = {
	"lobby": "res://assets/audio/music/lobby.wav",
	"battle": "res://assets/audio/music/battle.wav",
	"boss": "res://assets/audio/music/boss.wav",
}

var _sfx_streams: Dictionary = {}
var _music_streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _cursor: int = 0
var _music_player: AudioStreamPlayer = null
var _current_music: String = ""
var _music_volume: float = 0.65
var _sfx_volume: float = 0.85
var _last_play_ms: Dictionary = {}
var _play_counts: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_SFX)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player)

	for id in SFX_FILES:
		var path: String = str(SFX_FILES[id])
		if ResourceLoader.exists(path):
			var st: Resource = load(path)
			if st is AudioStream:
				_sfx_streams[str(id)] = st

	for id in MUSIC_FILES:
		var path: String = str(MUSIC_FILES[id])
		if ResourceLoader.exists(path):
			var st: Resource = load(path)
			if st is AudioStreamWAV:
				var wav: AudioStreamWAV = st as AudioStreamWAV
				wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
				wav.loop_begin = 0
				wav.loop_end = int(round(wav.get_length() * float(wav.mix_rate)))
				_music_streams[str(id)] = wav
			elif st is AudioStream:
				_music_streams[str(id)] = st

	var g: Node = get_tree().root.get_node_or_null("Global")
	if g != null:
		_music_volume = float(g.settings.get("music", 0.8))
		_sfx_volume = float(g.settings.get("sfx", 0.9))
	set_music_volume(_music_volume)
	set_sfx_volume(_sfx_volume)


func _ensure_bus(bus_name: String) -> int:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")
	return idx


func play(id: String, volume_db: float = 0.0, pitch_jitter: float = 0.08) -> void:
	var stream_val: Variant = _sfx_streams.get(id, null)
	if stream_val == null:
		return
	var now_ms: int = Time.get_ticks_msec()
	if MIN_INTERVAL_MS > 0 and _last_play_ms.has(id):
		if now_ms - int(_last_play_ms[id]) < MIN_INTERVAL_MS:
			return
	_last_play_ms[id] = now_ms
	var stream: AudioStream = stream_val as AudioStream
	var chosen: AudioStreamPlayer = null
	for p in _pool:
		if is_instance_valid(p) and not p.playing:
			chosen = p
			break
	if chosen == null:
		if _pool.size() < MAX_VOICES:
			chosen = AudioStreamPlayer.new()
			chosen.bus = BUS_SFX
			chosen.process_mode = Node.PROCESS_MODE_ALWAYS
			add_child(chosen)
			_pool.append(chosen)
		elif not _pool.is_empty():
			_cursor = _cursor % _pool.size()
			chosen = _pool[_cursor]
			_cursor = (_cursor + 1) % _pool.size()
			chosen.stop()
	if chosen == null:
		return
	chosen.stream = stream
	chosen.volume_db = volume_db
	chosen.pitch_scale = randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter) if pitch_jitter > 0.0 else 1.0
	chosen.play()
	_play_counts[id] = int(_play_counts.get(id, 0)) + 1


func play_music(id: String) -> void:
	if id == "":
		stop_music()
		return
	if id == _current_music and _music_player.playing:
		return
	var stream_val: Variant = _music_streams.get(id, null)
	if stream_val == null:
		return
	_current_music = id
	_music_player.stream = stream_val as AudioStream
	_music_player.play()


func stop_music() -> void:
	_current_music = ""
	if _music_player != null:
		_music_player.stop()


func stop_all_sfx() -> void:
	for p in _pool:
		if is_instance_valid(p):
			p.stop()
	_last_play_ms.clear()


func cleanup() -> void:
	stop_music()
	stop_all_sfx()
	if _music_player != null and is_instance_valid(_music_player):
		_music_player.stream = null
	for p in _pool:
		if is_instance_valid(p):
			p.stream = null
			p.queue_free()
	_pool.clear()
	_sfx_streams.clear()
	_music_streams.clear()


func play_count(id: String) -> int:
	return int(_play_counts.get(id, 0))


func reset_play_counts() -> void:
	_play_counts.clear()


func active_sfx_count() -> int:
	var count: int = 0
	for p in _pool:
		if is_instance_valid(p) and p.playing:
			count += 1
	return count


func current_music() -> String:
	return _current_music


func set_music_volume(v: float) -> void:
	_music_volume = clampf(v, 0.0, 1.0)
	_apply_bus_volume(BUS_MUSIC, _music_volume)


func set_sfx_volume(v: float) -> void:
	_sfx_volume = clampf(v, 0.0, 1.0)
	_apply_bus_volume(BUS_SFX, _sfx_volume)


func get_music_volume() -> float:
	return _music_volume


func get_sfx_volume() -> float:
	return _sfx_volume


func _apply_bus_volume(bus_name: String, v: float) -> void:
	var idx: int = _ensure_bus(bus_name)
	if v <= 0.0001:
		AudioServer.set_bus_mute(idx, true)
		AudioServer.set_bus_volume_db(idx, -80.0)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(v))
