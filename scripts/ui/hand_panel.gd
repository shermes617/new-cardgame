extends PanelContainer

signal card_pressed(card_id: String, card_instance_id: String)
signal reset_pressed

const CardViewScene := preload("res://scenes/battle/card_view.tscn")
const MAX_VISIBLE_CARDS := 9
const MAX_CARD_WIDTH := 142.0
const MIN_CARD_WIDTH := 112.0
const CARD_SEPARATION := 5.0

@onready var draw_pile_count: Label = %DrawPileCount
@onready var energy_label: Label = %EnergyLabel
@onready var hand_reset_button: Button = %HandResetButton
@onready var discard_pile_count: Label = %DiscardPileCount
@onready var hand_container: HBoxContainer = %HandContainer


func _ready() -> void:
	hand_reset_button.pressed.connect(reset_pressed.emit)
	resized.connect(_resize_cards)


func display_state(state: RefCounted, database: RefCounted) -> void:
	draw_pile_count.text = str(state.draw_pile_ids.size())
	discard_pile_count.text = str(state.discard_pile_ids.size())
	energy_label.text = "%d / %d" % [state.energy, int(state.config["energy_max"])]
	hand_reset_button.text = tr("UI_RESET_HAND") if state.hand_reset_available else tr("UI_RESET_HAND_WAIT")
	_clear_cards()
	for hand_card in state.hand_cards:
		var card_view: Control = CardViewScene.instantiate()
		card_view.custom_minimum_size.x = MIN_CARD_WIDTH
		hand_container.add_child(card_view)
		card_view.call("display_card", database.get_card(hand_card.card_id), hand_card)
		card_view.card_pressed.connect(card_pressed.emit)
	call_deferred("_resize_cards")


func refresh_interaction(controller: RefCounted, interaction_enabled: bool, reset_available: bool) -> void:
	hand_reset_button.disabled = not interaction_enabled or not reset_available
	for card_view in hand_container.get_children():
		var card_enabled: bool = (
			interaction_enabled
			and controller.can_select_card(card_view.card_id, card_view.card_instance_id)
		)
		var card_selected: bool = controller.is_card_selected(
			card_view.card_id, card_view.card_instance_id
		)
		card_view.call("set_interaction_state", card_selected, card_enabled)


func _resize_cards() -> void:
	var card_count: int = mini(hand_container.get_child_count(), MAX_VISIBLE_CARDS)
	if card_count <= 0:
		return
	var available_width: float = hand_container.size.x - CARD_SEPARATION * float(card_count - 1)
	var card_width: float = clampf(available_width / float(card_count), MIN_CARD_WIDTH, MAX_CARD_WIDTH)
	for card_view in hand_container.get_children():
		card_view.custom_minimum_size.x = card_width


func _clear_cards() -> void:
	for child in hand_container.get_children():
		child.queue_free()
