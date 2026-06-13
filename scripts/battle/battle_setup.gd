class_name BattleSetup
extends RefCounted

const BattleStateScript := preload("res://scripts/models/battle_state.gd")


static func create_initial_state(
	database: RefCounted, inherited_ally_hp: Dictionary = {}, deck_ids: Array[String] = []
) -> RefCounted:
	var state: RefCounted = BattleStateScript.new()
	state.initialize(database, inherited_ally_hp, deck_ids)
	return state
