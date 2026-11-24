extends Node
## Dữ liệu dùng chung toàn game (autoload "Global"):
## tướng đang chọn, tiền xu, lưu game, trạng thái lượt chơi và điều khiển cảm ứng.

const SAVE_PATH := "user://save.json"
var save_path := SAVE_PATH        # bài kiểm thử đổi sang tệp riêng để không đụng tệp lưu thật
const HeroData = preload("res://scripts/data/heroes.gd")
const UI = preload("res://scripts/ui/ui.gd")
const Art = preload("res://scripts/art/art.gd")

# --- Dữ liệu được lưu lại ---
var selected_hero: String = "ngo_quyen"
var coins: int = 0
var best_level: int = 0
var unlocked: Array = []
var upgrades: Dictionary = {}     # nâng cấp vĩnh viễn ở Lò rèn: mã -> cấp
var discovered: Array = []        # vũ khí đã sưu tầm
var stats: Dictionary = {"runs": 0, "kills": 0, "bosses": 0}
var free_revives := 0             # lượt hồi sinh miễn phí còn lại trong lượt chơi

# Nâng cấp ở Lò rèn
const UPGRADES := {
	"mau": {"name": "Rèn thân", "desc": "+1 máu tối đa", "max": 3, "cost": 150},
	"giap": {"name": "Rèn giáp", "desc": "+1 giáp tối đa", "max": 3, "cost": 150},
	"nang_luong": {"name": "Luyện khí", "desc": "+40 năng lượng tối đa", "max": 3, "cost": 120},
	"khoi_dau": {"name": "Lễ xuất quân", "desc": "Bắt đầu lượt chơi với 1 phúc lành", "max": 1, "cost": 600},
	"hoi_sinh": {"name": "Thuốc hồi sinh", "desc": "Mỗi lượt được hồi sinh miễn phí 1 lần", "max": 1, "cost": 800},
}

# --- Trạng thái lượt chơi hiện tại ---
var level: int = 1
var run_coins: int = 0
var revived: bool = false
var boss_order: Array = []
var legend_chance := 0.4         # tỉ lệ màn giữa chương có trùm Tam Yêu
var legend_last := ""      # thứ tự trùm ngẫu nhiên của lượt chơi này
var run_buffs: Dictionary = {}   # phúc lành đã chọn trong lượt: mã -> số lần

# --- Điều khiển ---
var touch_mode: bool = false     # true trên điện thoại: hiện cần gạt + nút ảo, tự ngắm
var using_pad: bool = false      # true khi đang dùng tay cầm
var joy_vector: Vector2 = Vector2.ZERO
var touch_attack: bool = false   # đang giữ nút tấn công
var touch_skill: bool = false    # vừa bấm nút kỹ năng (player đọc xong sẽ tắt)
var touch_swap: bool = false     # vừa bấm nút đổi/nhặt vũ khí
var _force_touch: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for id in HeroData.ORDER:
		if HeroData.DATA[id].cost == 0:
			unlocked.append(id)
	_setup_inputs()
	_force_touch = OS.get_cmdline_user_args().has("--touch")
	touch_mode = _force_touch or OS.has_feature("mobile")
	load_game()
	# Chủ đề giao diện chung: font pixel tiếng Việt + khung sơn mài
	get_tree().root.theme = UI.make_theme()
	Art.preload_all()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		touch_mode = true
		using_pad = false
	elif _force_touch:
		return
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event.relative.length() > 2.0:
			touch_mode = false
			using_pad = false
	elif event is InputEventKey and event.pressed:
		touch_mode = false
	elif event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.4):
		touch_mode = false
		using_pad = true


## Tự ngắm vào quái gần nhất (điện thoại, tay cầm). Trên máy tính thì ngắm bằng chuột.
func auto_aim() -> bool:
	return touch_mode or using_pad


# ------------------------------------------------------------------ Lượt chơi

func start_run() -> void:
	level = 1
	boss_order = []
	legend_last = ""
	run_coins = 0
	revived = false
	run_buffs = {}
	free_revives = upgrade("hoi_sinh")
	stats["runs"] = int(stats.get("runs", 0)) + 1


## Trùm thứ idx (0 = trùm đầu tiên) của lượt chơi: xáo ngẫu nhiên cả 10 trùm,
## gặp hết 10 con mới xáo lại (không gặp lại ngay con vừa đánh).
func boss_at(idx: int) -> String:
	var all: Array = preload("res://scripts/data/enemies.gd").BOSSES.keys()
	while boss_order.size() <= idx:
		var batch := all.duplicate()
		batch.shuffle()
		if not boss_order.is_empty() and batch[0] == boss_order.back():
			batch.push_back(batch.pop_front())
		boss_order.append_array(batch)
	return boss_order[idx]


## Chọn 1 trong Tam Yêu, không lặp lại con vừa gặp
func pick_legend() -> String:
	var all: Array = preload("res://scripts/data/enemies.gd").LEGENDS.keys()
	all.erase(legend_last)
	legend_last = all.pick_random()
	return legend_last


func upgrade(id: String) -> int:
	return int(upgrades.get(id, 0))


func upgrade_cost(id: String) -> int:
	return int(UPGRADES[id].cost) * (upgrade(id) + 1)


func try_upgrade(id: String) -> bool:
	if upgrade(id) >= int(UPGRADES[id].max) or coins < upgrade_cost(id):
		return false
	coins -= upgrade_cost(id)
	upgrades[id] = upgrade(id) + 1
	save_game()
	return true


func discover(weapon_id: String) -> void:
	if weapon_id != "" and not discovered.has(weapon_id):
		discovered.append(weapon_id)


func add_stat(key: String, n := 1) -> void:
	stats[key] = int(stats.get(key, 0)) + n


func coin_mult() -> float:
	return 1.0 + 0.5 * int(run_buffs.get("boi_thu", 0))


func end_run() -> void:
	coins += run_coins
	run_coins = 0
	best_level = maxi(best_level, level)
	save_game()


func try_unlock(hero_id: String) -> bool:
	var cost: int = HeroData.DATA[hero_id].cost
	if unlocked.has(hero_id) or coins < cost:
		return false
	coins -= cost
	unlocked.append(hero_id)
	save_game()
	return true


## Chỗ gắn quảng cáo có thưởng (AdMob) sau này.
## Hiện tại gọi luôn phần thưởng để thử game.
func show_rewarded_ad(on_reward: Callable) -> void:
	# TODO: thay bằng plugin AdMob khi xuất bản lên Android.
	on_reward.call()


# ------------------------------------------------------------------ Lưu game

func save_game() -> void:
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"coins": coins,
		"best_level": best_level,
		"unlocked": unlocked,
		"selected_hero": selected_hero,
		"upgrades": upgrades,
		"discovered": discovered,
		"stats": stats,
	}))


func load_game() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var f := FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	coins = int(data.get("coins", 0))
	best_level = int(data.get("best_level", 0))
	for id in data.get("unlocked", []):
		if HeroData.DATA.has(id) and not unlocked.has(id):
			unlocked.append(id)
	var up = data.get("upgrades", {})
	if typeof(up) == TYPE_DICTIONARY:
		for k in up:
			upgrades[k] = int(up[k])
	for wid in data.get("discovered", []):
		discover(str(wid))
	var st = data.get("stats", {})
	if typeof(st) == TYPE_DICTIONARY:
		for k in st:
			stats[k] = int(st[k])
	var sel: String = str(data.get("selected_hero", selected_hero))
	if unlocked.has(sel):
		selected_hero = sel


# ------------------------------------------------------------------ Phím bấm

func _setup_inputs() -> void:
	_add_keys("move_left", [KEY_A, KEY_LEFT])
	_add_keys("move_right", [KEY_D, KEY_RIGHT])
	_add_keys("move_up", [KEY_W, KEY_UP])
	_add_keys("move_down", [KEY_S, KEY_DOWN])
	_add_keys("attack", [KEY_J])
	_add_mouse("attack", MOUSE_BUTTON_LEFT)
	_add_keys("skill", [KEY_SPACE, KEY_K])
	_add_mouse("skill", MOUSE_BUTTON_RIGHT)
	_add_keys("swap", [KEY_E, KEY_Q])
	_add_keys("pause", [KEY_ESCAPE, KEY_P])
	# Tay cầm (để sau này bán trên Steam)
	_add_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_add_pad("attack", JOY_BUTTON_A)
	_add_axis("attack", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_add_pad("skill", JOY_BUTTON_B)
	_add_pad("swap", JOY_BUTTON_Y)
	_add_pad("pause", JOY_BUTTON_START)


func _ensure(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.3)


func _add_keys(action: String, keys: Array) -> void:
	_ensure(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _add_mouse(action: String, button: MouseButton) -> void:
	_ensure(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


func _add_pad(action: String, button: JoyButton) -> void:
	_ensure(action)
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


func _add_axis(action: String, axis: JoyAxis, value: float) -> void:
	_ensure(action)
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action, ev)
