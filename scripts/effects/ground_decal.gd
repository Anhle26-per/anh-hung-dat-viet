extends Node2D
## Vết chiến trường trên mặt đất: vết cháy nổ, vết chém, mảnh giáp, dấu chân, mực máu.

const MAX_DECALS := 36

var kind: String = "scorch"
var decal_color: Color = Color.WHITE
var decal_scale: float = 1.0
var life: float = 7.0
var max_life: float = 7.0

var _bits: Array = []


func _ready() -> void:
	z_index = -1
	decal_scale = maxf(0.2, decal_scale)
	if kind == "footstep" and is_equal_approx(life, 7.0) and is_equal_approx(max_life, 7.0):
		life = 2.0
		max_life = 2.0
	max_life = maxf(max_life, maxf(life, 0.05))
	_enforce_cap()
	add_to_group("ground_decals")
	_build_bits()
	queue_redraw()


func _enforce_cap() -> void:
	if not is_inside_tree():
		return
	var existing: Array = get_tree().get_nodes_in_group("ground_decals")
	var active: Array = []
	for node in existing:
		if node != self and is_instance_valid(node) and not node.is_queued_for_deletion():
			active.append(node)
	var to_remove: int = active.size() - (MAX_DECALS - 1)
	if to_remove <= 0:
		return
	for i in to_remove:
		var old: Node = active[i]
		old.remove_from_group("ground_decals")
		old.queue_free()


func _build_bits() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3(position.x, position.y, rotation)) ^ hash(kind) ^ int(Time.get_ticks_usec() & 0xffff)
	_bits.clear()
	match kind:
		"scorch":
			for i in 7:
				var ang := rng.randf_range(0.0, TAU)
				var dist := rng.randf_range(4.0, 14.0)
				_bits.append({
					"ang": ang,
					"dist": dist,
					"r": rng.randf_range(1.0, 2.4),
					"len": rng.randf_range(3.5, 7.5),
				})
		"slash_mark":
			for i in 3:
				_bits.append({
					"y": lerpf(-3.2, 3.2, float(i) / 2.0) + rng.randf_range(-0.8, 0.8),
					"len": rng.randf_range(10.0, 15.0) * (1.0 if i == 1 else 0.78),
					"tilt": rng.randf_range(-0.14, 0.14),
				})
		"armor_shards":
			for i in 6:
				var ang := (TAU * float(i) / 6.0) + rng.randf_range(-0.35, 0.35)
				var dist := rng.randf_range(3.5, 13.0)
				_bits.append({
					"pos": Vector2.from_angle(ang) * dist,
					"rot": rng.randf_range(0.0, TAU),
					"w": rng.randf_range(2.4, 4.4),
					"h": rng.randf_range(1.5, 2.8),
					"gold": i % 2 == 0,
				})
		"footstep":
			for i in 2:
				_bits.append({
					"pos": Vector2(-2.2 if i == 0 else 2.2, -2.6 if i == 0 else 2.6),
					"r": rng.randf_range(1.6, 2.2),
				})
		"blood_ink":
			for i in 6:
				var ang := rng.randf_range(0.0, TAU)
				var dist := rng.randf_range(2.5, 11.5)
				_bits.append({
					"pos": Vector2.from_angle(ang) * dist,
					"r": rng.randf_range(1.1, 3.0),
				})
		_:
			for i in 4:
				var ang := rng.randf_range(0.0, TAU)
				_bits.append({"pos": Vector2.from_angle(ang) * rng.randf_range(2.0, 8.0), "r": rng.randf_range(1.2, 2.5)})


func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	var fade_win := minf(1.5, max_life * 0.45)
	if life < fade_win and fade_win > 0.0:
		modulate.a = clampf(life / fade_win, 0.0, 1.0)
	else:
		modulate.a = 1.0


func _draw() -> void:
	var s := decal_scale
	var c := decal_color
	match kind:
		"scorch":
			var outer := Color(c.r * 0.45, c.g * 0.45, c.b * 0.45, 0.36)
			var core := Color(0.08, 0.05, 0.05, 0.62)
			var ring := Color(c.lerp(Color(0.28, 0.17, 0.12), 0.55), 0.54)
			draw_circle(Vector2.ZERO, 13.5 * s, outer)
			draw_circle(Vector2.ZERO, 8.5 * s, core)
			draw_arc(Vector2.ZERO, 10.8 * s, 0.0, TAU, 18, ring, maxf(1.0, 1.6 * s))
			for idx in _bits.size():
				var b: Dictionary = _bits[idx]
				var dir := Vector2.from_angle(float(b["ang"]))
				if idx < 4:
					draw_line(dir * (5.5 * s), dir * ((5.5 + float(b["len"])) * s), Color(0.10, 0.07, 0.06, 0.55), maxf(1.0, 1.2 * s))
				draw_circle(dir * (float(b["dist"]) * s), float(b["r"]) * s, Color(0.22, 0.18, 0.16, 0.45))
		"slash_mark":
			var gouge_col := c.lerp(Color(1.0, 0.84, 0.35), 0.28) if c != Color.WHITE else Color(0.95, 0.35, 0.35)
			for b in _bits:
				var half_l := float(b["len"]) * s
				var y := float(b["y"]) * s
				var dy := tan(float(b["tilt"])) * half_l
				var p0 := Vector2(-half_l, y - dy)
				var p1 := Vector2(half_l, y + dy)
				draw_line(p0 + Vector2(0.0, 0.8 * s), p1 + Vector2(0.0, 0.8 * s), Color(0.07, 0.04, 0.05, 0.58), maxf(1.4, 2.4 * s))
				draw_line(p0, p1, Color(gouge_col.r, gouge_col.g, gouge_col.b, 0.78), maxf(1.0, 1.2 * s))
		"armor_shards":
			var base_tint := c if c != Color.WHITE else Color(0.88, 0.72, 0.35)
			for b in _bits:
				var p: Vector2 = b["pos"] * s
				var rot := float(b["rot"])
				var w := float(b["w"]) * s
				var h := float(b["h"]) * s
				var ax := Vector2.from_angle(rot)
				var ay := Vector2(-ax.y, ax.x)
				var pts := PackedVector2Array([
					p - ax * (w * 0.5) - ay * (h * 0.35),
					p + ax * (w * 0.55) - ay * (h * 0.2),
					p + ax * (w * 0.35) + ay * (h * 0.5),
					p - ax * (w * 0.4) + ay * (h * 0.4),
				])
				var sh_pts := PackedVector2Array()
				for pt in pts:
					sh_pts.append(pt + Vector2(0.6 * s, 1.1 * s))
				draw_colored_polygon(sh_pts, Color(0.05, 0.04, 0.05, 0.42))
				var shard_col := base_tint.lightened(0.25) if bool(b["gold"]) else Color(0.62, 0.66, 0.74).lerp(base_tint, 0.35)
				draw_colored_polygon(pts, Color(shard_col.r, shard_col.g, shard_col.b, 0.85))
				draw_line(pts[0], pts[1], Color(1.0, 0.96, 0.82, 0.65), 1.0)
		"footstep":
			var dust := Color(c.lerp(Color(0.76, 0.70, 0.58), 0.62), 0.36)
			for b in _bits:
				var p: Vector2 = b["pos"] * s
				var r := float(b["r"]) * s
				draw_rect(Rect2(p - Vector2(r * 1.1, r * 0.65), Vector2(r * 2.2, r * 1.3)), dust)
				draw_circle(p + Vector2(-r * 0.8, 0.0), r * 0.55, Color(dust.r, dust.g, dust.b, 0.24))
		"blood_ink":
			var ink := c.lerp(Color(0.36, 0.04, 0.08), 0.5)
			draw_circle(Vector2.ZERO, 4.6 * s, Color(ink.r, ink.g, ink.b, 0.64))
			draw_circle(Vector2(2.1, -1.3) * s, 2.8 * s, Color(ink.r * 0.7, ink.g * 0.7, ink.b * 0.7, 0.58))
			for b in _bits:
				var p: Vector2 = b["pos"] * s
				draw_circle(p, float(b["r"]) * s, Color(ink.r, ink.g, ink.b, 0.55))
		_:
			draw_circle(Vector2.ZERO, 6.0 * s, Color(c.r, c.g, c.b, 0.45))
