extends RefCounted
## Đồng bộ autoload và tài nguyên script khi người chơi cập nhật từ bản cũ bằng user://patch.pck.

const DATA_SCRIPTS: Array[String] = [
	"res://scripts/data/version.gd",
	"res://scripts/data/weapons.gd",
	"res://scripts/data/weapon_evolutions.gd",
	"res://scripts/data/materials.gd",
	"res://scripts/data/enemies.gd",
	"res://scripts/data/achievements.gd",
	"res://scripts/data/heroes.gd",
	"res://scripts/data/hero_skills_ext.gd",
	"res://scripts/data/run_modes.gd",
	"res://scripts/data/buffs.gd",
	"res://scripts/data/synergy.gd",
	"res://scripts/data/progression.gd",
	"res://scripts/data/weapon_mods.gd",
	"res://scripts/art/art.gd",
	"res://scripts/ui/ui.gd",
	"res://scripts/effects/fx.gd",
]

const SCENE_SCRIPTS: Array[String] = [
	"res://scripts/ui/main_menu.gd",
	"res://scripts/ui/update_popup.gd",
	"res://scripts/ui/settings_menu.gd",
	"res://scripts/ui/challenge_menu.gd",
	"res://scripts/ui/lan_menu.gd",
	"res://scripts/ui/hero_select.gd",
	"res://scripts/ui/shop_ui.gd",
	"res://scripts/ui/touch_controls.gd",
	"res://scripts/ui/buff_select.gd",
	"res://scripts/ui/pause_menu.gd",
	"res://scripts/ui/hud.gd",
	"res://scripts/ui/lobby_ui.gd",
	"res://scripts/entities/bullet.gd",
	"res://scripts/entities/pickup.gd",
	"res://scripts/entities/enemy.gd",
	"res://scripts/entities/player.gd",
	"res://scripts/entities/event_altar.gd",
	"res://scripts/entities/mount_pickup.gd",
	"res://scripts/entities/battlefield_hazard.gd",
	"res://scripts/game/room.gd",
	"res://scripts/game/dungeon.gd",
	"res://scripts/game/lobby.gd",
	"res://scripts/game/game.gd",
]


static func _reload_script(gd_path: String) -> Script:
	var gdc_path: String = gd_path.trim_suffix(".gd") + ".gdc"
	var load_path: String = gdc_path if FileAccess.file_exists(gdc_path) else gd_path
	if not FileAccess.file_exists(load_path) and not ResourceLoader.exists(load_path):
		return null
	var fresh: Script = ResourceLoader.load(load_path, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
	if fresh != null:
		fresh.take_over_path(gdc_path)
		fresh.take_over_path(gd_path)
	return fresh


static func needs_autoload_sync(tree: SceneTree) -> bool:
	if tree == null:
		return false
	var g: Node = tree.root.get_node_or_null("Global")
	if g == null:
		return false
	for m in ["owned_blueprint_count", "unclaimed_achievement_count", "roll_boss_blueprint", "active_skill_index"]:
		if not g.has_method(m):
			return true
	if not InputMap.has_action("sprint") or not InputMap.has_action("dash") or not InputMap.has_action("merge_weapon"):
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
	_reload_script("res://scripts/autoload/hotpatch_sync.gd")
	for p in DATA_SCRIPTS:
		_reload_script(p)
	var g: Node = tree.root.get_node_or_null("Global")
	if g != null:
		var saved_path: String = str(g.get("save_path")) if g.get("save_path") != null else "user://save.json"
		var saved_run_path: String = str(g.get("run_save_path")) if g.get("run_save_path") != null else ""
		var fresh_g: Script = _reload_script("res://scripts/autoload/global.gd")
		if fresh_g != null:
			g.set_script(fresh_g)
			g.save_path = saved_path
			g.run_save_path = saved_run_path
			g._ready()
	var s: Node = tree.root.get_node_or_null("Sfx")
	if s != null:
		var fresh_s: Script = _reload_script("res://scripts/audio/sfx.gd")
		if fresh_s != null:
			for ch in s.get_children():
				if ch is AudioStreamPlayer:
					(ch as AudioStreamPlayer).stop()
				s.remove_child(ch)
				ch.queue_free()
			s.set_script(fresh_s)
			s._ready()
	for sp in SCENE_SCRIPTS:
		_reload_script(sp)
	for scn in ["res://scenes/lobby.tscn", "res://scenes/game.tscn", "res://scenes/main_menu.tscn"]:
		if ResourceLoader.exists(scn):
			ResourceLoader.load(scn, "", ResourceLoader.CACHE_MODE_REPLACE)
	return true


static func sync_and_reload_scene_if_needed(tree: SceneTree, scene_path: String) -> bool:
	if ensure_autoloads_synced(tree):
		tree.change_scene_to_file.call_deferred(scene_path)
		return true
	return false
