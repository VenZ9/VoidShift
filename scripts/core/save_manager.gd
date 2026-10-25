# save_manager.gd
# VOIDSHIFT - Local Persistent Data & Settings Manager
extends Node

const SAVE_PATH = "user://savegame.json"
const SETTINGS_PATH = "user://settings.json"

var profile_data: Dictionary = {
	"total_runs": 0,
	"victories": 0,
	"highest_sector": 1,
	"total_scrap_collected": 0,
	"available_scrap": 0,
	"unlocked_upgrades": [],
	"permanent_stats": {
		"bonus_max_hp": 0.0,
		"bonus_energy_regen": 0.0,
		"bonus_speed": 0.0
	}
}

var settings_data: Dictionary = {
	"master_volume": 1.0,
	"sfx_volume": 0.9,
	"ambient_volume": 0.6,
	"haptics_enabled": true,
	"touch_controls_opacity": 0.85,
	"camera_rotate_with_gravity": true,
	"screen_shake_intensity": 1.0
}

func _ready() -> void:
	load_settings()
	load_profile()

func _write_json(path: String, data: Dictionary) -> bool:
	# Atomic two-step write: temp file first, then rename over the target so a
	# crash mid-write cannot corrupt the persisted data.
	var tmp_path := path + ".tmp"
	var file = FileAccess.open(tmp_path, FileAccess.WRITE)
	if not file:
		printerr("Failed to open save file for writing: ", tmp_path)
		return false
	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()
	var dir = DirAccess.open(path.get_base_dir())
	if dir == null or dir.rename(tmp_path, path) != OK:
		# Fallback: direct overwrite if the rename is unavailable.
		var direct = FileAccess.open(path, FileAccess.WRITE)
		if not direct:
			printerr("Failed to write save file: ", path)
			return false
		direct.store_string(json_string)
		direct.close()
	return true

func load_profile() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_profile()
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var parsed = JSON.parse_string(text)
		if parsed is Dictionary:
			# Merge with defaults to ensure all keys exist
			for key in parsed:
				profile_data[key] = parsed[key]
		elif text.length() > 0:
			# Corrupt or truncated save: keep defaults instead of crashing.
			printerr("Save game at %s is unreadable; using default profile." % SAVE_PATH)
		file.close()

func save_profile() -> bool:
	return _write_json(SAVE_PATH, profile_data)

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		save_settings()
		return
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var parsed = JSON.parse_string(text)
		if parsed is Dictionary:
			for key in parsed:
				settings_data[key] = parsed[key]
		elif text.length() > 0:
			printerr("Settings at %s are unreadable; using default settings." % SETTINGS_PATH)
		file.close()
	_apply_loaded_settings()

func save_settings() -> bool:
	return _write_json(SETTINGS_PATH, settings_data)

func _apply_loaded_settings() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.set_master_volume(settings_data.get("master_volume", 1.0))
		AudioManager.set_sfx_volume(settings_data.get("sfx_volume", 0.9))
		AudioManager.set_ambient_volume(settings_data.get("ambient_volume", 0.6))
		AudioManager.haptics_enabled = settings_data.get("haptics_enabled", true)

func add_scrap(amount: int) -> void:
	profile_data["total_scrap_collected"] += amount
	profile_data["available_scrap"] += amount
	save_profile()

func spend_scrap(amount: int) -> bool:
	if profile_data.get("available_scrap", 0) >= amount:
		profile_data["available_scrap"] -= amount
		save_profile()
		return true
	return false

func record_run_completion(victory: bool, sector: int) -> void:
	profile_data["total_runs"] += 1
	if victory:
		profile_data["victories"] += 1
	if sector > profile_data.get("highest_sector", 1):
		profile_data["highest_sector"] = sector
	save_profile()
