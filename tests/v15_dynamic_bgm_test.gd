extends Node
## Kiểm thử tổng hợp v1.5.0: Nhạc nền động 14 bài, crossfade 2 kênh, chuyển nhạc theo màn/phòng/trùm,
## và thẻ thông báo đổi nhạc trên HUD.
## Chạy: godot --headless --path . res://tests/v15_dynamic_bgm_test.tscn -> in "V15 DYNAMIC BGM TEST OK"

const HUD = preload("res://scripts/ui/hud.gd")
const Player = preload("res://scripts/entities/player.gd")

const TEST_SAVE := "user://v15_dynamic_bgm_test_save.json"

var _fail: int = 0
var _completed: bool = false


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		push_error("KIỂM THỬ THẤT BẠI: " + msg)
		print("  THẤT BẠI: ", msg)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _wipe() -> void:
	for p in [TEST_SAVE, TEST_SAVE + ".tmp", Global.run_path(), Global.run_path() + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _ready() -> void:
	get_tree().create_timer(60.0).timeout.connect(func():
		print("V15 DYNAMIC BGM TEST FAILED: quá thời gian")
		get_tree().quit(1))
	await _frames(2)
	await _run()
	_wipe()
	if _fail == 0 and _completed:
		print("V15 DYNAMIC BGM TEST OK")
		get_tree().quit(0)
	else:
		print("V15 DYNAMIC BGM TEST FAILED: %d lỗi (completed=%s)" % [_fail, str(_completed)])
		get_tree().quit(1)


func _run() -> void:
	Global.save_path = TEST_SAVE
	_wipe()
	Global.chapter_order = []
	Global.boss_order = []

	print("== 1. Kiểm tra 19 bản nhạc nền trong MUSIC_FILES & MUSIC_TITLES (stereo 44100 Hz, 30..60s)")
	_check(Sfx.MUSIC_FILES.size() >= 19, "MUSIC_FILES phải có >= 19 bài (hiện %d)" % Sfx.MUSIC_FILES.size())
	_check(Sfx.MUSIC_TITLES.size() >= 19, "MUSIC_TITLES phải có >= 19 tiêu đề (hiện %d)" % Sfx.MUSIC_TITLES.size())
	var expected_ids: Array[String] = [
		"lobby", "basement",
		"battle", "battle_forest", "battle_river", "battle_citadel", "battle_modern", "battle_sprint", "battle_mythic",
		"boss", "boss_frenzy", "boss_legend", "boss_mythic", "victory",
		"coloa_defense", "coloa_siege", "secret_thuy_cung", "secret_tan_vien", "boss_hon_mang",
	]
	for mid in expected_ids:
		_check(Sfx.MUSIC_FILES.has(mid), "MUSIC_FILES thiếu: " + mid)
		_check(Sfx.MUSIC_TITLES.has(mid), "MUSIC_TITLES thiếu: " + mid)
		var title_s: String = Sfx.music_title(mid)
		_check(title_s != "" and title_s == str(Sfx.MUSIC_TITLES.get(mid, "")), "music_title(%s) sai: %s" % [mid, title_s])
		var path: String = str(Sfx.MUSIC_FILES.get(mid, ""))
		_check(FileAccess.file_exists(path), "thiếu tệp wav nhạc nền: " + path)
		var st: Resource = load(path)
		_check(st is AudioStreamWAV, "không nạp được AudioStreamWAV: " + path)
		if st is AudioStreamWAV:
			var wav: AudioStreamWAV = st as AudioStreamWAV
			var len_s: float = wav.get_length()
			_check(wav.mix_rate == 44100 and wav.stereo, "%s không phải stereo 44100 Hz" % path)
			_check(len_s >= 30.0 and len_s <= 60.0, "%s dài %.2fs (cần 30.0..60.0s)" % [path, len_s])

	print("== 2. Kiểm tra Sfx.stage_music_id(level, room_seq) luân phiên theo màn & phòng")
	var lv_tracks: Array[String] = []
	for lv in range(1, 6):
		var t_id: String = Sfx.stage_music_id(lv, 0)
		_check(Sfx.MUSIC_FILES.has(t_id), "stage_music_id(%d, 0) trả về id không hợp lệ: %s" % [lv, t_id])
		lv_tracks.append(t_id)
		if lv > 1:
			_check(t_id != lv_tracks[lv - 2], "stage_music_id(%d) trùng màn trước (%s)" % [lv, t_id])

	var r0: String = Sfx.stage_music_id(1, 0)
	var r1: String = Sfx.stage_music_id(1, 1)
	var r2: String = Sfx.stage_music_id(1, 2)
	_check(r0 != r1 and r1 != r2 and r0 != r2, "3 phòng chiến đấu liên tiếp phải đổi nhạc khác nhau (%s, %s, %s)" % [r0, r1, r2])
	_check(Sfx.stage_music_id(16, 0) == "victory", "level 16 phải trả về victory")
	_check(Sfx.stage_music_id(32, 0) == "victory", "level 32 phải trả về victory")
	_check(Sfx.stage_music_id(33, 2) == "victory", "level >= 32 phải trả về victory")
	var m_track: String = Sfx.stage_music_id(17, 0)
	_check(Sfx.MUSIC_FILES.has(m_track) and m_track != "victory", "level 17 phải trả về nhạc chiến đấu hợp lệ (hiện %s)" % m_track)

	print("== 3. Kiểm tra Sfx.boss_music_id & is_boss_music")
	_check(Sfx.boss_music_id(5, "boss", false) == "boss", "trùm thường phải trả về 'boss'")
	_check(Sfx.boss_music_id(3, "legend", false) == "boss_legend", "Tam Yêu phải trả về 'boss_legend'")
	_check(Sfx.boss_music_id(21, "boss", false) == "boss_mythic", "trùm Thần Thoại phải trả về 'boss_mythic'")
	_check(Sfx.boss_music_id(33, "boss", false) == "boss_hon_mang", "Hỗn Mang Yêu Đế màn 33 phải trả về 'boss_hon_mang'")
	_check(Sfx.boss_music_id(5, "boss", true) == "boss_frenzy", "trùm cuồng nộ phải trả về 'boss_frenzy'")
	_check(Sfx.boss_music_id(21, "boss", true) == "boss_frenzy", "trùm Thần Thoại cuồng nộ phải trả về 'boss_frenzy'")
	_check(Sfx.boss_music_id(3, "legend", true) == "boss_frenzy", "Tam Yêu cuồng nộ phải trả về 'boss_frenzy'")
	_check(Sfx.secret_biome_music_id("thuy_cung") == "secret_thuy_cung", "thuy_cung phải trả về 'secret_thuy_cung'")
	_check(Sfx.secret_biome_music_id("dinh_tan_vien") == "secret_tan_vien", "dinh_tan_vien phải trả về 'secret_tan_vien'")
	for bid in ["boss", "boss_legend", "boss_mythic", "boss_frenzy", "coloa_siege", "boss_hon_mang"]:
		_check(Sfx.is_boss_music(bid), "is_boss_music(%s) phải là true" % bid)
	for nbid in ["lobby", "basement", "battle", "victory", ""]:
		_check(not Sfx.is_boss_music(nbid), "is_boss_music(%s) phải là false" % nbid)

	print("== 4. Kiểm tra crossfade 2 kênh (play_music -> play_music -> stop_music)")
	Sfx.stop_music()
	await _frames(1)
	_check(Sfx.current_music() == "", "stop_music phải xóa current_music")
	var emitted: Array = []
	var on_changed: Callable = func(tid: String, ttitle: String) -> void:
		emitted.append({"id": tid, "title": ttitle})
	Sfx.music_changed.connect(on_changed)

	Sfx.play_music("battle", 0.0)
	_check(Sfx.current_music() == "battle", "play_music('battle') phải cập nhật current_music đồng bộ")
	var slot_before: int = Sfx.active_music_slot()
	_check(emitted.size() == 1 and str(emitted[0]["id"]) == "battle", "play_music('battle') phải phát tín hiệu music_changed")
	await _frames(1)

	Sfx.play_music("boss", 0.25)
	_check(Sfx.current_music() == "boss", "play_music('boss', 0.25) phải cập nhật current_music ngay lập tức")
	var slot_after: int = Sfx.active_music_slot()
	_check(slot_after == 1 - slot_before, "crossfade phải đổi kênh phát active_music_slot (%d -> %d)" % [slot_before, slot_after])
	_check(emitted.size() == 2 and str(emitted[1]["id"]) == "boss" and str(emitted[1]["title"]) == Sfx.music_title("boss"), "crossfade phải phát tín hiệu music_changed cho 'boss'")
	await get_tree().create_timer(0.38).timeout
	_check(Sfx.current_music() == "boss", "sau crossfade current_music vẫn phải là 'boss'")
	var ma: AudioStreamPlayer = Sfx._music_a
	var mb: AudioStreamPlayer = Sfx._music_b
	var active_p: AudioStreamPlayer = ma if slot_after == 0 else mb
	var inactive_p: AudioStreamPlayer = mb if slot_after == 0 else ma
	_check(active_p != null and active_p.playing, "kênh mới sau crossfade phải đang phát")
	_check(inactive_p != null and not inactive_p.playing, "kênh cũ sau crossfade phải đã dừng")

	Sfx.stop_music()
	_check(Sfx.current_music() == "", "stop_music() phải xóa current_music")
	_check(not ma.playing and not mb.playing, "stop_music() phải dừng cả 2 AudioStreamPlayer")
	if Sfx.music_changed.is_connected(on_changed):
		Sfx.music_changed.disconnect(on_changed)

	print("== 5. Kiểm tra HUD show_music_toast & kết nối Sfx.music_changed")
	var base_conns: int = Sfx.music_changed.get_connections().size()
	var host := Node2D.new()
	add_child(host)
	var p := Player.new()
	p.setup("hai_ba_trung")
	host.add_child(p)
	var hud := HUD.new()
	hud.player = p
	host.add_child(hud)
	await _frames(3)
	_check(Sfx.music_changed.is_connected(hud.show_music_toast), "HUD phải kết nối với Sfx.music_changed")
	_check(Sfx.music_changed.get_connections().size() == base_conns + 1, "HUD phải thêm đúng 1 kết nối Sfx.music_changed")

	Sfx.play_music("battle_river", 0.1)
	await _frames(2)
	_check(str(hud.get("_bgm_toast_id")) == "battle_river", "HUD _bgm_toast_id phải là 'battle_river'")
	_check(str(hud.get("_bgm_toast_title")) == Sfx.music_title("battle_river"), "HUD _bgm_toast_title sai")
	_check(float(hud.get("_bgm_toast_t")) > 2.0, "HUD _bgm_toast_t phải > 2.0s")

	hud.show_music_toast("boss_frenzy", Sfx.music_title("boss_frenzy"))
	await _frames(2)
	_check(str(hud.get("_bgm_toast_id")) == "boss_frenzy", "show_music_toast phải cập nhật _bgm_toast_id = 'boss_frenzy'")
	_check(str(hud.get("_bgm_toast_title")) == "Bạo Nộ Huyết Chiến", "show_music_toast phải cập nhật tiêu đề 'Bạo Nộ Huyết Chiến'")
	_check(float(hud.get("_bgm_toast_t")) > 2.5, "show_music_toast phải đặt _bgm_toast_t ~ 3.0s")

	Sfx.stop_music()
	host.queue_free()
	await _frames(3)
	_check(not is_instance_valid(hud), "HUD phải được giải phóng sau host.queue_free()")
	_check(Sfx.music_changed.get_connections().size() == base_conns, "HUD khi thoát cây phải ngắt kết nối Sfx.music_changed")

	_completed = true
