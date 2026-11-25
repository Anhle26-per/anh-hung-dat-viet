extends Node2D
## Gánh hàng rong: bà hàng đội nón lá bày 3 kệ tre bán vũ khí, hồ lô thuốc và bùa phúc lành.
## Trả bằng xu nhặt được trong lượt chơi.

const Art = preload("res://scripts/art/art.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")
const BuffData = preload("res://scripts/data/buffs.gd")
const Stand = preload("res://scripts/game/shop_stand.gd")

const LINES := ["Hàng tốt đây, giá phải chăng!", "Mua đi tướng quân ơi!", "Đánh giặc no bụng mới mạnh!", "Bùa này linh lắm đấy!"]

var level := 1
var room_key: String = ""
var stands: Array = []
var _merchant: AnimatedSprite2D
var _line := ""
var _line_t := 0.0
var _t := 0.0
var _mat_half_w: float = 72.0


func _ready() -> void:
	z_index = 1
	var sh := Sprite2D.new()
	sh.texture = Art.tex("fx/shadow.png")
	sh.position = Vector2(0, -25)
	sh.scale = Vector2(2.6, 1.4)
	sh.z_index = -1
	add_child(sh)
	_merchant = AnimatedSprite2D.new()
	_merchant.sprite_frames = Art.strip("world/merchant.png", 30, 30, 2.5, true)
	_merchant.position = Vector2(0, -44)
	_merchant.scale = Vector2(1.3, 1.3)
	_merchant.play("play")
	add_child(_merchant)
	# chiếu cói trải dưới các kệ (mở rộng theo số người chơi trong LAN)
	var goods: Array = [["weapon", WeaponData.roll(level, 1)], ["potion", "potion_big" if randf() < 0.5 else "potion_energy"]]
	var buff_pool: Dictionary = {} if Net.is_online() else Global.run_buffs
	var offer: Array = BuffData.offer(buff_pool, 1)
	if offer.is_empty():
		goods.append(["weapon", WeaponData.roll(level, 0)])
	else:
		goods.append(["buff", offer[0]])
	var target_count: int = mini(6, 3 + (Net.player_count() - 1)) if Net.is_online() else 3
	for extra_i in range(3, target_count):
		if extra_i % 2 == 1:
			goods.append(["potion", "potion_big" if randf() < 0.5 else "potion_energy"])
		else:
			goods.append(["weapon", WeaponData.roll(level, 1)])
	var count: int = goods.size()
	var spacing: float = 46.0 if count <= 3 else 40.0
	var start_x: float = -spacing * float(count - 1) * 0.5
	_mat_half_w = 72.0 if count <= 3 else (spacing * float(count - 1) * 0.5 + 26.0)
	for i in count:
		var s := Stand.new()
		s.good = str(goods[i][0])
		s.item = str(goods[i][1])
		s.level = level
		s.stand_id = "%s:%d" % [room_key, i]
		s.position = Vector2(start_x + float(i) * spacing, 8)
		s.bought.connect(_on_bought)
		add_child(s)
		stands.append(s)
	_say(LINES[0])


func _say(t: String) -> void:
	_line = t
	_line_t = 3.0


func _on_bought(ok: bool) -> void:
	_say(LINES.pick_random() if ok else "Chưa đủ xu rồi, tướng quân!")


func _process(delta: float) -> void:
	_t += delta
	_line_t -= delta
	var p: Node = Global.nearest_player(global_position)
	if p != null and _line_t < -6.0 and global_position.distance_to(p.global_position) < 70.0:
		_say(LINES.pick_random())
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-_mat_half_w, -6, _mat_half_w * 2.0, 30), Color(0.78, 0.66, 0.4, 0.55))
	for y in range(-4, 24, 4):
		draw_line(Vector2(-_mat_half_w, y), Vector2(_mat_half_w, y), Color(0.6, 0.48, 0.28, 0.5))
	draw_rect(Rect2(-_mat_half_w, -6, _mat_half_w * 2.0, 30), Color(0.5, 0.2, 0.16, 0.8), false, 1.0)
	Art.draw_text(self, Vector2(0, -66), "Gánh hàng rong", 13, Color(1, 0.85, 0.5))
	if _line_t > 0.0:
		Art.draw_text(self, Vector2(0, -77), "\"%s\"" % _line, 12, Color(1, 1, 1, clampf(_line_t, 0.0, 1.0)))
