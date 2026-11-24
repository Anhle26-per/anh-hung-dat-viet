extends Node2D
## Gánh hàng rong: bà hàng đội nón lá bày 3 kệ tre bán vũ khí, hồ lô thuốc và bùa phúc lành.
## Trả bằng xu nhặt được trong lượt chơi.

const Art = preload("res://scripts/art/art.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")
const BuffData = preload("res://scripts/data/buffs.gd")
const Stand = preload("res://scripts/game/shop_stand.gd")

const LINES := ["Hàng tốt đây, giá phải chăng!", "Mua đi tướng quân ơi!", "Đánh giặc no bụng mới mạnh!", "Bùa này linh lắm đấy!"]

var level := 1
var stands: Array = []
var _merchant: AnimatedSprite2D
var _line := ""
var _line_t := 0.0
var _t := 0.0


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
	# chiếu cói trải dưới các kệ
	var goods: Array = [["weapon", WeaponData.roll(level, 1)], ["potion", "potion_big" if randf() < 0.5 else "potion_energy"]]
	var offer := BuffData.offer(Global.run_buffs, 1)
	if offer.is_empty():
		goods.append(["weapon", WeaponData.roll(level, 0)])
	else:
		goods.append(["buff", offer[0]])
	for i in goods.size():
		var s := Stand.new()
		s.good = goods[i][0]
		s.item = goods[i][1]
		s.level = level
		s.position = Vector2((i - 1) * 46, 8)
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
	var p = get_tree().get_first_node_in_group("player")
	if p != null and _line_t < -6.0 and global_position.distance_to(p.global_position) < 70.0:
		_say(LINES.pick_random())
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-72, -6, 144, 30), Color(0.78, 0.66, 0.4, 0.55))
	for y in range(-4, 24, 4):
		draw_line(Vector2(-72, y), Vector2(72, y), Color(0.6, 0.48, 0.28, 0.5))
	draw_rect(Rect2(-72, -6, 144, 30), Color(0.5, 0.2, 0.16, 0.8), false, 1.0)
	Art.draw_text(self, Vector2(0, -66), "Gánh hàng rong", 13, Color(1, 0.85, 0.5))
	if _line_t > 0.0:
		Art.draw_text(self, Vector2(0, -77), "\"%s\"" % _line, 12, Color(1, 1, 1, clampf(_line_t, 0.0, 1.0)))
