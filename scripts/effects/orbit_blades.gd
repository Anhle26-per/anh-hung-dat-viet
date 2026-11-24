extends Node2D
## "Gươm Thuận Thiên": ba thanh gươm thần bay vòng quanh Lê Lợi.

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")

var life := 6.0
var radius := 30.0
var _blades: Array = []
var _cd := {}
var _t := 0.0


func _ready() -> void:
	z_index = 5
	for i in 3:
		var s := Sprite2D.new()
		s.texture = Art.tex("weapons/thuan_thien.png")
		s.material = Art.additive()
		s.modulate = Color(1, 0.95, 0.7)
		add_child(s)
		_blades.append(s)


func _process(delta: float) -> void:
	_t += delta
	life -= delta
	if life <= 0.0:
		Fx.particles(get_parent().get_parent(), global_position, Color(1, 0.9, 0.5), 16, 100.0, 0.5)
		queue_free()
		return
	for k in _cd.keys():
		_cd[k] -= delta
	for i in 3:
		var ang := _t * 5.0 + TAU * i / 3.0
		var s: Sprite2D = _blades[i]
		s.position = Vector2.from_angle(ang) * radius
		s.rotation = ang + PI / 2.0
		var gp := global_position + s.position
		for e in get_tree().get_nodes_in_group("enemies"):
			if gp.distance_to(e.global_position) < 12.0 + e.radius:
				var id: int = e.get_instance_id()
				if _cd.get(id, 0.0) <= 0.0:
					_cd[id] = 0.3
					e.take_damage(6, (e.global_position - global_position).normalized() * 160.0)
		for b in get_tree().get_nodes_in_group("enemy_bullets"):
			if gp.distance_to(b.global_position) < 10.0:
				b.destroy()
	modulate.a = clampf(life / 0.4, 0.0, 1.0)
