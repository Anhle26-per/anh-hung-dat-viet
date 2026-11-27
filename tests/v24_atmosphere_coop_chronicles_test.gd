extends Node
## Kiểm thử tổng hợp v2.4.0 — Hồn Sử Đại Việt:
##   1) WeatherFx theo từng chương (petals, rain_mist, embers, bamboo_leaves, mythic_snow) & khởi tạo setup.
##   2) GroundDecal + Fx.decal (giới hạn tối đa 36 vết) + Fx.weapon_trail.
##   3) CoopSynergyData.resolve (5 cặp danh tướng, Thánh Gióng, trùng tướng, fallback) + CoopComboFx + game.trigger_coop_combo_test + hud.show_coop_combo.
##   4) ChronicleData (16 mục khớp 10 BOSSES + 3 LEGENDS + 3 Kỷ vật), unlock_chronicle_for_boss, assemble_blueprint mở relic_boss_motif, lưu/nạp file save, LobbyUI.open_chronicles() & TrophyWallDisplay.
##   5) Dummy DPS / Peak DPS / Total dmg + LobbyUI.open_weapon_test_rack() cầm thử & restore_test_weapons() khôi phục trước khi xuất trận.

const VersionData = preload("res://scripts/data/version.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")
const MaterialData = preload("res://scripts/data/materials.gd")
const WeatherFx = preload("res://scripts/effects/weather_fx.gd")
const GroundDecal = preload("res://scripts/effects/ground_decal.gd")
const Fx = preload("res://scripts/effects/fx.gd")
const CoopSynergyData = preload("res://scripts/data/coop_synergy.gd")
const CoopComboFx = preload("res://scripts/effects/coop_combo_fx.gd")
const ChronicleData = preload("res://scripts/data/chronicles.gd")
const DummyScript = preload("res://scripts/game/dummy.gd")
const HotpatchSync = preload("res://scripts/autoload/hotpatch_sync.gd")

const TEST_SAVE := "user://v24_test_save.json"

var _fail: int = 0
var _completed: bool = false


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		push_error("KIỂM THỬ THẤT BẠI: " + msg)
		print("  THẤT BẠI: ", msg)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _wipe() -> void:
	for p in [TEST_SAVE, TEST_SAVE + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _ready() -> void:
	Global.save_path = TEST_SAVE
	Global.log_path = ""
	_wipe()
	get_tree().create_timer(60.0).timeout.connect(func():
		print("V24 ATMOSPHERE COOP CHRONICLES TEST FAILED: quá thời gian")
		_wipe()
		get_tree().quit(1))
	await _frames(2)
	await _run()
	_wipe()
	if _fail == 0 and _completed:
		print("V24 ATMOSPHERE COOP CHRONICLES TEST OK")
		get_tree().quit(0)
	else:
		print("V24 ATMOSPHERE COOP CHRONICLES TEST FAILED: %d lỗi (completed=%s)" % [_fail, str(_completed)])
		get_tree().quit(1)


func _run() -> void:
	print("== 1. Kiểm tra Version (>= 2.4.0 / BUILD >= 240) & HotpatchSync")
	_check(VersionData.VERSION != "", "VERSION không được rỗng")
	_check(VersionData.BUILD >= 240, "BUILD phải >= 240 (hiện %d)" % VersionData.BUILD)
	_check(not HotpatchSync.needs_autoload_sync(get_tree()), "HotpatchSync.needs_autoload_sync phải false trên bản hiện tại")

	await _test_weather_fx()
	await _test_combat_juice_decals_and_trails()
	await _test_coop_synergy_and_game_combo()
	await _test_chronicles_data_save_and_lobby()
	await _test_dummy_dps_and_weapon_test_rack()
	_completed = true


func _test_weather_fx() -> void:
	print("== 2. Kiểm tra WeatherFx.preset_for_level & WeatherFx.setup")
	var expected_by_chapter := {
		0: "petals",        # Mê Linh
		1: "petals",        # Núi Nưa
		2: "rain_mist",     # Sông Bạch Đằng
		3: "rain_mist",     # Sông Như Nguyệt
		4: "embers",        # Thành Thăng Long
		5: "embers",        # Ải Chi Lăng
		6: "embers",        # Gò Đống Đa
		7: "rain_mist",     # Vàm Nhật Tảo
		8: "bamboo_leaves", # Rừng Yên Thế
		9: "embers",        # Điện Biên Phủ
	}
	for ch_idx in expected_by_chapter:
		Global.chapter_order = [int(ch_idx), 0, 2]
		var p: Dictionary = WeatherFx.preset_for_level(1)
		_check(str(p.get("kind", "")) == str(expected_by_chapter[ch_idx]),
			"Chapter %d weather kind phải là '%s' (hiện '%s')" % [int(ch_idx), str(expected_by_chapter[ch_idx]), str(p.get("kind", ""))])
		_check(str(p.get("label", "")) != "", "Chapter %d thiếu weather label" % int(ch_idx))

	for myth_lv in [17, 19, 24]:
		var mp: Dictionary = WeatherFx.preset_for_level(int(myth_lv))
		_check(str(mp.get("kind", "")) == "mythic_snow",
			"Mythic level %d weather kind phải là 'mythic_snow' (hiện '%s')" % [int(myth_lv), str(mp.get("kind", ""))])

	Global.chapter_order = [0, 1, 2]
	var host := Node2D.new()
	get_tree().root.add_child(host)
	var wf := WeatherFx.new()
	host.add_child(wf)
	wf.setup(11, Rect2(-240, -180, 480, 360)) # Level 11 -> chapter_order[2] == 2 (Sông Bạch Đằng)
	await _frames(3)
	_check(str(wf.preset.get("kind", "")) == "rain_mist", "WeatherFx.setup(11 / Bạch Đằng) phải tạo preset rain_mist")
	_check(wf.get_child_count() >= 1, "WeatherFx.setup phải tạo ít nhất 1 CPUParticles2D con")
	var env_node = WeatherFx.apply_glow_environment(host)
	_check(env_node == null, "Headless apply_glow_environment phải trả về null an toàn")
	host.queue_free()
	await _frames(2)


func _test_combat_juice_decals_and_trails() -> void:
	print("== 3. Kiểm tra GroundDecal, Fx.decal (cap 36) & Fx.weapon_trail")
	var host := Node2D.new()
	get_tree().root.add_child(host)
	await _frames(1)

	for i in 44:
		var k: String = ["scorch", "slash_mark", "armor_shards", "footstep", "blood_ink"][i % 5]
		var d: Node2D = Fx.decal(host, Vector2(float(i) * 4.0, 10.0), k, Color(1.0, 0.7, 0.3), 1.0, 0.25)
		_check(d != null and is_instance_valid(d), "Fx.decal(%s) trả về null" % k)
	await _frames(2)
	var active_decals: Array = get_tree().get_nodes_in_group("ground_decals")
	_check(active_decals.size() <= GroundDecal.MAX_DECALS and active_decals.size() == 36,
		"Số lượng ground_decals phải bị giới hạn đúng MAX_DECALS=36 (hiện %d)" % active_decals.size())

	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 0.5, 0.2, 1))
	var tex := ImageTexture.create_from_image(img)
	var before_children: int = host.get_child_count()
	Fx.weapon_trail(host, tex, Vector2(20, 20), 0.5, Vector2.ONE, false, Color(1.0, 0.35, 0.35), 0.22)
	_check(host.get_child_count() == before_children + 1, "Fx.weapon_trail phải thêm Sprite2D ghost trail vào parent")
	await _frames(2)
	host.queue_free()
	await _frames(2)


func _test_coop_synergy_and_game_combo() -> void:
	print("== 4. Kiểm tra CoopSynergyData, CoopComboFx, game.trigger_coop_combo_test & hud.show_coop_combo")
	var pair1: Dictionary = CoopSynergyData.resolve("ngo_quyen", "tran_hung_dao")
	var pair1_rev: Dictionary = CoopSynergyData.resolve("tran_hung_dao", "ngo_quyen")
	_check(str(pair1.get("id", "")) == "bach_dang_hoa_coc", "Ngô Quyền + Trần Hưng Đạo phải ra bach_dang_hoa_coc")
	_check(str(pair1_rev.get("id", "")) == "bach_dang_hoa_coc", "CoopSynergyData.resolve phải đối xứng thứ tự")
	_check(str(CoopSynergyData.resolve("hai_ba_trung", "ba_trieu").get("id", "")) == "nu_kiet_linh_nam", "Hai Bà Trưng + Bà Triệu")
	_check(str(CoopSynergyData.resolve("ly_thuong_kiet", "le_loi").get("id", "")) == "nam_quoc_thuan_thien", "Lý Thường Kiệt + Lê Lợi")
	_check(str(CoopSynergyData.resolve("quang_trung", "nguyen_trung_truc").get("id", "")) == "hoa_toc_than_binh", "Quang Trung + Nguyễn Trung Trực")
	_check(str(CoopSynergyData.resolve("hoang_hoa_tham", "chien_si_dien_bien").get("id", "")) == "phao_kich_yen_the", "Hoàng Hoa Thám + Điện Biên")
	_check(str(CoopSynergyData.resolve("thanh_giong", "le_loi").get("id", "")) == "phu_dong_thien_vuong", "Thánh Gióng + tướng khác")
	_check(str(CoopSynergyData.resolve("ngo_quyen", "ngo_quyen").get("id", "")) == "song_hung_dong_tam", "Cùng tướng phải ra song_hung_dong_tam")
	_check(str(CoopSynergyData.resolve("ngo_quyen", "quang_trung").get("id", "")) == "hop_chieu_dai_viet", "Cặp tự do phải ra hop_chieu_dai_viet")

	var fx_host := Node2D.new()
	get_tree().root.add_child(fx_host)
	var fx_node: Node2D = CoopComboFx.spawn(fx_host, Vector2(-40, 0), Vector2(40, 0), pair1)
	_check(fx_node != null and is_instance_valid(fx_node), "CoopComboFx.spawn phải tạo node hợp lệ")
	await _frames(2)
	fx_host.queue_free()
	await _frames(1)

	Global.selected_hero = "ngo_quyen"
	Global.chapter_order = [2, 3, 4]
	Global.level = 1
	Global.save_game()
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	var game: Node = game_scene.instantiate()
	get_tree().root.add_child(game)
	await _frames(6)

	_check(game.get("_weather_node") != null and is_instance_valid(game.get("_weather_node")),
		"Game màn Bạch Đằng phải gắn _weather_node vào world")
	var prev_combos: int = int(Global.stats.get("coop_combos", 0))
	var combo_res: Dictionary = game.trigger_coop_combo_test("ngo_quyen", "tran_hung_dao",
		game.player.global_position + Vector2(-32, 0), game.player.global_position + Vector2(32, 0))
	_check(str(combo_res.get("id", "")) == "bach_dang_hoa_coc", "trigger_coop_combo_test phải trả về bach_dang_hoa_coc")
	_check(int(Global.stats.get("coop_combos", 0)) == prev_combos + 1, "coop_combos stat phải tăng +1")
	_check(Global.has_chronicle("coop_dong_tam"), "trigger_coop_combo_test phải mở khóa kỷ vật coop_dong_tam")
	_check(game.hud != null and float(game.hud.get("_coop_combo_t")) > 0.0, "HUD phải bật banner show_coop_combo")

	game.hud.show_coop_combo("Thử Nghiệm Hợp Chiêu", "Phụ đề", Color.GOLD)
	_check(str(game.hud.get("_coop_combo_name")) == "Thử Nghiệm Hợp Chiêu", "hud.show_coop_combo phải cập nhật tên banner")
	await _frames(3)
	game.queue_free()
	await _frames(3)


func _test_chronicles_data_save_and_lobby() -> void:
	print("== 5. Kiểm tra ChronicleData (>= 16 mục), Boss/Blueprint Unlock, Save/Load & Lobby Trophy Wall / Modal")
	_check(ChronicleData.total_count() >= 16, "ChronicleData phải có >= 16 mục (hiện %d)" % ChronicleData.total_count())
	for bid in EnemyData.BOSSES:
		var cid: String = ChronicleData.entry_for_boss(str(bid))
		_check(cid != "" and ChronicleData.DATA.has(cid), "Thiếu trang Hồn Sử cho Boss '%s'" % str(bid))
	for lid in EnemyData.LEGENDS:
		var cid2: String = ChronicleData.entry_for_boss(str(lid))
		_check(cid2 != "" and ChronicleData.DATA.has(cid2), "Thiếu trang Hồn Sử cho Tam Yêu '%s'" % str(lid))

	Global.unlocked_chronicles.clear()
	Global.blueprints.clear()
	Global.blueprint_fragments.clear()
	Global.coins = 100
	Global.save_game()

	var u1: Dictionary = Global.unlock_chronicle_for_boss("hoang_thao")
	_check(bool(u1.get("newly_unlocked", false)) and str(u1.get("id", "")) == "hoang_thao",
		"unlock_chronicle_for_boss('hoang_thao') phải mở mới thành công")
	var u1_dup: Dictionary = Global.unlock_chronicle_for_boss("hoang_thao")
	_check(u1_dup.is_empty(), "Mở lại cùng 1 chronicle phải trả về {}")
	var u_alias: Dictionary = Global.unlock_chronicle_for_boss("cuu_vi_ho")
	_check(str(u_alias.get("id", "")) == "ho_tinh_vuong", "Alias 'cuu_vi_ho' phải ánh xạ về 'ho_tinh_vuong'")

	var bm_wid: String = "huyet_dao_to_dinh"
	var need: int = MaterialData.fragments_needed(bm_wid)
	_check(need > 0, "huyet_dao_to_dinh phải cần mảnh bản vẽ")
	Global.add_blueprint_fragment(bm_wid, need)
	var assembled: bool = Global.assemble_blueprint(bm_wid)
	_check(assembled, "assemble_blueprint('%s') phải thành công" % bm_wid)
	_check(Global.has_chronicle("relic_boss_motif"), "Ghép bản vẽ boss_motif phải mở khóa 'relic_boss_motif'")

	Global.save_game()
	Global.unlocked_chronicles.clear()
	Global.load_game()
	_check(Global.has_chronicle("hoang_thao") and Global.has_chronicle("ho_tinh_vuong") and Global.has_chronicle("relic_boss_motif"),
		"Save/Load phải giữ nguyên danh sách unlocked_chronicles")

	var lobby_scene: PackedScene = load("res://scenes/lobby.tscn")
	var lobby: Node = lobby_scene.instantiate()
	get_tree().root.add_child(lobby)
	await _frames(5)

	var wall = lobby.get("_trophy_wall")
	_check(wall != null and is_instance_valid(wall), "Lobby phải có _trophy_wall (TrophyWallDisplay)")
	_check(wall.trophy_count() >= 3, "TrophyWallDisplay phải hiển thị >= 3 kỷ vật đã mở (hiện %d)" % wall.trophy_count())
	_check(lobby.stations.any(func(s): return str(s.kind) == "chronicles"), "Lobby phải có trạm 'chronicles'")
	_check(lobby.stations.any(func(s): return str(s.kind) == "weapon_test"), "Lobby phải có trạm 'weapon_test'")

	lobby.ui.open_chronicles()
	await _frames(2)
	_check(lobby.ui._panel != null and lobby.ui._panel.visible, "LobbyUI.open_chronicles() phải mở modal")
	var chron_txt: String = _collect_ui_text(lobby.ui)
	_check(chron_txt.contains("HỒN SỬ ĐẠI VIỆT"), "Modal Hồn Sử phải có tiêu đề HỒN SỬ ĐẠI VIỆT")
	_check(chron_txt.contains("Hoằng Tháo"), "Modal Hồn Sử phải hiển thị trang Hoằng Tháo đã mở")
	lobby.ui.close()
	await _frames(2)
	lobby.queue_free()
	await _frames(3)


func _test_dummy_dps_and_weapon_test_rack() -> void:
	print("== 6. Kiểm tra Dummy DPS/Peak DPS/Total dmg & Thử Binh Khí + restore_test_weapons")
	var host := Node2D.new()
	get_tree().root.add_child(host)
	var dm: Node2D = DummyScript.new()
	dm.position = Vector2(120, 120)
	host.add_child(dm)
	await _frames(2)

	dm.take_damage(30)
	dm.take_damage(45)
	dm.dot_damage(12, "burn")
	await _frames(2)
	_check(int(dm.total_dmg) >= 87, "Dummy.total_dmg phải >= 87 (hiện %d)" % int(dm.total_dmg))
	_check(float(dm.dps) > 0.0 and float(dm.peak_dps) >= float(dm.dps),
		"Dummy.dps (%.1f) & peak_dps (%.1f) phải > 0" % [float(dm.dps), float(dm.peak_dps)])
	dm.reset_dps()
	_check(int(dm.total_dmg) == 0 and is_zero_approx(float(dm.dps)) and is_zero_approx(float(dm.peak_dps)),
		"Dummy.reset_dps() phải xóa sạch DPS, Peak DPS và Total dmg")
	host.queue_free()
	await _frames(2)

	Global.selected_hero = "ngo_quyen"
	Global.discover("huyet_dao_to_dinh", true)
	var lobby_scene: PackedScene = load("res://scenes/lobby.tscn")
	var lobby: Node = lobby_scene.instantiate()
	get_tree().root.add_child(lobby)
	await _frames(5)

	var orig_wid: String = str(lobby.player.weapons[lobby.player.slot])
	_check(orig_wid == "giao_tre", "Vũ khí ban đầu của Ngô Quyền phải là giao_tre (hiện '%s')" % orig_wid)
	lobby.ui.open_weapon_test_rack(5)
	await _frames(2)
	var rack_txt: String = _collect_ui_text(lobby.ui)
	_check(rack_txt.contains("Thử Binh Khí"), "Modal open_weapon_test_rack phải hiển thị tiêu đề Thử Binh Khí")
	var ok_equip: bool = lobby.player.equip_test_weapon("huyet_dao_to_dinh")
	_check(ok_equip, "equip_test_weapon('huyet_dao_to_dinh') phải trả về true")
	_check(str(lobby.player.weapons[lobby.player.slot]) == "huyet_dao_to_dinh",
		"Sau equip_test_weapon, vũ khí đang cầm phải là huyet_dao_to_dinh")
	lobby.ui.close()
	await _frames(1)
	lobby.player.restore_test_weapons()
	_check(str(lobby.player.weapons[lobby.player.slot]) == orig_wid,
		"restore_test_weapons() phải trả lại vũ khí gốc '%s'" % orig_wid)

	# Kiểm tra start_run_with_code cũng tự gọi restore_test_weapons trước khi vào trận
	lobby.player.equip_test_weapon("huyet_dao_to_dinh")
	_check(str(lobby.player.weapons[lobby.player.slot]) == "huyet_dao_to_dinh", "Đang cầm vũ khí thử trước khi xuất trận")
	get_tree().current_scene = lobby
	lobby.start_run_with_code("")
	_check(str(lobby.player.weapons[lobby.player.slot]) == orig_wid,
		"start_run_with_code phải tự gọi restore_test_weapons() trả về '%s'" % orig_wid)
	_check(lobby.player._lobby_test_backup.is_empty(), "_lobby_test_backup phải được xóa sạch sau start_run_with_code")
	await _frames(4)
	if is_instance_valid(lobby):
		lobby.queue_free()
	if get_tree().current_scene != null and is_instance_valid(get_tree().current_scene) and get_tree().current_scene != self:
		get_tree().current_scene.queue_free()
	get_tree().current_scene = self
	await _frames(2)


func _collect_ui_text(node: Node) -> String:
	var out: PackedStringArray = []
	_walk_text(node, out)
	return "\n".join(out)


func _walk_text(n: Node, out: PackedStringArray) -> void:
	if n is Label:
		out.append((n as Label).text)
	elif n is RichTextLabel:
		out.append((n as RichTextLabel).text)
	elif n is Button:
		out.append((n as Button).text)
	for c in n.get_children():
		_walk_text(c, out)
