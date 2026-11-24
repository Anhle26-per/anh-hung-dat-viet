extends Node2D
## Đồ trang trí trong phòng: đuốc (có ánh sáng lập lòe), cờ, đèn lồng, chum, tre, cây đào, mặt trống đồng.

const Art = preload("res://scripts/art/art.gd")

var kind := "torch"
var _light: PointLight2D
var _t := 0.0


func _ready() -> void:
	_t = randf() * 10.0
	match kind:
		"torch":
			_add_anim("world/torch.png", 10, 18, 10.0, Vector2(0, -2))
			var em := CPUParticles2D.new()
			em.position = Vector2(0, -10)
			em.amount = 5
			em.lifetime = 1.2
			em.direction = Vector2.UP
			em.spread = 25.0
			em.gravity = Vector2(0, -20)
			em.initial_velocity_min = 6.0
			em.initial_velocity_max = 14.0
			em.scale_amount_min = 1.0
			em.scale_amount_max = 1.5
			var eg := Gradient.new()
			eg.set_color(0, Color(1, 0.8, 0.3, 1))
			eg.set_color(1, Color(1, 0.3, 0.1, 0))
			em.color_ramp = eg
			em.material = Art.additive()
			add_child(em)
			_light = Art.light(Color(1.0, 0.65, 0.3), 1.3, 0.8)
			_light.position = Vector2(0, -6)
			add_child(_light)
		"banner":
			_add_anim("world/banner.png", 14, 24, 2.0, Vector2(0, 4))
		"lantern":
			_add_anim("world/lantern.png", 10, 16, 2.0, Vector2(0, 2))
			_light = Art.light(Color(1.0, 0.4, 0.3), 1.0, 0.7)
			add_child(_light)
		"pot":
			_add_tex("world/pot.png", Vector2(0, -4))
		"bamboo":
			_add_tex("world/bamboo.png", Vector2(0, -12))
		"peach":
			_add_tex("world/peach.png", Vector2(0, -12))
		"crate":
			_add_tex("world/crate.png", Vector2(0, -4))
		"sandbag":
			_add_tex("world/sandbag.png", Vector2(0, -4))
		"drum":
			var s := _add_tex("world/drum_floor.png", Vector2.ZERO)
			s.z_index = 0


func _add_anim(rel: String, fw: int, fh: int, fps: float, off: Vector2) -> AnimatedSprite2D:
	var a := AnimatedSprite2D.new()
	a.sprite_frames = Art.strip(rel, fw, fh, fps, true)
	a.position = off
	a.play("play")
	a.frame = randi() % 2
	add_child(a)
	return a


func _add_tex(rel: String, off: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Art.tex(rel)
	s.position = off
	add_child(s)
	return s


func _process(delta: float) -> void:
	_t += delta
	# cây cối đung đưa trong gió, đèn lồng lắc nhẹ
	if kind == "bamboo" or kind == "peach":
		rotation = sin(_t * 1.3) * 0.035 + sin(_t * 3.1) * 0.01
	elif kind == "lantern":
		rotation = sin(_t * 1.8) * 0.08
	elif kind == "banner":
		skew = sin(_t * 1.5) * 0.05
	if _light == null:
		return
	_light.energy = (0.75 if kind == "torch" else 0.55) + 0.12 * sin(_t * 9.0) + 0.06 * sin(_t * 23.0)
