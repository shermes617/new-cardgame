extends Control

const GameDatabaseScript := preload("res://scripts/data/game_database.gd")
const BattleSetupScript := preload("res://scripts/battle/battle_setup.gd")
const PlayerActionControllerScript := preload("res://scripts/battle/player_action_controller.gd")
const BattleFlowScript := preload("res://scripts/battle/battle_flow.gd")
const UnitSlotScene := preload("res://scenes/battle/unit_slot.tscn")
const CardViewScene := preload("res://scenes/battle/card_view.tscn")

@onready var timeline_panel: PanelContainer = %TimelinePanel
@onready var ally_container: HBoxContainer = %AllyContainer
@onready var enemy_container: HBoxContainer = %EnemyContainer
@onready var hand_container: HBoxContainer = %HandContainer
@onready var draw_pile_count: Label = %DrawPileCount
@onready var discard_pile_count: Label = %DiscardPileCount
@onready var energy_label: Label = %EnergyLabel
@onready var action_panel: PanelContainer = %ActionPanel

var database: RefCounted
var battle_state: RefCounted
var player_action_controller: RefCounted
var battle_flow: RefCounted


func _ready() -> void:
	database = GameDatabaseScript.new()
	if not database.load_all():
		push_error("BattleSceneController: failed to load game database")
		return

	battle_state = BattleSetupScript.create_initial_state(database)
	battle_flow = BattleFlowScript.new(battle_state, database)
	player_action_controller = PlayerActionControllerScript.new(battle_state, database)
	player_action_controller.selection_changed.connect(_refresh_interaction)
	player_action_controller.request_created.connect(_on_request_created)
	battle_flow.state_changed.connect(_refresh_view)
	battle_flow.player_choice_required.connect(_refresh_interaction)
	action_panel.basic_attack_pressed.connect(player_action_controller.select_basic_attack)
	action_panel.cancel_pressed.connect(player_action_controller.cancel_selection)
	battle_flow.initialize_events()


func _refresh_view() -> void:
	draw_pile_count.text = str(battle_state.draw_pile_ids.size())
	discard_pile_count.text = str(battle_state.discard_pile_ids.size())
	energy_label.text = "%d / %d" % [battle_state.energy, int(battle_state.config["energy_max"])]
	_display_units()
	_display_hand()
	timeline_panel.call(
		"display_timeline", battle_state.current_time, battle_flow.event_queue.events, database
	)
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


func _display_hand() -> void:
	_clear_container(hand_container)
	var hand_index := 0
	for card_id in battle_state.hand_ids:
		var card_view: Node = CardViewScene.instantiate()
		hand_container.add_child(card_view)
		card_view.call("display_card", database.get_card(card_id), hand_index)
		card_view.card_pressed.connect(player_action_controller.select_card)
		hand_index += 1


func _refresh_interaction() -> void:
	for unit_slot in ally_container.get_children():
		var choosing_actor: bool = battle_state.current_actor_id.is_empty()
		unit_slot.call(
			"set_interaction_state",
			unit_slot.unit_id == battle_state.current_actor_id,
			_is_unit_selectable(unit_slot.unit_id),
			"UI_SELECT_ACTOR" if choosing_actor else "UI_SELECT_TARGET"
		)
	for unit_slot in enemy_container.get_children():
		unit_slot.call(
			"set_interaction_state",
			false,
			player_action_controller.valid_target_ids.has(unit_slot.unit_id)
		)
	for card_view in hand_container.get_children():
		card_view.call(
			"set_interaction_state",
			player_action_controller.is_card_selected(card_view.card_id, card_view.hand_index),
			player_action_controller.can_select_card(card_view.card_id)
		)

	var actor: RefCounted = battle_state.get_unit(battle_state.current_actor_id)
	var action_name: String = _get_selected_action_name()
	var request_text: String = (
		player_action_controller.latest_request.call("describe")
		if player_action_controller.latest_request != null
		else ""
	)
	action_panel.call(
		"display_state",
		tr(actor.name_key) if actor != null else "",
		action_name,
		not player_action_controller.selected_action_type.is_empty(),
		request_text,
		actor != null
	)


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
	if battle_state.current_actor_id.is_empty():
		battle_flow.choose_actor(unit_id)
	else:
		player_action_controller.select_target(unit_id)


func _is_unit_selectable(unit_id: String) -> bool:
	if battle_state.current_actor_id.is_empty():
		return battle_flow.available_actor_ids.has(unit_id)
	return player_action_controller.valid_target_ids.has(unit_id)


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()
