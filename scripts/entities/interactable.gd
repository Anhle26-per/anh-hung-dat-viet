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
	var p = get_tree().get_first_node_in_group("player")
	if p == null:
		return
	var was := near
	near = enabled and not p.dead and global_position.distance_to(p.global_position) < radius
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
	var p = get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	if p != null and p.interact_target == self:
		p.interact_target = null


func draw_hint(y: float) -> void:
	if not near or hint() == "":
		return
	var key := "DÙNG" if Global.touch_mode else "E"
	Art.draw_text(self, Vector2(0, y), "%s: %s" % [key, hint()], 13, Color(1, 0.95, 0.75))
