extends SceneTree

const GameDatabaseScript := preload("res://scripts/data/game_database.gd")
const BattleSetupScript := preload("res://scripts/battle/battle_setup.gd")
const BattleFlowScript := preload("res://scripts/battle/battle_flow.gd")
const ActionRequestScript := preload("res://scripts/battle/action_request.gd")
const EventQueueScript := preload("res://scripts/battle/event_queue.gd")
const BattleEventScript := preload("res://scripts/battle/battle_event.gd")


func _init() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var database: RefCounted = GameDatabaseScript.new()
	assert(database.load_all(), "Stage 2: database validation failed")
	assert(
		not database.get_unit_definition("rift_bug").has("speed"),
		"Stage 2: enemies must not use speed"
	)
	assert(
		is_equal_approx(float(database.get_unit_definition("tide_crab")["action_interval"]), 4.0),
		"Stage 2: wrong enemy action interval"
	)

	var state: RefCounted = BattleSetupScript.create_initial_state(database)
	var flow: RefCounted = BattleFlowScript.new(state, database)
	flow.initialize_events()

	assert(is_equal_approx(state.current_time, 0.0), "Stage 2: allies should act at time zero")
	assert(flow.available_actor_ids.size() == 4, "Stage 2: all allies should be selectable")
	assert(
		flow.event_queue.get_events_at_time(0.0, "unit_action", "enemy").is_empty(),
		"Stage 2: enemies must not act at time zero"
	)
	assert(
		flow.event_queue.get_events_at_time(4.0, "unit_action", "enemy")[0].unit_id == "tide_crab",
		"Stage 2: tide crab should act first at time four"
	)

	flow.choose_actor("lia")
	flow.submit_player_request(ActionRequestScript.new("lia", "basic_attack", "", ["rift_bug"]))
	assert(state.get_unit("rift_bug").hp == 12, "Stage 2: zero-charge skill did not resolve first")
	assert(not flow.available_actor_ids.has("lia"), "Stage 2: acted ally still available")
	assert(flow.available_actor_ids.size() == 3, "Stage 2: remaining allies should stay selectable")

	flow.choose_actor("arthur")
	flow.submit_player_request(ActionRequestScript.new("arthur", "basic_attack", "", ["vine_beast"]))
	flow.choose_actor("berin")
	flow.submit_player_request(ActionRequestScript.new("berin", "basic_attack", "", ["tide_crab"]))
	flow.choose_actor("chloe")
	flow.submit_player_request(ActionRequestScript.new("chloe", "basic_attack", "", ["ruin_skeleton"]))

	assert(is_equal_approx(state.current_time, 5.0), "Stage 2: timeline did not advance correctly")
	assert(flow.available_actor_ids == ["chloe"], "Stage 2: Chloe should be ready at time five")
	assert(state.get_unit("arthur").hp == 24, "Stage 2: tide crab attack did not resolve")
	var tide_events: Array[RefCounted] = flow.event_queue.get_events_at_time(8.0, "unit_action", "enemy")
	assert(tide_events.size() == 1, "Stage 2: tide crab next action must use fixed interval")

	var priority_queue: RefCounted = EventQueueScript.new()
	priority_queue.add_event(BattleEventScript.new("", 3.0, "unit_action", "enemy", "rift_bug"))
	priority_queue.add_event(BattleEventScript.new("", 3.0, "unit_action", "ally", "arthur"))
	priority_queue.add_event(BattleEventScript.new("", 3.0, "skill_execute", "enemy", "rift_bug"))
	priority_queue.add_event(BattleEventScript.new("", 3.0, "skill_execute", "ally", "arthur"))
	assert(priority_queue.events[0].side == "ally", "Stage 2: ally skill should resolve first")
	assert(priority_queue.events[1].side == "enemy", "Stage 2: enemy skill should resolve second")
	assert(priority_queue.events[2].side == "ally", "Stage 2: ally action should precede enemy action")
	assert(not priority_queue.events[0].id.is_empty(), "Stage 2: event id should be generated")

	var charge_state: RefCounted = BattleSetupScript.create_initial_state(database)
	var charge_flow: RefCounted = BattleFlowScript.new(charge_state, database)
	charge_flow.initialize_events()
	charge_state.draw_pile_ids.push_front("heavy_strike")
	var heavy_card: RefCounted = charge_flow.deck_manager.draw_one()
	charge_flow.choose_actor("arthur")
	charge_flow.submit_player_request(
		ActionRequestScript.new("arthur", "card", "heavy_strike", ["rift_bug"], heavy_card.instance_id)
	)
	assert(
		charge_flow.event_queue.get_events_at_time(1.0, "skill_execute", "ally").size() == 1,
		"Stage 2: charged card execute time is wrong"
	)
	assert(
		charge_flow.event_queue.get_events_at_time(5.2, "unit_action", "ally").size() == 1,
		"Stage 2: overload should start after charge"
	)
	assert(charge_state.energy == 2, "Stage 2: card energy was not deducted")
	assert(charge_state.discard_pile_ids.has("heavy_strike"), "Stage 2: used card not discarded")

	print("Stage 2 validation passed")
	quit()
