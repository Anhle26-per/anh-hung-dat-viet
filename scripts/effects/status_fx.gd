extends Node2D
## Trạng thái bất lợi gắn vào người chơi hoặc giặc: Cháy (lửa) và Trúng độc (chướng khí).
## Mỗi trạng thái gây sát thương theo nhịp, hiện biểu tượng trên đầu và tỏa hạt.
## Đơn vị chủ cần có hàm dot_damage(amount: int, kind: String).

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")

# nhịp gây sát thương (giây) và màu hạt
const INFO := {
	"burn": {"tick": 0.5, "color": Color(1.0, 0.55, 0.2), "icon": "ui/status_burn.png"},
	"poison": {"tick": 0.9, "color": Color(0.5, 0.9, 0.25), "icon": "ui/status_poison.png"},
}

var unit = null
var head := 18.0          # độ cao biểu tượng trên đầu
var tick_damage := 1
var _time := {}           # kind -> thời gian còn lại
var _acc := {}            # kind -> tích lũy nhịp
var _fx_t := 0.0


func _ready() -> void:
	z_index = 6


func apply(kind: String, duration: float) -> void:
	if not INFO.has(kind):
		return
	if not _time.has(kind):
		_acc[kind] = 0.0
	_time[kind] = maxf(float(_time.get(kind, 0.0)), duration)
	queue_redraw()


func has(kind: String) -> bool:
	return float(_time.get(kind, 0.0)) > 0.0


func clear() -> void:
	_time.clear()
	queue_redraw()


func _process(delta: float) -> void:
	if _time.is_empty():
		return
	if unit == null or not is_instance_valid(unit) or unit.dead:
		_time.clear()
		queue_redraw()
		return
	_fx_t -= delta
	for k in _time.keys():
		_time[k] = float(_time[k]) - delta
		_acc[k] = float(_acc[k]) + delta
		var tick: float = INFO[k].tick
		if float(_acc[k]) >= tick:
			_acc[k] = float(_acc[k]) - tick
			unit.dot_damage(tick_damage, k)
			if unit == null or not is_instance_valid(unit) or unit.dead:
				_time.clear()
				break
		if _fx_t <= 0.0:
			Fx.particles(unit.get_parent(), unit.global_position + Vector2(randf_range(-5, 5), -4), INFO[k].color, 2, 25.0, 0.45, -60.0 if k == "burn" else -20.0, 1.0)
		if _time.has(k) and float(_time[k]) <= 0.0:
			_time.erase(k)
	if _fx_t <= 0.0:
		_fx_t = 0.12
	queue_redraw()


func _draw() -> void:
	var ks := _time.keys()
	for i in ks.size():
		var t := Art.tex(INFO[ks[i]].icon)
		var x := (i - (ks.size() - 1) / 2.0) * 10.0 - t.get_width() / 2.0
		var bob := sin(Time.get_ticks_msec() / 160.0 + i) * 1.0
		var pos := Vector2(x, -head - t.get_height() + bob)
		draw_circle(pos + Vector2(t.get_width(), t.get_height()) / 2.0, 6.0, Color(0.08, 0.04, 0.08, 0.7))
		draw_arc(pos + Vector2(t.get_width(), t.get_height()) / 2.0, 6.0, 0.0, TAU, 16, INFO[ks[i]].color, 1.0)
		draw_texture(t, pos)
