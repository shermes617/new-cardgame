class_name HandResetManager
extends RefCounted

const BattleEventScript := preload("res://scripts/battle/battle_event.gd")

var state: RefCounted
var event_queue: RefCounted
var deck_manager: RefCounted


func _init(p_state: RefCounted, p_event_queue: RefCounted, p_deck_manager: RefCounted) -> void:
	state = p_state
	event_queue = p_event_queue
	deck_manager = p_deck_manager


func reset_hand() -> bool:
	if not state.hand_reset_available:
		return false
	state.hand_reset_available = false
	deck_manager.discard_all_hand_cards()
	deck_manager.draw_cards(int(state.config["initial_hand_size"]))
	_schedule_refresh()
	return true


func resolve_refresh() -> void:
	state.hand_reset_available = true


func _schedule_refresh() -> void:
	var interval: float = float(state.config["hand_reset_refresh_interval"])
	var refresh_time := snappedf((floorf(state.current_time / interval) + 1.0) * interval, 0.1)
	event_queue.add_event(BattleEventScript.new("", refresh_time, "hand_reset_refresh"))
