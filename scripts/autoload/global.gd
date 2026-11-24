extends Node
## Dữ liệu dùng chung toàn game (autoload "Global"):
## tướng đang chọn, tiền xu, lưu game, trạng thái lượt chơi và điều khiển cảm ứng.

const SAVE_PATH := "user://save.json"
var save_path := SAVE_PATH        # bài kiểm thử đổi sang tệp riêng để không đụng tệp lưu thật
const RUN_SAVE_PATH := "user://run.json"   # điểm lưu lượt chơi dở (Chơi tiếp)
const RUN_VERSION := 1
var run_save_path := ""           # để trống: tự suy ra từ save_path (test dùng tệp riêng)
var resume_data: Dictionary = {}  # trạng thái nhân vật chờ nạp lại khi "Chơi tiếp"
const HeroData = preload("res://scripts/data/heroes.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")
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

const DEFAULT_SETTINGS: Dictionary = {
	"music": 0.8,
	"sfx": 0.9,
	"shake": true,
	"fullscreen": false,
	"touch_scale": 1.0,
	"difficulty": "thuong",
}
var settings: Dictionary = DEFAULT_SETTINGS.duplicate()

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
	apply_settings.call_deferred()


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
	# còn lượt chơi dở chưa xử lý: cộng xu của lượt đó vào kho trước khi bắt đầu lượt mới
	if has_run():
		var keep := selected_hero     # giữ tướng vừa chọn, không lấy tướng của lượt cũ
		abandon_run()
		selected_hero = keep
	resume_data = {}
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
	clear_run()
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


# ------------------------------------------------------------------ Cài đặt & Độ khó

func set_setting(key: String, value: Variant) -> void:
	match key:
		"music", "sfx":
			settings[key] = clampf(float(value), 0.0, 1.0)
		"shake", "fullscreen":
			settings[key] = bool(value)
		"touch_scale":
			var ts: float = float(value)
			if ts < 0.9:
				ts = 0.8
			elif ts > 1.1:
				ts = 1.25
			else:
				ts = 1.0
			settings["touch_scale"] = ts
		"difficulty":
			var d: String = str(value)
			if d in ["de", "thuong", "kho"]:
				settings["difficulty"] = d
	apply_settings()


func apply_settings() -> void:
	if is_inside_tree():
		var sfx: Node = get_tree().root.get_node_or_null("Sfx")
		if sfx != null:
			sfx.set_music_volume(float(settings.get("music", 0.8)))
			sfx.set_sfx_volume(float(settings.get("sfx", 0.9)))
	if DisplayServer.get_name() != "headless" and not OS.has_feature("mobile") and not OS.has_feature("web"):
		var want_fs: bool = bool(settings.get("fullscreen", false))
		var target_mode: int = DisplayServer.WINDOW_MODE_FULLSCREEN if want_fs else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != target_mode:
			DisplayServer.window_set_mode(target_mode)


func difficulty_hp_mult() -> float:
	match str(settings.get("difficulty", "thuong")):
		"de":
			return 0.7
		"kho":
			return 1.4
		_:
			return 1.0


func difficulty_dmg_mult() -> float:
	match str(settings.get("difficulty", "thuong")):
		"de":
			return 0.75
		"kho":
			return 1.25
		_:
			return 1.0


func scale_enemy_damage(amount: int) -> int:
	if amount <= 0:
		return 0
	var m: float = difficulty_dmg_mult()
	if is_equal_approx(m, 1.0):
		return amount
	var raw: float = float(amount) * m
	var base_dmg: int = int(floor(raw))
	var frac: float = raw - float(base_dmg)
	if frac > 0.0 and randf() < frac:
		base_dmg += 1
	return base_dmg


# ------------------------------------------------------------------ Lưu game

func save_game() -> void:
	_write_json_atomic(save_path, {
		"coins": coins,
		"best_level": best_level,
		"unlocked": unlocked,
		"selected_hero": selected_hero,
		"upgrades": upgrades,
		"discovered": discovered,
		"stats": stats,
		"settings": settings,
	})


## Ghi JSON an toàn: ghi ra tệp .tmp trước rồi mới đổi tên đè lên tệp thật,
## nên tắt máy / đóng game giữa chừng không làm hỏng tệp lưu.
func _write_json_atomic(path: String, data: Dictionary) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	var abs_tmp := ProjectSettings.globalize_path(tmp)
	var abs_path := ProjectSettings.globalize_path(path)
	if DirAccess.rename_absolute(abs_tmp, abs_path) == OK:
		return true
	# Windows không cho đổi tên đè lên tệp đã có: xóa tệp cũ rồi đổi tên lại
	DirAccess.remove_absolute(abs_path)
	return DirAccess.rename_absolute(abs_tmp, abs_path) == OK


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var j := JSON.new()
	if j.parse(f.get_as_text()) != OK:
		return null      # tệp hỏng: bỏ qua, không văng game
	return j.data


# ------------------------------------------------------------------ Lượt chơi dở (Chơi tiếp)

## Đường dẫn tệp lưu lượt chơi. Khi test đổi save_path thì tệp này cũng tự tách riêng.
func run_path() -> String:
	if run_save_path != "":
		return run_save_path
	if save_path == SAVE_PATH:
		return RUN_SAVE_PATH
	return save_path.get_basename() + "_run.json"


func has_run() -> bool:
	return FileAccess.file_exists(run_path())


## Lưu lượt đang chơi. p = người chơi (có hàm snapshot()); null thì giữ trạng thái nhân vật cũ.
func save_run(p = null) -> bool:
	var who: Dictionary = resume_data
	if p != null and is_instance_valid(p):
		who = p.snapshot()
	if who.is_empty():
		return false
	return _write_json_atomic(run_path(), {
		"version": RUN_VERSION,
		"hero": selected_hero,
		"level": level,
		"player": who,
		"run_buffs": run_buffs,
		"run_coins": run_coins,
		"boss_order": boss_order,
		"legend_last": legend_last,
		"revived": revived,
		"free_revives": free_revives,
	})


## Đọc thử tệp lượt chơi (để hiện nút "Chơi tiếp"). Tệp hỏng / sai phiên bản -> {}.
func peek_run() -> Dictionary:
	var data: Variant = _read_json(run_path())
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	var d: Dictionary = data
	if int(d.get("version", 0)) != RUN_VERSION:
		return {}
	if not HeroData.DATA.has(str(d.get("hero", ""))):
		return {}
	if int(d.get("level", 0)) < 1 or typeof(d.get("player", null)) != TYPE_DICTIONARY:
		return {}
	return d


## Nạp lượt chơi dở vào Global (game.gd sẽ nạp tiếp trạng thái nhân vật từ resume_data).
func load_run() -> bool:
	var d := peek_run()
	if d.is_empty():
		return false
	selected_hero = str(d.hero)
	level = int(d.level)
	run_coins = int(d.get("run_coins", 0))
	revived = bool(d.get("revived", false))
	free_revives = int(d.get("free_revives", 0))
	legend_last = str(d.get("legend_last", ""))
	boss_order = []
	for b in d.get("boss_order", []):
		boss_order.append(str(b))
	run_buffs = {}
	var rb: Variant = d.get("run_buffs", {})
	if typeof(rb) == TYPE_DICTIONARY:
		for k in rb:
			run_buffs[str(k)] = int(rb[k])
	var pl: Dictionary = d.player
	resume_data = {}
	for k in pl:
		resume_data[str(k)] = pl[k]
	var ws: Array = []
	for w in pl.get("weapons", []):
		var wid := str(w)
		ws.append(wid if (wid == "" or WeaponData.DATA.has(wid)) else "")
	resume_data["weapons"] = ws
	return true


func clear_run() -> void:
	resume_data = {}
	if FileAccess.file_exists(run_path()):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(run_path()))


## Bỏ lượt chơi dở: nhận số xu đã nhặt trong lượt đó.
func abandon_run() -> int:
	var got := 0
	if load_run():
		got = run_coins
		end_run()
	else:
		clear_run()
	return got


## Đóng cửa sổ (máy tính) hoặc ẩn ứng dụng (điện thoại): giữ lại tiến trình.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_on_exit()


func save_on_exit() -> void:
	if is_inside_tree():
		var g = get_tree().get_first_node_in_group("game")
		if g != null and g.player != null and is_instance_valid(g.player):
			if g.player.dead:
				end_run()      # đã ngã: kết thúc lượt, cộng xu
			else:
				save_run(g.player)
	save_game()


func load_game() -> void:
	settings = DEFAULT_SETTINGS.duplicate()
	var data: Variant = _read_json(save_path)
	if typeof(data) != TYPE_DICTIONARY:
		apply_settings()
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
	var cfg: Variant = data.get("settings", null)
	if typeof(cfg) == TYPE_DICTIONARY:
		var cfg_dict: Dictionary = cfg
		for k in cfg_dict:
			set_setting(str(k), cfg_dict[k])
	else:
		apply_settings()


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
