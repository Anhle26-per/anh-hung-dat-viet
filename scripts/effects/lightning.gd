extends Node2D
## Tia sét gấp khúc nối các điểm (Búa Thiên Lôi).

var points: Array = []
var _t := 0.0
var _seed := 0
const DUR := 0.22


func _ready() -> void:
	z_index = 8
	material = CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_seed = randi()


func _process(delta: float) -> void:
	_t += delta
	if _t >= DUR:
		queue_free()
		return
	if int(_t * 40.0) % 2 == 0:
		_seed = randi()
	queue_redraw()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	var a := 1.0 - _t / DUR
	for i in range(points.size() - 1):
		var p0: Vector2 = points[i] - global_position
		var p1: Vector2 = points[i + 1] - global_position
		var pts := PackedVector2Array([p0])
		var n := 6
		var perp := (p1 - p0).orthogonal().normalized()
		for k in range(1, n):
			pts.append(p0.lerp(p1, float(k) / n) + perp * rng.randf_range(-6, 6))
		pts.append(p1)
		draw_polyline(pts, Color(0.4, 0.8, 1.0, 0.5 * a), 4.0)
		draw_polyline(pts, Color(0.85, 0.95, 1.0, a), 1.5)
