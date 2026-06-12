class_name ActionScheduler
extends RefCounted

const BattleEventScript := preload("res://scripts/battle/battle_event.gd")

const ALLY_BASIC_OVERLOAD := 6.0
const ALLY_BASIC_SPEED_MODIFIER := -0.2


static func schedule_player_request(
	state: RefCounted, database: RefCounted, event_queue: RefCounted, request: RefCounted
) -> void:
	var actor: RefCounted = state.get_unit(request.actor_id)
	if request.action_type == "basic_attack":
		var actual_overload := snappedf(
			maxf(1.0, ALLY_BASIC_OVERLOAD + actor.speed * ALLY_BASIC_SPEED_MODIFIER), 0.1
		)
		event_queue.add_event(
			BattleEventScript.new(
				"", state.current_time, "skill_execute", "ally", actor.id, "basic_attack", request.target_ids
			)
		)
		_schedule_next_action(state, event_queue, actor, state.current_time + actual_overload)
		return

	var card: RefCounted = database.get_card(request.card_id)
	state.energy -= card.cost
	var hand_index: int = request.hand_index
	if hand_index >= 0 and hand_index < state.hand_ids.size():
		state.hand_ids.remove_at(hand_index)
	else:
		state.hand_ids.erase(card.id)
	state.discard_pile_ids.append(card.id)

	var execute_time: float = state.current_time + card.charge
	event_queue.add_event(
		BattleEventScript.new(
			"", execute_time, "skill_execute", "ally", actor.id, card.id, request.target_ids
		)
	)
	_schedule_next_action(state, event_queue, actor, execute_time + card.get_actual_overload(actor.speed))


static func schedule_enemy_action(state: RefCounted, event_queue: RefCounted, request: RefCounted) -> void:
	var actor: RefCounted = state.get_unit(request.actor_id)
	event_queue.add_event(
		BattleEventScript.new(
			"", state.current_time, "skill_execute", "enemy", actor.id, "enemy_basic_attack",
			request.target_ids
		)
	)
	_schedule_next_action(state, event_queue, actor, state.current_time + actor.action_interval)


static func _schedule_next_action(
	state: RefCounted, event_queue: RefCounted, actor: RefCounted, action_time: float
) -> void:
	actor.next_action_time = snappedf(action_time, 0.1)
	event_queue.add_event(
		BattleEventScript.new("", actor.next_action_time, "unit_action", actor.side, actor.id)
	)
