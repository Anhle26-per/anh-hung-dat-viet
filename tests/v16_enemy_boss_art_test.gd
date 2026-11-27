extends Node
## Kiểm thử v1.6.0 (đã nâng cấp đồng bộ khung hình v1.7.0): mọi quái nhỏ có đủ 16 khung hành động mượt
## và mọi trùm lịch sử + Pha 2 + Tam Yêu có đủ 24 khung sắc nét với bảng màu phong phú.
## Chạy: godot --headless --path . res://tests/v16_enemy_boss_art_test.tscn -> in "V16 ENEMY BOSS ART TEST OK"

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


func _frame_signature(img: Image, f_idx: int, fw: int, fh: int) -> String:
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


func _unique_colors(img: Image, fw: int, fh: int, frames: int) -> int:
	var seen: Dictionary = {}
	var cols: int = maxi(1, int(img.get_width() / fw))
	for f in range(frames):
		@warning_ignore("integer_division")
		var x0: int = (f % cols) * fw
		@warning_ignore("integer_division")
		var y0: int = (f / cols) * fh
		for y in range(0, fh, 2):
			for x in range(0, fw, 2):
				var c: Color = img.get_pixel(x0 + x, y0 + y)
				if c.a > 0.2:
					seen[int(round(c.r * 31.0)) * 1024 + int(round(c.g * 31.0)) * 32 + int(round(c.b * 31.0))] = true
	return seen.size()


func _ready() -> void:
	get_tree().create_timer(45.0).timeout.connect(func():
		print("V16 ENEMY BOSS ART TEST FAILED: quá thời gian")
		get_tree().quit(1))
	Global.save_path = "user://v16_art_test_save.json"
	await _frames(1)
	await _run()
	if _fail == 0:
		print("V16 ENEMY BOSS ART TEST OK")
		get_tree().quit(0)
	else:
		print("V16 ENEMY BOSS ART TEST FAILED: %d lỗi" % _fail)
		get_tree().quit(1)


func _run() -> void:
	print("== 1. Kiểm tra 40 tờ hình lính (10 đạo quân x 4 loại, 24x26 x 24 khung)")
	var armies: Array[String] = [
		"dong_han", "dong_ngo", "nam_han", "tong", "nguyen_mong",
		"minh", "thanh", "phap_thuy", "phap_vien_chinh", "phap_1954",
	]
	var checked_soldiers: int = 0
	for army in armies:
		var kinds: Array = ["bo_binh", "linh_sung", "xa_thu", "phao_binh"] if army.begins_with("phap") else ["bo_binh", "cung_thu", "khien_binh", "phap_su"]
		for kind in kinds:
			var path: String = "res://assets/sprites/enemies/%s_%s.png" % [army, kind]
			var tex: Texture2D = load(path)
			_check(tex != null, "không nạp được texture: " + path)
			if tex == null:
				continue
			var img: Image = tex.get_image()
			_check(img.get_width() == 576 and img.get_height() == 26, "%s kích thước %dx%d (cần 576x26)" % [path, img.get_width(), img.get_height()])
			var sig_w0: String = _frame_signature(img, 0, 24, 26)
			var sig_wind: String = _frame_signature(img, 9, 24, 26)
			var sig_atk: String = _frame_signature(img, 11, 24, 26)
			var sig_rec: String = _frame_signature(img, 13, 24, 26)
			var sig_hurt: String = _frame_signature(img, 14, 24, 26)
			var sig_idle: String = _frame_signature(img, 20, 24, 26)
			_check(sig_w0 != sig_atk and sig_wind != sig_atk and sig_atk != sig_hurt, "các khung hành động của %s bị trùng nhau" % path)
			_check(sig_w0 != sig_hurt and sig_rec != sig_hurt and sig_idle != sig_atk, "khung trúng đòn/thở của %s chưa tách biệt" % path)
			checked_soldiers += 1
	_check(checked_soldiers == 40, "phải kiểm đủ 40 tờ lính (thực tế %d)" % checked_soldiers)

	print("== 2. Kiểm tra kỵ binh, xe tăng và 7 yêu quái đều có 24 khung chi tiết")
	var mob_specs: Array = [
		["nguyen_mong_ky_binh", 34, 30],
		["xe_tang", 40, 30],
		["tieu_yeu", 16, 17],
		["ho_tinh", 22, 16],
		["moc_tinh", 26, 28],
		["chan_tinh", 30, 32],
		["dai_bang", 36, 26],
		["ma_troi", 14, 18],
		["ngu_tinh", 60, 46],
	]
	for spec in mob_specs:
		var mid: String = str(spec[0])
		var fw: int = int(spec[1])
		var fh: int = int(spec[2])
		var mpath: String = "res://assets/sprites/enemies/%s.png" % mid
		var mtex: Texture2D = load(mpath)
		_check(mtex != null, "không nạp được mob: " + mpath)
		if mtex == null:
			continue
		var mimg: Image = mtex.get_image()
		_check(mimg.get_width() == fw * 24 and mimg.get_height() == fh, "%s phải %dx%d (thực tế %dx%d)" % [mpath, fw * 24, fh, mimg.get_width(), mimg.get_height()])
		var s0: String = _frame_signature(mimg, 0, fw, fh)
		var s9: String = _frame_signature(mimg, 9, fw, fh)
		var s11: String = _frame_signature(mimg, 11, fw, fh)
		var s14: String = _frame_signature(mimg, 14, fw, fh)
		var s20: String = _frame_signature(mimg, 20, fw, fh)
		_check(s0 != s9 and s9 != s11 and s11 != s14 and s20 != s11, "khung hành động của %s bị trùng" % mpath)

	print("== 3. Kiểm tra 10 trùm lịch sử + Pha 2 + 3 Tam Yêu (48 khung lưới 12x4 & bảng màu phong phú)")
	for bid in EnemyData.BOSSES:
		var is_ship: bool = (bid == "tau_hy_vong")
		var bfw: int = 64 if is_ship else 48
		var bfh: int = 44 if is_ship else 48
		var p1: String = "res://assets/sprites/enemies/boss_%s.png" % bid
		var p2: String = "res://assets/sprites/enemies/boss_%s_2.png" % bid
		var t1: Texture2D = load(p1)
		var t2: Texture2D = load(p2)
		_check(t1 != null and t2 != null, "thiếu sheet trùm %s" % bid)
		if t1 != null:
			var i1: Image = t1.get_image()
			_check(i1.get_width() == bfw * 12 and i1.get_height() == bfh * 4, "%s sai kích thước %dx%d (cần %dx%d)" % [p1, i1.get_width(), i1.get_height(), bfw * 12, bfh * 4])
			_check(i1.get_width() <= 1728, "%s quá rộng (%d)" % [p1, i1.get_width()])
			_check(_unique_colors(i1, bfw, bfh, 48) >= 18, "trùm %s P1 quá ít sắc độ màu" % bid)
		if t2 != null:
			var i2: Image = t2.get_image()
			var ew2: int = (bfw * 2 + 16) * 12
			var eh2: int = (bfh * 2 + 18) * 4
			_check(i2.get_width() == ew2 and i2.get_height() == eh2, "%s sai kích thước %dx%d (cần %dx%d)" % [p2, i2.get_width(), i2.get_height(), ew2, eh2])
			_check(i2.get_width() <= 1728, "%s quá rộng (%d)" % [p2, i2.get_width()])
			_check(_unique_colors(i2, bfw * 2 + 16, bfh * 2 + 18, 48) >= 20, "trùm %s P2 quá ít sắc độ màu" % bid)

	for lid in EnemyData.LEGENDS:
		var lg: Dictionary = EnemyData.LEGENDS[lid]
		var lsz: Vector2i = lg.get("size", Vector2i(84, 60))
		for suf in ["", "_2"]:
			var lp: String = "res://assets/sprites/enemies/boss_%s%s.png" % [lid, suf]
			var lt: Texture2D = load(lp)
			_check(lt != null, "thiếu sheet Tam Yêu " + lp)
			if lt != null:
				var li: Image = lt.get_image()
				_check(li.get_width() == lsz.x * 12 and li.get_height() == lsz.y * 4, "%s sai kích thước %dx%d (cần %dx%d)" % [lp, li.get_width(), li.get_height(), lsz.x * 12, lsz.y * 4])
				_check(li.get_width() <= 1728, "%s quá rộng (%d)" % [lp, li.get_width()])
				_check(_unique_colors(li, lsz.x, lsz.y, 48) >= 18, "%s quá ít sắc độ màu" % lp)

	print("== 4. Kiểm tra SpriteFrames 24/48 khung & chuyển hoạt ảnh trong Enemy")
	var arena := Node2D.new()
	add_child(arena)
	var mob = EnemyScript.new()
	mob.setup("bo_binh", 1, null)
	mob.position = Vector2(180, 180)
	arena.add_child(mob)
	await _frames(2)
	var msf: SpriteFrames = mob.spr.sprite_frames
	for anim in ["idle", "walk", "windup", "attack", "hurt"]:
		_check(msf.has_animation(anim), "quái nhỏ thiếu hoạt ảnh '%s'" % anim)
	_check(msf.get_frame_count("walk") == 8 and msf.get_frame_count("attack") == 6 and msf.get_frame_count("idle") == 4, "số khung walk/attack/idle của quái nhỏ chưa đúng (walk=%d, attack=%d, idle=%d)" % [msf.get_frame_count("walk"), msf.get_frame_count("attack"), msf.get_frame_count("idle")])
	mob._hurt_anim_t = 0.15
	mob._update_anim(0.016)
	_check(mob.spr.animation == "hurt", "quái nhỏ trúng đòn phải chuyển sang 'hurt' (hiện '%s')" % mob.spr.animation)
	mob._hurt_anim_t = 0.0
	mob._charge_state = "windup"
	mob._update_anim(0.016)
	_check(mob.spr.animation == "windup", "quái lấy đà phải chuyển sang 'windup'")
	mob._charge_state = ""
	mob._attack_anim_t = 0.25
	mob._update_anim(0.016)
	_check(mob.spr.animation == "attack", "quái tấn công phải chuyển sang 'attack'")

	var bnode = EnemyScript.new()
	Global.boss_order = ["to_dinh"]
	bnode.setup("boss", 5, null)
	bnode.position = Vector2(360, 180)
	arena.add_child(bnode)
	await _frames(2)
	var bsf: SpriteFrames = bnode.spr.sprite_frames
	for banim in ["walk", "windup", "attack", "dash", "leap", "rage", "special"]:
		_check(bsf.has_animation(banim), "trùm thiếu hoạt ảnh '%s'" % banim)
	arena.queue_free()
	await _frames(2)
