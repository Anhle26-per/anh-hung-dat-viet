extends RefCounted
## Đồng bộ autoload và tài nguyên script khi người chơi cập nhật từ bản cũ bằng user://patch.pck.

const DATA_SCRIPTS: Array[String] = [
	"res://scripts/data/version.gd",
	"res://scripts/data/weapons.gd",
	"res://scripts/data/materials.gd",
	"res://scripts/data/enemies.gd",
	"res://scripts/data/achievements.gd",
	"res://scripts/data/heroes.gd",
	"res://scripts/data/buffs.gd",
	"res://scripts/data/synergy.gd",
	"res://scripts/data/progression.gd",
	"res://scripts/data/weapon_mods.gd",
]


static func _norm_path(p: String) -> String:
	return p.replace("\\", "/").strip_edges().to_lower()


static func is_booted_from_main_pack(patch_path: String = "user://patch.pck", args: PackedStringArray = OS.get_cmdline_args()) -> bool:
	var target: String = _norm_path(ProjectSettings.globalize_path(patch_path))
	var raw_target: String = _norm_path(patch_path)
	for i in range(args.size() - 1):
		if str(args[i]) == "--main-pack":
			var val: String = _norm_path(str(args[i + 1]))
			if val == target or val == raw_target or val.ends_with("/patch.pck") or val == "patch.pck":
				return true
	return false


static func needs_autoload_sync(tree: SceneTree) -> bool:
	if tree == null:
		return false
	var g: Node = tree.root.get_node_or_null("Global")
	if g == null:
		return false
	for m in ["owned_blueprint_count", "unclaimed_achievement_count", "roll_boss_blueprint"]:
		if not g.has_method(m):
			return true
	if not InputMap.has_action("sprint"):
		return true
	var s: Node = tree.root.get_node_or_null("Sfx")
	if s == null:
		return false
	for sm in ["play_stage_music", "play_weapon", "play_skill"]:
		if not s.has_method(sm):
			return true
	return false


static func ensure_autoloads_synced(tree: SceneTree) -> bool:
	if tree == null or not needs_autoload_sync(tree):
		return false
	var changed: bool = false
	for p in DATA_SCRIPTS:
		if ResourceLoader.exists(p):
			ResourceLoader.load(p, "", ResourceLoader.CACHE_MODE_REPLACE)
	var g: Node = tree.root.get_node_or_null("Global")
	if g != null and (not g.has_method("owned_blueprint_count") or not g.has_method("unclaimed_achievement_count") or not g.has_method("roll_boss_blueprint") or not InputMap.has_action("sprint")):
		var saved_path: String = str(g.get("save_path")) if g.get("save_path") != null else "user://save.json"
		var new_g: Script = ResourceLoader.load("res://scripts/autoload/global.gd", "", ResourceLoader.CACHE_MODE_REPLACE) as Script
		if new_g != null:
			g.set_script(new_g)
			g.save_path = saved_path
			g._ready()
			changed = true
	var s: Node = tree.root.get_node_or_null("Sfx")
	if s != null and (not s.has_method("play_stage_music") or not s.has_method("play_weapon") or not s.has_method("play_skill")):
		for ch in s.get_children():
			if ch is AudioStreamPlayer:
				(ch as AudioStreamPlayer).stop()
			s.remove_child(ch)
			ch.queue_free()
		var new_s: Script = ResourceLoader.load("res://scripts/audio/sfx.gd", "", ResourceLoader.CACHE_MODE_REPLACE) as Script
		if new_s != null:
			s.set_script(new_s)
			s._ready()
			changed = true
	return changed


static func ensure_clean_patch_boot(tree: SceneTree) -> bool:
	if tree == null or not needs_autoload_sync(tree):
		return false
	if DisplayServer.get_name() != "headless" and not OS.has_feature("editor") and not OS.has_feature("mobile"):
		var u: Node = tree.root.get_node_or_null("Updater")
		if u != null and bool(u.get("patch_loaded")):
			var pp: String = str(u.get("patch_path"))
			if pp != "" and FileAccess.file_exists(pp) and not is_booted_from_main_pack(pp):
				OS.set_restart_on_exit(true, PackedStringArray(["--main-pack", ProjectSettings.globalize_path(pp)]))
				tree.quit(0)
				return true
	ensure_autoloads_synced(tree)
	return false
