extends "res://scripts/entities/interactable.gd"
## Rương sơn mài chiến lợi phẩm: hiện ra sau mỗi phòng đã dọn sạch giặc.
## Mở ra ngẫu nhiên theo tỉ lệ: xu + linh khí (nhiều nhất), hồ lô thuốc, hoặc vũ khí.

const WeaponData = preload("res://scripts/data/weapons.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")
const MaterialData = preload("res://scripts/data/materials.gd")
const Pickup = preload("res://scripts/entities/pickup.gd")
const Fx = preload("res://scripts/effects/fx.gd")

var level := 1
var chest_id: String = ""
var opened := false
var _pending_open: bool = false
var _spr: AnimatedSprite2D


func _ready() -> void:
	add_to_group("loot_chests")
	z_index = 1
	radius = 22.0
	var sh := Sprite2D.new()
	sh.texture = Art.tex("fx/shadow.png")
	sh.position = Vector2(0, 8)
	sh.scale = Vector2(1.6, 1.2)
	sh.z_index = -1
	add_child(sh)
	_spr = AnimatedSprite2D.new()
	_spr.sprite_frames = Art.frames("items/loot_chest.png", 22, 20, {"closed": [[0], 1.0, false], "open": [[1, 2, 3], 14.0, false]})
	_spr.play("closed")
	_spr.scale = Vector2(1.3, 1.3)
	add_child(_spr)
	# rơi từ trên xuống cho có cảm giác "phần thưởng"
	_spr.position.y = -40.0
	_spr.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_spr, "position:y", 0.0, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(_spr, "modulate:a", 1.0, 0.2)
	tw.tween_callback(func(): Fx.anim(get_parent(), global_position + Vector2(0, 6), "fx/dust.png", 10, 10, 14.0, 2.0))


func hint() -> String:
	return "Mở rương sơn mài"


func interact() -> void:
	if opened or _pending_open:
		return
	if Net.is_online():
		if Net.is_host():
			host_open_and_broadcast()
		else:
			_pending_open = true
			Net.send_world_event("chest_open_req", {"id": chest_id}, true)
		return
	opened = true
	enabled = false
	near = false
	_spr.play("open")
	Sfx.play("chest_open")
	var par := get_parent()
	var c := global_position + Vector2(0, 14)
	Fx.particles(par, global_position, Color(1, 0.85, 0.35), 18, 90.0, 0.6, -50.0, 2.0)
	var r := randf()
	if r < 0.58:
		for i in randi_range(6, 10):
			_drop("coin", 1, c)
		for i in 3:
			_drop("energy", 5, c)
	elif r < 0.85:
		var q := randf()
		if q < 0.45:
			_drop("potion", 2, c)
		elif q < 0.8:
			_drop("potion_energy", 80, c)
		else:
			_drop("potion_big", 5, c)
		for i in 3:
			_drop("coin", 1, c)
	else:
		var p := Pickup.new()
		p.kind = "weapon"
		p.weapon_id = WeaponData.roll(level, 1 if level >= 10 else 0)
		p.position = c
		par.add_child(p)
		Fx.burst(par, global_position, WeaponData.tier_color(p.weapon_id), 40.0, 0.5)
	var modern: bool = bool(EnemyData.chapter(level).get("modern", false))
	for mid in MaterialData.roll_chest_drops(modern):
		var mp := Pickup.new()
		mp.kind = "material"
		mp.material_id = str(mid)
		mp.amount = 1
		mp.position = c
		par.add_child(mp)
	queue_redraw()
	# rương mở xong mờ dần
	var tw := create_tween()
	tw.tween_interval(4.0)
	tw.tween_property(self, "modulate:a", 0.0, 0.6)
	tw.tween_callback(queue_free)


func host_open_and_broadcast() -> void:
	if opened:
		return
	var ns: Node = get_tree().get_first_node_in_group("net_sync")
	if ns != null and ns.opened_chests.has(chest_id):
		return
	if ns != null:
		ns.opened_chests[chest_id] = true
	var drops: Array = []
	var r: float = randf()
	if r < 0.58:
		for i in randi_range(6, 10):
			drops.append({"kind": "coin", "amount": 1, "weapon_id": "", "material_id": "", "pickup_id": 0})
		for i in 3:
			drops.append({"kind": "energy", "amount": 5, "weapon_id": "", "material_id": "", "pickup_id": 0})
	elif r < 0.85:
		var q: float = randf()
		var pid: int = ns.alloc_pickup_id() if ns != null else 0
		if q < 0.45:
			drops.append({"kind": "potion", "amount": 2, "weapon_id": "", "material_id": "", "pickup_id": pid})
		elif q < 0.8:
			drops.append({"kind": "potion_energy", "amount": 80, "weapon_id": "", "material_id": "", "pickup_id": pid})
		else:
			drops.append({"kind": "potion_big", "amount": 5, "weapon_id": "", "material_id": "", "pickup_id": pid})
		for i in 3:
			drops.append({"kind": "coin", "amount": 1, "weapon_id": "", "material_id": "", "pickup_id": 0})
	else:
		var wid: String = WeaponData.roll(level, 1 if level >= 10 else 0)
		var pid2: int = ns.alloc_pickup_id() if ns != null else 0
		drops.append({"kind": "weapon", "amount": 1, "weapon_id": wid, "material_id": "", "pickup_id": pid2})
	var modern: bool = bool(EnemyData.chapter(level).get("modern", false))
	for mid in MaterialData.roll_chest_drops(modern):
		drops.append({"kind": "material", "amount": 1, "weapon_id": "", "material_id": str(mid), "pickup_id": 0})
	Net.send_world_event("chest_open", {"id": chest_id, "drops": drops}, false)
	apply_open_drops(drops)


func apply_open_drops(drops: Array) -> void:
	if opened:
		return
	opened = true
	enabled = false
	near = false
	_pending_open = false
	_spr.play("open")
	Sfx.play("chest_open")
	var par: Node = get_parent()
	var c: Vector2 = global_position + Vector2(0, 14)
	var ns: Node = get_tree().get_first_node_in_group("net_sync")
	Fx.particles(par, global_position, Color(1, 0.85, 0.35), 18, 90.0, 0.6, -50.0, 2.0)
	for item in drops:
		if not (item is Dictionary):
			continue
		var d: Dictionary = item
		var p := Pickup.new()
		p.kind = str(d.get("kind", "coin"))
		p.amount = int(d.get("amount", 1))
		p.weapon_id = str(d.get("weapon_id", ""))
		p.material_id = str(d.get("material_id", ""))
		p.pickup_id = int(d.get("pickup_id", 0))
		p.position = c
		par.add_child(p)
		if p.pickup_id > 0 and ns != null:
			ns.register_pickup(p)
		if p.kind == "weapon" and p.weapon_id != "":
			Fx.burst(par, global_position, WeaponData.tier_color(p.weapon_id), 40.0, 0.5)
	queue_redraw()
	var tw := create_tween()
	tw.tween_interval(4.0)
	tw.tween_property(self, "modulate:a", 0.0, 0.6)
	tw.tween_callback(queue_free)


func _drop(k: String, amount: int, pos: Vector2) -> void:
	var p := Pickup.new()
	p.kind = k
	p.amount = amount
	p.position = pos
	get_parent().add_child(p)


func _draw() -> void:
	if not opened:
		var a := 0.35 + 0.25 * sin(_t * 4.0)
		draw_set_transform(Vector2(0, 8), 0.0, Vector2(1.0, 0.4))
		draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 24, Color(1, 0.8, 0.35, a), 1.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_hint(-22.0)
