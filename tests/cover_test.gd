extends Node
## Kiểm thử logic đạn va chạm tường & thẻ G12 (Vật cản che đạn thuần Việt).
## Chạy: godot --headless --path . res://tests/cover_test.tscn -> in "COVER TEST OK"

const Bullet = preload("res://scripts/entities/bullet.gd")
const Cover = preload("res://scripts/entities/cover.gd")
const Dungeon = preload("res://scripts/game/dungeon.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")
const Player = preload("res://scripts/entities/player.gd")

var _fail: int = 0


class TargetDummy extends CharacterBody2D:
	var radius: float = 7.0
	var dead: bool = false
	var hits: int = 0

	func _ready() -> void:
		add_to_group("enemies")
		collision_layer = 4
		collision_mask = 0
		var sh := CircleShape2D.new()
		sh.radius = radius
		var cs := CollisionShape2D.new()
		cs.shape = sh
		add_child(cs)

	func is_spawning() -> bool:
		return false

	func take_damage(_amount: int, _knock: Vector2 = Vector2.ZERO) -> void:
		hits += 1

	func apply_stun(_t: float) -> void:
		pass

	func apply_status(_k: String, _d: float) -> void:
		pass


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		push_error("KIỂM THỬ THẤT BẠI: " + msg)
		print("  THẤT BẠI: ", msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _make_wall(pos: Vector2, sz: Vector2) -> StaticBody2D:
	var w := StaticBody2D.new()
	w.collision_layer = 1
	w.collision_mask = 0
	w.position = pos
	var sh := RectangleShape2D.new()
	sh.size = sz
	var cs := CollisionShape2D.new()
	cs.shape = sh
	w.add_child(cs)
	return w


func _ready() -> void:
	get_tree().create_timer(45.0).timeout.connect(func():
		print("COVER TEST FAILED: quá thời gian")
		get_tree().quit(1))
	await _frames(2)
	await _run()
	if _fail == 0:
		print("COVER TEST OK")
		get_tree().quit(0)
	else:
		print("COVER TEST FAILED: %d lỗi" % _fail)
		get_tree().quit(1)


func _run() -> void:
	print("== 1. Đạn nhanh 900px/s và bắn sát tường không xuyên tường")
	var arena := Node2D.new()
	add_child(arena)
	var wall := _make_wall(Vector2(100, 0), Vector2(16, 120))
	arena.add_child(wall)
	var target := TargetDummy.new()
	target.position = Vector2(140, 0)
	arena.add_child(target)

	var fast_b := Bullet.new()
	fast_b.setup(true, Vector2(40, 0), Vector2.RIGHT, 900.0, 24, 1.0, "bullet")
	fast_b.spawn_origin = Vector2(30, 0)
	fast_b.pierce = 99
	arena.add_child(fast_b)

	var nose_b := Bullet.new()
	nose_b.setup(true, Vector2(114, 10), Vector2.RIGHT, 480.0, 5, 1.0, "bullet")
	nose_b.spawn_origin = Vector2(88, 10)
	arena.add_child(nose_b)

	await _frames(15)
	_check(target.hits == 0, "đạn đã xuyên qua tường trúng mục tiêu phía sau (%d lần)" % target.hits)
	_check(not is_instance_valid(fast_b), "đạn nhanh 900px/s chưa hủy khi chạm tường")
	_check(not is_instance_valid(nose_b), "đạn sát tường chưa hủy khi nòng thò vào tường")

	print("== 2. Lựu đạn nảy tường rồi mới nổ khi hết thời gian")
	var gran_target := TargetDummy.new()
	gran_target.position = Vector2(45, 0)
	arena.add_child(gran_target)
	var gr := Bullet.new()
	gr.setup(true, Vector2(60, 0), Vector2.RIGHT, 260.0, 12, 0.35, "grenade")
	gr.spawn_origin = Vector2(45, 0)
	gr.explode_radius = 45.0
	arena.add_child(gr)
	await _frames(12)
	_check(is_instance_valid(gr) and gr.dir.x < 0.0, "lựu đạn không nảy ngược khi chạm tường")
	_check(is_instance_valid(gr) and gr.bounces == 1, "lựu đạn không giảm số lần nảy: %d" % (gr.bounces if is_instance_valid(gr) else -1))
	await _frames(18)
	_check(not is_instance_valid(gr), "lựu đạn không nổ khi hết thời gian")
	_check(gran_target.hits >= 1, "lựu đạn nảy về gần mục tiêu nhưng nổ không gây sát thương")

	print("== 3. Rìu Thạch Sanh (boomerang) chạm tường quay về xuyên tường tới tay")
	var owner_p := Player.new()
	owner_p.setup("hai_ba_trung")
	owner_p.position = Vector2(30, 0)
	arena.add_child(owner_p)
	var axe := Bullet.new()
	axe.setup(true, Vector2(65, 0), Vector2.RIGHT, 320.0, 14, 0.9, "axe")
	axe.boomerang = true
	axe.owner_node = owner_p
	axe.spawn_origin = owner_p.position
	axe.pierce = 99
	arena.add_child(axe)
	await _frames(10)
	_check(not is_instance_valid(axe) or axe._returning, "boomerang chạm tường không chuyển sang trạng thái bay về")
	await _frames(25)
	_check(not is_instance_valid(axe), "boomerang không quay về được tới người chơi")
	arena.queue_free()
	await _frames(2)

	print("== 4. Vật cản che đạn (chum/bia/thùng/bao cát) chặn đạn 2 phe & vỡ đúng số đòn")
	var a2 := Node2D.new()
	add_child(a2)
	var stele := Cover.new()
	stele.kind = "stele"
	stele.position = Vector2(0, 0)
	a2.add_child(stele)
	for i in 10:
		var bs := Bullet.new()
		bs.setup(i % 2 == 0, Vector2(-30 if i % 2 == 0 else 30, 0), Vector2.RIGHT if i % 2 == 0 else Vector2.LEFT, 400.0, 5, 0.5, "bullet")
		bs.spawn_origin = bs.position - bs.dir * 6.0
		a2.add_child(bs)
		await _frames(8)
	_check(is_instance_valid(stele) and not stele.destructible, "bia đá bị vỡ hoặc sai cờ destructible")

	var pot := Cover.new()
	pot.kind = "pot"
	pot.position = Vector2(0, 40)
	a2.add_child(pot)
	for i in 3:
		var bp := Bullet.new()
		bp.setup(false, Vector2(-30, 40), Vector2.RIGHT, 400.0, 1, 0.5, "orb_pink")
		bp.spawn_origin = Vector2(-36, 40)
		a2.add_child(bp)
		await _frames(8)
	await _frames(2)
	_check(not is_instance_valid(pot), "chum gốm không vỡ sau 3 phát đạn")

	var crate := Cover.new()
	crate.kind = "crate"
	crate.position = Vector2(0, 80)
	a2.add_child(crate)
	var p2 := Player.new()
	p2.setup("le_loi")
	p2.position = Vector2(-24, 80)
	p2.aim_dir = Vector2.RIGHT
	a2.add_child(p2)
	await _frames(2)
	for i in 4:
		p2._fire_timer = 0.0
		p2._try_attack()
		await _frames(2)
	_check(not is_instance_valid(crate), "đòn cận chiến không phá vỡ được thùng gỗ")
	a2.queue_free()
	await _frames(2)

	print("== 5. Sinh hầm ngục 28 hạt giống (màn 1, 3, 13, 25): đủ vật cản theo thời kỳ, không chặn cửa/giữa/phòng đầu")
	var levels: Array[int] = [1, 3, 13, 25]
	var tactical_covers := ["wall_h", "wall_v", "pillar", "barrel_boom"]
	var saw_ancient_era: bool = false
	var saw_modern_era: bool = false
	var saw_tactical: bool = false
	for lv in levels:
		var ch: Dictionary = EnemyData.chapter(lv)
		var is_modern: bool = bool(ch.get("modern", false))
		var ch_decor: Array = ch.get("decor", [])
		for s in range(7):
			seed(1000 + lv * 50 + s)
			var d := Dungeon.new()
			add_child(d)
			d.generate(lv)
			await _frames(2)
			for cell in d.rooms:
				var r = d.rooms[cell]
				if r.kind == "start":
					_check(r.covers.is_empty(), "phòng %s màn %d vẫn có vật cản (%d)" % [r.kind, lv, r.covers.size()])
				elif r.kind in ["combat", "boss", "legend"]:
					if r.kind == "combat":
						_check(r.covers.size() >= 4, "phòng combat màn %d có quá ít vật cản (%d)" % [lv, r.covers.size()])
					else:
						_check(not r.covers.is_empty(), "phòng %s màn %d phải có vật cản che đạn" % [r.kind, lv])
					for cv in r.covers:
						_check(is_instance_valid(cv), "vật cản không hợp lệ")
						if not is_instance_valid(cv):
							continue
						if cv.kind in tactical_covers:
							saw_tactical = true
						if not is_modern:
							if cv.kind in ["pot", "stele"]:
								saw_ancient_era = true
							_check(cv.kind in ["pot", "stele"] or cv.kind in tactical_covers,
								"màn cổ/thần thoại %d lại sinh vật cản hiện đại %s" % [lv, cv.kind])
						else:
							if cv.kind in ["crate", "sandbag"]:
								saw_modern_era = true
							var allow_pot: bool = cv.kind == "pot" and ch_decor.has("pot")
							_check(cv.kind in ["crate", "sandbag"] or cv.kind in tactical_covers or allow_pot,
								"màn hiện đại %d lại sinh vật cản cổ %s" % [lv, cv.kind])
						_check(cv.global_position.distance_to(r.rect.get_center()) >= 28.0,
							"vật cản chặn tâm phòng ở màn %d: dist=%.1f" % [lv, cv.global_position.distance_to(r.rect.get_center())])
						for dr in r.door_rects:
							_check(not (dr as Rect2).grow(32.0).has_point(cv.global_position),
								"vật cản nằm quá gần cửa ở màn %d" % lv)
			d.queue_free()
			await _frames(1)
	_check(saw_ancient_era, "chưa thấy vật cản thời cổ (pot/stele)")
	_check(saw_modern_era, "chưa thấy vật cản thời cận đại (crate/sandbag)")
	_check(saw_tactical, "chưa thấy vật cản chiến thuật chung (wall_h/wall_v/pillar/barrel_boom)")
