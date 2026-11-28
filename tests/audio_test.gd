extends Node
## Kiểm thử thẻ G02: kiểm tra tệp wav, phát SFX/nhạc nền headless, giới hạn 8 tiếng cùng lúc, điều khiển bus âm lượng.
## Chạy: godot --headless --path . res://tests/audio_test.tscn  -> in "AUDIO TEST OK"

var _fail: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		push_error("KIỂM THỬ THẤT BẠI: " + msg)
		print("  THẤT BẠI: ", msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _ready() -> void:
	get_tree().create_timer(60.0).timeout.connect(func():
		print("AUDIO TEST FAILED: quá thời gian")
		get_tree().quit(1))
	await _frames(1)
	await _run()
	if _fail == 0:
		print("AUDIO TEST OK")
		get_tree().quit(0)
	else:
		print("AUDIO TEST FAILED: %d lỗi" % _fail)
		get_tree().quit(1)


func _scan_gd(dir: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for sub in d.get_directories():
		out += _scan_gd(dir + "/" + sub)
	return out


func _run() -> void:
	print("== (a) Kiểm tra đủ tệp .wav và mã âm thanh được gọi")
	_check(Sfx.SFX_FILES.size() >= 15, "cần tối thiểu 15 SFX, hiện có %d" % Sfx.SFX_FILES.size())
	_check(Sfx.MUSIC_FILES.size() >= 3, "cần 3 bản nhạc nền, hiện có %d" % Sfx.MUSIC_FILES.size())

	for id in Sfx.SFX_FILES:
		var path: String = str(Sfx.SFX_FILES[id])
		_check(FileAccess.file_exists(path), "thiếu tệp SFX: " + path)
		var st: Resource = load(path)
		_check(st is AudioStreamWAV, "không nạp được AudioStreamWAV: " + path)
		if st is AudioStreamWAV:
			var wav: AudioStreamWAV = st as AudioStreamWAV
			_check(wav.mix_rate == 44100 and not wav.stereo, "SFX không phải mono 44100 Hz: " + path)

	for id in Sfx.MUSIC_FILES:
		var path: String = str(Sfx.MUSIC_FILES[id])
		_check(FileAccess.file_exists(path), "thiếu tệp nhạc: " + path)
		var st: Resource = load(path)
		_check(st is AudioStreamWAV, "không nạp được AudioStreamWAV: " + path)
		if st is AudioStreamWAV:
			var wav: AudioStreamWAV = st as AudioStreamWAV
			var len_s: float = wav.get_length()
			_check(wav.mix_rate == 44100 and wav.stereo, "nhạc không phải stereo 44100 Hz: " + path)
			_check(len_s >= 30.0 and len_s <= 60.0, "nhạc %s dài %.2fs (cần 30-60s)" % [path, len_s])

	var rx_sfx := RegEx.new()
	rx_sfx.compile("(?:Sfx|sfx)\\.play\\(\"([a-z0-9_]+)\"\\)")
	var rx_bgm := RegEx.new()
	rx_bgm.compile("(?:Sfx|sfx)\\.play_music\\(\"([a-z0-9_]+)\"\\)")
	var called_sfx: int = 0
	var called_bgm: int = 0
	for path in _scan_gd("res://scripts"):
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var txt: String = f.get_as_text()
		for m in rx_sfx.search_all(txt):
			called_sfx += 1
			var sid: String = m.get_string(1)
			_check(Sfx.SFX_FILES.has(sid), "mã SFX '%s' gọi trong %s chưa khai báo" % [sid, path])
		for m in rx_bgm.search_all(txt):
			called_bgm += 1
			var mid: String = m.get_string(1)
			_check(Sfx.MUSIC_FILES.has(mid), "mã nhạc '%s' gọi trong %s chưa khai báo" % [mid, path])
	_check(called_sfx >= 15, "mã nguồn phải gọi đủ hiệu ứng SFX (gọi %d lần)" % called_sfx)
	_check(called_bgm >= 3, "mã nguồn phải gọi đủ 3 bản nhạc (gọi %d lần)" % called_bgm)

	print("== (b) Phát từng tiếng SFX và nhạc nền headless")
	for id in Sfx.SFX_FILES:
		Sfx.play(str(id))
		await _frames(1)
	Sfx.stop_all_sfx()
	for id in Sfx.MUSIC_FILES:
		var mid: String = str(id)
		Sfx.play_music(mid)
		await _frames(1)
		_check(Sfx.current_music() == mid, "không chuyển được nhạc sang " + mid)
	Sfx.stop_music()

	print("== (c) Phát 20 tiếng cùng lúc, số tiếng đang kêu <= 8")
	Sfx.stop_all_sfx()
	await _frames(1)
	var keys: Array = Sfx.SFX_FILES.keys()
	for i in 20:
		Sfx.play(str(keys[i % keys.size()]))
	var playing_now: int = Sfx.active_sfx_count()
	print("   active_sfx_count sau 20 lần play = %d" % playing_now)
	_check(playing_now > 0, "không có tiếng nào phát ở chế độ headless")
	_check(playing_now <= 8, "vượt quá 8 tiếng cùng lúc (%d)" % playing_now)
	await _frames(2)
	var playing_later: int = Sfx.active_sfx_count()
	_check(playing_later <= 8, "sau 2 khung hình vẫn vượt quá 8 tiếng (%d)" % playing_later)
	Sfx.stop_all_sfx()

	print("== (d) set_music_volume(0) làm bus Music tắt tiếng")
	var music_idx: int = AudioServer.get_bus_index("Music")
	var sfx_idx: int = AudioServer.get_bus_index("SFX")
	_check(music_idx != -1 and sfx_idx != -1, "thiếu bus Music hoặc SFX")
	if music_idx != -1:
		Sfx.set_music_volume(0.0)
		_check(AudioServer.is_bus_mute(music_idx), "set_music_volume(0) không tắt tiếng bus Music")
		_check(AudioServer.get_bus_volume_db(music_idx) <= -79.0, "volume_db bus Music chưa về mức tắt")
		Sfx.set_music_volume(0.5)
		_check(not AudioServer.is_bus_mute(music_idx), "set_music_volume(0.5) không mở lại tiếng bus Music")
		_check(absf(AudioServer.get_bus_volume_db(music_idx) - linear_to_db(0.5)) < 0.05, "sai âm lượng bus Music khi đặt 0.5")
	if sfx_idx != -1:
		Sfx.set_sfx_volume(0.0)
		_check(AudioServer.is_bus_mute(sfx_idx), "set_sfx_volume(0) không tắt tiếng bus SFX")
		Sfx.set_sfx_volume(0.85)
		_check(not AudioServer.is_bus_mute(sfx_idx), "set_sfx_volume(0.85) không mở lại tiếng bus SFX")

	print("== (g) Đủ 7 tiếng va chạm mới")
	for nid in ["hit_flesh", "hit_bullet", "hit_metal", "hit_wall", "hit_wood", "hit_crit", "hit_boss"]:
		_check(Sfx.SFX_FILES.has(nid), "thiếu khóa mới: " + nid)
		var npath: String = str(Sfx.SFX_FILES.get(nid, ""))
		_check(FileAccess.file_exists(npath), "thiếu tệp mới: " + npath)
		_check(load(npath) is AudioStreamWAV, "không nạp được AudioStreamWAV: " + npath)

	print("== (h) Chống ồn: gọi hit_bullet 30 lần trong 1 khung chỉ phát 1 tiếng")
	Sfx.stop_all_sfx()
	await _frames(1)
	Sfx.reset_play_counts()
	for i in 30:
		Sfx.play("hit_bullet")
	_check(Sfx.play_count("hit_bullet") == 1, "hit_bullet phát %d lần trong 1 khung (phải là 1)" % Sfx.play_count("hit_bullet"))
	_check(Sfx.active_sfx_count() == 1, "số kênh kêu = %d (phải là 1)" % Sfx.active_sfx_count())
	Sfx.stop_all_sfx()

	print("== (i) Bắn 1 viên đạn trúng giặc phát hit_bullet")
	await _frames(1)
	Sfx.reset_play_counts()
	var EnemyScript = load("res://scripts/entities/enemy.gd")
	var BulletScript = load("res://scripts/entities/bullet.gd")
	var arena := Node2D.new()
	add_child(arena)
	var foe = EnemyScript.new()
	foe.setup("bo_binh", 1, null)
	foe.position = Vector2(200, 200)
	arena.add_child(foe)
	foe._spawn_t = 0.0
	var proj = BulletScript.new()
	proj.setup(true, Vector2(170, 200), Vector2.RIGHT, 420.0, 1, 1.0, "bullet")
	arena.add_child(proj)
	for f in 20:
		await get_tree().physics_frame
		if Sfx.play_count("hit_bullet") >= 1:
			break
	_check(Sfx.play_count("hit_bullet") >= 1, "bắn đạn trúng giặc không phát hit_bullet")
	arena.queue_free()
	await _frames(2)
	Sfx.stop_all_sfx()
