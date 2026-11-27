extends "res://scripts/entities/interactable.gd"
## Lồng giam NPC Doanh Trại trong hầm ngục: dọn sạch giặc rồi phá lồng để giải cứu.

const CampNpcs = preload("res://scripts/data/camp_npcs.gd")
const Fx = preload("res://scripts/effects/fx.gd")

var npc_id: String = "than_y_tue_tinh"
var rescued: bool = false
var _spr: Sprite2D = null
var _light: PointLight2D = null
var _has_tex: bool = false


func setup(id: String) -> void:
	if CampNpcs.NPCS.has(id):
		npc_id = id


func _ready() -> void:
	add_to_group("rescue_npcs")
	radius = 28.0
	z_index = 2

	var info: Dictionary = CampNpcs.get_npc(npc_id)
	var col: Color = info.get("color", Color(1.0, 0.88, 0.35))

	if ResourceLoader.exists("res://assets/sprites/world/rescue_cage.png"):
		_has_tex = true
		_spr = Sprite2D.new()
		_spr.texture = Art.tex("world/rescue_cage.png")
		_spr.position = Vector2(0, -10)
		add_child(_spr)

	_light = Art.light(col, 0.9, 0.75)
	_light.position = Vector2(0, -8)
	add_child(_light)


func _process(delta: float) -> void:
	super._process(delta)
	if not rescued:
		queue_redraw()


func hint() -> String:
	if rescued:
		return ""
	return "Giải cứu %s" % CampNpcs.npc_name(npc_id)


func interact() -> void:
	if rescued or not enabled:
		return
	var par: Node = get_parent()
	if par != null and str(par.get("state")) == "fighting":
		Fx.float_text(par, global_position + Vector2(0, -26), "Hãy dọn sạch giặc trước!", Color(1.0, 0.45, 0.35), 14)
		Sfx.play("hit_metal")
		return

	rescued = true
	enabled = false
	if _spr != null and is_instance_valid(_spr):
		_spr.visible = false
	if _light != null and is_instance_valid(_light):
		_light.enabled = false

	var info: Dictionary = CampNpcs.get_npc(npc_id)
	var col: Color = info.get("color", Color(1.0, 0.88, 0.35))
	var fx_parent: Node = par if par != null else self

	Sfx.play("chest_open")
	Fx.burst(fx_parent, global_position + Vector2(0, -8), Color(1.0, 0.88, 0.35), 44.0, 0.5)
	Fx.particles(fx_parent, global_position + Vector2(0, -8), Color(1.0, 0.90, 0.38), 18, 95.0, 0.65, -45.0, 2.0, 180.0, Vector2.UP, col)

	if Global != null:
		Global.run_coins += 35
		if Global.has_method("add_run_material"):
			Global.add_run_material("ngoc_than", 1)
		if Global.has_method("rescue_npc"):
			Global.call("rescue_npc", npc_id)
		else:
			var arr: Variant = Global.get("rescued_npcs")
			if arr is Array and not (arr as Array).has(npc_id):
				(arr as Array).append(npc_id)
				if Global.has_method("save_game"):
					Global.save_game()
		var lp: Node = Global.local_player()
		if lp != null and is_instance_valid(lp):
			if lp.has_method("on_coins_collected"):
				lp.on_coins_collected(35)
			if lp.has_signal("stats_changed"):
				lp.stats_changed.emit()

	var n_name: String = CampNpcs.npc_name(npc_id)
	Fx.float_text(fx_parent, global_position + Vector2(0, -28), "Đã giải cứu %s!" % n_name, Color(1.0, 0.92, 0.42), 15)
	Fx.float_text(fx_parent, global_position + Vector2(0, -14), "+35 xu & +1 Ngọc thần", Color(0.55, 0.96, 0.76), 12)
	if is_inside_tree():
		get_tree().call_group("hud", "show_banner", "Đã giải cứu %s!" % n_name)
	queue_redraw()


func _draw() -> void:
	if rescued:
		draw_circle(Vector2(0, 4), 10.0, Color(0.35, 0.28, 0.22, 0.25))
		return

	var info: Dictionary = CampNpcs.get_npc(npc_id)
	var col: Color = info.get("color", Color(1.0, 0.88, 0.35))
	var pulse: float = 0.5 + 0.3 * sin(_t * 4.2)
	var ring_r: float = 17.0 + sin(_t * 3.0) * 1.5
	draw_circle(Vector2(0, 2), ring_r, Color(col.r, col.g, col.b, 0.14 * pulse))
	draw_arc(Vector2(0, 2), ring_r, 0.0, TAU, 24, Color(1.0, 0.88, 0.38, 0.55 * pulse), 1.6)

	if not _has_tex:
		# Fallback khung lồng sắt thủ công nếu chưa có sprite
		draw_rect(Rect2(-13, -24, 26, 28), Color(0.14, 0.12, 0.16, 0.88))
		draw_circle(Vector2(0, -12), 5.0, col)
		draw_rect(Rect2(-4, -7, 8, 9), col.darkened(0.25))
		for bx in [-10, -5, 0, 5, 10]:
			draw_line(Vector2(bx, -24), Vector2(bx, 4), Color(0.65, 0.70, 0.78), 1.5)
		draw_rect(Rect2(-13, -24, 26, 28), Color(0.85, 0.72, 0.35), false, 1.8)

	Art.draw_text(self, Vector2(0, -34), CampNpcs.npc_name(npc_id), 11, Color(1.0, 0.94, 0.65))
	draw_hint(-47.0)
