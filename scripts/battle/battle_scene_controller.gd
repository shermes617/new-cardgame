extends Control

const GameDatabaseScript := preload("res://scripts/data/game_database.gd")
const BattleSetupScript := preload("res://scripts/battle/battle_setup.gd")
const PlayerActionControllerScript := preload("res://scripts/battle/player_action_controller.gd")
const BattleFlowScript := preload("res://scripts/battle/battle_flow.gd")
const GameRunStateScript := preload("res://scripts/models/game_run_state.gd")
const RewardManagerScript := preload("res://scripts/battle/reward_manager.gd")
const UnitSlotScene := preload("res://scenes/battle/unit_slot.tscn")

@onready var timeline_panel: PanelContainer = %TimelinePanel
@onready var ally_container: HBoxContainer = %AllyContainer
@onready var enemy_container: HBoxContainer = %EnemyContainer
@onready var hand_panel: PanelContainer = %HandPanel
@onready var action_panel: PanelContainer = %ActionPanel
@onready var battle_end_panel: PanelContainer = %BattleEndPanel

var database: RefCounted
var run_state: RefCounted
var reward_manager: RefCounted
var battle_state: RefCounted
var player_action_controller: RefCounted
var battle_flow: RefCounted


func _ready() -> void:
	database = GameDatabaseScript.new()
	if not database.load_all():
		push_error("BattleSceneController: failed to load game database")
		return

	run_state = GameRunStateScript.new()
	run_state.initialize(database)
	reward_manager = RewardManagerScript.new(database)
	battle_end_panel.connect("reward_selected", _on_reward_selected)
	battle_end_panel.connect("restart_requested", _on_restart_requested)
	action_panel.basic_attack_pressed.connect(_on_basic_attack_pressed)
	action_panel.cancel_pressed.connect(_on_cancel_pressed)
	hand_panel.card_pressed.connect(_on_card_pressed)
	hand_panel.reset_pressed.connect(_on_hand_reset_pressed)
	_start_battle()


func _start_battle() -> void:
	battle_end_panel.call("hide_panel")
	battle_state = BattleSetupScript.create_initial_state(database, run_state.inherited_ally_hp, run_state.deck_ids)
	battle_flow = BattleFlowScript.new(battle_state, database)
	player_action_controller = PlayerActionControllerScript.new(battle_state, database)
	player_action_controller.selection_changed.connect(_refresh_interaction)
	player_action_controller.request_created.connect(_on_request_created)
	battle_flow.state_changed.connect(_refresh_view)
	battle_flow.player_choice_required.connect(_refresh_interaction)
	battle_flow.battle_ended.connect(_on_battle_ended)
	battle_flow.initialize_events()


func _refresh_view() -> void:
	_display_units()
	hand_panel.call("display_state", battle_state, database)
	timeline_panel.call("display_timeline", battle_state.current_time, battle_flow.event_queue.events, database)
	_refresh_interaction()


func _display_units() -> void:
	_clear_container(ally_container)
	_clear_container(enemy_container)
	var displayed_allies: Array = battle_state.allies.duplicate()
	displayed_allies.reverse()
	for unit in displayed_allies:
		var unit_slot: Node = UnitSlotScene.instantiate()
		ally_container.add_child(unit_slot)
		unit_slot.call("display_unit", unit)
		unit_slot.unit_pressed.connect(_on_unit_pressed)

	for unit in battle_state.enemies:
		var unit_slot: Node = UnitSlotScene.instantiate()
		enemy_container.add_child(unit_slot)
		unit_slot.call("display_unit", unit)
		unit_slot.unit_pressed.connect(_on_unit_pressed)


func _refresh_interaction() -> void:
	var interaction_enabled: bool = not bool(battle_flow.is_ended)
	for unit_slot in ally_container.get_children():
		var choosing_actor: bool = battle_state.current_actor_id.is_empty()
		var unit_enabled: bool = interaction_enabled and _is_unit_selectable(unit_slot.unit_id)
		unit_slot.call(
			"set_interaction_state", unit_slot.unit_id == battle_state.current_actor_id, unit_enabled
		)
	for unit_slot in enemy_container.get_children():
		var target_enabled: bool = interaction_enabled and player_action_controller.valid_target_ids.has(unit_slot.unit_id)
		unit_slot.call("set_interaction_state", false, target_enabled)
	hand_panel.call(
		"refresh_interaction", player_action_controller, interaction_enabled,
		battle_state.hand_reset_available
	)

	var actor: RefCounted = battle_state.get_unit(battle_state.current_actor_id)
	var action_name: String = _get_selected_action_name()
	var request_text := ""
	if player_action_controller.latest_request != null:
		request_text = player_action_controller.latest_request.call("describe")
	var actor_name := tr(actor.name_key) if actor != null else ""
	var has_selection: bool = not player_action_controller.selected_action_type.is_empty()
	action_panel.call("display_state", actor_name, action_name, has_selection, request_text, actor != null and interaction_enabled)


func _get_selected_action_name() -> String:
	if player_action_controller.selected_action_type == "basic_attack":
		return tr("UI_BASIC_ATTACK")
	if player_action_controller.selected_action_type == "card":
		return tr(database.get_card(player_action_controller.selected_card_id).name_key)
	return ""


func _on_request_created(request: RefCounted) -> void:
	battle_flow.submit_player_request(request)
	player_action_controller.cancel_selection()


func _on_unit_pressed(unit_id: String) -> void:
	if battle_flow.is_ended:
		return
	if battle_state.current_actor_id.is_empty():
		battle_flow.choose_actor(unit_id)
	else:
		player_action_controller.select_target(unit_id)


func _is_unit_selectable(unit_id: String) -> bool:
	if battle_state.current_actor_id.is_empty():
		return battle_flow.available_actor_ids.has(unit_id)
	return player_action_controller.valid_target_ids.has(unit_id)


func _on_basic_attack_pressed() -> void:
	if not battle_flow.is_ended:
		player_action_controller.select_basic_attack()


func _on_card_pressed(card_id: String, card_instance_id: String) -> void:
	if not battle_flow.is_ended:
		player_action_controller.select_card(card_id, card_instance_id)


func _on_cancel_pressed() -> void:
	if not battle_flow.is_ended:
		player_action_controller.cancel_selection()


func _on_hand_reset_pressed() -> void:
	if battle_flow.is_ended:
		return
	player_action_controller.cancel_selection()
	battle_flow.reset_hand()


func _on_battle_ended(result: String) -> void:
	player_action_controller.cancel_selection()
	if result == "victory":
		run_state.record_victory(battle_state)
		battle_end_panel.call(
			"show_victory", reward_manager.generate_rewards(), database,
			run_state.completed_battles, run_state.deck_ids.size()
		)
	else:
		battle_end_panel.call("show_defeat", run_state.completed_battles, run_state.deck_ids.size())


func _on_reward_selected(card_id: String) -> void:
	run_state.add_reward(card_id)
	_start_battle()


func _on_restart_requested() -> void:
	run_state.initialize(database)
	_start_battle()


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()
