extends RefCounted
## Thư viện đồ họa: nạp ảnh, tạo hoạt ảnh từ dải ảnh, font pixel, hiệu ứng nháy trắng.

const BASE := "res://assets/sprites/"
const FONT_PATH := "res://assets/fonts/VT323-Regular.ttf"

static var _frames := {}
static var _font: FontFile = null
static var _flash_shader: Shader = null


static var _tex := {}


static func clear_cache() -> void:
	_tex.clear()
	_frames.clear()


static func tex(rel: String) -> Texture2D:
	if not _tex.has(rel):
		_tex[rel] = load(BASE + rel)
	return _tex[rel]


## Nạp sẵn mọi ảnh vũ khí, biểu tượng, tướng (gọi 1 lần khi mở game) để không bị
## ô trắng khi vẽ lần đầu trong _draw().
static func preload_all() -> void:
	for dir in ["weapons", "ui", "heroes", "items", "fx", "enemies", "world"]:
		var d := DirAccess.open(BASE + dir)
		if d == null:
			continue
		for f in d.get_files():
			if f.ends_with(".png"):
				tex(dir + "/" + f)
			elif f.ends_with(".png.import"):
				tex(dir + "/" + f.trim_suffix(".import"))


## Tạo SpriteFrames từ dải ảnh ngang hoặc lưới nhiều hàng.
## anims = {"walk": [[0, 1, 2, 3], 10.0, true], ...}  (khung, tốc độ, lặp)
static func frames(rel: String, fw: int, fh: int, anims: Dictionary) -> SpriteFrames:
	var key := "%s|%d|%d|%s" % [rel, fw, fh, str(anims)]
	if _frames.has(key):
		return _frames[key]
	var t := tex(rel)
	@warning_ignore("integer_division")
	var cols: int = maxi(1, int(t.get_width()) / fw)
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for name in anims:
		var a: Array = anims[name]
		sf.add_animation(name)
		sf.set_animation_speed(name, a[1])
		sf.set_animation_loop(name, a[2])
		for raw_i in a[0]:
			var i: int = int(raw_i)
			var at := AtlasTexture.new()
			at.atlas = t
			@warning_ignore("integer_division")
			at.region = Rect2((i % cols) * fw, (i / cols) * fh, fw, fh)
			sf.add_frame(name, at)
	_frames[key] = sf
	return sf


## Hoạt ảnh 1 chiều đơn giản: tất cả khung trong dải ảnh hoặc lưới nhiều hàng
static func strip(rel: String, fw: int, fh: int, fps := 12.0, loop := false) -> SpriteFrames:
	var t := tex(rel)
	@warning_ignore("integer_division")
	var cols: int = maxi(1, int(t.get_width()) / fw)
	@warning_ignore("integer_division")
	var rows: int = maxi(1, int(t.get_height()) / fh)
	var n := cols * rows
	var idx: Array = []
	for i in n:
		idx.append(i)
	return frames(rel, fw, fh, {"play": [idx, fps, loop]})


static func font() -> FontFile:
	if _font == null:
		_font = load(FONT_PATH)
		_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		_font.hinting = TextServer.HINTING_NONE
		_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return _font


## Vật liệu nháy trắng khi trúng đòn (mỗi nhân vật 1 bản riêng)
static func flash_material() -> ShaderMaterial:
	if _flash_shader == null:
		_flash_shader = Shader.new()
		_flash_shader.code = """
shader_type canvas_item;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	COLOR = vec4(mix(c.rgb, flash_color.rgb, flash), c.a);
}
"""
	var m := ShaderMaterial.new()
	m.shader = _flash_shader
	return m


static var _gray_shader: Shader = null


## Tượng đá: chuyển ảnh sang xám đá (dùng cho tướng chưa mở khóa)
static func stone_material() -> ShaderMaterial:
	if _gray_shader == null:
		_gray_shader = Shader.new()
		_gray_shader.code = """
shader_type canvas_item;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float l = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	COLOR = vec4(vec3(l) * vec3(0.78, 0.76, 0.72) + vec3(0.08), c.a * COLOR.a);
}
"""
	var m := ShaderMaterial.new()
	m.shader = _gray_shader
	return m


static func additive() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m


static func draw_text(ci: CanvasItem, pos: Vector2, text: String, size: int, color: Color, center := true) -> void:
	var f := font()
	var p := pos
	if center:
		p.x -= f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x / 2.0
	ci.draw_string_outline(f, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(0.06, 0.03, 0.08, 0.9 * color.a))
	ci.draw_string(f, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


static func text_width(text: String, size: int) -> float:
	return font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## Ánh sáng tròn (dùng cho người chơi, đuốc, vụ nổ)
static func light(color: Color, scale: float, energy := 1.0) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = tex("fx/light.png")
	l.color = color
	l.texture_scale = scale
	l.energy = energy
	return l
