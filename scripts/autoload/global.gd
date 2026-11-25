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
const MaterialData = preload("res://scripts/data/materials.gd")
const ProgressionData = preload("res://scripts/data/progression.gd")
const WeaponMods = preload("res://scripts/data/weapon_mods.gd")
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
var materials: Dictionary = {}    # kho nguyên liệu: mã -> số lượng
var forged: String = ""           # mã vũ khí đã rèn chờ mang vào lượt kế tiếp ("" nếu trống)
var hero_levels: Dictionary = {}  # mã tướng -> cấp (1..5)
var weapon_ranks: Dictionary = {} # mã tướng -> bậc vũ khí khởi đầu (1..5)
var leaderboard: Array = []       # bảng điểm so tài cục bộ (tối đa 20 mục, xếp theo điểm giảm dần)
var log_path: String = "user://nhat_ky.csv"

const DEFAULT_SETTINGS: Dictionary = {
	"music": 0.8,
	"sfx": 0.9,
	"shake": true,
	"fullscreen": false,
	"touch_scale": 1.0,
	"difficulty": "thuong",
	"player_name": "Anh Hùng",
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
var run_materials: Dictionary = {} # nguyên liệu nhặt được trong lượt chơi hiện tại
var run_weapon_mods: Dictionary = {} # bùa vũ khí gắn trong lượt: mã vũ khí -> mã bùa
var _run_active: bool = false
var run_elapsed: float = 0.0
var run_kills: int = 0
var run_boss_hp: Array = []
var run_last_hit: String = ""
var run_syn_counts: Array = [0, 0, 0]
var run_cap_bac: String = "1/1"
var challenge_code: String = ""   # mã thử thách của lượt hiện tại (rỗng = chơi thường)
var _run_score_recorded: bool = false

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


# ------------------------------------------------------------------ Hỗ trợ nhiều người chơi (LAN)

func all_players() -> Array:
	var out: Array = []
	if not is_inside_tree():
		return out
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p):
			out.append(p)
	return out


func local_player() -> Node:
	var list: Array = all_players()
	for p in list:
		if bool(p.get("is_local")):
			return p
	if not list.is_empty():
		return list[0]
	return null


func nearest_player(pos: Vector2, alive_only: bool = true) -> Node:
	var best: Node = null
	var best_d: float = INF
	for p in all_players():
		var p2d: Node2D = p as Node2D
		if p2d == null:
			continue
		if alive_only and (bool(p.get("dead")) or bool(p.get("downed"))):
			continue
		var d: float = pos.distance_to(p2d.global_position)
		if d < best_d:
			best_d = d
			best = p
	return best


func difficulty() -> String:
	return str(settings.get("difficulty", "thuong"))


func eff_upgrade(id: String) -> int:
	if Net != null and Net.is_online() and Net.host_profile.has("upgrades"):
		var ups: Variant = Net.host_profile.get("upgrades", {})
		if typeof(ups) == TYPE_DICTIONARY:
			return int((ups as Dictionary).get(id, 0))
	return upgrade(id)


func eff_hero_level(hid: String) -> int:
	if Net != null and Net.is_online() and Net.host_profile.has("hero_levels"):
		var hls: Variant = Net.host_profile.get("hero_levels", {})
		if typeof(hls) == TYPE_DICTIONARY:
			return clampi(int((hls as Dictionary).get(hid, 1)), 1, 5)
	return hero_level(hid)


func eff_weapon_rank(hid: String) -> int:
	if Net != null and Net.is_online() and Net.host_profile.has("weapon_ranks"):
		var wrs: Variant = Net.host_profile.get("weapon_ranks", {})
		if typeof(wrs) == TYPE_DICTIONARY:
			return clampi(int((wrs as Dictionary).get(hid, 1)), 1, 5)
	return weapon_rank(hid)


func eff_difficulty() -> String:
	if Net != null and Net.is_online() and Net.host_profile.has("difficulty"):
		return str(Net.host_profile.get("difficulty", "thuong"))
	return difficulty()


# ------------------------------------------------------------------ Lượt chơi

## Băm mã thử thách thành hạt giống cố định (FNV-1a 31-bit, giống nhau giữa mọi phiên chơi).
static func challenge_seed(code: String) -> int:
	var norm: String = code.strip_edges().to_upper()
	var h: int = 2166136261
	var buf: PackedByteArray = norm.to_utf8_buffer()
	for i in buf.size():
		h = (h ^ int(buf[i])) * 16777619
		h = h & 0x7FFFFFFF
	var out: int = h % 2147483647
	return out if out > 0 else 1


static func format_time(sec: float) -> String:
	var total: int = maxi(0, int(round(sec)))
	var mins: int = total / 60
	var secs: int = total % 60
	return "%02d:%02d" % [mins, secs]


func start_run(code: String = "") -> void:
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
	run_materials = {}
	run_weapon_mods = {}
	_run_active = true
	_run_score_recorded = false
	run_elapsed = 0.0
	run_kills = 0
	run_boss_hp = []
	run_last_hit = ""
	run_syn_counts = [0, 0, 0]
	run_cap_bac = "%d/%d" % [eff_hero_level(selected_hero), eff_weapon_rank(selected_hero)]
	free_revives = eff_upgrade("hoi_sinh")
	stats["runs"] = int(stats.get("runs", 0)) + 1
	challenge_code = code.strip_edges().to_upper()
	if challenge_code != "":
		seed(challenge_seed(challenge_code))
		boss_at(0)
	else:
		randomize()


## Trùm thứ idx (0 = trùm đầu tiên) của lượt chơi: xáo ngẫu nhiên cả 10 trùm,
## gặp hết 10 con mới xáo lại (không gặp lại ngay con vừa đánh).
func boss_at(idx: int) -> String:
	var all: Array = preload("res://scripts/data/enemies.gd").BOSSES.keys()
	while boss_order.size() <= idx:
		if challenge_code != "" and not boss_order.is_empty():
			seed(challenge_seed(challenge_code) + boss_order.size() * 3571)
		var batch := all.duplicate()
		batch.shuffle()
		if not boss_order.is_empty() and batch[0] == boss_order.back():
			batch.push_back(batch.pop_front())
		boss_order.append_array(batch)
	return boss_order[idx]


func calc_score(lv: int, elapsed: float, kills: int) -> int:
	var time_bonus: int = maxi(0, 1200 - int(elapsed))
	return maxi(0, lv * 1000 + kills * 25 + time_bonus)


func _sort_and_cap_leaderboard() -> void:
	leaderboard.sort_custom(func(a: Variant, b: Variant) -> bool:
		var da: Dictionary = a
		var db: Dictionary = b
		var sa: int = int(da.get("score", 0))
		var sb: int = int(db.get("score", 0))
		if sa != sb:
			return sa > sb
		var la: int = int(da.get("level", 0))
		var lb: int = int(db.get("level", 0))
		if la != lb:
			return la > lb
		return float(da.get("time", 0.0)) < float(db.get("time", 0.0)))
	if leaderboard.size() > 20:
		leaderboard = leaderboard.slice(0, 20)


func record_score(outcome: String = "") -> Dictionary:
	var sc: int = calc_score(level, run_elapsed, run_kills)
	var entry: Dictionary = {
		"code": challenge_code,
		"hero": selected_hero,
		"level": level,
		"time": int(round(run_elapsed)),
		"kills": run_kills,
		"score": sc,
		"date": Time.get_date_string_from_system(),
		"outcome": outcome,
	}
	if Net != null and Net.is_online() and not Net.is_host():
		_run_score_recorded = true
		return entry
	leaderboard.append(entry)
	_sort_and_cap_leaderboard()
	_run_score_recorded = true
	save_game()
	return entry


func format_share_text(entry: Dictionary) -> String:
	var code: String = str(entry.get("code", "")).strip_edges().to_upper()
	var hero_id: String = str(entry.get("hero", selected_hero))
	var hero_name: String = str(HeroData.DATA[hero_id].name) if HeroData.DATA.has(hero_id) else hero_id
	var lv: int = int(entry.get("level", 1))
	var elapsed: float = float(entry.get("time", 0.0))
	var kills: int = int(entry.get("kills", 0))
	var sc: int = int(entry.get("score", 0))
	var lines: PackedStringArray = []
	if code != "":
		lines.append("[Anh Hùng Đất Việt] Thử thách: %s" % code)
	else:
		lines.append("[Anh Hùng Đất Việt] Thành tích chinh chiến")
	lines.append("Tướng: %s" % hero_name)
	lines.append("Màn: %d | Thời gian: %s | Hạ giặc: %d" % [lv, format_time(elapsed), kills])
	lines.append("Điểm: %d" % sc)
	if code != "":
		lines.append("Nhập mã %s để so tài cùng mình!" % code)
	return "\n".join(lines)


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
	if key == "kills" and _run_active:
		run_kills += n


func on_boss_killed(player_hp: int) -> void:
	if _run_active:
		run_boss_hp.append(player_hp)


func coin_mult() -> float:
	return 1.0 + 0.5 * int(run_buffs.get("boi_thu", 0))


func material_count(id: String) -> int:
	return int(materials.get(id, 0))


func add_run_material(id: String, n: int = 1) -> void:
	if n > 0 and MaterialData.DATA.has(id):
		run_materials[id] = int(run_materials.get(id, 0)) + n


func set_weapon_mod(wid: String, mod_id: String) -> void:
	if wid == "":
		return
	if mod_id == "" or not WeaponMods.DATA.has(mod_id):
		run_weapon_mods.erase(wid)
		return
	run_weapon_mods[wid] = mod_id


func get_weapon_mod(wid: String) -> String:
	if wid == "":
		return ""
	return str(run_weapon_mods.get(wid, ""))


func _commit_run_materials() -> void:
	for id in run_materials:
		var k: String = str(id)
		var v: int = int(run_materials[id])
		if v > 0 and MaterialData.DATA.has(k):
			materials[k] = material_count(k) + v
	run_materials = {}


func forgeable_weapons() -> Array:
	var out: Array = []
	for wid in discovered:
		var w: String = str(wid)
		if MaterialData.can_forge_weapon(w) and not out.has(w):
			out.append(w)
	out.sort_custom(func(a: String, b: String) -> bool:
		var ta: int = int(WeaponData.DATA[a].tier)
		var tb: int = int(WeaponData.DATA[b].tier)
		if ta != tb:
			return ta < tb
		return str(WeaponData.DATA[a].name) < str(WeaponData.DATA[b].name))
	return out


func _has_cost(coins_need: int, mats: Dictionary) -> bool:
	if coins < coins_need:
		return false
	for mid in mats:
		if material_count(str(mid)) < int(mats[mid]):
			return false
	return true


func _spend_cost(coins_need: int, mats: Dictionary) -> void:
	coins -= coins_need
	for mid in mats:
		var k: String = str(mid)
		var left: int = material_count(k) - int(mats[mid])
		if left > 0:
			materials[k] = left
		else:
			materials.erase(k)


func can_craft(wid: String) -> bool:
	if forged != "" or not discovered.has(wid) or not MaterialData.can_forge_weapon(wid):
		return false
	var rec: Dictionary = MaterialData.recipe_for(wid)
	if rec.is_empty():
		return false
	return _has_cost(int(rec.coins), rec.mats)


func try_craft(wid: String) -> bool:
	if not can_craft(wid):
		return false
	var rec: Dictionary = MaterialData.recipe_for(wid)
	_spend_cost(int(rec.coins), rec.mats)
	forged = wid
	save_game()
	return true


func hero_level(id: String) -> int:
	return clampi(int(hero_levels.get(id, 1)), 1, 5)


func weapon_rank(id: String) -> int:
	return clampi(int(weapon_ranks.get(id, 1)), 1, 5)


func can_upgrade_hero(id: String) -> bool:
	if not HeroData.DATA.has(id) or not unlocked.has(id):
		return false
	var cur: int = hero_level(id)
	if cur >= 5:
		return false
	var nxt: Dictionary = ProgressionData.HERO_LEVELS[cur + 1]
	return _has_cost(int(nxt.coins), nxt.mats)


func try_upgrade_hero(id: String) -> bool:
	if not can_upgrade_hero(id):
		return false
	var cur: int = hero_level(id)
	var nxt: Dictionary = ProgressionData.HERO_LEVELS[cur + 1]
	_spend_cost(int(nxt.coins), nxt.mats)
	hero_levels[id] = cur + 1
	save_game()
	return true


func can_upgrade_weapon(id: String) -> bool:
	if not HeroData.DATA.has(id) or not unlocked.has(id):
		return false
	var cur: int = weapon_rank(id)
	if cur >= 5:
		return false
	var nxt: Dictionary = ProgressionData.WEAPON_RANKS[cur + 1]
	return _has_cost(int(nxt.coins), nxt.mats)


func try_upgrade_weapon(id: String) -> bool:
	if not can_upgrade_weapon(id):
		return false
	var cur: int = weapon_rank(id)
	var nxt: Dictionary = ProgressionData.WEAPON_RANKS[cur + 1]
	_spend_cost(int(nxt.coins), nxt.mats)
	weapon_ranks[id] = cur + 1
	save_game()
	return true


func consume_forged() -> String:
	if Net != null and Net.is_online() and not Net.is_host():
		return ""
	var out: String = forged
	if out != "":
		forged = ""
		save_game()
	return out


func _csv_cell(v: Variant) -> String:
	var s: String = str(v).replace("\r", " ").replace("\n", " ")
	if s.contains(",") or s.contains("\""):
		s = "\"" + s.replace("\"", "\"\"") + "\""
	return s


func _write_run_log(outcome: String) -> void:
	if not _run_active or log_path == "":
		return
	var existed: bool = FileAccess.file_exists(log_path)
	var f: FileAccess = FileAccess.open(log_path, FileAccess.READ_WRITE if existed else FileAccess.WRITE)
	if f == null:
		return
	if existed:
		f.seek_end()
	if not existed or f.get_length() == 0:
		f.store_line("ngay_gio,tuong,do_kho,man_xa_nhat,thoi_gian_giay,giac_da_ha,chet_o_man,chet_vi,mau_con_lai_sau_moi_trum,xu_nhat,nguyen_lieu_nhat,phuc_lanh,dong_dieu,cap_bac")
	var dt: String = Time.get_datetime_string_from_system(false, true)
	var diff: String = str(settings.get("difficulty", "thuong"))
	var death_lvl: int = 0 if outcome == "thang" else level
	var cause: String = outcome if outcome != "" else (run_last_hit if run_last_hit != "" else "Giặc")
	var boss_hp_parts: PackedStringArray = []
	for h in run_boss_hp:
		boss_hp_parts.append(str(h))
	var mat_parts: PackedStringArray = []
	for mid in MaterialData.ORDER:
		var mc: int = int(run_materials.get(mid, 0))
		if mc > 0:
			mat_parts.append("%s:%d" % [str(mid), mc])
	var buff_parts: PackedStringArray = []
	for bid in run_buffs:
		var bc: int = int(run_buffs[bid])
		for i in bc:
			buff_parts.append(str(bid))
	var syn_str: String = "%d|%d|%d" % [int(run_syn_counts[0]), int(run_syn_counts[1]), int(run_syn_counts[2])]
	var cols: PackedStringArray = [
		_csv_cell(dt),
		_csv_cell(selected_hero),
		_csv_cell(diff),
		str(level),
		str(int(round(run_elapsed))),
		str(run_kills),
		str(death_lvl),
		_csv_cell(cause),
		_csv_cell("|".join(boss_hp_parts)),
		str(run_coins),
		_csv_cell("|".join(mat_parts)),
		_csv_cell("|".join(buff_parts)),
		_csv_cell(syn_str),
		_csv_cell(run_cap_bac),
	]
	f.store_line(",".join(cols))
	f.close()


func end_run(outcome: String = "") -> void:
	if Net != null and Net.is_online() and not Net.is_host():
		_run_active = false
		_run_score_recorded = false
		run_coins = 0
		run_materials = {}
		run_weapon_mods = {}
		resume_data = {}
		return
	if _run_active and not _run_score_recorded and outcome != "bo_luot":
		record_score(outcome)
	_write_run_log(outcome)
	_run_active = false
	_run_score_recorded = false
	coins += run_coins
	run_coins = 0
	_commit_run_materials()
	run_weapon_mods = {}
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
		"player_name":
			var pn: String = str(value).strip_edges()
			if pn.length() > 18:
				pn = pn.substr(0, 18)
			settings["player_name"] = pn if pn != "" else "Anh Hùng"
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
	match eff_difficulty():
		"de":
			return 0.7
		"kho":
			return 1.4
		_:
			return 1.0


func difficulty_dmg_mult() -> float:
	match eff_difficulty():
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
		"materials": materials,
		"forged": forged,
		"hero_levels": hero_levels,
		"weapon_ranks": weapon_ranks,
		"leaderboard": leaderboard,
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
	if Net != null and Net.is_online() and not Net.is_host():
		return false
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
		"run_materials": run_materials,
		"run_weapon_mods": run_weapon_mods,
		"run_coins": run_coins,
		"boss_order": boss_order,
		"legend_last": legend_last,
		"revived": revived,
		"free_revives": free_revives,
		"run_elapsed": run_elapsed,
		"run_kills": run_kills,
		"run_boss_hp": run_boss_hp,
		"run_last_hit": run_last_hit,
		"run_syn_counts": run_syn_counts,
		"run_cap_bac": run_cap_bac,
		"challenge_code": challenge_code,
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
	run_materials = {}
	var rm: Variant = d.get("run_materials", {})
	if typeof(rm) == TYPE_DICTIONARY:
		for k in rm:
			var mk: String = str(k)
			var mv: int = int(rm[k])
			if mv > 0 and MaterialData.DATA.has(mk):
				run_materials[mk] = mv
	run_weapon_mods = {}
	var rwm: Variant = d.get("run_weapon_mods", {})
	if typeof(rwm) == TYPE_DICTIONARY:
		var rwmd: Dictionary = rwm
		for k in rwmd:
			var wk: String = str(k)
			var mv: String = str(rwmd[k])
			if wk != "" and WeaponMods.DATA.has(mv):
				run_weapon_mods[wk] = mv
	var pl: Dictionary = d.player
	resume_data = {}
	for k in pl:
		resume_data[str(k)] = pl[k]
	var ws: Array = []
	for w in pl.get("weapons", []):
		var wid := str(w)
		ws.append(wid if (wid == "" or WeaponData.DATA.has(wid)) else "")
	resume_data["weapons"] = ws
	_run_active = true
	run_elapsed = float(d.get("run_elapsed", 0.0))
	run_kills = int(d.get("run_kills", 0))
	run_boss_hp = []
	for bh in d.get("run_boss_hp", []):
		run_boss_hp.append(int(bh))
	run_last_hit = str(d.get("run_last_hit", ""))
	run_syn_counts = [0, 0, 0]
	var sc_arr: Variant = d.get("run_syn_counts", [0, 0, 0])
	if typeof(sc_arr) == TYPE_ARRAY and sc_arr.size() >= 3:
		run_syn_counts = [int(sc_arr[0]), int(sc_arr[1]), int(sc_arr[2])]
	run_cap_bac = str(d.get("run_cap_bac", "%d/%d" % [hero_level(selected_hero), weapon_rank(selected_hero)]))
	challenge_code = str(d.get("challenge_code", "")).strip_edges().to_upper()
	_run_score_recorded = false
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
		end_run("bo_luot")
	else:
		clear_run()
	return got


## Đóng cửa sổ (máy tính) hoặc ẩn ứng dụng (điện thoại): giữ lại tiến trình.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_on_exit()
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_inside_tree():
		var sfx: Node = get_tree().root.get_node_or_null("Sfx")
		if sfx != null and sfx.has_method("cleanup"):
			sfx.cleanup()


func save_on_exit() -> void:
	if Net != null and Net.is_online() and not Net.is_host():
		return
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
	leaderboard = []
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
	materials = {}
	var mat_val: Variant = data.get("materials", null)
	if typeof(mat_val) == TYPE_DICTIONARY:
		var md: Dictionary = mat_val
		for k in md:
			var mk: String = str(k)
			var mv: int = int(md[k])
			if mv > 0 and MaterialData.DATA.has(mk):
				materials[mk] = mv
	var fg: String = str(data.get("forged", ""))
	forged = fg if MaterialData.can_forge_weapon(fg) else ""
	hero_levels = {}
	var hl: Variant = data.get("hero_levels", null)
	if typeof(hl) == TYPE_DICTIONARY:
		var hld: Dictionary = hl
		for k in hld:
			var hk: String = str(k)
			if HeroData.DATA.has(hk):
				hero_levels[hk] = clampi(int(hld[k]), 1, 5)
	weapon_ranks = {}
	var wr: Variant = data.get("weapon_ranks", null)
	if typeof(wr) == TYPE_DICTIONARY:
		var wrd: Dictionary = wr
		for k in wrd:
			var wk: String = str(k)
			if HeroData.DATA.has(wk):
				weapon_ranks[wk] = clampi(int(wrd[k]), 1, 5)
	leaderboard = []
	var lb: Variant = data.get("leaderboard", null)
	if typeof(lb) == TYPE_ARRAY:
		var lb_arr: Array = lb
		for item in lb_arr:
			if typeof(item) == TYPE_DICTIONARY:
				var ld: Dictionary = item
				leaderboard.append({
					"code": str(ld.get("code", "")).strip_edges().to_upper(),
					"hero": str(ld.get("hero", "")),
					"level": int(ld.get("level", 1)),
					"time": int(round(float(ld.get("time", 0.0)))),
					"kills": int(ld.get("kills", 0)),
					"score": int(ld.get("score", 0)),
					"date": str(ld.get("date", "")),
					"outcome": str(ld.get("outcome", "")),
				})
		_sort_and_cap_leaderboard()


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
	_add_keys("swap_weapon", [KEY_Q])
	_add_mouse("swap_weapon", MOUSE_BUTTON_WHEEL_UP)
	_add_mouse("swap_weapon", MOUSE_BUTTON_WHEEL_DOWN)
	_add_keys("interact", [KEY_E])
	_add_keys("pause", [KEY_ESCAPE, KEY_P])
	# Tay cầm (để sau này bán trên Steam)
	_add_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_add_pad("attack", JOY_BUTTON_A)
	_add_axis("attack", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_add_pad("skill", JOY_BUTTON_B)
	_add_pad("swap_weapon", JOY_BUTTON_LEFT_SHOULDER)
	_add_pad("interact", JOY_BUTTON_Y)
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
