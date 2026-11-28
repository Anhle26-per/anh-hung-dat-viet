extends Node2D
## Sạp Thương Nhân Đại Việt: bà hàng áo tứ thân, mái hiên gấm đỏ, đèn lồng & các kệ sơn mài.
## Trả bằng xu nhặt được trong lượt chơi; có thể đứng cạnh bà hàng bấm E để mở Sạp đầy đủ.

const Art = preload("res://scripts/art/art.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")
const BuffData = preload("res://scripts/data/buffs.gd")
const Stand = preload("res://scripts/game/shop_stand.gd")
const Interactable = preload("res://scripts/entities/interactable.gd")
const ShopUI = preload("res://scripts/ui/shop_ui.gd")
const Fx = preload("res://scripts/effects/fx.gd")

const LINES := [
	"Hàng tốt đây, giá phải chăng!",
	"Mời tướng quân ghé sạp xem hàng!",
	"Đánh giặc no bụng mới mạnh!",
	"Bùa này linh lắm đấy!",
	"Hộp Kỳ Duyên thử vận may nào!",
]

const MAX_REROLLS := 2

var level := 1
var room_key: String = ""
var stands: Array = []
var reroll_count: int = 0
var _merchant: AnimatedSprite2D
var _vendor_npc: Node2D
var _lanterns: Array[AnimatedSprite2D] = []
var _lantern_lights: Array[PointLight2D] = []
var _line := ""
var _line_t := 0.0
var _t := 0.0
var _spark_t := 0.6
var _mat_half_w: float = 82.0


class VendorNpc extends Interactable:
	var shop_owner: Node2D = null

	func hint() -> String:
		return "Mở sạp Thương Nhân"

	func interact() -> void:
		if shop_owner != null and is_instance_valid(shop_owner) and shop_owner.has_method("open_ui"):
			shop_owner.open_ui()

	func _process(delta: float) -> void:
		super(delta)
		queue_redraw()

	func _draw() -> void:
		if near:
			var a: float = 0.4 + 0.25 * sin(_t * 4.0)
			draw_set_transform(Vector2(0, 14), 0.0, Vector2(1.0, 0.42))
			draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 24, Color(1.0, 0.86, 0.35, a), 1.5)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_hint(-34.0)


func _ready() -> void:
	z_index = 1
	var sh := Sprite2D.new()
	sh.texture = Art.tex("fx/shadow.png")
	sh.position = Vector2(0, -24)
	sh.scale = Vector2(2.8, 1.45)
	sh.z_index = -1
	add_child(sh)

	_merchant = AnimatedSprite2D.new()
	var mtex: Texture2D = Art.tex("world/merchant.png")
	if mtex != null and mtex.get_width() >= 256:
		_merchant.sprite_frames = Art.frames("world/merchant.png", 32, 32, {
			"idle": [[0, 1, 2, 3], 4.8, true],
			"action": [[4, 5, 6, 7], 7.8, true],
		})
		_merchant.play("idle")
	else:
		_merchant.sprite_frames = Art.strip("world/merchant.png", 32, 32, 5.2, true)
		_merchant.play("play")
	_merchant.position = Vector2(0, -42)
	_merchant.scale = Vector2(1.28, 1.28)
	add_child(_merchant)

	var goods: Array = _roll_goods()
	var count: int = goods.size()
	var spacing: float = 48.0 if count <= 3 else 42.0
	var start_x: float = -spacing * float(count - 1) * 0.5
	_mat_half_w = 82.0 if count <= 3 else (spacing * float(count - 1) * 0.5 + 32.0)

	# Hai đèn lồng đỏ treo ở hai cột mái hiên
	for sx in [-_mat_half_w + 10.0, _mat_half_w - 10.0]:
		var lan := AnimatedSprite2D.new()
		lan.sprite_frames = Art.strip("world/shop_lantern.png", 10, 18, 4.0, true)
		lan.position = Vector2(sx, -50)
		lan.z_index = 2
		lan.play("play")
		add_child(lan)
		_lanterns.append(lan)
		var lglow := Art.light(Color(1.0, 0.62, 0.25), 0.95, 0.65)
		lglow.position = Vector2(sx, -48)
		add_child(lglow)
		_lantern_lights.append(lglow)

	for i in count:
		var s := Stand.new()
		s.good = str(goods[i][0])
		s.item = str(goods[i][1])
		s.level = level
		s.stand_id = "%s:%d" % [room_key, i]
		s.position = Vector2(start_x + float(i) * spacing, 12)
		s.bought.connect(_on_bought)
		add_child(s)
		stands.append(s)

	# NPC Thương nhân tương tác riêng (không nằm trong `stands`!)
	var vn := VendorNpc.new()
	vn.shop_owner = self
	vn.radius = 22.0
	vn.position = Vector2(0, -34)
	vn.z_index = 2
	add_child(vn)
	_vendor_npc = vn

	_say(LINES[0])


func _roll_goods() -> Array:
	var pot_roll: float = randf()
	var pot_id: String = "potion_full" if pot_roll < 0.24 else ("potion_big" if pot_roll < 0.62 else "potion_energy")
	var goods: Array = [
		["weapon", WeaponData.roll(level, 1)],
		["potion", pot_id],
	]
	var buff_pool: Dictionary = {} if Net.is_online() else Global.run_buffs
	var offer: Array = BuffData.offer(buff_pool, 1)
	if not offer.is_empty() and randf() < 0.72:
		goods.append(["buff", str(offer[0])])
	else:
		goods.append(["mystery", "mystery_box"])
	var target_count: int = mini(6, 3 + (Net.player_count() - 1)) if Net.is_online() else 3
	for extra_i in range(3, target_count):
		if extra_i % 2 == 1:
			goods.append(["potion", "potion_big" if randf() < 0.5 else "potion_energy"])
		else:
			goods.append(["weapon", WeaponData.roll(level, 1)])
	return goods


func open_ui() -> void:
	if not get_tree().get_nodes_in_group("shop_ui_open").is_empty():
		return
	var ui := ShopUI.new()
	ui.shop = self
	get_tree().current_scene.add_child(ui)


func rerolls_left() -> int:
	return maxi(0, MAX_REROLLS - reroll_count)


func can_reroll() -> bool:
	if rerolls_left() <= 0:
		return false
	for st in stands:
		if is_instance_valid(st) and not bool(st.sold):
			return true
	return false


func reroll_cost() -> int:
	if rerolls_left() <= 0:
		return 999
	var p: Node = Global.local_player()
	var free_first: bool = reroll_count == 0 and p != null and is_instance_valid(p) and p.has_method("buff") and p.buff("thuong_khach") > 0
	if free_first:
		return 0
	return 15 + reroll_count * 10


func try_reroll() -> bool:
	if not can_reroll():
		return false
	var cost: int = reroll_cost()
	if Global.run_coins < cost:
		Sfx.play("buy_fail")
		return false
	Global.run_coins = maxi(0, Global.run_coins - cost)
	reroll_count += 1
	var p: Node = Global.local_player()
	if p != null and is_instance_valid(p):
		if p.has_method("sync_gold_armor"):
			p.sync_gold_armor()
		p.stats_changed.emit()
	var fresh: Array = _roll_goods()
	for i in mini(stands.size(), fresh.size()):
		var st = stands[i]
		if is_instance_valid(st) and not st.sold:
			st.setup_good(str(fresh[i][0]), str(fresh[i][1]), level)
	Sfx.play("forge")
	if get_parent() != null:
		Fx.particles(get_parent(), global_position, Color(1.0, 0.86, 0.35), 18, 90.0, 0.5)
	_say("Mới về hàng nóng hổi đây!")
	return true


func _say(t: String) -> void:
	_line = t
	_line_t = 3.2


func _on_bought(ok: bool) -> void:
	_say(LINES.pick_random() if ok else "Chưa đủ xu rồi, tướng quân!")


func _process(delta: float) -> void:
	_t += delta
	_line_t -= delta
	if _merchant != null and is_instance_valid(_merchant):
		var br := sin(_t * 3.6) * 0.04
		_merchant.position.y = -42.0 + sin(_t * 3.6) * 0.9
		_merchant.scale = Vector2(1.28 * (1.0 - br * 0.5), 1.28 * (1.0 + br))
	for i in _lanterns.size():
		var lan := _lanterns[i]
		if is_instance_valid(lan):
			lan.rotation = sin(_t * 2.4 + float(i) * 1.4) * 0.09
	for i in _lantern_lights.size():
		var lg := _lantern_lights[i]
		if is_instance_valid(lg):
			lg.energy = 0.6 + 0.14 * sin(_t * 6.0 + float(i) * 1.7)
	_spark_t -= delta
	if _spark_t <= 0.0 and get_parent() != null:
		_spark_t = 0.95
		Fx.particles(get_parent(), global_position + Vector2(randf_range(-20, 20), -42), Color(1.0, 0.9, 0.45), 3, 22.0, 0.55, -16.0, 1.5, 45.0, Vector2.UP, Color(1.0, 0.65, 0.25))
	var p: Node = Global.nearest_player(global_position)
	if _merchant != null and is_instance_valid(_merchant):
		var p_near: bool = p != null and is_instance_valid(p) and global_position.distance_to(p.global_position) < 95.0
		if p != null and is_instance_valid(p):
			_merchant.flip_h = p.global_position.x < global_position.x
		if _merchant.sprite_frames != null and _merchant.sprite_frames.has_animation("action"):
			var act: bool = p_near or _line_t > 0.0 or fmod(_t, 4.5) > 3.1
			_merchant.play("action" if act else "idle")
	if p != null and _line_t < -6.0 and global_position.distance_to(p.global_position) < 75.0:
		_say(LINES.pick_random())
	queue_redraw()


func _draw() -> void:
	var mw: float = _mat_half_w
	# Thảm gấm đỏ-vàng dưới các kệ
	var carpet := Rect2(-mw, -4, mw * 2.0, 34)
	draw_rect(carpet, Color(0.56, 0.16, 0.20, 0.82))
	draw_rect(carpet.grow(-3), Color(0.86, 0.66, 0.28, 0.65), false, 1.0)
	draw_rect(carpet, Color(0.95, 0.78, 0.34, 0.92), false, 1.5)
	for cx in [-mw + 5.0, mw - 5.0]:
		for cy in [1.0, 25.0]:
			draw_circle(Vector2(cx, cy), 2.2, Color(1.0, 0.86, 0.38, 0.85))

	# Hai cột gỗ sơn son dựng sạp
	for px in [-mw + 4.0, mw - 4.0]:
		draw_rect(Rect2(px - 2.5, -72, 5, 70), Color(0.42, 0.10, 0.12))
		draw_rect(Rect2(px - 1.5, -72, 2, 70), Color(0.68, 0.18, 0.20))
		draw_rect(Rect2(px - 4.0, -5, 8, 4), Color(0.55, 0.50, 0.45))

	# Mái hiên vải sọc đỏ-kem & viền tua vàng
	var awning_top: float = -76.0
	var awning_bot: float = -60.0
	draw_rect(Rect2(-mw - 4, awning_top - 2, mw * 2.0 + 8, 18), Color(0.18, 0.06, 0.08, 0.95))
	var stripes: int = int(maxf(8.0, floor((mw * 2.0) / 14.0)))
	var sw: float = (mw * 2.0) / float(stripes)
	for i in stripes:
		var sx: float = -mw + float(i) * sw
		var col := Color(0.76, 0.18, 0.22) if i % 2 == 0 else Color(0.94, 0.84, 0.64)
		draw_rect(Rect2(sx, awning_top, sw, awning_bot - awning_top), col)
		draw_circle(Vector2(sx + sw * 0.5, awning_bot), sw * 0.45, col)
		draw_circle(Vector2(sx + sw * 0.5, awning_bot + 3.0), 1.5, Color(1.0, 0.85, 0.32))
	draw_line(Vector2(-mw - 4, awning_top), Vector2(mw + 4, awning_top), Color(0.95, 0.78, 0.32), 2.0)

	# Bảng hiệu sơn mài "SẠP THƯƠNG NHÂN"
	var sign_w: float = 112.0
	var sign_r := Rect2(-sign_w * 0.5, -88, sign_w, 13)
	draw_rect(sign_r, Color(0.24, 0.06, 0.09, 0.96))
	draw_rect(sign_r, Color(0.95, 0.78, 0.32), false, 1.2)
	Art.draw_text(self, Vector2(0, -78), "SẠP THƯƠNG NHÂN", 11, Color(1.0, 0.88, 0.42))

	# Bong bóng lời thoại gọn đẹp khi bà hàng nói
	if _line_t > 0.0:
		var a: float = clampf(_line_t, 0.0, 1.0)
		var bob_y: float = sin(_t * 5.0) * 1.5
		var btxt: String = "\"%s\"" % _line
		var bw: float = Art.text_width(btxt, 11) + 14.0
		var br := Rect2(-bw * 0.5, -106.0 + bob_y, bw, 14)
		draw_rect(br, Color(0.08, 0.04, 0.07, 0.9 * a))
		draw_rect(br, Color(0.92, 0.74, 0.32, 0.9 * a), false, 1.0)
		draw_circle(Vector2(bw * 0.5 + 4.0, -99.0 + bob_y), 2.2, Color(1.0, 0.88, 0.4, 0.85 * a))
		Art.draw_text(self, Vector2(0, -96.0 + bob_y), btxt, 11, Color(1, 0.96, 0.86, a))
