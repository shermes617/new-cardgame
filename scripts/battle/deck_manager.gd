class_name DeckManager
extends RefCounted

const HandCardScript := preload("res://scripts/models/hand_card.gd")

var state: RefCounted
var event_queue: RefCounted
var rng := RandomNumberGenerator.new()
var next_hand_instance_order: int = 0


func _init(p_state: RefCounted, p_event_queue: RefCounted, seed: int = -1) -> void:
	state = p_state
	event_queue = p_event_queue
	if seed >= 0:
		rng.seed = seed
	else:
		rng.randomize()


func initialize_deck() -> void:
	state.draw_pile_ids.assign(state.deck_ids)
	state.hand_cards.clear()
	state.discard_pile_ids.clear()
	_shuffle_draw_pile()
	draw_cards(int(state.config["initial_hand_size"]))


func draw_cards(amount: int) -> void:
	for _index in amount:
		draw_one()


func draw_one() -> RefCounted:
	if state.draw_pile_ids.is_empty():
		_reshuffle_discard()
	if state.draw_pile_ids.is_empty():
		return null

	var card_id: String = state.draw_pile_ids.pop_front()
	if state.hand_cards.size() >= int(state.config["hand_limit"]):
		state.discard_pile_ids.append(card_id)
		return null

	var instance_id := "hand_%04d" % next_hand_instance_order
	next_hand_instance_order += 1
	var hand_card: RefCounted = HandCardScript.new(instance_id, card_id, state.current_time)
	state.hand_cards.append(hand_card)
	return hand_card


func remove_hand_card(instance_id: String) -> String:
	var hand_card: RefCounted = state.get_hand_card(instance_id)
	if hand_card == null:
		return ""
	state.hand_cards.erase(hand_card)
	return hand_card.card_id


func discard_card(card_id: String) -> void:
	if not card_id.is_empty():
		state.discard_pile_ids.append(card_id)


func discard_hand_card(instance_id: String) -> String:
	var card_id := remove_hand_card(instance_id)
	discard_card(card_id)
	return card_id


func discard_all_hand_cards() -> void:
	for hand_card in state.hand_cards:
		state.discard_pile_ids.append(hand_card.card_id)
	state.hand_cards.clear()


func _reshuffle_discard() -> void:
	if state.discard_pile_ids.is_empty():
		return
	state.draw_pile_ids.assign(state.discard_pile_ids)
	state.discard_pile_ids.clear()
	_shuffle_draw_pile()


func _shuffle_draw_pile() -> void:
	for index in range(state.draw_pile_ids.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var card_id: String = state.draw_pile_ids[index]
		state.draw_pile_ids[index] = state.draw_pile_ids[swap_index]
		state.draw_pile_ids[swap_index] = card_id
