extends SceneTree

const GameDatabaseScript := preload("res://scripts/data/game_database.gd")
const BattleSetupScript := preload("res://scripts/battle/battle_setup.gd")
const BattleFlowScript := preload("res://scripts/battle/battle_flow.gd")
const GameRunStateScript := preload("res://scripts/models/game_run_state.gd")
const RewardManagerScript := preload("res://scripts/battle/reward_manager.gd")


func _init() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var database: RefCounted = GameDatabaseScript.new()
	assert(database.load_all(), "Stage 5: database validation failed")
	_validate_battle_end(database)
	_validate_rewards_and_next_battle(database)
	print("Stage 5 validation passed")
	quit()


func _validate_battle_end(database: RefCounted) -> void:
	var state: RefCounted = BattleSetupScript.create_initial_state(database)
	var flow: RefCounted = BattleFlowScript.new(state, database)
	flow.initialize_events(5)
	for enemy in state.enemies:
		enemy.hp = 0
	assert(flow.call("_check_battle_end"), "Stage 5: victory was not detected")
	assert(flow.is_ended and flow.result == "victory", "Stage 5: wrong victory result")
	assert(flow.event_queue.events.is_empty(), "Stage 5: events must stop after battle end")
	assert(flow.available_actor_ids.is_empty(), "Stage 5: actors remain selectable after battle end")

	var defeat_state: RefCounted = BattleSetupScript.create_initial_state(database)
	var defeat_flow: RefCounted = BattleFlowScript.new(defeat_state, database)
	defeat_flow.initialize_events(6)
	for ally in defeat_state.allies:
		ally.hp = 0
	assert(defeat_flow.call("_check_battle_end"), "Stage 5: defeat was not detected")
	assert(defeat_flow.result == "defeat", "Stage 5: wrong defeat result")


func _validate_rewards_and_next_battle(database: RefCounted) -> void:
	var run_state: RefCounted = GameRunStateScript.new()
	run_state.initialize(database)
	var reward_manager: RefCounted = RewardManagerScript.new(database, 7)
	var rewards: Array[String] = reward_manager.generate_rewards()
	assert(rewards.size() == 3, "Stage 5: expected three rewards")
	assert(rewards[0] != rewards[1] and rewards[1] != rewards[2] and rewards[0] != rewards[2])

	var first_battle: RefCounted = BattleSetupScript.create_initial_state(database, {}, run_state.deck_ids)
	first_battle.get_unit("arthur").take_damage(9)
	run_state.record_victory(first_battle)
	run_state.add_reward(rewards[0])
	var next_battle: RefCounted = BattleSetupScript.create_initial_state(
		database, run_state.inherited_ally_hp, run_state.deck_ids
	)
	assert(next_battle.deck_ids.size() == 11, "Stage 5: reward was not added to deck")
	assert(next_battle.get_unit("arthur").hp == 21, "Stage 5: ally health was not inherited")
	assert(next_battle.get_unit("arthur").shield == 0, "Stage 5: ally shield should reset")
	assert(next_battle.get_unit("rift_bug").hp == 18, "Stage 5: enemy health should reset")
	assert(next_battle.energy == 3, "Stage 5: energy should reset")
