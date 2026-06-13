extends SceneTree

const GameDatabaseScript := preload("res://scripts/data/game_database.gd")
const BattleSetupScript := preload("res://scripts/battle/battle_setup.gd")
const BattleFlowScript := preload("res://scripts/battle/battle_flow.gd")
const BattleEventScript := preload("res://scripts/battle/battle_event.gd")
const BattleResolverScript := preload("res://scripts/battle/battle_resolver.gd")
const GameRunStateScript := preload("res://scripts/models/game_run_state.gd")
const RewardManagerScript := preload("res://scripts/battle/reward_manager.gd")
const PlayerActionControllerScript := preload("res://scripts/battle/player_action_controller.gd")


func _init() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var database: RefCounted = GameDatabaseScript.new()
	assert(database.load_all(), "Stage 6: database validation failed")
	_validate_multiple_battles(database)
	_validate_dead_unit_event_cancellation(database)
	_validate_no_legal_targets(database)
	_validate_simultaneous_battle_end(database)
	print("Stage 6 validation passed")
	quit()


func _validate_multiple_battles(database: RefCounted) -> void:
	var run_state: RefCounted = GameRunStateScript.new()
	var reward_manager: RefCounted = RewardManagerScript.new(database, 17)
	run_state.initialize(database)
	var expected_arthur_hp := 30

	for battle_index in 3:
		var state: RefCounted = BattleSetupScript.create_initial_state(
			database, run_state.inherited_ally_hp, run_state.deck_ids
		)
		assert(state.deck_ids.size() == 10 + battle_index, "Stage 6: deck growth was not inherited")
		assert(state.get_unit("arthur").hp == expected_arthur_hp, "Stage 6: health inheritance failed")
		state.get_unit("arthur").take_damage(1)
		expected_arthur_hp -= 1
		run_state.record_victory(state)
		run_state.add_reward(reward_manager.generate_rewards()[0])

	assert(run_state.completed_battles == 3, "Stage 6: completed battle count is wrong")
	assert(run_state.deck_ids.size() == 13, "Stage 6: deck should gain one reward per victory")
	assert(run_state.inherited_ally_hp["arthur"] == 27, "Stage 6: final inherited health is wrong")


func _validate_dead_unit_event_cancellation(database: RefCounted) -> void:
	var state: RefCounted = BattleSetupScript.create_initial_state(database)
	var flow: RefCounted = BattleFlowScript.new(state, database)
	flow.initialize_events(23)
	flow.event_queue.add_event(
		BattleEventScript.new("", 3.0, "skill_execute", "enemy", "rift_bug", "enemy_basic_attack", ["arthur"])
	)
	flow.event_queue.add_event(BattleEventScript.new("", 6.0, "unit_action", "enemy", "rift_bug"))
	state.get_unit("rift_bug").hp = 1
	var kill_event: RefCounted = BattleEventScript.new(
		"", 0.0, "skill_execute", "ally", "arthur", "basic_attack", ["rift_bug"]
	)
	BattleResolverScript.resolve_skill(state, database, kill_event, flow.deck_manager, flow.energy_manager)
	flow.call("_cancel_dead_unit_events")
	for event in flow.event_queue.events:
		assert(event.unit_id != "rift_bug", "Stage 6: dead unit retained a future event")


func _validate_no_legal_targets(database: RefCounted) -> void:
	var state: RefCounted = BattleSetupScript.create_initial_state(database)
	var flow: RefCounted = BattleFlowScript.new(state, database)
	flow.initialize_events(29)
	var controller: RefCounted = PlayerActionControllerScript.new(state, database)
	flow.choose_actor("arthur")
	for enemy in state.enemies:
		enemy.hp = 0
	controller.select_basic_attack()
	assert(controller.valid_target_ids.is_empty(), "Stage 6: dead enemies must not be legal targets")
	controller.select_target("rift_bug")
	assert(controller.latest_request == null, "Stage 6: invalid target created an action request")


func _validate_simultaneous_battle_end(database: RefCounted) -> void:
	var state: RefCounted = BattleSetupScript.create_initial_state(database)
	var flow: RefCounted = BattleFlowScript.new(state, database)
	flow.initialize_events(31)
	for ally in state.allies:
		ally.hp = 0
	for enemy in state.enemies:
		enemy.hp = 0
	assert(flow.call("_check_battle_end"), "Stage 6: simultaneous end was not detected")
	assert(flow.result == "defeat", "Stage 6: simultaneous wipe should resolve as defeat")
