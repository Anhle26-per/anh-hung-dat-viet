extends Node
## Hệ thống âm thanh và nhạc nền toàn game (autoload "Sfx").
## Tạo 2 bus "Music" và "SFX" bằng mã, giới hạn tối đa 8 tiếng SFX phát cùng lúc.

const WeaponData = preload("res://scripts/data/weapons.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")

signal music_changed(track_id: String, title: String)

const MAX_VOICES: int = 8
const MIN_INTERVAL_MS: int = 50
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"

const SFX_FILES: Dictionary = {
	"slash": "res://assets/audio/sfx/slash.wav",
	"arrow": "res://assets/audio/sfx/arrow.wav",
	"shoot": "res://assets/audio/sfx/shoot.wav",
	"explode": "res://assets/audio/sfx/explode.wav",
	"player_hurt": "res://assets/audio/sfx/player_hurt.wav",
	"enemy_hurt": "res://assets/audio/sfx/enemy_hurt.wav",
	"enemy_die": "res://assets/audio/sfx/enemy_die.wav",
	"coin": "res://assets/audio/sfx/coin.wav",
	"pickup": "res://assets/audio/sfx/pickup.wav",
	"pickup_coin": "res://assets/audio/sfx/pickup_coin.wav",
	"pickup_weapon": "res://assets/audio/sfx/pickup_weapon.wav",
	"chest_open": "res://assets/audio/sfx/chest_open.wav",
	"buy": "res://assets/audio/sfx/buy.wav",
	"buy_fail": "res://assets/audio/sfx/buy_fail.wav",
	"door_close": "res://assets/audio/sfx/door_close.wav",
	"portal": "res://assets/audio/sfx/portal.wav",
	"boss_appear": "res://assets/audio/sfx/boss_appear.wav",
	"boss_morph": "res://assets/audio/sfx/boss_morph.wav",
	"level_clear": "res://assets/audio/sfx/level_clear.wav",
	"ui_click": "res://assets/audio/sfx/ui_click.wav",
	"player_die": "res://assets/audio/sfx/player_die.wav",
	"skill": "res://assets/audio/sfx/skill.wav",
	"hit_flesh": "res://assets/audio/sfx/hit_flesh.wav",
	"hit_bullet": "res://assets/audio/sfx/hit_bullet.wav",
	"hit_metal": "res://assets/audio/sfx/hit_metal.wav",
	"hit_wall": "res://assets/audio/sfx/hit_wall.wav",
	"hit_wood": "res://assets/audio/sfx/hit_wood.wav",
	"hit_crit": "res://assets/audio/sfx/hit_crit.wav",
	"hit_boss": "res://assets/audio/sfx/hit_boss.wav",
	"pickup_material": "res://assets/audio/sfx/pickup_material.wav",
	"forge": "res://assets/audio/sfx/forge.wav",
	# 14 kỹ năng tướng riêng biệt + Chiêu 2 + Cổ Loa + Ping + Thiên Phú/Thần Thú
	"skill_hai_ba_trung": "res://assets/audio/sfx/skill_hai_ba_trung.wav",
	"skill_ba_trieu": "res://assets/audio/sfx/skill_ba_trieu.wav",
	"skill_ngo_quyen": "res://assets/audio/sfx/skill_ngo_quyen.wav",
	"skill_ly_thuong_kiet": "res://assets/audio/sfx/skill_ly_thuong_kiet.wav",
	"skill_tran_hung_dao": "res://assets/audio/sfx/skill_tran_hung_dao.wav",
	"skill_le_loi": "res://assets/audio/sfx/skill_le_loi.wav",
	"skill_quang_trung": "res://assets/audio/sfx/skill_quang_trung.wav",
	"skill_nguyen_trung_truc": "res://assets/audio/sfx/skill_nguyen_trung_truc.wav",
	"skill_hoang_hoa_tham": "res://assets/audio/sfx/skill_hoang_hoa_tham.wav",
	"skill_chien_si_dien_bien": "res://assets/audio/sfx/skill_chien_si_dien_bien.wav",
	"skill_thanh_giong": "res://assets/audio/sfx/skill_thanh_giong.wav",
	"skill_an_duong_vuong": "res://assets/audio/sfx/skill_an_duong_vuong.wav",
	"skill_lac_long_quan": "res://assets/audio/sfx/skill_lac_long_quan.wav",
	"skill_son_tinh": "res://assets/audio/sfx/skill_son_tinh.wav",
	"skill2_cast": "res://assets/audio/sfx/skill2_cast.wav",
	"tower_build": "res://assets/audio/sfx/tower_build.wav",
	"tower_upgrade": "res://assets/audio/sfx/tower_upgrade.wav",
	"core_repair": "res://assets/audio/sfx/core_repair.wav",
	"core_crossbow": "res://assets/audio/sfx/core_crossbow.wav",
	"war_drum": "res://assets/audio/sfx/war_drum.wav",
	"core_alarm": "res://assets/audio/sfx/core_alarm.wav",
	"ping_focus": "res://assets/audio/sfx/ping_focus.wav",
	"ping_danger": "res://assets/audio/sfx/ping_danger.wav",
	"ping_loot": "res://assets/audio/sfx/ping_loot.wav",
	"ping_combo": "res://assets/audio/sfx/ping_combo.wav",
	"skill_tree_unlock": "res://assets/audio/sfx/skill_tree_unlock.wav",
	"pet_awaken": "res://assets/audio/sfx/pet_awaken.wav",
	# 32 nhóm âm thanh vũ khí (phủ toàn bộ 225 binh khí)
	"w_bamboo": "res://assets/audio/sfx/w_bamboo.wav",
	"w_dagger": "res://assets/audio/sfx/w_dagger.wav",
	"w_sword": "res://assets/audio/sfx/w_sword.wav",
	"w_greatsword": "res://assets/audio/sfx/w_greatsword.wav",
	"w_spear": "res://assets/audio/sfx/w_spear.wav",
	"w_axe": "res://assets/audio/sfx/w_axe.wav",
	"w_hammer": "res://assets/audio/sfx/w_hammer.wav",
	"w_scythe": "res://assets/audio/sfx/w_scythe.wav",
	"w_spin": "res://assets/audio/sfx/w_spin.wav",
	"w_fan": "res://assets/audio/sfx/w_fan.wav",
	"w_whip": "res://assets/audio/sfx/w_whip.wav",
	"w_bow": "res://assets/audio/sfx/w_bow.wav",
	"w_crossbow": "res://assets/audio/sfx/w_crossbow.wav",
	"w_dart": "res://assets/audio/sfx/w_dart.wav",
	"w_boomerang": "res://assets/audio/sfx/w_boomerang.wav",
	"w_pistol": "res://assets/audio/sfx/w_pistol.wav",
	"w_rifle": "res://assets/audio/sfx/w_rifle.wav",
	"w_shotgun": "res://assets/audio/sfx/w_shotgun.wav",
	"w_musket": "res://assets/audio/sfx/w_musket.wav",
	"w_cannon": "res://assets/audio/sfx/w_cannon.wav",
	"w_rocket": "res://assets/audio/sfx/w_rocket.wav",
	"w_grenade": "res://assets/audio/sfx/w_grenade.wav",
	"w_fire": "res://assets/audio/sfx/w_fire.wav",
	"w_ice": "res://assets/audio/sfx/w_ice.wav",
	"w_lightning": "res://assets/audio/sfx/w_lightning.wav",
	"w_poison": "res://assets/audio/sfx/w_poison.wav",
	"w_jade": "res://assets/audio/sfx/w_jade.wav",
	"w_void": "res://assets/audio/sfx/w_void.wav",
	"w_magic_orb": "res://assets/audio/sfx/w_magic_orb.wav",
	"w_laser": "res://assets/audio/sfx/w_laser.wav",
	"w_drum": "res://assets/audio/sfx/w_drum.wav",
	"w_flute": "res://assets/audio/sfx/w_flute.wav",
}

const WEAPON_ARCHETYPE: Dictionary = {
	# Tre / Côn / Gậy
	"gay_tre": "w_bamboo", "con_lam_son": "w_bamboo", "tre_tram_dot": "w_bamboo", "quat_mo": "w_bamboo", "gay_sat": "w_bamboo",
	# Dao găm / Liềm / Bút lông
	"dao_gam": "w_dagger", "dao_gam_doc": "w_dagger", "dao_gam_ao_anh": "w_dagger", "liem": "w_dagger", "but_long_than": "w_dagger",
	# Kiếm / Gươm / Mã tấu
	"kiem_dong": "w_sword", "doan_dao": "w_sword", "guom_lenh": "w_sword", "dao_rua": "w_sword",
	"kiem": "w_sword", "ma_tau": "w_sword", "song_kiem": "w_sword", "kiem_nhat_nguyet": "w_sword",
	"song_dao_phong_ba": "w_sword", "muoi_duc_anh_trang": "w_sword",
	# Đại đao / Thần kiếm
	"dao": "w_greatsword", "kiem_rong_tien": "w_greatsword", "thuan_thien": "w_greatsword",
	"dai_dao_huyen_vu": "w_greatsword", "dai_dao_thanh_long": "w_greatsword",
	# Giáo / Thương / Kích / Đinh ba
	"giao_tre": "w_spear", "giao": "w_spear", "mac": "w_spear", "kich": "w_spear",
	"truong_thuong": "w_spear", "thuong_dong": "w_spear", "thuong_bang": "w_spear",
	"thuong_hoa_long": "w_spear", "kich_thien_loi": "w_spear", "thuong_bach_long": "w_spear", "dinh_ba_thuy_tinh": "w_spear",
	# Rìu
	"riu_da": "w_axe", "riu_chien": "w_axe", "riu_thach_sanh": "w_axe",
	# Chùy / Búa
	"chuy_dong": "w_hammer", "bua_sat": "w_hammer", "bua_bang_ha": "w_hammer",
	"bua_chan_thien": "w_hammer", "bua_thien_loi": "w_hammer", "bua_cuu_le": "w_hammer",
	# Lưỡi hái
	"luoi_hai_bac": "w_scythe", "luoi_hai_huyet_nguyet": "w_scythe", "luoi_hai_tu_than": "w_scythe",
	# Xoay / Cưa
	"con_nhi_khuc": "w_spin", "cua_may_cam_tay": "w_spin", "sung_ban_cua": "w_spin", "sung_cua_xoay": "w_spin",
	# Quạt
	"quat_thep": "w_fan", "quat_ngoc_luan": "w_fan", "quat_ba_tieu": "w_fan",
	# Roi sắt
	"roi_sat_giong": "w_whip",
	# Cung
	"cung": "w_bow", "cung_dai": "w_bow", "cung_tre": "w_bow", "cung_bang": "w_bow",
	"cung_set": "w_bow", "cung_tinh_van": "w_bow", "cung_nguyet_anh": "w_bow",
	"cung_vang": "w_bow", "cung_rong": "w_bow", "cung_thai_duong": "w_bow", "cung_phan_than": "w_bow",
	# Nỏ
	"no_tay": "w_crossbow", "no": "w_crossbow", "no_doc": "w_crossbow", "no_bang_suong": "w_crossbow",
	"no_bao_lua": "w_crossbow", "no_thien_co": "w_crossbow", "no_lien_chau": "w_crossbow",
	"no_cuu_long": "w_crossbow", "no_huyet_anh": "w_crossbow",
	# Phi tiêu / Bài / Ná / Đinh
	"phi_tieu": "w_dart", "phi_tieu_doc": "w_dart", "phi_tieu_sao_bang": "w_dart",
	"na": "w_dart", "guoc_moc": "w_dart", "xuc_xac_no": "w_dart",
	"sung_ban_da": "w_dart", "sung_ban_dinh": "w_dart", "sung_tien_xu": "w_dart",
	"bai_tu_sac": "w_dart", "bo_bai_than": "w_dart",
	# Boomerang / Luân
	"non_la_bay": "w_boomerang", "chong_chong_tre": "w_boomerang", "luan_hoi_ban": "w_boomerang",
	"vong_sen_luan": "w_boomerang", "phi_dao_luan_hoi": "w_boomerang", "banh_xe_phong_hoa": "w_boomerang",
	# Súng ngắn / Lục
	"sung_kip": "w_pistol", "sung_ngan": "w_pistol", "sung_luc": "w_pistol", "sung_dan_nay": "w_pistol",
	# Súng trường / Tiểu liên / Máy
	"sung_truong_bo_binh": "w_rifle", "sung_truong": "w_rifle", "tieu_lien": "w_rifle",
	"sung_truong_tan_cong": "w_rifle", "sung_ban_tia": "w_rifle", "sung_may": "w_rifle",
	# Súng săn
	"sung_san": "w_shotgun", "sung_hai_nong": "w_shotgun",
	# Hỏa mai / Thần cơ
	"hoa_mai_yen_the": "w_musket", "hoa_mai": "w_musket", "than_co_sang": "w_musket",
	# Pháo đồng / Đại bác
	"phao_dong": "w_cannon", "dai_bac_than_cong": "w_cannon", "dai_bac_long_vuong": "w_cannon",
	# Hỏa tiễn / Pháo hoa
	"hoa_tien": "w_rocket", "sung_phong_ten_lua": "w_rocket", "phao_hoa_tet": "w_rocket",
	"phao_thang_thien": "w_rocket", "sung_hoa_ti_lien": "w_rocket",
	# Phóng lựu / Hồ lô
	"sung_phong_luu": "w_grenade", "binh_ho_lo_ruou": "w_grenade", "xuc_xac_van_menh": "w_grenade",
	# Hỏa diễm / Bùa lửa
	"ong_lua": "w_fire", "hoa_ho": "w_fire", "sung_phun_lua": "w_fire", "dua_tia_lua": "w_fire",
	"truong_hoa_cau": "w_fire", "sach_thien_thach": "w_fire", "truong_hoa_nguc": "w_fire",
	"kiem_lua": "w_fire", "kiem_phuong_hoang": "w_fire", "bua_giay_vang": "w_fire",
	"bua_tru_ta": "w_fire", "bua_thien_su": "w_fire",
	# Hàn băng
	"gay_suong_mu": "w_ice", "dua_bang_suong": "w_ice", "truong_bang_gia": "w_ice",
	"truong_bao_tuyet": "w_ice", "kiem_bang": "w_ice", "song_kiem_bang_hoa": "w_ice",
	"sung_bang": "w_ice", "sung_tuyet_son": "w_ice",
	# Sấm sét
	"truong_sam_set": "w_lightning", "sach_loi_than": "w_lightning", "truong_cuu_thien": "w_lightning",
	"dua_ngoc_hoang": "w_lightning", "kiem_set": "w_lightning", "sung_dien_giat": "w_lightning", "sung_tesla": "w_lightning",
	# Độc tố
	"sach_la_doc": "w_poison", "truong_doc_to": "w_poison", "sach_doc_vuong": "w_poison",
	"kiem_doc_xa": "w_poison", "sung_axit": "w_poison", "sung_doc_duoc": "w_poison",
	# Thủy / Ngọc / Bong bóng
	"dua_giot_nuoc": "w_jade", "truong_thai_cuc": "w_jade", "sung_tia_nuoc": "w_jade",
	"sung_bong_bong": "w_jade", "sung_bong_bong_tien": "w_jade",
	# Hư không / Linh hồn / Thời không
	"dua_but_long": "w_void", "truong_trong_luc": "w_void", "sach_hu_khong": "w_void",
	"truong_ho_den": "w_void", "dua_linh_hon": "w_void", "long_den_ma_troi": "w_void",
	"bua_tran_yeu": "w_void", "kiem_thoi_khong": "w_void", "sung_trong_luc": "w_void", "sung_phan_vat_chat": "w_void",
	# Ma pháp tinh tú
	"sach_ma_phap_co": "w_magic_orb", "quyen_truong_phu_thuy": "w_magic_orb", "sach_sao_bang": "w_magic_orb",
	"sach_ngan_ha": "w_magic_orb", "sach_thien_khai": "w_magic_orb", "truong_ngu_hanh": "w_magic_orb", "den_ong_sao": "w_magic_orb",
	# Tia laze / Plasma / Điện từ
	"kiem_tia_sang": "w_laser", "kiem_plasma": "w_laser", "kiem_luong_tu": "w_laser",
	"sung_plasma": "w_laser", "sung_luong_tu": "w_laser", "sung_tieu_huy": "w_laser",
	"sung_laze": "w_laser", "sung_dien_tu": "w_laser", "sung_railgun": "w_laser",
	"sung_quang_tu": "w_laser", "sung_lang_kinh": "w_laser", "truong_anh_sang": "w_laser",
	"sach_tinh_tu": "w_laser", "guong_bat_quai": "w_laser", "kinh_van_hoa": "w_laser",
	# Trống đồng / Địa chấn
	"trong_dong": "w_drum", "trong_com_set": "w_drum", "gay_son_tinh": "w_drum", "truong_dia_chan": "w_drum",
	# Sáo / Đàn / Chuông
	"sao_truc": "w_flute", "sao_truc_bao_to": "w_flute", "dan_than": "w_flute",
	"chuong_dong": "w_flute", "chuong_chieu_hon": "w_flute", "chuong_phat_to": "w_flute", "sach_gio_loc": "w_flute",
	# 25 Binh Khí Hợp Nhất / Thần Binh Đỏ / Tướng v3.0
	"no_co_loa": "w_crossbow", "long_uyen_kiem": "w_sword", "bua_tan_vien": "w_hammer",
	"thai_cuc_kiem": "w_greatsword", "cung_loi_hoa": "w_bow", "phao_thien_long": "w_rocket",
	"luoi_hai_am_duong": "w_scythe", "long_than_hai_kich": "w_spear", "thien_loi_than_cung": "w_bow",
	"huyet_dao_to_dinh": "w_greatsword", "kich_luc_dan": "w_spear", "dinh_ba_hoang_thao": "w_spear",
	"cung_quach_quy": "w_bow", "ong_dong_thoat_hoan": "w_cannon", "bua_lieu_thang": "w_axe",
	"phao_ton_si_nghi": "w_cannon", "hoa_phao_hy_vong": "w_cannon", "sung_don_truong": "w_rifle",
	"phao_coi_do_cat": "w_rocket", "ho_ly_cuu_vi": "w_fire", "truong_xuong_cuong": "w_drum",
	"hai_than_hac_hai": "w_jade", "dinh_ba_thuy_tinh_than": "w_spear", "loi_chuy_thien_de": "w_hammer",
	"thai_to_thien_kiem": "w_greatsword",
}

const TIER_PITCHES: Dictionary = {
	1: 1.05,
	2: 1.01,
	3: 0.97,
	4: 0.93,
	5: 0.89,
}

const MUSIC_FILES: Dictionary = {
	"lobby": "res://assets/audio/music/lobby.wav",
	"basement": "res://assets/audio/music/basement.wav",
	"battle": "res://assets/audio/music/battle.wav",
	"battle_forest": "res://assets/audio/music/battle_forest.wav",
	"battle_river": "res://assets/audio/music/battle_river.wav",
	"battle_citadel": "res://assets/audio/music/battle_citadel.wav",
	"battle_modern": "res://assets/audio/music/battle_modern.wav",
	"battle_sprint": "res://assets/audio/music/battle_sprint.wav",
	"battle_mythic": "res://assets/audio/music/battle_mythic.wav",
	"boss": "res://assets/audio/music/boss.wav",
	"boss_frenzy": "res://assets/audio/music/boss_frenzy.wav",
	"boss_legend": "res://assets/audio/music/boss_legend.wav",
	"boss_mythic": "res://assets/audio/music/boss_mythic.wav",
	"victory": "res://assets/audio/music/victory.wav",
	"coloa_defense": "res://assets/audio/music/coloa_defense.wav",
	"coloa_siege": "res://assets/audio/music/coloa_siege.wav",
	"secret_thuy_cung": "res://assets/audio/music/secret_thuy_cung.wav",
	"secret_tan_vien": "res://assets/audio/music/secret_tan_vien.wav",
	"boss_hon_mang": "res://assets/audio/music/boss_hon_mang.wav",
}

const MUSIC_TITLES: Dictionary = {
	"lobby": "Doanh Trại Yên Bình",
	"basement": "Tầng Hầm Chiến Tích",
	"battle": "Hành Quân Khởi Nghĩa",
	"battle_forest": "Đại Ngàn Mai Phục",
	"battle_river": "Sóng Gió Bạch Đằng",
	"battle_citadel": "Khí Phách Thăng Long",
	"battle_modern": "Tiến Quân Điện Biên",
	"battle_sprint": "Thần Tốc Xung Phong",
	"battle_mythic": "Lĩnh Nam Huyền Ảo",
	"boss": "Quyết Chiến Đại Tướng",
	"boss_frenzy": "Bạo Nộ Huyết Chiến",
	"boss_legend": "Tam Yêu Hiện Hình",
	"boss_mythic": "Thần Thoại Đại Chiến",
	"victory": "Khải Hoàn Ca",
	"coloa_defense": "Hào Khí Thành Cổ Loa",
	"coloa_siege": "Cổ Loa Công Thành",
	"secret_thuy_cung": "Thủy Cung Long Vương",
	"secret_tan_vien": "Đỉnh Tản Viên Linh Thiêng",
	"boss_hon_mang": "Hỗn Mang Diệt Thế",
}

var _sfx_streams: Dictionary = {}
var _music_streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _cursor: int = 0
var _music_a: AudioStreamPlayer = null
var _music_b: AudioStreamPlayer = null
var _active_music_slot: int = 0
var _music_tween: Tween = null
var _current_music: String = ""
var _music_volume: float = 0.65
var _sfx_volume: float = 0.85
var _last_play_ms: Dictionary = {}
var _play_counts: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_SFX)

	_music_a = AudioStreamPlayer.new()
	_music_a.bus = BUS_MUSIC
	_music_a.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_a)

	_music_b = AudioStreamPlayer.new()
	_music_b.bus = BUS_MUSIC
	_music_b.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_b)

	for id in SFX_FILES:
		var path: String = str(SFX_FILES[id])
		if ResourceLoader.exists(path):
			var st: Resource = load(path)
			if st is AudioStream:
				_sfx_streams[str(id)] = st

	for id in MUSIC_FILES:
		var path: String = str(MUSIC_FILES[id])
		if ResourceLoader.exists(path):
			var st: Resource = load(path)
			if st is AudioStreamWAV:
				var wav: AudioStreamWAV = st as AudioStreamWAV
				wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
				wav.loop_begin = 0
				wav.loop_end = int(round(wav.get_length() * float(wav.mix_rate)))
				_music_streams[str(id)] = wav
			elif st is AudioStream:
				_music_streams[str(id)] = st

	var g: Node = get_tree().root.get_node_or_null("Global")
	if g != null:
		_music_volume = float(g.settings.get("music", 0.8))
		_sfx_volume = float(g.settings.get("sfx", 0.9))
	set_music_volume(_music_volume)
	set_sfx_volume(_sfx_volume)


func _ensure_bus(bus_name: String) -> int:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")
	return idx


func play(id: String, volume_db: float = 0.0, pitch_jitter: float = 0.08) -> void:
	_play_internal(id, 1.0, volume_db, pitch_jitter)


func play_pitched(id: String, pitch: float = 1.0, volume_db: float = 0.0, pitch_jitter: float = 0.04) -> void:
	_play_internal(id, pitch, volume_db, pitch_jitter)


func skill_sfx_id(hero_id: String) -> String:
	var candidate: String = "skill_" + hero_id
	if SFX_FILES.has(candidate):
		return candidate
	return "skill"


func play_skill(hero_id: String, volume_db: float = 0.0, skill_slot: int = 1) -> void:
	var pitch: float = 1.06 if skill_slot == 2 else 1.0
	play_pitched(skill_sfx_id(hero_id), pitch, volume_db, 0.03)
	if skill_slot == 2 and SFX_FILES.has("skill2_cast"):
		play_pitched("skill2_cast", 1.0, volume_db - 2.5, 0.03)


func _hash_id(s: String) -> int:
	var h: int = 2166136261
	for i in s.length():
		h = ((h ^ s.unicode_at(i)) * 16777619) & 0x7FFFFFFF
	return h


func _infer_weapon_archetype(weapon_id: String, w: Dictionary) -> String:
	if WEAPON_ARCHETYPE.has(weapon_id):
		return str(WEAPON_ARCHETYPE[weapon_id])
	var wtype: String = str(w.get("type", "melee"))
	var proj: String = str(w.get("proj", ""))
	var st: String = str(w.get("status", ""))
	if wtype == "beam":
		return "w_laser"
	if wtype == "spikes":
		return "w_drum"
	if wtype == "wave":
		if weapon_id.find("trong") != -1:
			return "w_drum"
		return "w_flute"
	if wtype == "melee":
		if str(w.get("style", "")) == "thrust":
			return "w_spear"
		if str(w.get("style", "")) == "spin":
			return "w_spin"
		if int(w.get("chain", 0)) > 0:
			return "w_lightning"
		if st == "burn" or bool(w.get("fire", false)):
			return "w_fire"
		if st == "slow" or float(w.get("slow", 0.0)) > 0.0:
			return "w_ice"
		if st == "poison":
			return "w_poison"
		return "w_sword"
	if bool(w.get("boomerang", false)) or proj == "chakram":
		return "w_boomerang"
	if proj == "arrow":
		return "w_crossbow" if weapon_id.begins_with("no_") else "w_bow"
	if proj in ["dart", "stone", "card"]:
		return "w_dart"
	if proj == "axe":
		return "w_axe"
	if proj == "sawblade":
		return "w_spin"
	if proj == "rocket":
		return "w_rocket"
	if proj == "grenade":
		return "w_grenade"
	if proj == "cannonball":
		return "w_cannon" if float(w.get("explode", 0.0)) > 0.0 else "w_musket"
	if proj == "fireball":
		return "w_fire"
	if proj == "orb_ice":
		return "w_ice"
	if proj == "orb_lightning":
		return "w_lightning"
	if proj == "orb_poison":
		return "w_poison"
	if proj in ["orb_water", "bubble"]:
		return "w_jade"
	if proj in ["orb_void", "soul_bolt"]:
		return "w_void"
	if proj in ["orb_star", "orb_pink"]:
		return "w_magic_orb"
	if proj == "plasma":
		return "w_laser"
	if proj == "pellet":
		return "w_shotgun"
	if proj == "talisman":
		return "w_fire"
	return "w_rifle"


func weapon_sfx_profile(weapon_id: String, weapon_data: Dictionary = {}) -> Dictionary:
	var w: Dictionary = weapon_data
	if w.is_empty() and weapon_id != "":
		w = WeaponData.get_data(weapon_id)
	var sid: String = _infer_weapon_archetype(weapon_id, w)
	var tier: int = clampi(int(w.get("tier", 1)), 1, 5)
	var h: int = _hash_id(weapon_id)
	var base_pitch: float = float(TIER_PITCHES.get(tier, 1.0))
	var fine_pitch: float = (float(h % 1000) / 999.0 - 0.5) * 0.14
	var pitch: float = snappedf(clampf(base_pitch + fine_pitch, 0.72, 1.32), 0.0001)
	var vol_tier: float = float(tier - 2) * 0.35
	var vol_fine: float = (float((h >> 10) % 100) / 99.0 - 0.5) * 1.2
	var vol: float = snappedf(clampf(vol_tier + vol_fine, -3.5, 2.5), 0.001)
	return {"id": sid, "pitch": pitch, "vol": vol}


func play_weapon(weapon_id: String, weapon_data: Dictionary = {}, volume_db_offset: float = 0.0) -> void:
	var prof: Dictionary = weapon_sfx_profile(weapon_id, weapon_data)
	play_pitched(str(prof.get("id", "shoot")), float(prof.get("pitch", 1.0)), float(prof.get("vol", 0.0)) + volume_db_offset, 0.03)


func _play_internal(id: String, base_pitch: float, volume_db: float, pitch_jitter: float) -> void:
	var stream_val: Variant = _sfx_streams.get(id, null)
	if stream_val == null:
		return
	var now_ms: int = Time.get_ticks_msec()
	if MIN_INTERVAL_MS > 0 and _last_play_ms.has(id):
		if now_ms - int(_last_play_ms[id]) < MIN_INTERVAL_MS:
			return
	_last_play_ms[id] = now_ms
	var stream: AudioStream = stream_val as AudioStream
	var chosen: AudioStreamPlayer = null
	for p in _pool:
		if is_instance_valid(p) and not p.playing:
			chosen = p
			break
	if chosen == null:
		if _pool.size() < MAX_VOICES:
			chosen = AudioStreamPlayer.new()
			chosen.bus = BUS_SFX
			chosen.process_mode = Node.PROCESS_MODE_ALWAYS
			add_child(chosen)
			_pool.append(chosen)
		elif not _pool.is_empty():
			_cursor = _cursor % _pool.size()
			chosen = _pool[_cursor]
			_cursor = (_cursor + 1) % _pool.size()
			chosen.stop()
	if chosen == null:
		return
	var p_scale: float = clampf(base_pitch, 0.35, 2.5)
	if pitch_jitter > 0.0:
		p_scale *= randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	chosen.stream = stream
	chosen.volume_db = volume_db
	chosen.pitch_scale = p_scale
	chosen.play()
	_play_counts[id] = int(_play_counts.get(id, 0)) + 1


func _active_music_player() -> AudioStreamPlayer:
	return _music_a if _active_music_slot == 0 else _music_b


func _inactive_music_player() -> AudioStreamPlayer:
	return _music_b if _active_music_slot == 0 else _music_a


func active_music_slot() -> int:
	return _active_music_slot


func music_title(id: String) -> String:
	if id == "":
		return ""
	return str(MUSIC_TITLES.get(id, id))


func is_boss_music(id: String) -> bool:
	return id in ["boss", "boss_frenzy", "boss_legend", "boss_mythic", "coloa_siege", "boss_hon_mang"]


func stage_playlist(level: int) -> Array[String]:
	var ch: Dictionary = EnemyData.chapter(level)
	var theme: int = int(ch.get("theme", 0))
	if EnemyData.is_mythic_level(level) or bool(ch.get("mythic", false)):
		if theme == 0:
			return ["battle_mythic", "battle_forest", "battle_sprint"]
		if theme == 1:
			return ["battle_mythic", "battle_river", "battle_citadel"]
		return ["battle_mythic", "battle_citadel", "battle_sprint"]
	if bool(ch.get("modern", false)):
		if theme == 1:
			return ["battle_river", "battle_modern", "battle_sprint"]
		if theme == 5:
			return ["battle_forest", "battle_modern", "battle_sprint"]
		return ["battle_modern", "battle_sprint", "battle_citadel"]
	match theme:
		0:
			return ["battle_forest", "battle", "battle_sprint"]
		1:
			return ["battle_river", "battle", "battle_citadel"]
		2:
			return ["battle_citadel", "battle_sprint", "battle"]
		3:
			return ["battle_sprint", "battle_citadel", "battle"]
		_:
			return ["battle", "battle_sprint", "battle_citadel"]


func stage_music_id(level: int, room_seq: int = 0) -> String:
	if level == 16 or level >= 32:
		return "victory"
	var playlist: Array[String] = stage_playlist(level)
	if playlist.is_empty():
		return "battle"
	return playlist[(maxi(level - 1, 0) + maxi(room_seq, 0)) % playlist.size()]


func boss_music_id(level: int, kind: String = "boss", enraged: bool = false) -> String:
	if enraged:
		return "boss_frenzy"
	if level == 33:
		return "boss_hon_mang"
	if kind == "legend":
		return "boss_legend"
	if EnemyData.is_mythic_level(level):
		return "boss_mythic"
	return "boss"


func secret_biome_music_id(biome_id: String) -> String:
	if biome_id == "thuy_cung":
		return "secret_thuy_cung"
	if biome_id == "dinh_tan_vien":
		return "secret_tan_vien"
	return "battle_mythic"


func play_secret_biome_music(biome_id: String, fade_s: float = 0.75) -> String:
	var mid: String = secret_biome_music_id(biome_id)
	play_music(mid, fade_s)
	return mid


func play_stage_music(level: int, room_seq: int = 0, fade_s: float = 0.75) -> String:
	var mid: String = stage_music_id(level, room_seq)
	play_music(mid, fade_s)
	return mid


func play_boss_music(level: int, kind: String = "boss", enraged: bool = false, fade_s: float = 0.32) -> String:
	var mid: String = boss_music_id(level, kind, enraged)
	play_music(mid, fade_s)
	return mid


func play_music(id: String, fade_s: float = 0.65) -> void:
	if id == "":
		stop_music()
		return
	var cur_player: AudioStreamPlayer = _active_music_player()
	if id == _current_music and cur_player != null and is_instance_valid(cur_player) and cur_player.playing:
		return
	var stream_val: Variant = _music_streams.get(id, null)
	if stream_val == null:
		return
	_current_music = id
	if _music_tween != null and is_instance_valid(_music_tween):
		_music_tween.kill()
		_music_tween = null

	var outgoing: AudioStreamPlayer = _active_music_player()
	var incoming: AudioStreamPlayer = _inactive_music_player()
	var is_crossfade: bool = outgoing != null and is_instance_valid(outgoing) and outgoing.playing and fade_s > 0.0 and incoming != null and is_instance_valid(incoming)
	if is_crossfade:
		incoming.stop()
		incoming.stream = stream_val as AudioStream
		incoming.volume_db = -28.0
		incoming.play()
		_active_music_slot = 1 - _active_music_slot
		_music_tween = create_tween()
		_music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_music_tween.set_parallel(true)
		_music_tween.tween_property(incoming, "volume_db", 0.0, fade_s)
		_music_tween.tween_property(outgoing, "volume_db", -34.0, fade_s)
		_music_tween.chain().tween_callback(func():
			if is_instance_valid(outgoing) and outgoing != _active_music_player():
				outgoing.stop()
				outgoing.volume_db = 0.0
		)
	else:
		if incoming != null and is_instance_valid(incoming):
			incoming.stop()
			incoming.volume_db = 0.0
		if outgoing != null and is_instance_valid(outgoing):
			outgoing.stop()
			outgoing.stream = stream_val as AudioStream
			outgoing.volume_db = 0.0
			outgoing.play()
	music_changed.emit(id, music_title(id))


func stop_music() -> void:
	_current_music = ""
	if _music_tween != null and is_instance_valid(_music_tween):
		_music_tween.kill()
		_music_tween = null
	if _music_a != null and is_instance_valid(_music_a):
		_music_a.stop()
		_music_a.volume_db = 0.0
	if _music_b != null and is_instance_valid(_music_b):
		_music_b.stop()
		_music_b.volume_db = 0.0


func stop_all_sfx() -> void:
	for p in _pool:
		if is_instance_valid(p):
			p.stop()
	_last_play_ms.clear()


func cleanup() -> void:
	stop_music()
	stop_all_sfx()
	if _music_a != null and is_instance_valid(_music_a):
		_music_a.stream = null
	if _music_b != null and is_instance_valid(_music_b):
		_music_b.stream = null
	for p in _pool:
		if is_instance_valid(p):
			p.stream = null
			p.queue_free()
	_pool.clear()
	_sfx_streams.clear()
	_music_streams.clear()


func play_count(id: String) -> int:
	return int(_play_counts.get(id, 0))


func reset_play_counts() -> void:
	_play_counts.clear()


func active_sfx_count() -> int:
	var count: int = 0
	for p in _pool:
		if is_instance_valid(p) and p.playing:
			count += 1
	return count


func current_music() -> String:
	return _current_music


func set_music_volume(v: float) -> void:
	_music_volume = clampf(v, 0.0, 1.0)
	_apply_bus_volume(BUS_MUSIC, _music_volume)


func set_sfx_volume(v: float) -> void:
	_sfx_volume = clampf(v, 0.0, 1.0)
	_apply_bus_volume(BUS_SFX, _sfx_volume)


func get_music_volume() -> float:
	return _music_volume


func get_sfx_volume() -> float:
	return _sfx_volume


func _apply_bus_volume(bus_name: String, v: float) -> void:
	var idx: int = _ensure_bus(bus_name)
	if v <= 0.0001:
		AudioServer.set_bus_mute(idx, true)
		AudioServer.set_bus_volume_db(idx, -80.0)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(v))
