extends "res://scripts/entities/interactable.gd"
## Thú cưỡi / Chiến xa có thể lên cưỡi bằng [E]:
##   voi_chien_mount (Voi Chiến), ngua_sat_mount (Ngựa Sắt), xe_tang_mount (Xe Tăng Chiến).

const Fx = preload("res://scripts/effects/fx.gd")

const MOUNT_ORDER: Array[String] = ["voi_chien_mount", "ngua_sat_mount", "xe_tang_mount"]

const MOUNT_DATA: Dictionary = {
	"voi_chien_mount": {
		"name": "Voi Chiến",
		"hp": 14,
		"desc": "+14 Giáp Thú Cưỡi · Húc mạnh",
		"color": Color(0.95, 0.78, 0.35),
		"sprite": "world/voi_chien_mount.png",
	},
	"ngua_sat_mount": {
		"name": "Ngựa Sắt",
		"hp": 10,
		"desc": "+10 Giáp Thú Cưỡi · Siêu tốc",
		"color": Color(1.0, 0.52, 0.25),
		"sprite": "world/ngua_sat_mount.png",
	},
	"xe_tang_mount": {
		"name": "Xe Tăng Chiến",
		"hp": 20,
		"desc": "+20 Giáp Thú Cưỡi · Thiết giáp",
		"color": Color(0.45, 0.88, 0.42),
		"sprite": "world/xe_tang_mount.png",
	},
}

var mount_id: String = "voi_chien_mount"
var mount_hp: int = -1
var _used: bool = false
var _spr: Sprite2D = null
var _light: PointLight2D = null


func _ready() -> void:
	add_to_group("mount_pickups")
	z_index = 1
	radius = 24.0
	if not MOUNT_DATA.has(mount_id):
		mount_id = "voi_chien_mount"
	if mount_hp <= 0:
		mount_hp = int(MOUNT_DATA[mount_id].get("hp", 12))
	var info: Dictionary = MOUNT_DATA[mount_id]
	var col: Color = info.get("color", Color(1.0, 0.85, 0.35)) as Color
	var spr_path: String = "res://assets/sprites/" + str(info.get("sprite", ""))
	if ResourceLoader.exists(spr_path):
		_spr = Sprite2D.new()
		_spr.texture = Art.tex(str(info.get("sprite", "")))
		_spr.position = Vector2(0, -6)
		add_child(_spr)
	_light = Art.light(col, 1.15, 0.75)
	_light.position = Vector2(0, -4)
	add_child(_light)


func _mount_info() -> Dictionary:
	return MOUNT_DATA.get(mount_id, MOUNT_DATA["voi_chien_mount"])


func hint() -> String:
	var info: Dictionary = _mount_info()
	var mhp: int = mount_hp if mount_hp > 0 else int(info.get("hp", 12))
	return "Cưỡi %s (%d HP)" % [str(info.get("name", mount_id)), mhp]


func interact() -> void:
	if _used:
		return
	var p: Node = Global.local_player()
	if p == null or not is_instance_valid(p):
		return
	var info: Dictionary = _mount_info()
	var mhp: int = mount_hp if mount_hp > 0 else int(info.get("hp", 12))
	if p.has_method("board_mount"):
		p.board_mount(mount_id, mhp)
	else:
		p.set("mount_id", mount_id)
		p.set("mount_hp", mhp)
		p.set("mount_max_hp", mhp)
		Global.set("active_mount", mount_id)
		Global.set("active_mount_hp", mhp)
	_used = true
	enabled = false
	near = false
	var par: Node = get_parent() if get_parent() != null else self
	var col: Color = info.get("color", Color(1.0, 0.85, 0.35)) as Color
	Sfx.play("pickup_weapon")
	Fx.particles(par, global_position, col, 18, 95.0, 0.5, -40.0, 2.2)
	Fx.burst(par, global_position, col, 36.0, 0.4)
	Fx.float_text(par, global_position + Vector2(0, -28), "Cưỡi %s!" % str(info.get("name", mount_id)), col, 15)
	queue_free()


func _process(delta: float) -> void:
	super(delta)
	if _spr != null:
		_spr.position.y = -6.0 + sin(_t * 3.5) * 1.5
	queue_redraw()


func _draw() -> void:
	var info: Dictionary = _mount_info()
	var col: Color = info.get("color", Color(1.0, 0.85, 0.35)) as Color
	var pulse: float = 0.5 + 0.5 * sin(_t * 4.0)
	draw_circle(Vector2(0, 6), 15.0, Color(0.0, 0.0, 0.0, 0.32))
	draw_set_transform(Vector2(0, 6), 0.0, Vector2(1.0, 0.42))
	draw_arc(Vector2.ZERO, 17.0 + pulse * 1.5, 0.0, TAU, 24, Color(col, 0.35 + 0.25 * pulse), 1.4)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if _spr == null:
		var bob: float = sin(_t * 3.5) * 1.5
		match mount_id:
			"voi_chien_mount":
				draw_rect(Rect2(-12, -13 + bob, 24, 15), Color("888c96"))
				draw_rect(Rect2(-8, -14 + bob, 14, 6), Color("b82a2a"))
				draw_rect(Rect2(-8, -14 + bob, 14, 2), Color("f2c64b"))
				draw_circle(Vector2(10, -8 + bob), 5.0, Color("969aa4"))
				draw_line(Vector2(13, -6 + bob), Vector2(16, -2 + bob), Color("fff4dc"), 2.2)
				draw_line(Vector2(12, -4 + bob), Vector2(15, 2 + bob), Color("888c96"), 2.5)
			"ngua_sat_mount":
				draw_rect(Rect2(-11, -11 + bob, 22, 11), Color("586476"))
				draw_rect(Rect2(5, -17 + bob, 8, 9), Color("6e7b90"))
				draw_rect(Rect2(-6, -12 + bob, 10, 4), Color("ff7a2e"))
				draw_line(Vector2(-8, 0 + bob), Vector2(-10, 6 + bob), Color("444c5a"), 2.4)
				draw_line(Vector2(7, 0 + bob), Vector2(9, 6 + bob), Color("444c5a"), 2.4)
			"xe_tang_mount":
				draw_rect(Rect2(-14, -5 + bob, 28, 9), Color("2c3626"))
				draw_rect(Rect2(-12, -12 + bob, 24, 9), Color("4b6b3c"))
				draw_rect(Rect2(-7, -17 + bob, 14, 6), Color("5e844c"))
				draw_line(Vector2(5, -14 + bob), Vector2(17, -14 + bob), Color("3c4838"), 3.0)
				draw_circle(Vector2(-2, -14 + bob), 1.8, Color("f0c848"))

	Art.draw_text(self, Vector2(0, -27), str(info.get("name", mount_id)), 12, col)
	draw_hint(-40.0)
