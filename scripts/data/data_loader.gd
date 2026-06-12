class_name GameDataLoader
extends RefCounted


static func load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("GameDataLoader: file not found: %s" % path)
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("GameDataLoader: failed to open file: %s" % path)
		return null

	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	if error != OK:
		push_error(
			"GameDataLoader: invalid JSON in %s at line %d: %s"
			% [path, json.get_error_line(), json.get_error_message()]
		)
		return null

	return json.data


static func load_array(path: String) -> Array:
	var data: Variant = load_json(path)
	if data is not Array:
		push_error("GameDataLoader: expected an array in: %s" % path)
		return []
	return data


static func load_dictionary(path: String) -> Dictionary:
	var data: Variant = load_json(path)
	if data is not Dictionary:
		push_error("GameDataLoader: expected an object in: %s" % path)
		return {}
	return data
