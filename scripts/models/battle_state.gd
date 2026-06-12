class_name BattleState
extends RefCounted

const UnitStateScript := preload("res://scripts/models/unit_state.gd")

var current_time: float = 0.0
var energy: int = 0
var current_actor_id: String = ""
var allies: Array[RefCounted] = []
var enemies: Array[RefCounted] = []
var deck_ids: Array[String] = []
var draw_pile_ids: Array[String] = []
var hand_ids: Array[String] = []
var discard_pile_ids: Array[String] = []
var event_queue: RefCounted
var config: Dictionary = {}


func initialize(database: RefCounted, inherited_ally_hp: Dictionary = {}) -> void:
	_clear()
	config = database.battle_config.duplicate(true)
	current_time = float(config["initial_action_time"])
	energy = int(config["initial_energy"])
	deck_ids.assign(database.starter_deck_ids)
	draw_pile_ids.assign(deck_ids)

	for definition in database.get_unit_definitions("ally"):
		var unit_id: String = definition["id"]
		var inherited_hp := int(inherited_ally_hp.get(unit_id, -1))
		var unit: RefCounted = UnitStateScript.new(definition, inherited_hp)
		unit.next_action_time = current_time
		allies.append(unit)

	for definition in database.get_unit_definitions("enemy"):
		var unit: RefCounted = UnitStateScript.new(definition)
		unit.next_action_time = current_time
		enemies.append(unit)


func export_ally_hp() -> Dictionary:
	var result := {}
	for ally in allies:
		result[ally.id] = ally.hp
	return result


func get_unit(unit_id: String) -> RefCounted:
	for unit in allies:
		if unit.id == unit_id:
			return unit
	for unit in enemies:
		if unit.id == unit_id:
			return unit
	return null


func _clear() -> void:
	current_time = 0.0
	energy = 0
	current_actor_id = ""
	allies.clear()
	enemies.clear()
	deck_ids.clear()
	draw_pile_ids.clear()
	hand_ids.clear()
	discard_pile_ids.clear()
	event_queue = null
	config.clear()
