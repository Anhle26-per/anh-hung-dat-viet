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
var stand_id: String = ""
var _pending_buy: bool = false


func _ready() -> void:
	add_to_group("shop_stands")
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
	if sold or _pending_buy:
		return
	var p: Node = Global.local_player()
	if p == null:
		return
	if Global.run_coins < price:
		Sfx.play("buy_fail")
		Fx.float_text(get_parent().get_parent(), global_position + Vector2(0, -30), "Không đủ xu!", Color(1, 0.5, 0.4), 13)
		bought.emit(false)
		return
	if Net.is_online():
		if Net.is_host():
			var ns: Node = get_tree().get_first_node_in_group("net_sync")
			if ns != null:
				if ns.sold_stands.has(stand_id):
					return
				ns.sold_stands[stand_id] = true
			_apply_buy_local(p, true)
			Net.send_world_event("shop_sold", {"id": stand_id, "buyer": Net.local_peer_id()}, false)
		else:
			_pending_buy = true
			Net.send_world_event("shop_buy", {"id": stand_id}, true)
		return
	_apply_buy_local(p, false)


func _apply_buy_local(p: Node, sync_weapon: bool) -> void:
	Global.run_coins = maxi(0, Global.run_coins - price)
	sold = true
	enabled = false
	near = false
	_pending_buy = false
	var par: Node = get_parent().get_parent()
	match good:
		"weapon":
			if not Net.is_online() or sync_weapon:
				_spawn_bought_weapon(par, sync_weapon)
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


func _spawn_bought_weapon(par: Node, broadcast: bool) -> void:
	var w := Pickup.new()
	w.kind = "weapon"
	w.weapon_id = item
	var drop_pos: Vector2 = global_position + Vector2(0, 16)
	w.position = drop_pos
	if broadcast:
		var ns: Node = get_tree().get_first_node_in_group("net_sync")
		if ns != null:
			w.pickup_id = ns.alloc_pickup_id()
			par.add_child(w)
			ns.register_pickup(w)
			Net.send_world_event("spawn_pickup", {
				"id": w.pickup_id,
				"kind": "weapon",
				"amount": 1,
				"weapon_id": item,
				"material_id": "",
				"x": drop_pos.x,
				"y": drop_pos.y,
			}, false)
			return
	par.add_child(w)


func host_approve_buy(buyer_peer: int) -> void:
	if sold:
		return
	sold = true
	enabled = false
	near = false
	_pending_buy = false
	var par: Node = get_parent().get_parent()
	if good == "weapon":
		_spawn_bought_weapon(par, true)
	Fx.particles(par, global_position, Color(1, 0.85, 0.35), 14, 70.0, 0.5, -40.0, 2.0)
	bought.emit(true)
	queue_redraw()
	Net.send_world_event("shop_sold", {"id": stand_id, "buyer": buyer_peer}, false)


func client_apply_sold(buyer_peer: int) -> void:
	if sold:
		return
	var p: Node = Global.local_player()
	if buyer_peer == Net.local_peer_id() and p != null and is_instance_valid(p):
		_apply_buy_local(p, false)
	else:
		sold = true
		enabled = false
		near = false
		_pending_buy = false
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
