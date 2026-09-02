extends RefCounted

const SAVE_PATH := "user://save.json"


static func save_game(data: Dictionary) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write save file: %s" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


static func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not read save file: %s" % FileAccess.get_open_error())
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


static func delete_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return true
	var dir := DirAccess.open("user://")
	if dir == null:
		push_error("Could not open user:// to delete save.")
		return false
	var err := dir.remove("save.json")
	if err != OK:
		push_error("Could not delete save file: %s" % error_string(err))
		return false
	return true
