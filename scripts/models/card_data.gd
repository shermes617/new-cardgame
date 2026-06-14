class_name CardData
extends RefCounted

var id: String
var name_key: String
var description_key: String
var image_path: String
var category: String
var type: String
var cost: int
var charge: float
var overload: float
var charge_speed_modifier: float
var overload_speed_modifier: float
var target_side: String
var target_type: String
var effects: Array[Dictionary] = []


func _init(data: Dictionary) -> void:
	id = data["id"]
	name_key = data["name_key"]
	description_key = data["description_key"]
	image_path = data["image_path"]
	category = data["category"]
	type = data["type"]
	cost = int(data["cost"])
	charge = float(data["charge"])
	overload = float(data["overload"])
	charge_speed_modifier = float(data["charge_speed_modifier"])
	overload_speed_modifier = float(data["overload_speed_modifier"])
	target_side = data["target_side"]
	target_type = data["target_type"]
	for effect in data["effects"]:
		effects.append(effect.duplicate(true))


func get_actual_overload(speed: int) -> float:
	return snappedf(maxf(1.0, overload + speed * overload_speed_modifier), 0.1)
