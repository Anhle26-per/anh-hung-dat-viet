extends Node2D
## Vật tương tác trong hầm ngục (rương, kệ hàng...): đứng gần, bấm E / nút DÙNG.
## Lớp con ghi đè interact(), hint() và _draw_item().

const Art = preload("res://scripts/art/art.gd")

var radius := 20.0
var near := false
var enabled := true
var _t := 0.0


func hint() -> String:
	return ""


func interact() -> void:
	pass


func _process(delta: float) -> void:
	_t += delta
	var p: Node = Global.local_player()
	if p == null or not is_instance_valid(p):
		return
	var was := near
	var incapacitated: bool = bool(p.get("dead")) or bool(p.get("downed"))
	near = enabled and not incapacitated and global_position.distance_to(p.global_position) < radius
	if near:
		var cur = p.interact_target
		if cur == null or not is_instance_valid(cur) or cur == self \
				or global_position.distance_to(p.global_position) < cur.global_position.distance_to(p.global_position):
			p.interact_target = self
	elif p.interact_target == self:
		p.interact_target = null
	if near != was or near:
		queue_redraw()


func _exit_tree() -> void:
	var p: Node = Global.local_player() if is_inside_tree() else null
	if p != null and is_instance_valid(p) and p.interact_target == self:
		p.interact_target = null


func draw_hint(y: float) -> void:
	if not near or hint() == "":
		return
	var p: Node = Global.local_player()
	if p == null or not is_instance_valid(p) or p.interact_target != self:
		return
	var key := "DÙNG" if Global.touch_mode else "E"
	Art.draw_text(self, Vector2(0, y), "%s: %s" % [key, hint()], 13, Color(1, 0.95, 0.75))
