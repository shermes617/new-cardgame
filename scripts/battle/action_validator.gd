class_name ActionValidator
extends RefCounted


static func can_select_card(state: RefCounted, card: RefCounted) -> bool:
	var actor: RefCounted = state.get_unit(state.current_actor_id)
	return (
		actor != null
		and actor.is_alive()
		and state.hand_ids.has(card.id)
		and state.energy >= card.cost
	)


static func get_valid_target_ids(state: RefCounted, target_side: String) -> Array[String]:
	var result: Array[String] = []
	var units: Array = state.allies if target_side == "ally" else state.enemies
	for unit in units:
		if unit.is_alive():
			result.append(unit.id)
	return result


static func is_valid_target(state: RefCounted, target_side: String, target_id: String) -> bool:
	return get_valid_target_ids(state, target_side).has(target_id)
