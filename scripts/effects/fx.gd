extends RefCounted
## Hiệu ứng dùng chung: hoạt ảnh 1 lần, hạt bắn tung, chữ bay, nhát chém, bóng mờ, rung màn hình.

const Art = preload("res://scripts/art/art.gd")
const Burst = preload("res://scripts/effects/burst.gd")
const FloatText = preload("res://scripts/effects/float_text.gd")

static var _hitstop_active: bool = false


## Khựng nhẹ khung hình khi chí mạng hoặc hạ trùm (tự bỏ qua ở chế độ headless).
static func hitstop(tree: SceneTree, dur: float = 0.04) -> void:
	if tree == null or DisplayServer.get_name() == "headless" or _hitstop_active:
		return
	_hitstop_active = true
	Engine.time_scale = 0.15
	tree.create_timer(dur, true, false, true).timeout.connect(func():
		Engine.time_scale = 1.0
		_hitstop_active = false)


## Chạy 1 hoạt ảnh rồi tự xóa. rel: đường dẫn dải ảnh trong assets/sprites
static func anim(parent: Node, pos: Vector2, rel: String, fw: int, fh: int, fps := 14.0,
		scale := 1.0, rot := 0.0, color := Color.WHITE, add := false, z := 5) -> AnimatedSprite2D:
	if parent == null or not is_instance_valid(parent):
		return null
	var s := AnimatedSprite2D.new()
	s.sprite_frames = Art.strip(rel, fw, fh, fps, false)
	s.position = pos
	s.rotation = rot
	s.scale = Vector2(scale, scale)
	s.modulate = color
	s.z_index = z
	if add:
		s.material = Art.additive()
	s.animation_finished.connect(s.queue_free)
	parent.add_child(s)
	s.play("play")
	return s


## Hạt bắn tung (các ô vuông pixel)
static func particles(parent: Node, pos: Vector2, color: Color, amount := 10, speed := 80.0,
		life := 0.45, gravity := 0.0, size := 2.0, spread := 180.0, dir := Vector2.UP, color2 := Color.TRANSPARENT) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = amount
	p.lifetime = life
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, gravity)
	p.damping_min = speed * 0.8
	p.damping_max = speed * 1.6
	p.scale_amount_min = size
	p.scale_amount_max = size * 1.5
	if color2.a > 0.0:
		var g := Gradient.new()
		g.set_color(0, color)
		g.set_color(1, Color(color2, 0.0))
		p.color_ramp = g
	else:
		var g2 := Gradient.new()
		g2.set_color(0, color)
		g2.set_color(1, Color(color, 0.0))
		p.color_ramp = g2
	p.z_index = 6
	parent.add_child(p)
	p.emitting = true
	p.get_tree().create_timer(life + 0.2).timeout.connect(p.queue_free)


static func burst(parent: Node, pos: Vector2, color: Color, radius: float, dur := 0.3) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var b := Burst.new()
	b.position = pos
	b.color = color
	b.max_r = radius
	b.dur = dur
	parent.add_child(b)


static func float_text(parent: Node, pos: Vector2, text: String, color: Color, size := 14) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var t := FloatText.new()
	t.position = pos + Vector2(randf_range(-3, 3), 0)
	t.text = text
	t.color = color
	t.size = size
	parent.add_child(t)


## Nhát chém: lưỡi liềm sáng (vung) hoặc vệt đâm (thrust), tô màu theo cấp vũ khí
static func slash(parent: Node, pos: Vector2, dir: Vector2, reach: float, arc: float, color: Color, style := "swing") -> void:
	if style == "thrust":
		var s := anim(parent, pos, "fx/thrust.png", 48, 12, 22.0, 1.0, dir.angle(), color, true)
		if s:
			s.offset = Vector2(24, 0)
			s.scale = Vector2(reach / 44.0, 1.0)
	elif style == "spin":
		for i in 3:
			var s2 := anim(parent, pos, "fx/slash.png", 48, 48, 20.0, reach / 21.0, dir.angle() + TAU * i / 3.0, color, true)
	else:
		var s3 := anim(parent, pos, "fx/slash.png", 48, 48, 20.0, reach / 21.0, dir.angle(), color, true)
		if s3:
			s3.scale.y *= clampf(arc / deg_to_rad(160.0), 0.6, 1.4)


## Bóng mờ (dùng cho Thần tốc, Voi chiến)
static func afterimage(parent: Node, spr: AnimatedSprite2D, pos: Vector2, color: Color, life := 0.3) -> void:
	if parent == null or spr == null or spr.sprite_frames == null:
		return
	var g := Sprite2D.new()
	g.texture = spr.sprite_frames.get_frame_texture(spr.animation, spr.frame)
	g.flip_h = spr.flip_h
	g.scale = spr.scale
	g.position = pos + spr.position
	g.offset = spr.offset
	g.modulate = color
	g.z_index = 1
	g.material = Art.additive()
	parent.add_child(g)
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, life)
	tw.tween_callback(g.queue_free)


static func shake(tree: SceneTree, amount: float) -> void:
	if tree:
		var g: Node = tree.root.get_node_or_null("Global")
		if g != null and not bool(g.settings.get("shake", true)):
			return
		tree.call_group("game", "add_shake", amount)


static func draw_text_centered(ci: CanvasItem, pos: Vector2, text: String, size: int, color: Color) -> void:
	Art.draw_text(ci, pos, text, size, color, true)
