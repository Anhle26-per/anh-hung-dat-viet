class_name WeaponEvolutions
extends RefCounted
## Công thức hợp nhất vũ khí (18 công thức, gồm 6 Thần binh Hợp nhất Cấp 5),
## Tiến Hóa vũ khí (+35% sát thương, +28% kích thước, +1 xuyên) và 13 Thần binh Trùm (Đỏ).

const WeaponData = preload("res://scripts/data/weapons.gd")

const MERGE_RECIPES: Array = [
	# --- 6 Thần binh Hợp nhất Cấp 5 ---
	{"a": "kiem_lua", "b": "kiem_bang", "result": "thai_cuc_kiem", "name": "Thái Cực Kiếm"},
	{"a": "cung_set", "b": "cung_rong", "result": "cung_loi_hoa", "name": "Cung Lôi Hỏa"},
	{"a": "phao_dong", "b": "sung_phong_ten_lua", "result": "phao_thien_long", "name": "Pháo Thiên Long"},
	{"a": "luoi_hai_bac", "b": "luoi_hai_huyet_nguyet", "result": "luoi_hai_am_duong", "name": "Lưỡi Hái Âm Dương"},
	{"a": "no_bang_suong", "b": "no_bao_lua", "result": "no_thien_co", "name": "Nỏ Thiên Cơ"},
	{"a": "truong_hoa_cau", "b": "truong_bang_gia", "result": "truong_ngu_hanh", "name": "Trượng Ngũ Hành"},
	# --- 12 Công thức Hợp nhất giữa các vũ khí hiện có ---
	{"a": "kiem_dong", "b": "dao_gam", "result": "song_kiem", "name": "Song Kiếm"},
	{"a": "giao_tre", "b": "tre_tram_dot", "result": "thuong_bach_long", "name": "Thương Bạch Long"},
	{"a": "cung", "b": "cung_dai", "result": "cung_vang", "name": "Cung Vàng Thạch Sanh"},
	{"a": "no", "b": "no_tay", "result": "no_lien_chau", "name": "Nỏ Thần Liên Châu"},
	{"a": "sung_ngan", "b": "sung_luc", "result": "tieu_lien", "name": "Tiểu Liên"},
	{"a": "sung_truong", "b": "sung_ban_tia", "result": "sung_railgun", "name": "Súng Railgun"},
	{"a": "sung_san", "b": "sung_hai_nong", "result": "sung_may", "name": "Súng Máy"},
	{"a": "sung_plasma", "b": "sung_dien_giat", "result": "sung_tesla", "name": "Súng Tesla"},
	{"a": "dua_tia_lua", "b": "dua_bang_suong", "result": "quyen_truong_phu_thuy", "name": "Quyền Trượng Phù Thủy"},
	{"a": "hoa_mai", "b": "than_co_sang", "result": "dai_bac_than_cong", "name": "Đại Bác Thần Công"},
	{"a": "quat_thep", "b": "quat_ngoc_luan", "result": "quat_ba_tieu", "name": "Quạt Ba Tiêu"},
	{"a": "bua_sat", "b": "bua_bang_ha", "result": "bua_thien_loi", "name": "Búa Thiên Lôi"},
	{"a": "dinh_ba_hoang_thao", "b": "kiem_rong_tien", "result": "long_than_hai_kich", "name": "Long Thần Hải Kích"},
	{"a": "cung_set", "b": "no_co_loa", "result": "thien_loi_than_cung", "name": "Thiên Lôi Thần Cung"},
]

## Ánh xạ 16 Trùm (10 chương lịch sử + 3 trùm Thần Thoại + 3 trùm Bí Cảnh/Kết Thúc Thực) sang 16 Thần binh Đỏ (tier 5, boss_motif: true)
const BOSS_MOTIF_BY_BOSS: Dictionary = {
	"to_dinh": "huyet_dao_to_dinh",
	"luc_dan": "kich_luc_dan",
	"hoang_thao": "dinh_ba_hoang_thao",
	"quach_quy": "cung_quach_quy",
	"thoat_hoan": "ong_dong_thoat_hoan",
	"lieu_thang": "bua_lieu_thang",
	"ton_si_nghi": "phao_ton_si_nghi",
	"tau_hy_vong": "hoa_phao_hy_vong",
	"don_truong": "sung_don_truong",
	"do_cat": "phao_coi_do_cat",
	"cuu_vi_ho": "ho_ly_cuu_vi",
	"xuong_cuong": "truong_xuong_cuong",
	"hac_hai_ngu": "hai_than_hac_hai",
	"thuy_tinh": "dinh_ba_thuy_tinh_than",
	"thien_loi": "loi_chuy_thien_de",
	"hon_mang_yeu_de": "thai_to_thien_kiem",
}


static func find_merge(w1: String, w2: String) -> String:
	if w1 == "" or w2 == "" or w1 == w2:
		return ""
	for r in MERGE_RECIPES:
		var a: String = str(r.get("a", ""))
		var b: String = str(r.get("b", ""))
		if (a == w1 and b == w2) or (a == w2 and b == w1):
			return str(r.get("result", ""))
	return ""


static func find_merge_recipe(w1: String, w2: String) -> Dictionary:
	if w1 == "" or w2 == "" or w1 == w2:
		return {}
	for r in MERGE_RECIPES:
		var a: String = str(r.get("a", ""))
		var b: String = str(r.get("b", ""))
		if (a == w1 and b == w2) or (a == w2 and b == w1):
			return r
	return {}


static func can_evolve(wid: String, evolved_map: Dictionary) -> bool:
	if wid == "" or not WeaponData.DATA.has(wid):
		return false
	return not bool(evolved_map.get(wid, false))


static func evolved_bonus(_wid: String) -> Dictionary:
	return {
		"dmg_mult": 1.35,
		"scale_mult": 1.28,
		"pierce_add": 1,
		"suffix": " ★Tiến Hóa",
	}


static func boss_weapon_for(boss_id: String) -> String:
	return str(BOSS_MOTIF_BY_BOSS.get(boss_id, ""))
