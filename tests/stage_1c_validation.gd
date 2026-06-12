extends SceneTree

const GameDatabaseScript := preload("res://scripts/data/game_database.gd")
const BattleSetupScript := preload("res://scripts/battle/battle_setup.gd")
const PlayerActionControllerScript := preload("res://scripts/battle/player_action_controller.gd")
const BattleFlowScript := preload("res://scripts/battle/battle_flow.gd")
const BattleScene := preload("res://scenes/battle/battle_scene.tscn")


func _init() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var database: RefCounted = GameDatabaseScript.new()
	assert(database.load_all(), "Stage 1C: database validation failed")
	var state: RefCounted = BattleSetupScript.create_initial_state(database)
	var controller: RefCounted = PlayerActionControllerScript.new(state, database)
	var flow: RefCounted = BattleFlowScript.new(state, database)
	flow.initialize_events()

	assert(state.current_actor_id.is_empty(), "Stage 1C: actor should be chosen by player")
	assert(flow.available_actor_ids.size() == 4, "Stage 1C: expected four available actors")
	flow.choose_actor("arthur")

	controller.select_basic_attack()
	assert(controller.valid_target_ids.size() == 4, "Stage 1C: basic attack should target enemies")
	controller.select_target("rift_bug")
	assert(controller.latest_request.action_type == "basic_attack", "Stage 1C: wrong action type")
	assert(controller.latest_request.target_ids == ["rift_bug"], "Stage 1C: wrong basic attack target")

	controller.cancel_selection()
	controller.select_card("strike", 2)
	assert(controller.is_card_selected("strike", 2), "Stage 1C: selected card copy not highlighted")
	assert(not controller.is_card_selected("strike", 1), "Stage 1C: wrong card copy highlighted")
	controller.select_target("vine_beast")
	assert(controller.latest_request.card_id == "strike", "Stage 1C: wrong card request")
	assert(controller.latest_request.target_ids == ["vine_beast"], "Stage 1C: wrong card target")

	controller.cancel_selection()
	state.energy = 0
	controller.select_card("strike")
	assert(controller.selected_action_type.is_empty(), "Stage 1C: unaffordable card was selected")

	state.energy = 3
	state.hand_ids.append("group_defense")
	controller.select_card("group_defense")
	assert(controller.latest_request.target_ids.size() == 4, "Stage 1C: group card needs all allies")

	controller.cancel_selection()
	state.hand_ids.append("energy_supply")
	controller.select_card("energy_supply")
	assert(controller.latest_request.target_ids.is_empty(), "Stage 1C: no-target card has targets")

	var scene: Control = BattleScene.instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.get_node("%ActionPanel") != null, "Stage 1C: action panel missing")
	assert(
		scene.get_node("%ActionPanel").get_node("%BasicAttackButton") != null,
		"Stage 1C: basic attack button missing"
	)

	print("Stage 1C validation passed")
	quit()
