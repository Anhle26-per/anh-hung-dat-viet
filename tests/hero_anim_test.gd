extends Node
## Kiểm thử thẻ G10: 11 tờ ảnh tướng 512x32 (16 khung) và hoạt ảnh attack/skill/down trên Player.
## Chạy: godot --headless --path . res://tests/hero_anim_test.tscn -> in "HERO ANIM TEST OK"

const HeroData = preload("res://scripts/data/heroes.gd")
const Player = preload("res://scripts/entities/player.gd")
const Art = preload("res://scripts/art/art.gd")

var _fail: int = 0
var _completed: bool = false


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		push_error("KIỂM THỬ THẤT BẠI: " + msg)
		print("  THẤT BẠI: ", msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _ready() -> void:
	Global.save_path = "user://hero_anim_test_save.json"
	get_tree().create_timer(30.0).timeout.connect(func():
		print("HERO ANIM TEST FAILED: quá thời gian")
		get_tree().quit(1))
	await _frames(2)
	await _run()
	if _fail == 0 and _completed:
		print("HERO ANIM TEST OK")
		get_tree().quit(0)
	else:
		print("HERO ANIM TEST FAILED: %d lỗi (completed=%s)" % [_fail, str(_completed)])
		get_tree().quit(1)


func _run() -> void:
	print("== 1. Kiểm tra 11 tờ ảnh tướng đều 512x32 (16 khung 32x32)")
	_check(HeroData.ORDER.size() == 11, "số tướng phải là 11")
	for hid_v in HeroData.ORDER:
		var hid: String = str(hid_v)
		var rel: String = "heroes/%s.png" % hid
		var abs_path: String = ProjectSettings.globalize_path("res://assets/sprites/" + rel)
		var img: Image = Image.load_from_file(abs_path)
		_check(img != null and img.get_width() == 512 and img.get_height() == 32,
			"%s phải 512x32 (thực tế %s)" % [hid, "null" if img == null else "%dx%d" % [img.get_width(), img.get_height()]])
		var tex: Texture2D = Art.tex(rel)
		_check(tex != null and tex.get_width() == 512 and tex.get_height() == 32,
			"Art.tex(%s) phải 512x32" % rel)

	print("== 2. Kiểm tra đủ 6 hoạt ảnh trong player.body.sprite_frames")
	var world := Node2D.new()
	add_child(world)
	var p := Player.new()
	p.setup("ngo_quyen")
	world.add_child(p)
	await _frames(2)

	var sf: SpriteFrames = p.body.sprite_frames
	_check(sf != null, "player.body.sprite_frames bị null")
	var expected_counts: Dictionary = {
		"idle": 4,
		"walk": 4,
		"hurt": 1,
		"attack": 2,
		"skill": 2,
		"down": 3,
	}
	for anim_name_v in expected_counts:
		var anim_name: String = str(anim_name_v)
		var exp_cnt: int = int(expected_counts[anim_name])
		_check(sf.has_animation(anim_name), "thiếu hoạt ảnh: " + anim_name)
		if sf.has_animation(anim_name):
			_check(sf.get_frame_count(anim_name) == exp_cnt,
				"số khung %s = %d (kỳ vọng %d)" % [anim_name, sf.get_frame_count(anim_name), exp_cnt])
	_check(not sf.get_animation_loop("attack"), "attack không được lặp")
	_check(not sf.get_animation_loop("skill"), "skill không được lặp")
	_check(not sf.get_animation_loop("down"), "down không được lặp")

	print("== 3. Kiểm tra phát hoạt ảnh attack, skill, down và revive -> idle")
	# Tấn công -> attack
	p._fire_timer = 0.0
	p._try_attack()
	_check(p.body.animation == &"attack", "sau _try_attack() phải phát attack (thực tế: %s)" % str(p.body.animation))
	await _frames(2)
	_check(p.body.animation == &"attack", "_process không được ghi đè attack trong thời gian khóa (thực tế: %s)" % str(p.body.animation))

	# Hết thời gian khóa -> trở về idle
	p._anim_lock_t = 0.0
	await _frames(2)
	_check(p.body.animation == &"idle", "sau khi hết khóa phải về idle (thực tế: %s)" % str(p.body.animation))

	# Dùng kỹ năng -> skill
	p.skill_timer = 0.0
	p._use_skill()
	_check(p.body.animation == &"skill", "sau _use_skill() phải phát skill (thực tế: %s)" % str(p.body.animation))
	await _frames(2)
	_check(p.body.animation == &"skill", "_process không được ghi đè skill trong thời gian khóa (thực tế: %s)" % str(p.body.animation))

	# Gục ngã -> down và giữ nguyên khi dead == true
	p.die()
	_check(p.dead, "sau die() phải dead == true")
	_check(p.body.animation == &"down", "sau die() phải phát down (thực tế: %s)" % str(p.body.animation))
	await _frames(3)
	_check(p.body.animation == &"down", "khi dead == true phải giữ down (thực tế: %s)" % str(p.body.animation))

	# Hồi sinh -> idle
	p.revive()
	_check(not p.dead, "sau revive() phải dead == false")
	_check(p.body.animation == &"idle", "sau revive() phải về idle (thực tế: %s)" % str(p.body.animation))
	await _frames(2)
	_check(p.body.animation == &"idle", "sau revive() vài frame vẫn idle (thực tế: %s)" % str(p.body.animation))

	world.queue_free()
	await _frames(2)
	_completed = true
