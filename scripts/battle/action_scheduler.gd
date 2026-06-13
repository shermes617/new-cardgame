class_name ActionScheduler
extends RefCounted

const BattleEventScript := preload("res://scripts/battle/battle_event.gd")

const ALLY_BASIC_OVERLOAD := 6.0
const ALLY_BASIC_SPEED_MODIFIER := -0.2


static func schedule_player_request(
	state: RefCounted, database: RefCounted, event_queue: RefCounted, deck_manager: RefCounted,
	energy_manager: RefCounted, request: RefCounted
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
	energy_manager.spend(card.cost)
	deck_manager.discard_hand_card(request.card_instance_id)

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
