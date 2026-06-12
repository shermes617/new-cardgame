class_name BattleSetup
extends RefCounted

const BattleStateScript := preload("res://scripts/models/battle_state.gd")


static func create_initial_state(database: RefCounted, inherited_ally_hp: Dictionary = {}) -> RefCounted:
	var state: RefCounted = BattleStateScript.new()
	state.initialize(database, inherited_ally_hp)
	_draw_initial_hand(state)
	return state


static func _draw_initial_hand(state: RefCounted) -> void:
	var amount := mini(int(state.config["initial_hand_size"]), state.draw_pile_ids.size())
	for _index in amount:
		state.hand_ids.append(state.draw_pile_ids.pop_front())
