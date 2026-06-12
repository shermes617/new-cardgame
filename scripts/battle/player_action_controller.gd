class_name PlayerActionController
extends RefCounted

const ActionRequestScript := preload("res://scripts/battle/action_request.gd")
const ActionValidatorScript := preload("res://scripts/battle/action_validator.gd")

signal selection_changed
signal request_created(request: RefCounted)

var battle_state: RefCounted
var database: RefCounted
var selected_action_type: String = ""
var selected_card_id: String = ""
var selected_hand_index: int = -1
var valid_target_ids: Array[String] = []
var latest_request: RefCounted


func _init(p_battle_state: RefCounted, p_database: RefCounted) -> void:
	battle_state = p_battle_state
	database = p_database


func select_basic_attack() -> void:
	var actor: RefCounted = battle_state.get_unit(battle_state.current_actor_id)
	if actor == null or not actor.is_alive():
		return
	selected_action_type = "basic_attack"
	selected_card_id = ""
	selected_hand_index = -1
	valid_target_ids = ActionValidatorScript.get_valid_target_ids(battle_state, "enemy")
	selection_changed.emit()


func select_card(card_id: String, hand_index: int = -1) -> void:
	var card: RefCounted = database.get_card(card_id)
	if card == null or not ActionValidatorScript.can_select_card(battle_state, card):
		return

	selected_action_type = "card"
	selected_card_id = card_id
	selected_hand_index = hand_index
	valid_target_ids = ActionValidatorScript.get_valid_target_ids(battle_state, card.target_side)
	selection_changed.emit()

	if card.target_type == "none":
		_create_request([])
	elif card.target_type == "all":
		_create_request(valid_target_ids)


func select_target(target_id: String) -> void:
	if selected_action_type.is_empty() or not valid_target_ids.has(target_id):
		return
	_create_request([target_id])


func cancel_selection() -> void:
	selected_action_type = ""
	selected_card_id = ""
	selected_hand_index = -1
	valid_target_ids.clear()
	latest_request = null
	selection_changed.emit()


func is_card_selected(card_id: String, hand_index: int = -1) -> bool:
	if selected_action_type != "card" or selected_card_id != card_id:
		return false
	return selected_hand_index == hand_index if selected_hand_index >= 0 else true


func can_select_card(card_id: String) -> bool:
	var card: RefCounted = database.get_card(card_id)
	return card != null and ActionValidatorScript.can_select_card(battle_state, card)


func _create_request(target_ids: Array[String]) -> void:
	latest_request = ActionRequestScript.new(
		battle_state.current_actor_id, selected_action_type, selected_card_id, target_ids, selected_hand_index
	)
	request_created.emit(latest_request)
	selection_changed.emit()
