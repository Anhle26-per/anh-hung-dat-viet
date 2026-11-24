extends "res://scripts/entities/interactable.gd"
## Một kệ tre trong gánh hàng rong. good: weapon / potion / buff

signal bought(ok: bool)

const WeaponData = preload("res://scripts/data/weapons.gd")
const BuffData = preload("res://scripts/data/buffs.gd")
const Pickup = preload("res://scripts/entities/pickup.gd")
const Fx = preload("res://scripts/effects/fx.gd")

var good := "weapon"
var item := ""
var level := 1
var price := 10
var sold := false


func _ready() -> void:
	z_index = 1
	radius = 18.0
	match good:
		"weapon":
			price = 8 + int(WeaponData.get_data(item).get("tier", 1)) * 9 + level
		"potion":
			price = (10 if item == "potion_big" else 7) + int(level / 2)
		"buff":
			price = 30 + level * 2


func _title() -> String:
	match good:
		"weapon":
			return WeaponData.get_data(item).name
		"potion":
			return "Hồ lô lớn (+5 máu)" if item == "potion_big" else "Hồ lô linh khí (+80)"
		"buff":
			return "Bùa: %s" % BuffData.DATA[item].name
	return ""


func hint() -> String:
	return "Mua %s - %d xu" % [_title(), price]


func interact() -> void:
	if sold:
		return
	var p = get_tree().get_first_node_in_group("player")
	if p == null:
		return
	if Global.run_coins < price:
		Sfx.play("buy_fail")
		Fx.float_text(get_parent().get_parent(), global_position + Vector2(0, -30), "Không đủ xu!", Color(1, 0.5, 0.4), 13)
		bought.emit(false)
		return
	Global.run_coins -= price
	sold = true
	enabled = false
	near = false
	var par: Node = get_parent().get_parent()
	match good:
		"weapon":
			var w := Pickup.new()
			w.kind = "weapon"
			w.weapon_id = item
			w.position = global_position + Vector2(0, 16)
			par.add_child(w)
		"potion":
			if item == "potion_big":
				p.heal(5)
				p.status.clear()
			else:
				p.add_energy(80)
				Fx.float_text(par, p.global_position + Vector2(0, -22), "+80 linh khí", Color(0.5, 0.8, 1.0))
		"buff":
			p.apply_buff(item)
			Fx.float_text(par, p.global_position + Vector2(0, -30), BuffData.DATA[item].name, Color(1, 0.85, 0.4), 15)
	Fx.particles(par, global_position, Color(1, 0.85, 0.35), 14, 70.0, 0.5, -40.0, 2.0)
	Sfx.play("buy")
	p.stats_changed.emit()
	bought.emit(true)
	queue_redraw()


func _icon() -> Texture2D:
	match good:
		"weapon":
			return Art.tex("weapons/%s.png" % item)
		"potion":
			return Art.tex("items/%s.png" % item)
		"buff":
			return Art.tex("ui/buff_%s.png" % item)
	return null


func _process(delta: float) -> void:
	super(delta)
	queue_redraw()


func _draw() -> void:
	var st := Art.tex("world/stand.png")
	draw_texture(st, Vector2(-st.get_width() / 2.0, -4))
	if sold:
		Art.draw_text(self, Vector2(0, 20), "Đã bán", 11, Color(0.8, 0.75, 0.7, 0.7))
		return
	var ic := _icon()
	if ic != null:
		var bob := sin(_t * 3.0) * 1.5
		var sc := 1.0 if good == "weapon" else (0.75 if good == "buff" else 1.0)
		var sz := Vector2(ic.get_width(), ic.get_height()) * sc
		if good == "weapon":
			var col := WeaponData.tier_color(item)
			draw_set_transform(Vector2(0, 0), 0.0, Vector2(1.0, 0.4))
			draw_circle(Vector2.ZERO, 9.0, Color(col, 0.25 + 0.1 * sin(_t * 3.0)))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_texture_rect(ic, Rect2(Vector2(-sz.x / 2.0, -sz.y - 2 + bob), sz), false)
	var ctex := Art.tex("items/coin.png")
	var txt := str(price)
	var w := Art.text_width(txt, 12) + 10
	draw_texture_rect_region(ctex, Rect2(-w / 2.0, 13, 9, 9), Rect2(0, 0, 9, 9))
	Art.draw_text(self, Vector2(-w / 2.0 + 11, 21), txt, 12, Color(1, 0.88, 0.45) if Global.run_coins >= price else Color(1, 0.5, 0.45), false)
	draw_hint(-30.0)
