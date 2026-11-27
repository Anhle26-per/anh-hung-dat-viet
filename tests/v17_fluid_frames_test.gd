extends Node
## Kiểm thử v1.7.0: mở rộng đồng bộ lên 16 khung cho toàn bộ 49 quái nhỏ & 24 khung cho toàn bộ 26 tờ trùm.
## Chạy: godot --headless --path . res://tests/v17_fluid_frames_test.tscn -> "V17 FLUID FRAMES TEST OK"

const EnemyData = preload("res://scripts/data/enemies.gd")
const EnemyScript = preload("res://scripts/entities/enemy.gd")

var _fail: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		push_error("KIỂM THỬ THẤT BẠI: " + msg)
		print("  THẤT BẠI: ", msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _sig(img: Image, f_idx: int, fw: int, fh: int) -> String:
	var h: int = 2166136261
	var count: int = 0
	var cols: int = maxi(1, int(img.get_width() / fw))
	@warning_ignore("integer_division")
	var x0: int = (f_idx % cols) * fw
	@warning_ignore("integer_division")
	var y0: int = (f_idx / cols) * fh
	for y in range(fh):
		for x in range(fw):
			var c: Color = img.get_pixel(x0 + x, y0 + y)
			if c.a > 0.1:
				count += 1
				var q: int = (int(round(c.r * 255.0)) << 16) | (int(round(c.g * 255.0)) << 8) | int(round(c.b * 255.0))
				h = ((h ^ q) ^ ((x * 31 + y * 17))) * 16777619 & 0x7FFFFFFF
	return "%d:%d" % [count, h]


func _ready() -> void:
	get_tree().create_timer(45.0).timeout.connect(func():
		print("V17 FLUID FRAMES TEST FAILED: quá thời gian")
		get_tree().quit(1))
	Global.save_path = "user://v17_fluid_test_save.json"
	await _frames(1)
	await _run()
	if _fail == 0:
		print("V17 FLUID FRAMES TEST OK")
		get_tree().quit(0)
	else:
		print("V17 FLUID FRAMES TEST FAILED: %d lỗi" % _fail)
		get_tree().quit(1)


func _run() -> void:
	print("== 1. Kiểm tra 49 tờ quái nhỏ có đủ 24 khung chuyển động mượt & khác nhau theo từng pha")
	var mob_entries: Array = []
	var armies: Array[String] = [
		"dong_han", "dong_ngo", "nam_han", "tong", "nguyen_mong",
		"minh", "thanh", "phap_thuy", "phap_vien_chinh", "phap_1954",
	]
	for army in armies:
		var kinds: Array = ["bo_binh", "linh_sung", "xa_thu", "phao_binh"] if army.begins_with("phap") else ["bo_binh", "cung_thu", "khien_binh", "phap_su"]
		for kind in kinds:
			mob_entries.append(["enemies/%s_%s.png" % [army, kind], 24, 26])
	mob_entries.append(["enemies/nguyen_mong_ky_binh.png", 34, 30])
	mob_entries.append(["enemies/xe_tang.png", 40, 30])
	for mid in ["tieu_yeu", "ho_tinh", "moc_tinh", "chan_tinh", "dai_bang", "ma_troi", "ngu_tinh"]:
		var sz: Vector2i = EnemyData.FOLK[mid]["size"]
		mob_entries.append([EnemyData.FOLK[mid]["sheet"], sz.x, sz.y])

	_check(mob_entries.size() == 49, "phải kiểm đủ 49 tờ quái nhỏ (thực tế %d)" % mob_entries.size())
	for entry in mob_entries:
		var path: String = "res://assets/sprites/" + str(entry[0])
		var fw: int = int(entry[1])
		var fh: int = int(entry[2])
		var tex: Texture2D = load(path)
		_check(tex != null, "không nạp được " + path)
		if tex == null:
			continue
		var img: Image = tex.get_image()
		_check(img.get_width() == fw * 24 and img.get_height() == fh, "%s phải là %dx%d (thực tế %dx%d)" % [path, fw * 24, fh, img.get_width(), img.get_height()])
		_check(img.get_width() <= 4096, "%s vượt giới hạn GPU 4096px" % path)
		var s0 := _sig(img, 0, fw, fh)
		var s2 := _sig(img, 2, fw, fh)
		var s8 := _sig(img, 8, fw, fh)
		var s9 := _sig(img, 9, fw, fh)
		var s10 := _sig(img, 10, fw, fh)
		var s11 := _sig(img, 11, fw, fh)
		var s14 := _sig(img, 14, fw, fh)
		var s18 := _sig(img, 18, fw, fh)
		var s19 := _sig(img, 19, fw, fh)
		var s20 := _sig(img, 20, fw, fh)
		var s22 := _sig(img, 22, fw, fh)
		_check(s0 != s2 and s20 != s22, "%s walk/idle khung bị giống hệt nhau" % path)
		_check(s8 != s9 and s10 != s11 and s11 != s14 and s18 != s19, "%s thiếu biến thiên giữa lấy đà/tấn công/trúng đòn" % path)

	print("== 2. Kiểm tra toàn bộ 26 tờ trùm (10 lịch sử P1/P2 + 3 Tam Yêu P1/P2) có đủ 48 khung lưới 12x4 & width <= 1728px")
	var boss_count: int = 0
	for bid in EnemyData.BOSSES:
		var is_ship: bool = (bid == "tau_hy_vong")
		var fw: int = 64 if is_ship else 48
		var fh: int = 44 if is_ship else 48
		for suf in ["", "_2"]:
			var bfw: int = fw if suf == "" else fw * 2 + 16
			var bfh: int = fh if suf == "" else fh * 2 + 18
			var bp: String = "res://assets/sprites/enemies/boss_%s%s.png" % [bid, suf]
			var bt: Texture2D = load(bp)
			_check(bt != null, "thiếu " + bp)
			if bt == null:
				continue
			var bi: Image = bt.get_image()
			_check(bi.get_width() == bfw * 12 and bi.get_height() == bfh * 4, "%s phải là %dx%d (thực tế %dx%d)" % [bp, bfw * 12, bfh * 4, bi.get_width(), bi.get_height()])
			_check(bi.get_width() <= 1728, "%s quá rộng (%d > 1728)" % [bp, bi.get_width()])
			var id0 := _sig(bi, 0, bfw, bfh)
			var w6 := _sig(bi, 6, bfw, bfh)
			var w10 := _sig(bi, 10, bfw, bfh)
			var wu0 := _sig(bi, 14, bfw, bfh)
			var wu3 := _sig(bi, 17, bfw, bfh)
			var a2 := _sig(bi, 22, bfw, bfh)
			var rg_shot := _sig(bi, 28, bfw, bfh)
			var cast_s := _sig(bi, 33, bfw, bfh)
			var d0 := _sig(bi, 36, bfw, bfh)
			var lp := _sig(bi, 41, bfw, bfh)
			var rg := _sig(bi, 44, bfw, bfh)
			var sp0 := _sig(bi, 46, bfw, bfh)
			var sp1 := _sig(bi, 47, bfw, bfh)
			_check(w6 != w10 and wu0 != wu3 and id0 != w6, "%s idle/walk/windup trùng khung" % bp)
			_check(a2 != wu3 and rg_shot != a2 and cast_s != rg_shot and d0 != a2 and lp != rg and sp0 != sp1, "%s các pha chiến đấu chưa tách biệt" % bp)
			boss_count += 1
	for lid in EnemyData.LEGENDS:
		var sz: Vector2i = EnemyData.LEGENDS[lid]["size"]
		for suf in ["", "_2"]:
			var lp: String = "res://assets/sprites/enemies/boss_%s%s.png" % [lid, suf]
			var lt: Texture2D = load(lp)
			_check(lt != null, "thiếu " + lp)
			if lt != null:
				var li: Image = lt.get_image()
				_check(li.get_width() == sz.x * 12 and li.get_height() == sz.y * 4, "%s phải là %dx%d (thực tế %dx%d)" % [lp, sz.x * 12, sz.y * 4, li.get_width(), li.get_height()])
				_check(li.get_width() <= 1728, "%s quá rộng (%d > 1728)" % [lp, li.get_width()])
				_check(_sig(li, 0, sz.x, sz.y) != _sig(li, 6, sz.x, sz.y) and _sig(li, 46, sz.x, sz.y) != _sig(li, 47, sz.x, sz.y), "%s khung hành động trùng nhau" % lp)
				boss_count += 1
	_check(boss_count == 26, "phải kiểm đủ 26 tờ trùm (thực tế %d)" % boss_count)

	print("== 3. Kiểm tra Enemy SpriteFrames cho quái 24 khung, Ngư Tinh, Trùm Pha 1 & Pha 2 (48 khung)")
	var arena := Node2D.new()
	add_child(arena)

	var ngu = EnemyScript.new()
	ngu.setup("ngu_tinh", 6, null)
	arena.add_child(ngu)
	await _frames(2)
	var nsf: SpriteFrames = ngu.spr.sprite_frames
	_check(nsf.get_frame_count("idle") == 4 and nsf.get_frame_count("walk") == 8 and nsf.get_frame_count("windup") == 4 and nsf.get_frame_count("attack") == 6 and nsf.get_frame_count("hurt") == 2, "Ngư Tinh 24 khung sai cấu trúc animation")

	Global.boss_order = ["to_dinh"]
	var boss = EnemyScript.new()
	boss.setup("boss", 5, null)
	arena.add_child(boss)
	await _frames(2)
	for check_phase in [1, 2]:
		var sf: SpriteFrames = boss.spr.sprite_frames
		var expected := {"idle": 6, "walk": 8, "windup": 6, "melee_sweep": 6, "attack": 6, "ranged_shot": 6, "cast_summon": 4, "dash": 4, "leap": 4, "rage": 2, "special": 2}
		for aname in expected:
			_check(sf.has_animation(aname) and sf.get_frame_count(aname) == int(expected[aname]), "Trùm Pha %d sai animation %s (%d)" % [check_phase, aname, sf.get_frame_count(aname) if sf.has_animation(aname) else -1])
		boss._leap_state = "windup"
		boss._update_anim(0.016)
		_check(boss.spr.animation == "windup", "Trùm leap windup phải chạy 'windup'")
		boss._leap_state = "air"
		boss._update_anim(0.016)
		_check(boss.spr.animation == "leap", "Trùm nhảy cao phải chạy 'leap'")
		boss._leap_state = ""
		boss._charge_state = "dash"
		boss._update_anim(0.016)
		_check(boss.spr.animation == "dash", "Trùm húc lướt phải chạy 'dash'")
		boss._charge_state = ""
		boss._special = "cuu_vi"
		boss._special_t = 0.5
		boss._update_anim(0.016)
		_check(boss.spr.animation == "special", "Trùm tuyệt chiêu phải chạy 'special'")
		boss._special = ""
		boss._special_t = 0.0
		if check_phase == 1:
			boss._finish_morph()
			await _frames(1)

	arena.queue_free()
	await _frames(2)
