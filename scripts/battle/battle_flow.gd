class_name BattleFlow
extends RefCounted

const BattleEventScript := preload("res://scripts/battle/battle_event.gd")
const EventQueueScript := preload("res://scripts/battle/event_queue.gd")
const ActionSchedulerScript := preload("res://scripts/battle/action_scheduler.gd")
const BattleResolverScript := preload("res://scripts/battle/battle_resolver.gd")
const EnemyAIScript := preload("res://scripts/battle/enemy_ai.gd")
const DeckManagerScript := preload("res://scripts/battle/deck_manager.gd")
const EnergyManagerScript := preload("res://scripts/battle/energy_manager.gd")
const HandResetManagerScript := preload("res://scripts/battle/hand_reset_manager.gd")

signal state_changed
signal player_choice_required
signal battle_ended(result: String)

var state: RefCounted
var database: RefCounted
var event_queue: RefCounted = EventQueueScript.new()
var deck_manager: RefCounted
var energy_manager: RefCounted
var hand_reset_manager: RefCounted
var available_actor_ids: Array[String] = []
var is_ended: bool = false
var result: String = ""


func _init(p_state: RefCounted, p_database: RefCounted) -> void:
	state = p_state
	database = p_database
	state.event_queue = event_queue
	deck_manager = DeckManagerScript.new(state, event_queue)
	energy_manager = EnergyManagerScript.new(state, event_queue)
	hand_reset_manager = HandResetManagerScript.new(state, event_queue, deck_manager)


func initialize_events(shuffle_seed: int = -1) -> void:
	if shuffle_seed >= 0:
		deck_manager = DeckManagerScript.new(state, event_queue, shuffle_seed)
		hand_reset_manager = HandResetManagerScript.new(state, event_queue, deck_manager)
	deck_manager.initialize_deck()
	energy_manager.initialize_events()
	for ally in state.allies:
		event_queue.add_event(BattleEventScript.new("", 0.0, "unit_action", "ally", ally.id))
	for enemy in state.enemies:
		enemy.next_action_time = enemy.action_interval
		event_queue.add_event(
			BattleEventScript.new("", enemy.next_action_time, "unit_action", "enemy", enemy.id)
		)
	advance_until_player_choice()


func choose_actor(actor_id: String) -> void:
	if is_ended or not available_actor_ids.has(actor_id):
		return
	state.current_actor_id = actor_id
	var actor: RefCounted = state.get_unit(actor_id)
	actor.clear_shield()
	state_changed.emit()
	player_choice_required.emit()


func reset_hand() -> bool:
	if is_ended or not hand_reset_manager.reset_hand():
		return false
	state_changed.emit()
	return true


func submit_player_request(request: RefCounted) -> void:
	if is_ended or request.actor_id != state.current_actor_id or not available_actor_ids.has(request.actor_id):
		return
	var action_event := _find_action_event(request.actor_id)
	if action_event != null:
		event_queue.remove_event(action_event)
	available_actor_ids.erase(request.actor_id)
	ActionSchedulerScript.schedule_player_request(
		state, database, event_queue, deck_manager, energy_manager, request
	)
	state.current_actor_id = ""
	advance_until_player_choice()


func advance_until_player_choice() -> void:
	if is_ended:
		return
	available_actor_ids.clear()
	while not event_queue.events.is_empty():
		var next_time: float = event_queue.peek_next_time()
		state.current_time = next_time
		_process_higher_priority_events()
		if is_ended:
			return
		_collect_available_allies()
		if not available_actor_ids.is_empty():
			state.current_actor_id = ""
			state_changed.emit()
			player_choice_required.emit()
			return
		_process_enemy_actions()
		if is_ended:
			return
		state_changed.emit()


func _process_higher_priority_events() -> void:
	while true:
		var event: RefCounted = event_queue.events[0] if not event_queue.events.is_empty() else null
		if event == null or not is_equal_approx(event.time, state.current_time) or event.get_priority() >= 5:
			return
		event_queue.pop_next_event()
		if event.event_type == "skill_execute":
			BattleResolverScript.resolve_skill(
				state, database, event, deck_manager, energy_manager
			)
			_cancel_dead_unit_events()
			if _check_battle_end():
				return
		elif event.event_type == "gain_energy":
			energy_manager.resolve_gain_event(event)
		elif event.event_type == "hand_reset_refresh":
			hand_reset_manager.resolve_refresh()


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


func _check_battle_end() -> bool:
	var allies_alive := _side_has_living_units(state.allies)
	var enemies_alive := _side_has_living_units(state.enemies)
	if allies_alive and enemies_alive:
		return false
	_finish_battle("victory" if allies_alive else "defeat")
	return true


func _side_has_living_units(units: Array[RefCounted]) -> bool:
	for unit in units:
		if unit.is_alive():
			return true
	return false


func _finish_battle(p_result: String) -> void:
	is_ended = true
	result = p_result
	available_actor_ids.clear()
	state.current_actor_id = ""
	event_queue.clear()
	state_changed.emit()
	battle_ended.emit(result)
