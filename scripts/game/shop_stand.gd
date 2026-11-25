extends "res://scripts/entities/interactable.gd"
## Một kệ sơn mài trong sạp thương nhân. good: weapon / potion / buff / mystery

signal bought(ok: bool)

const WeaponData = preload("res://scripts/data/weapons.gd")
const BuffData = preload("res://scripts/data/buffs.gd")
const SynergyData = preload("res://scripts/data/synergy.gd")
const Pickup = preload("res://scripts/entities/pickup.gd")
const Fx = preload("res://scripts/effects/fx.gd")

var good := "weapon"
var item := ""
var level := 1
var base_price := 10
var price := 10
var sold := false
var stand_id: String = ""
var _pending_buy: bool = false


func _ready() -> void:
	add_to_group("shop_stands")
	z_index = 1
	radius = 18.0
	setup_good(good, item, level)


func setup_good(g: String, it: String, lvl: int) -> void:
	good = g
	item = it
	level = lvl
	match good:
		"weapon":
			base_price = 8 + int(WeaponData.get_data(item).get("tier", 1)) * 9 + level
		"potion":
			if item == "potion_full":
				base_price = 16 + int(level / 2)
			else:
				base_price = (10 if item == "potion_big" else 7) + int(level / 2)
		"buff":
			var tr: int = BuffData.tier(item)
			base_price = (38 if tr >= 3 else (32 if tr == 2 else 26)) + level * 2
		"mystery":
			base_price = 14 + level
	refresh_price()


func refresh_price() -> void:
	var p: Node = Global.local_player()
	var disc: bool = p != null and is_instance_valid(p) and p.has_method("buff") and p.buff("thuong_khach") > 0
	if disc:
		price = maxi(1, int(round(float(base_price) * 0.7)))
	else:
		price = base_price
	queue_redraw()


func _title() -> String:
	match good:
		"weapon":
			return WeaponData.get_data(item).name
		"potion":
			if item == "potion_full":
				return "Tiên tửu (đầy máu & giáp)"
			return "Hồ lô lớn (+5 máu)" if item == "potion_big" else "Hồ lô linh khí (+80)"
		"buff":
			return "Bùa: %s" % BuffData.DATA[item].name
		"mystery":
			return "Hộp Kỳ Duyên"
	return ""


func hint() -> String:
	return "Mua %s - %d xu" % [_title(), price]


func inspect_info(p: Node) -> Dictionary:
	var icon_tex: Texture2D = _icon()
	var title_txt: String = _title()
	var title_col := Color(1.0, 0.92, 0.72)
	var badge_txt := "Hàng"
	var badge_col := Color(0.85, 0.72, 0.45)
	var desc_txt := ""
	var stats_txt := ""
	var syn_txt := ""
	var syn_col := Color(0.84, 0.9, 0.98)

	match good:
		"weapon":
			var w: Dictionary = WeaponData.get_data(item)
			var tier: int = int(w.get("tier", 1))
			title_txt = str(w.get("name", item))
			title_col = WeaponData.tier_color(item)
			badge_txt = "Vũ khí · %s" % WeaponData.TIER_NAMES[tier]
			badge_col = title_col
			desc_txt = str(w.get("desc", ""))
			stats_txt = "ST %d  ·  Tốc %.2fs  ·  NL %d" % [
				int(w.get("damage", 1)) * int(w.get("count", 1)),
				float(w.get("cooldown", 0.3)),
				int(w.get("energy", 0)),
			]
			var imp_name: String = SynergyData.imprint_name(item)
			if p != null and is_instance_valid(p):
				var slv: int = SynergyData.level(str(p.get("hero_id")), item)
				if slv == 2:
					syn_txt = "★★ Định mệnh · Ấn: %s" % imp_name
					syn_col = Color(1.0, 0.88, 0.35)
				elif slv == 1:
					syn_txt = "★ Hợp chiêu · Ấn: %s" % imp_name
					syn_col = Color(0.84, 0.92, 1.0)
				else:
					syn_txt = "Ấn: %s" % imp_name
					syn_col = SynergyData.family_color(SynergyData.family(item))
		"potion":
			if item == "potion_full":
				title_txt = "Tiên tửu"
				title_col = Color(1.0, 0.86, 0.35)
				badge_txt = "Thần dược · Hồi phục"
				badge_col = Color(1.0, 0.78, 0.32)
				desc_txt = "Hồi đầy toàn bộ Máu, Giáp và giải mọi trạng thái bất lợi."
			elif item == "potion_big":
				title_txt = "Hồ lô lớn"
				title_col = Color(1.0, 0.55, 0.55)
				badge_txt = "Hồ lô · Hồi máu"
				badge_col = Color(1.0, 0.45, 0.48)
				desc_txt = "Hồi +5 Máu và giải trừ cháy / độc."
			else:
				title_txt = "Hồ lô linh khí"
				title_col = Color(0.55, 0.85, 1.0)
				badge_txt = "Hồ lô · Linh khí"
				badge_col = Color(0.45, 0.82, 1.0)
				desc_txt = "Nạp ngay +80 Năng lượng để tung đòn."
		"buff":
			var b: Dictionary = BuffData.DATA[item]
			title_txt = str(b.get("name", item))
			badge_col = BuffData.tier_color(item)
			title_col = badge_col.lightened(0.15)
			badge_txt = "%s · %s" % [BuffData.tier_name(item), BuffData.category_name(item)]
			desc_txt = str(b.get("desc", ""))
			var cur_stk: int = int(Global.run_buffs.get(item, 0))
			var max_stk: int = int(b.get("max", 1))
			stats_txt = "Đang có: %d / %d" % [cur_stk, max_stk]
		"mystery":
			title_txt = "Hộp Kỳ Duyên"
			title_col = Color(0.9, 0.65, 1.0)
			badge_txt = "Bí ẩn · Thử vận may"
			badge_col = Color(0.82, 0.48, 1.0)
			desc_txt = "Mở ngẫu nhiên: binh khí bậc cao, bùa phúc lành, kho xu hoặc hồi phục!"

	return {
		"title": title_txt,
		"title_color": title_col,
		"badge": badge_txt,
		"badge_color": badge_col,
		"desc": desc_txt,
		"stats": stats_txt,
		"synergy": syn_txt,
		"synergy_color": syn_col,
		"icon": icon_tex,
		"price": price,
		"base_price": base_price,
		"sold": sold,
	}


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
	if p.has_method("sync_gold_armor"):
		p.sync_gold_armor()
	var par: Node = get_parent().get_parent()
	match good:
		"weapon":
			if not Net.is_online() or sync_weapon:
				_spawn_bought_weapon(par, item, sync_weapon)
		"potion":
			if item == "potion_full":
				p.hp = p.max_hp
				p.armor = p.max_armor
				p.status.clear()
				Fx.float_text(par, p.global_position + Vector2(0, -24), "Đầy máu & giáp!", Color(1.0, 0.88, 0.35), 14)
			elif item == "potion_big":
				p.heal(5)
				p.status.clear()
			else:
				p.add_energy(80)
				Fx.float_text(par, p.global_position + Vector2(0, -22), "+80 linh khí", Color(0.5, 0.8, 1.0))
		"buff":
			p.apply_buff(item)
			Fx.float_text(par, p.global_position + Vector2(0, -30), BuffData.DATA[item].name, BuffData.tier_color(item), 15)
		"mystery":
			_resolve_mystery(p, par, sync_weapon)
	Fx.particles(par, global_position, Color(1, 0.85, 0.35), 14, 70.0, 0.5, -40.0, 2.0)
	Sfx.play("buy")
	p.stats_changed.emit()
	bought.emit(true)
	queue_redraw()


func _resolve_mystery(p: Node, par: Node, sync_weapon: bool) -> void:
	var roll: float = randf()
	if roll < 0.30:
		var rw: String = WeaponData.roll(level, 2)
		if not Net.is_online() or sync_weapon:
			_spawn_bought_weapon(par, rw, sync_weapon)
		Fx.float_text(par, global_position + Vector2(0, -32), "Kỳ duyên: %s!" % WeaponData.get_data(rw).name, WeaponData.tier_color(rw), 15)
	elif roll < 0.60:
		var offer: Array = BuffData.offer(Global.run_buffs, 1)
		if not offer.is_empty():
			var bid: String = str(offer[0])
			p.apply_buff(bid)
			Fx.float_text(par, global_position + Vector2(0, -32), "Kỳ duyên: %s!" % BuffData.DATA[bid].name, BuffData.tier_color(bid), 15)
		else:
			p.hp = p.max_hp
			p.armor = p.max_armor
			Fx.float_text(par, global_position + Vector2(0, -32), "Kỳ duyên: Hồi đầy thể lực!", Color(0.6, 1.0, 0.6), 14)
	elif roll < 0.82:
		# Rơi túi xu thật trên mặt đất để không làm sai giá giao dịch tức thời
		for i in 10:
			var cp := Pickup.new()
			cp.kind = "coin"
			cp.amount = 3
			cp.position = global_position + Vector2(randf_range(-10, 10), 14 + randf_range(-4, 6))
			par.add_child(cp)
		Fx.float_text(par, global_position + Vector2(0, -32), "Kỳ duyên: Mưa tiền xu!", Color(1.0, 0.88, 0.35), 15)
	else:
		p.hp = p.max_hp
		p.armor = p.max_armor
		p.add_energy(100)
		p.status.clear()
		Fx.float_text(par, global_position + Vector2(0, -32), "Kỳ duyên: Hồi phục hoàn hảo!", Color(0.55, 0.95, 1.0), 15)


func _spawn_bought_weapon(par: Node, wid: String, broadcast: bool) -> void:
	var w := Pickup.new()
	w.kind = "weapon"
	w.weapon_id = wid
	var drop_pos: Vector2 = global_position + Vector2(0, 18)
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
				"weapon_id": wid,
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
		_spawn_bought_weapon(par, item, true)
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
		"mystery":
			return Art.tex("items/mystery_box.png")
	return null


func _process(delta: float) -> void:
	super(delta)
	queue_redraw()


func _draw() -> void:
	var st := Art.tex("world/stand.png")
	draw_texture(st, Vector2(-st.get_width() / 2.0, -5))
	if sold:
		draw_rect(Rect2(-14, 12, 28, 11), Color(0.12, 0.06, 0.08, 0.78))
		Art.draw_text(self, Vector2(0, 21), "Đã bán", 10, Color(0.85, 0.78, 0.72, 0.8))
		return

	var glow_col := Color(0.9, 0.85, 0.7, 0.0)
	if good == "weapon":
		glow_col = WeaponData.tier_color(item)
	elif good == "buff":
		glow_col = BuffData.tier_color(item)
	elif good == "mystery":
		glow_col = Color(0.82, 0.45, 1.0)
	elif good == "potion" and item == "potion_full":
		glow_col = Color(1.0, 0.84, 0.32)

	if glow_col.a > 0.0:
		var pulse: float = 0.5 + 0.5 * sin(_t * 3.2)
		draw_set_transform(Vector2(0, 0), 0.0, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, 10.5, Color(glow_col, 0.24 + 0.12 * pulse))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if good == "mystery" or (good == "buff" and BuffData.tier(item) >= 3) or (good == "weapon" and int(WeaponData.get_data(item).get("tier", 1)) >= 3):
			draw_rect(Rect2(-3.0, -24.0, 6.0, 22.0), Color(glow_col, 0.14 + 0.08 * pulse))

	var ic := _icon()
	if ic != null:
		var bob := sin(_t * 3.0) * 1.5
		var sc := 0.85 if good == "buff" else 1.0
		var sz := Vector2(ic.get_width(), ic.get_height()) * sc
		draw_texture_rect(ic, Rect2(Vector2(-sz.x / 2.0, -sz.y - 3 + bob), sz), false)

	var ctex := Art.tex("items/coin.png")
	var txt := str(price)
	var tw := Art.text_width(txt, 12) + 14.0
	var tag_bg := Color(0.08, 0.04, 0.07, 0.88)
	var tag_br := Color(0.95, 0.78, 0.32, 0.9) if Global.run_coins >= price else Color(0.85, 0.3, 0.3, 0.9)
	draw_rect(Rect2(-tw / 2.0, 12, tw, 12), tag_bg)
	draw_rect(Rect2(-tw / 2.0, 12, tw, 12), tag_br, false, 1.0)
	draw_texture_rect_region(ctex, Rect2(-tw / 2.0 + 2, 13.5, 9, 9), Rect2(0, 0, 9, 9))
	Art.draw_text(self, Vector2(-tw / 2.0 + 13, 21.5), txt, 12, Color(1, 0.88, 0.45) if Global.run_coins >= price else Color(1, 0.5, 0.45), false)
	if price < base_price:
		Art.draw_text(self, Vector2(0, -28), "-30%", 10, Color(0.55, 1.0, 0.65))
	draw_hint(-42.0)
