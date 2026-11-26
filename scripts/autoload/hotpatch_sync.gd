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
	"res://scripts/net/discovery.gd",
	"res://scripts/net/net_sync.gd",
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
	"res://scripts/entities/pet.gd",
	"res://scripts/entities/ally.gd",
	"res://scripts/entities/blacksmith_npc.gd",
	"res://scripts/entities/interactable.gd",
	"res://scripts/entities/loot_chest.gd",
	"res://scripts/entities/portal.gd",
	"res://scripts/entities/cover.gd",
	"res://scripts/entities/trap.gd",
	"res://scripts/entities/victory_altar.gd",
	"res://scripts/entities/event_altar.gd",
	"res://scripts/entities/mount_pickup.gd",
	"res://scripts/entities/battlefield_hazard.gd",
	"res://scripts/game/ambience.gd",
	"res://scripts/game/decor.gd",
	"res://scripts/game/dummy.gd",
	"res://scripts/game/lobby_life.gd",
	"res://scripts/game/shop.gd",
	"res://scripts/game/shop_stand.gd",
	"res://scripts/game/station.gd",
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
	var u: Node = tree.root.get_node_or_null("Updater")
	if u != null and not u.has_method("_is_running_from_project_dir"):
		return true
	var g: Node = tree.root.get_node_or_null("Global")
	if g == null:
		return false
	for m in ["owned_blueprint_count", "unclaimed_achievement_count", "roll_boss_blueprint", "active_skill_index"]:
		if not g.has_method(m):
			return true
	if not InputMap.has_action("sprint") or not InputMap.has_action("dash") or not InputMap.has_action("merge_weapon"):
		return true
	var s: Node = tree.root.get_node_or_null("Sfx")
	if s != null:
		for sm in ["play_stage_music", "play_weapon", "play_skill"]:
			if not s.has_method(sm):
				return true
	var n: Node = tree.root.get_node_or_null("Net")
	if n != null:
		if n.get("in_lobby") == null:
			return true
		for nm in ["host_enter_lobby", "request_set_pet"]:
			if not n.has_method(nm):
				return true
	return false


static func ensure_autoloads_synced(tree: SceneTree) -> bool:
	if tree == null or not needs_autoload_sync(tree):
		return false
	for p in DATA_SCRIPTS:
		_reload_script(p)
	var u: Node = tree.root.get_node_or_null("Updater")
	if u != null and not u.has_method("_is_running_from_project_dir"):
		var u_patch_loaded: bool = bool(u.get("patch_loaded"))
		var u_cur_ver: String = str(u.get("current_version"))
		var u_cur_build: int = int(u.get("current_build"))
		var u_latest: Variant = u.get("latest_info")
		var u_state: String = str(u.get("state"))
		var fresh_u: Script = _reload_script("res://scripts/autoload/updater.gd")
		if fresh_u != null:
			u.set_script(fresh_u)
			u.set("patch_loaded", u_patch_loaded)
			u.set("current_version", u_cur_ver)
			u.set("current_build", u_cur_build)
			if u_latest is Dictionary:
				u.set("latest_info", u_latest)
			u.set("state", u_state)
			u._ready()
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
	var n: Node = tree.root.get_node_or_null("Net")
	if n != null:
		var was_online: bool = n.has_method("is_online") and bool(n.call("is_online"))
		if not was_online:
			var mp: MultiplayerAPI = tree.get_multiplayer()
			if mp != null:
				for sig_pair in [
					["peer_connected", "_on_peer_connected"],
					["peer_disconnected", "_on_peer_disconnected"],
					["connected_to_server", "_on_connected_to_server"],
					["connection_failed", "_on_connection_failed"],
					["server_disconnected", "_on_server_disconnected"],
				]:
					var cb := Callable(n, str(sig_pair[1]))
					if mp.is_connected(str(sig_pair[0]), cb):
						mp.disconnect(str(sig_pair[0]), cb)
			for ch in n.get_children():
				n.remove_child(ch)
				ch.queue_free()
			var fresh_n: Script = _reload_script("res://scripts/net/net.gd")
			if fresh_n != null:
				n.set_script(fresh_n)
				n._ready()
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
