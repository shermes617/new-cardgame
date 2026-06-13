extends SceneTree

const GameDatabaseScript := preload("res://scripts/data/game_database.gd")
const BattleSetupScript := preload("res://scripts/battle/battle_setup.gd")
const BattleFlowScript := preload("res://scripts/battle/battle_flow.gd")
const BattleEventScript := preload("res://scripts/battle/battle_event.gd")
const BattleResolverScript := preload("res://scripts/battle/battle_resolver.gd")
const ActionRequestScript := preload("res://scripts/battle/action_request.gd")


func _init() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var database: RefCounted = GameDatabaseScript.new()
	assert(database.load_all(), "Stage 4: database validation failed")
	_validate_energy(database)
	_validate_card_effects(database)
	_validate_draw_tactics_order(database)
	print("Stage 4 validation passed")
	quit()


func _validate_energy(database: RefCounted) -> void:
	var state: RefCounted = BattleSetupScript.create_initial_state(database)
	var flow: RefCounted = BattleFlowScript.new(state, database)
	flow.initialize_events(4)
	assert(flow.event_queue.get_events_at_time(10.0, "gain_energy").size() == 1)
	state.energy = 9
	assert(flow.energy_manager.gain(2) == 1, "Stage 4: energy must stop at maximum")
	assert(state.energy == 10, "Stage 4: wrong maximum energy")
	assert(flow.energy_manager.spend(11) == false, "Stage 4: overspending should fail")
	state.energy = 0
	var basic_event: RefCounted = BattleEventScript.new(
		"", 0.0, "skill_execute", "ally", "arthur", "basic_attack", ["rift_bug"]
	)
	BattleResolverScript.resolve_skill(
		state, database, basic_event, flow.deck_manager, flow.energy_manager
	)
	assert(state.energy == 1, "Stage 4: basic attack should restore one energy")


func _validate_card_effects(database: RefCounted) -> void:
	var state: RefCounted = BattleSetupScript.create_initial_state(database)
	var flow: RefCounted = BattleFlowScript.new(state, database)
	flow.initialize_events(8)

	var ally: RefCounted = state.get_unit("chloe")
	ally.take_damage(20)
	_resolve_card(state, database, flow, "lia", "healing_light", ["chloe"])
	assert(ally.hp == 13, "Stage 4: healing light should heal eight health")
	ally.heal(100)
	assert(ally.hp == ally.max_hp, "Stage 4: healing must not exceed maximum health")

	state.draw_pile_ids.assign(["strike", "defend"])
	var hand_before: int = state.hand_cards.size()
	_resolve_card(state, database, flow, "lia", "draw_tactics", [])
	assert(state.hand_cards.size() == hand_before + 2, "Stage 4: draw tactics should draw two cards")

	_resolve_card(state, database, flow, "lia", "energy_supply", [])
	var energy_events: Array[RefCounted] = flow.event_queue.get_events_at_time(6.0, "gain_energy")
	assert(energy_events.size() == 1, "Stage 4: delayed energy event is missing")
	assert(energy_events[0].amount == 2, "Stage 4: delayed energy amount is wrong")

	var enemy: RefCounted = state.get_unit("rift_bug")
	enemy.shield = 10
	var actor: RefCounted = state.get_unit("arthur")
	_resolve_card(state, database, flow, "arthur", "iron_wave", ["rift_bug"])
	assert(enemy.hp == 16, "Stage 4: iron slash wave health damage is wrong")
	assert(actor.shield == 2, "Stage 4: iron slash wave shield must use health damage")


func _validate_draw_tactics_order(database: RefCounted) -> void:
	var state: RefCounted = BattleSetupScript.create_initial_state(database)
	var flow: RefCounted = BattleFlowScript.new(state, database)
	flow.initialize_events(19)
	state.hand_cards.clear()
	state.draw_pile_ids.assign(["draw_tactics"])
	state.discard_pile_ids.assign(["strike", "defend"])
	var draw_tactics: RefCounted = flow.deck_manager.draw_one()
	assert(state.draw_pile_ids.is_empty(), "Stage 4: draw tactics setup draw pile must be empty")
	flow.choose_actor("lia")
	flow.submit_player_request(
		ActionRequestScript.new("lia", "card", "draw_tactics", [], draw_tactics.instance_id)
	)
	assert(state.hand_cards.size() == 2, "Stage 4: draw tactics should draw the reshuffled cards")
	assert(
		not state.has_card_in_hand("draw_tactics"),
		"Stage 4: draw tactics must not draw itself during its effect"
	)
	assert(state.discard_pile_ids == ["draw_tactics"], "Stage 4: draw tactics must discard after drawing")

	var shortage_state: RefCounted = BattleSetupScript.create_initial_state(database)
	var shortage_flow: RefCounted = BattleFlowScript.new(shortage_state, database)
	shortage_flow.initialize_events(21)
	shortage_state.hand_cards.clear()
	shortage_state.draw_pile_ids.assign(["draw_tactics"])
	shortage_state.discard_pile_ids.assign(["strike"])
	var shortage_card: RefCounted = shortage_flow.deck_manager.draw_one()
	shortage_flow.choose_actor("lia")
	shortage_flow.submit_player_request(
		ActionRequestScript.new("lia", "card", "draw_tactics", [], shortage_card.instance_id)
	)
	assert(shortage_state.hand_cards.size() == 1, "Stage 4: draw should stop when all cards are drawn")
	assert(shortage_state.discard_pile_ids == ["draw_tactics"])


func _resolve_card(
	state: RefCounted, database: RefCounted, flow: RefCounted, actor_id: String, card_id: String,
	target_ids: Array[String]
) -> void:
	var event: RefCounted = BattleEventScript.new(
		"", state.current_time, "skill_execute", "ally", actor_id, card_id, target_ids
	)
	BattleResolverScript.resolve_skill(state, database, event, flow.deck_manager, flow.energy_manager)
