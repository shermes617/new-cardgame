class_name GameDatabase
extends RefCounted

const DataLoaderScript := preload("res://scripts/data/data_loader.gd")
const CardDataScript := preload("res://scripts/models/card_data.gd")

const ALLIES_PATH := "res://data/units/allies.json"
const ENEMIES_PATH := "res://data/units/enemies.json"
const STARTER_CARDS_PATH := "res://data/cards/starter_cards.json"
const COMMON_CARDS_PATH := "res://data/cards/common_cards.json"
const BATTLE_CONFIG_PATH := "res://data/config/battle_config.json"
const INITIAL_DECK_PATH := "res://data/config/initial_deck.json"

const UNIT_REQUIRED_FIELDS: Array[String] = [
	"id", "name_key", "side", "position", "strength", "will", "max_hp", "portrait_path"
]
const CARD_REQUIRED_FIELDS: Array[String] = [
	"id", "name_key", "description_key", "category", "type", "cost", "charge", "overload",
	"charge_speed_modifier", "overload_speed_modifier", "target_side", "target_type", "effects"
]
const CONFIG_REQUIRED_FIELDS: Array[String] = [
	"energy_max", "initial_energy", "initial_hand_size", "hand_limit", "hand_reset_refresh_interval",
	"energy_recovery_interval", "initial_action_time", "same_priority_tiebreaker",
	"carry_ally_hp_between_battles"
]

var battle_config: Dictionary = {}
var units_by_id: Dictionary = {}
var cards_by_id: Dictionary = {}
var ally_ids: Array[String] = []
var enemy_ids: Array[String] = []
var starter_deck_ids: Array[String] = []


func load_all() -> bool:
	_clear()

	var allies: Array = DataLoaderScript.load_array(ALLIES_PATH)
	var enemies: Array = DataLoaderScript.load_array(ENEMIES_PATH)
	var starter_cards: Array = DataLoaderScript.load_array(STARTER_CARDS_PATH)
	var common_cards: Array = DataLoaderScript.load_array(COMMON_CARDS_PATH)
	var initial_deck: Array = DataLoaderScript.load_array(INITIAL_DECK_PATH)
	battle_config = DataLoaderScript.load_dictionary(BATTLE_CONFIG_PATH)

	var is_valid := not battle_config.is_empty()
	is_valid = _register_units(allies, "ally") and is_valid
	is_valid = _register_units(enemies, "enemy") and is_valid
	is_valid = _register_cards(starter_cards) and is_valid
	is_valid = _register_cards(common_cards) and is_valid
	is_valid = _validate_config() and is_valid
	is_valid = _build_initial_deck(initial_deck) and is_valid
	return is_valid


func get_unit_definition(unit_id: String) -> Dictionary:
	return units_by_id.get(unit_id, {})


func get_card(card_id: String) -> RefCounted:
	return cards_by_id.get(card_id)


func get_card_ids_by_category(category: String) -> Array[String]:
	var result: Array[String] = []
	for card_id in cards_by_id:
		if cards_by_id[card_id].category == category:
			result.append(card_id)
	return result


func get_unit_definitions(side: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var ids: Array[String] = ally_ids if side == "ally" else enemy_ids
	for unit_id in ids:
		result.append(units_by_id[unit_id])
	return result


func _clear() -> void:
	battle_config.clear()
	units_by_id.clear()
	cards_by_id.clear()
	ally_ids.clear()
	enemy_ids.clear()
	starter_deck_ids.clear()


func _register_units(entries: Array, expected_side: String) -> bool:
	var is_valid := true
	for entry in entries:
		if entry is not Dictionary:
			push_error("GameDatabase: unit entry must be an object")
			is_valid = false
			continue
		if not _has_fields(entry, UNIT_REQUIRED_FIELDS, "unit"):
			is_valid = false
			continue

		var unit_id: String = entry["id"]
		if unit_id.is_empty() or units_by_id.has(unit_id):
			push_error("GameDatabase: invalid or duplicate unit id: %s" % unit_id)
			is_valid = false
			continue
		if entry["side"] != expected_side:
			push_error("GameDatabase: unit %s must have side '%s'" % [unit_id, expected_side])
			is_valid = false
			continue
		if int(entry["position"]) < 1 or int(entry["position"]) > 4:
			push_error("GameDatabase: unit %s has invalid position" % unit_id)
			is_valid = false
			continue
		if int(entry["max_hp"]) <= 0:
			push_error("GameDatabase: unit %s must have positive max_hp" % unit_id)
			is_valid = false
			continue
		if expected_side == "ally" and not entry.has("speed"):
			push_error("GameDatabase: ally unit %s is missing speed" % unit_id)
			is_valid = false
			continue
		if expected_side == "enemy" and (
			not entry.has("action_interval") or float(entry["action_interval"]) <= 0.0
		):
			push_error("GameDatabase: enemy unit %s must have positive action_interval" % unit_id)
			is_valid = false
			continue
		if not ResourceLoader.exists(entry["portrait_path"]):
			push_error("GameDatabase: portrait not found for unit %s: %s" % [unit_id, entry["portrait_path"]])
			is_valid = false
			continue

		units_by_id[unit_id] = entry
		if expected_side == "ally":
			ally_ids.append(unit_id)
		else:
			enemy_ids.append(unit_id)
	return is_valid


func _register_cards(entries: Array) -> bool:
	var is_valid := true
	for entry in entries:
		if entry is not Dictionary:
			push_error("GameDatabase: card entry must be an object")
			is_valid = false
			continue
		if not _has_fields(entry, CARD_REQUIRED_FIELDS, "card"):
			is_valid = false
			continue

		var card_id: String = entry["id"]
		if card_id.is_empty() or cards_by_id.has(card_id):
			push_error("GameDatabase: invalid or duplicate card id: %s" % card_id)
			is_valid = false
			continue
		if int(entry["cost"]) < 0 or float(entry["charge"]) < 0.0 or float(entry["overload"]) < 0.0:
			push_error("GameDatabase: card %s has a negative timing or cost value" % card_id)
			is_valid = false
			continue
		if entry["effects"] is not Array or entry["effects"].is_empty():
			push_error("GameDatabase: card %s must define at least one effect" % card_id)
			is_valid = false
			continue
		if not _validate_card_effects(card_id, entry["effects"]):
			is_valid = false
			continue

		cards_by_id[card_id] = CardDataScript.new(entry)
	return is_valid


func _validate_card_effects(card_id: String, effects: Array) -> bool:
	var is_valid := true
	for effect in effects:
		if effect is not Dictionary or not effect.has("effect_type"):
			push_error("GameDatabase: card %s has an invalid effect" % card_id)
			is_valid = false
			continue
		var effect_type: String = effect["effect_type"]
		if effect_type in ["damage", "shield", "heal", "damage_to_shield"]:
			if not effect.has("rate") or float(effect["rate"]) < 0.0:
				push_error("GameDatabase: card %s effect %s needs a non-negative rate" % [card_id, effect_type])
				is_valid = false
		elif effect_type == "draw_card":
			if not effect.has("amount") or int(effect["amount"]) <= 0:
				push_error("GameDatabase: card %s draw effect needs a positive amount" % card_id)
				is_valid = false
		elif effect_type == "delayed_energy":
			if (
				not effect.has("amount")
				or int(effect["amount"]) <= 0
				or not effect.has("delay")
				or float(effect["delay"]) < 0.0
			):
				push_error("GameDatabase: card %s delayed energy effect is invalid" % card_id)
				is_valid = false
		else:
			push_error("GameDatabase: card %s has unsupported effect type: %s" % [card_id, effect_type])
			is_valid = false
	return is_valid


func _validate_config() -> bool:
	if not _has_fields(battle_config, CONFIG_REQUIRED_FIELDS, "battle config"):
		return false
	if int(battle_config["energy_max"]) <= 0:
		push_error("GameDatabase: energy_max must be positive")
		return false
	if int(battle_config["initial_energy"]) > int(battle_config["energy_max"]):
		push_error("GameDatabase: initial_energy cannot exceed energy_max")
		return false
	if int(battle_config["initial_hand_size"]) > int(battle_config["hand_limit"]):
		push_error("GameDatabase: initial_hand_size cannot exceed hand_limit")
		return false
	if (
		float(battle_config["hand_reset_refresh_interval"]) <= 0.0
		or float(battle_config["energy_recovery_interval"]) <= 0.0
	):
		push_error("GameDatabase: battle timing intervals are invalid")
		return false
	if battle_config["same_priority_tiebreaker"] != "creation_order":
		push_error("GameDatabase: unsupported same_priority_tiebreaker")
		return false
	return true


func _build_initial_deck(entries: Array) -> bool:
	var is_valid := true
	for entry in entries:
		if entry is not Dictionary or not entry.has("card_id") or not entry.has("count"):
			push_error("GameDatabase: invalid initial deck entry")
			is_valid = false
			continue
		var card_id: String = entry["card_id"]
		var count := int(entry["count"])
		if not cards_by_id.has(card_id) or count <= 0:
			push_error("GameDatabase: invalid initial deck card or count: %s" % card_id)
			is_valid = false
			continue
		for index in count:
			starter_deck_ids.append(card_id)
	return is_valid


func _has_fields(data: Dictionary, fields: Array[String], context: String) -> bool:
	var is_valid := true
	for field in fields:
		if not data.has(field):
			push_error("GameDatabase: %s is missing required field: %s" % [context, field])
			is_valid = false
	return is_valid
