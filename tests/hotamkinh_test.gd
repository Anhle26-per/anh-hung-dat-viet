extends Node
## Kiểm thử thẻ G13: Phúc lành Hộ tâm kính (dữ liệu, biểu tượng, chặn đòn tràn vào máu, hồi 8 giây).
## Chạy: godot --headless --path . res://tests/hotamkinh_test.tscn -> in "HO TAM KINH TEST OK"

const BuffData = preload("res://scripts/data/buffs.gd")
const Player = preload("res://scripts/entities/player.gd")
const Art = preload("res://scripts/art/art.gd")

var _fail: int = 0
var _completed: bool = false


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		push_error("KIỂM THỬ THẤT BẠI: " + msg)
		print("  THẤT BẠI: ", msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _ready() -> void:
	Global.save_path = "user://hotamkinh_test_save.json"
	get_tree().create_timer(30.0).timeout.connect(func():
		print("HO TAM KINH TEST FAILED: quá thời gian")
		get_tree().quit(1))
	await _frames(2)
	await _run()
	if _fail == 0 and _completed:
		print("HO TAM KINH TEST OK")
		get_tree().quit(0)
	else:
		print("HO TAM KINH TEST FAILED: %d lỗi (completed=%s)" % [_fail, str(_completed)])
		get_tree().quit(1)


func _run() -> void:
	print("== 1. Kiểm tra dữ liệu BuffData.DATA['ho_tam_kinh']")
	_check(BuffData.DATA.has("ho_tam_kinh"), "thiếu ho_tam_kinh trong BuffData.DATA")
	if BuffData.DATA.has("ho_tam_kinh"):
		var entry: Dictionary = BuffData.DATA["ho_tam_kinh"]
		_check(str(entry.get("name", "")) == "Hộ tâm kính", "tên sai: " + str(entry.get("name", "")))
		_check(int(entry.get("max", 0)) == 1, "max phải bằng 1")
		_check(str(entry.get("desc", "")).length() > 10, "mô tả rỗng")

	print("== 2. Kiểm tra biểu tượng assets/sprites/ui/buff_ho_tam_kinh.png")
	var icon_res: String = "res://assets/sprites/ui/buff_ho_tam_kinh.png"
	var abs_icon: String = ProjectSettings.globalize_path(icon_res)
	_check(FileAccess.file_exists(icon_res), "không tìm thấy tệp " + icon_res)
	var img: Image = Image.load_from_file(abs_icon)
	_check(img != null and img.get_width() == 16 and img.get_height() == 16,
		"ảnh biểu tượng không đúng 16x16")
	var tex: Texture2D = Art.tex("ui/buff_ho_tam_kinh.png")
	_check(tex != null and tex.get_width() == 16 and tex.get_height() == 16,
		"Art.tex('ui/buff_ho_tam_kinh.png') lỗi hoặc không đúng 16x16")

	print("== 3. Kiểm tra cơ chế chặn đòn tràn vào máu và hồi chiêu 8 giây")
	Global.run_buffs = {}
	Global.settings["difficulty"] = "thuong"
	var world := Node2D.new()
	add_child(world)
	var p := Player.new()
	p.setup("ngo_quyen")
	world.add_child(p)
	await _frames(2)

	p.apply_buff("ho_tam_kinh")
	_check(p.buff("ho_tam_kinh") == 1, "apply_buff('ho_tam_kinh') thất bại")
	_check(is_equal_approx(p._htk_cd, 0.0), "_htk_cd ban đầu phải là 0")

	# Đòn không vượt giáp -> không kích hoạt Hộ tâm kính
	p.hp = 6
	p.max_hp = 6
	p.armor = 3
	p._invuln = 0.0
	p._armor_regen = 99.0
	p.take_damage(2)
	_check(p.armor == 1 and p.hp == 6, "đòn trong giáp phải trừ giáp (armor=%d hp=%d)" % [p.armor, p.hp])
	_check(is_equal_approx(p._htk_cd, 0.0), "đòn không tràn máu không được kích hoạt _htk_cd")

	# Đòn đầu tiên làm vỡ giáp và tràn vào máu -> chặn trọn overflow, hp không đổi, _htk_cd ~ 8.0
	p._invuln = 0.0
	p._armor_regen = 99.0
	p.take_damage(4)
	_check(p.armor == 0, "giáp phải về 0 sau khi vỡ (armor=%d)" % p.armor)
	_check(p.hp == 6, "máu phải giữ nguyên 6 nhờ Hộ tâm kính (hp=%d)" % p.hp)
	_check(p._htk_cd > 7.5 and p._htk_cd <= 8.0, "_htk_cd phải ~8.0s (thực tế %.2f)" % p._htk_cd)
	_check(p._invuln > 0.4 and p._invuln <= 0.5, "_invuln phải ~0.5s (thực tế %.2f)" % p._invuln)

	# Đòn thứ hai trong lúc đang hồi chiêu (kể cả khi vỡ giáp lại) -> PHẢI mất máu
	p._invuln = 0.0
	p.armor = 1
	p._armor_regen = 99.0
	p.take_damage(3)
	_check(p.armor == 0 and p.hp == 4, "đòn trong lúc đang hồi chiêu phải trừ máu còn 4 (armor=%d hp=%d)" % [p.armor, p.hp])
	_check(p._htk_cd > 0.0, "_htk_cd vẫn đang hồi")

	# Tua hết 8 giây hồi chiêu qua _physics_process
	for step in 16:
		p._armor_regen = 99.0
		p._physics_process(0.5)
	_check(p._htk_cd <= 0.001, "sau 8s _htk_cd phải về 0 (thực tế %.3f)" % p._htk_cd)

	# Khi giáp đã bằng 0 sẵn -> KHÔNG chặn đòn (tránh phá vỡ kiểm thử chết K2)
	p._invuln = 0.0
	p.armor = 0
	p._armor_regen = 99.0
	p.take_damage(1)
	_check(p.hp == 3, "khi armor == 0 sẵn phải mất máu bình thường (hp=%d)" % p.hp)
	_check(is_equal_approx(p._htk_cd, 0.0), "khi armor == 0 không được kích hoạt _htk_cd")

	# Khi giáp hồi lại (armor > 0) và vỡ giáp -> chặn trọn đòn tràn vào máu lần nữa
	p._invuln = 0.0
	p.armor = 1
	p._armor_regen = 99.0
	p.take_damage(3)
	_check(p.hp == 3, "sau khi hồi 8s và vỡ giáp phải chặn lại đòn tràn vào máu (hp=%d)" % p.hp)
	_check(p.armor == 0, "giáp về 0 sau khi vỡ (armor=%d)" % p.armor)
	_check(p._htk_cd > 7.5 and p._htk_cd <= 8.0, "_htk_cd phải đặt lại ~8.0s (thực tế %.2f)" % p._htk_cd)

	world.queue_free()
	Global.run_buffs = {}
	await _frames(2)
	_completed = true
