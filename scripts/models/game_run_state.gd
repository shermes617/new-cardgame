class_name GameRunState
extends RefCounted

var deck_ids: Array[String] = []
var inherited_ally_hp: Dictionary = {}
var completed_battles: int = 0


func initialize(database: RefCounted) -> void:
	deck_ids.assign(database.starter_deck_ids)
	inherited_ally_hp.clear()
	completed_battles = 0


func record_victory(battle_state: RefCounted) -> void:
	inherited_ally_hp = battle_state.export_ally_hp()
	completed_battles += 1


func add_reward(card_id: String) -> void:
	deck_ids.append(card_id)
