class_name BattleFlow
extends RefCounted

const BattleEventScript := preload("res://scripts/battle/battle_event.gd")
const EventQueueScript := preload("res://scripts/battle/event_queue.gd")
const ActionSchedulerScript := preload("res://scripts/battle/action_scheduler.gd")
const BattleResolverScript := preload("res://scripts/battle/battle_resolver.gd")
const EnemyAIScript := preload("res://scripts/battle/enemy_ai.gd")

signal state_changed
signal player_choice_required

var state: RefCounted
var database: RefCounted
var event_queue: RefCounted = EventQueueScript.new()
var available_actor_ids: Array[String] = []


func _init(p_state: RefCounted, p_database: RefCounted) -> void:
	state = p_state
	database = p_database
	state.event_queue = event_queue


func initialize_events() -> void:
	for ally in state.allies:
		event_queue.add_event(BattleEventScript.new("", 0.0, "unit_action", "ally", ally.id))
	for enemy in state.enemies:
		enemy.next_action_time = enemy.action_interval
		event_queue.add_event(
			BattleEventScript.new("", enemy.next_action_time, "unit_action", "enemy", enemy.id)
		)
	advance_until_player_choice()


func choose_actor(actor_id: String) -> void:
	if not available_actor_ids.has(actor_id):
		return
	state.current_actor_id = actor_id
	var actor: RefCounted = state.get_unit(actor_id)
	actor.clear_shield()
	state_changed.emit()
	player_choice_required.emit()


func submit_player_request(request: RefCounted) -> void:
	if request.actor_id != state.current_actor_id or not available_actor_ids.has(request.actor_id):
		return
	var action_event := _find_action_event(request.actor_id)
	if action_event != null:
		event_queue.remove_event(action_event)
	available_actor_ids.erase(request.actor_id)
	ActionSchedulerScript.schedule_player_request(state, database, event_queue, request)
	state.current_actor_id = ""
	advance_until_player_choice()


func advance_until_player_choice() -> void:
	available_actor_ids.clear()
	while not event_queue.events.is_empty():
		var next_time: float = event_queue.peek_next_time()
		state.current_time = next_time
		_process_higher_priority_events()
		_collect_available_allies()
		if not available_actor_ids.is_empty():
			state.current_actor_id = ""
			state_changed.emit()
			player_choice_required.emit()
			return
		_process_enemy_actions()
		state_changed.emit()


func _process_higher_priority_events() -> void:
	while true:
		var event: RefCounted = event_queue.events[0] if not event_queue.events.is_empty() else null
		if event == null or not is_equal_approx(event.time, state.current_time) or event.get_priority() >= 5:
			return
		event_queue.pop_next_event()
		if event.event_type == "skill_execute":
			BattleResolverScript.resolve_skill(state, database, event)
			_cancel_dead_unit_events()


func _collect_available_allies() -> void:
	for event in event_queue.get_events_at_time(state.current_time, "unit_action", "ally"):
		var actor: RefCounted = state.get_unit(event.unit_id)
		if actor != null and actor.is_alive():
			available_actor_ids.append(actor.id)


func _process_enemy_actions() -> void:
	var enemy_events: Array[RefCounted] = event_queue.get_events_at_time(
		state.current_time, "unit_action", "enemy"
	)
	for event in enemy_events:
		event_queue.remove_event(event)
		var enemy: RefCounted = state.get_unit(event.unit_id)
		if enemy == null or not enemy.is_alive():
			continue
		enemy.clear_shield()
		var request: RefCounted = EnemyAIScript.create_request(state, enemy)
		if request != null:
			ActionSchedulerScript.schedule_enemy_action(state, event_queue, request)
	_process_higher_priority_events()


func _find_action_event(actor_id: String) -> RefCounted:
	for event in event_queue.get_events_at_time(state.current_time, "unit_action", "ally"):
		if event.unit_id == actor_id:
			return event
	return null


func _cancel_dead_unit_events() -> void:
	for unit in state.allies + state.enemies:
		if not unit.is_alive():
			event_queue.cancel_unit_events(unit.id)
