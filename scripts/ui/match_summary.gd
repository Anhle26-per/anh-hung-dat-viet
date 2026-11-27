extends RefCounted
## Bảng Tổng Kết Chiến Công & MVP (hỗ trợ Solo 1 người và LAN tối đa 4 người).

const UI = preload("res://scripts/ui/ui.gd")
const HeroData = preload("res://scripts/data/heroes.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")


static func score_entry(st: Dictionary) -> int:
	var dmg: int = int(st.get("damage", 0))
	var kills: int = int(st.get("kills", 0))
	var combos: int = int(st.get("combos", 0))
	var revives: int = int(st.get("revives", 0))
	return dmg + kills * 20 + combos * 60 + revives * 80


static func compute_mvp_peer(stats_by_peer: Dictionary) -> Variant:
	var best_key: Variant = null
	var best_score: int = -1
	var keys: Array = stats_by_peer.keys()
	keys.sort()
	for k in keys:
		var v: Variant = stats_by_peer[k]
		if not (v is Dictionary):
			continue
		var sc: int = score_entry(v as Dictionary)
		if sc > best_score:
			best_score = sc
			best_key = k
	return best_key


static func _panel_style(border_col: Color, bg_col: Color, bw: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


static func build_panel(stats_by_peer: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme = UI.make_theme()
	panel.custom_minimum_size = Vector2(560.0, 0.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.92, 0.72, 0.28), Color(0.12, 0.05, 0.08, 0.95), 2))

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	panel.add_child(root)

	var header := UI.label("TỔNG KẾT CHIẾN CÔNG & MVP", 18, Color(1.0, 0.88, 0.38))
	root.add_child(header)

	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 4)
	root.add_child(grid)

	var cols: Array[String] = ["Tướng / Tên", "Sát thương", "Hạ giặc", "Hợp chiêu", "Cứu", "Mảnh BV", "Binh khí MVP"]
	for c_idx in cols.size():
		var h_lbl := UI.label(cols[c_idx], 12, Color(0.95, 0.82, 0.52))
		h_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if c_idx == 0 or c_idx == 6 else HORIZONTAL_ALIGNMENT_RIGHT
		h_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL if c_idx == 0 else Control.SIZE_FILL
		grid.add_child(h_lbl)

	var mvp_key: Variant = compute_mvp_peer(stats_by_peer)
	var keys: Array = stats_by_peer.keys()
	keys.sort()
	var shown_rows: int = 0
	for k in keys:
		if shown_rows >= 4:
			break
		var raw: Variant = stats_by_peer[k]
		if not (raw is Dictionary):
			continue
		shown_rows += 1
		var st: Dictionary = raw as Dictionary
		var is_mvp: bool = (k == mvp_key)
		var row_col: Color = Color(1.0, 0.90, 0.36) if is_mvp else Color(0.92, 0.90, 0.86)

		var hid: String = str(st.get("hero", ""))
		var hname: String = str(HeroData.DATA[hid].name) if HeroData.DATA.has(hid) else hid
		var pname: String = str(st.get("name", ""))
		var who_txt: String = ("%s (%s)" % [pname, hname]) if (pname != "" and hname != "") else (pname if pname != "" else (hname if hname != "" else "Anh Hùng"))
		if is_mvp:
			who_txt = "★ MVP  " + who_txt

		var wid: String = str(st.get("mvp_weapon", st.get("weapon", "")))
		var wname: String = str(WeaponData.get_data(wid).get("name", wid)) if (wid != "" and WeaponData.DATA.has(wid)) else (wid if wid != "" else "—")

		var vals: Array[String] = [
			who_txt,
			str(int(st.get("damage", 0))),
			str(int(st.get("kills", 0))),
			str(int(st.get("combos", 0))),
			str(int(st.get("revives", 0))),
			str(int(st.get("fragments", 0))),
			wname,
		]
		for v_idx in vals.size():
			var cell := UI.label(vals[v_idx], 13, row_col)
			cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if v_idx == 0 or v_idx == 6 else HORIZONTAL_ALIGNMENT_RIGHT
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL if v_idx == 0 else Control.SIZE_FILL
			grid.add_child(cell)

	return panel
