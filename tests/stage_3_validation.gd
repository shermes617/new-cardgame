extends SceneTree

const GameDatabaseScript := preload("res://scripts/data/game_database.gd")
const BattleSetupScript := preload("res://scripts/battle/battle_setup.gd")
const BattleFlowScript := preload("res://scripts/battle/battle_flow.gd")


func _init() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var database: RefCounted = GameDatabaseScript.new()
	assert(database.load_all(), "Stage 3: database validation failed")
	_validate_initial_draw(database)
	_validate_reset_and_refresh(database)
	_validate_exact_refresh_boundary(database)
	_validate_unused_reset(database)
	_validate_hand_limit_and_reshuffle(database)
	print("Stage 3 validation passed")
	quit()


func _validate_initial_draw(database: RefCounted) -> void:
	var flow: RefCounted = _create_flow(database, 12345)
	var state: RefCounted = flow.state
	assert(state.hand_cards.size() == 5, "Stage 3: initial hand must contain five cards")
	assert(state.draw_pile_ids.size() == 5, "Stage 3: initial draw pile must contain five cards")
	assert(state.hand_reset_available, "Stage 3: reset must initially be available")
	assert(_count_events(flow, "draw_card") == 0, "Stage 3: periodic draw event must not exist")
	assert(_count_events(flow, "hand_expire") == 0, "Stage 3: hand expiry event must not exist")
	assert(_count_events(flow, "hand_reset_refresh") == 0, "Stage 3: unused reset must not refresh")


func _validate_reset_and_refresh(database: RefCounted) -> void:
	var flow: RefCounted = _create_flow(database, 7)
	var state: RefCounted = flow.state
	assert(flow.reset_hand(), "Stage 3: available reset should succeed")
	assert(state.hand_cards.size() == 5, "Stage 3: reset must draw five cards")
	assert(state.discard_pile_ids.size() == 5, "Stage 3: reset must discard the old hand")
	assert(not state.hand_reset_available, "Stage 3: reset must become unavailable after use")
	assert(not flow.reset_hand(), "Stage 3: reset must not be reusable before refresh")
	assert(flow.event_queue.get_events_at_time(10.0, "hand_reset_refresh").size() == 1)
	state.current_time = 10.0
	flow.call("_process_higher_priority_events")
	assert(state.hand_reset_available, "Stage 3: reset must refresh at time 10")
	assert(_count_events(flow, "hand_reset_refresh") == 0, "Stage 3: refresh must not schedule itself")


func _validate_exact_refresh_boundary(database: RefCounted) -> void:
	var flow: RefCounted = _create_flow(database, 9)
	flow.state.current_time = 10.0
	assert(flow.reset_hand(), "Stage 3: reset at exact boundary should succeed")
	assert(flow.event_queue.get_events_at_time(20.0, "hand_reset_refresh").size() == 1)


func _validate_unused_reset(database: RefCounted) -> void:
	var flow: RefCounted = _create_flow(database, 11)
	assert(_count_events(flow, "hand_reset_refresh") == 0, "Stage 3: unused reset must not accumulate charges")


func _validate_hand_limit_and_reshuffle(database: RefCounted) -> void:
	var flow: RefCounted = _create_flow(database, 13)
	var state: RefCounted = flow.state
	flow.deck_manager.draw_cards(4)
	assert(state.hand_cards.size() == 9, "Stage 3: hand limit setup failed")
	state.draw_pile_ids.append("strike")
	var discard_before: int = state.discard_pile_ids.size()
	assert(flow.deck_manager.draw_one() == null, "Stage 3: full hand should reject draw")
	assert(state.discard_pile_ids.size() == discard_before + 1)
	state.hand_cards.clear()
	state.draw_pile_ids.clear()
	state.discard_pile_ids.assign(["strike", "defend"])
	assert(flow.deck_manager.draw_one() != null, "Stage 3: discard pile did not reshuffle")
	assert(state.draw_pile_ids.size() == 1, "Stage 3: reshuffled pile count is wrong")


func _create_flow(database: RefCounted, seed: int) -> RefCounted:
	var state: RefCounted = BattleSetupScript.create_initial_state(database)
	var flow: RefCounted = BattleFlowScript.new(state, database)
	flow.initialize_events(seed)
	return flow


func _count_events(flow: RefCounted, event_type: String) -> int:
	var count := 0
	for event in flow.event_queue.events:
		if event.event_type == event_type:
			count += 1
	return count
