extends PanelContainer

signal card_pressed(card_id: String, card_instance_id: String)
signal reset_pressed

const CardViewScene := preload("res://scenes/battle/card_view.tscn")
const MAX_VISIBLE_CARDS := 9
const RESET_BUTTON_NORMAL_COLOR := Color.WHITE
const RESET_BUTTON_HOVER_COLOR := Color(1.2, 1.14, 0.88)
const RESET_BUTTON_PRESSED_COLOR := Color(0.82, 0.78, 0.68)
const RESET_BUTTON_DISABLED_COLOR := Color(0.5, 0.5, 0.55)

@onready var draw_pile_count: Label = %DrawPileCount
@onready var energy_label: Label = %EnergyLabel
@onready var hand_reset_button: BaseButton = %HandResetButton
@onready var hand_reset_label: Label = %HandResetLabel
@onready var discard_pile_count: Label = %DiscardPileCount
@onready var hand_container: Container = %HandContainer
var reset_button_tween: Tween


func _ready() -> void:
	hand_reset_button.pressed.connect(reset_pressed.emit)
	hand_reset_button.mouse_entered.connect(_on_reset_button_mouse_entered)
	hand_reset_button.mouse_exited.connect(_on_reset_button_mouse_exited)
	hand_reset_button.button_down.connect(_on_reset_button_down)
	hand_reset_button.button_up.connect(_on_reset_button_up)
	hand_reset_button.resized.connect(_update_reset_button_pivot)
	_update_reset_button_pivot()


func display_state(state: RefCounted, database: RefCounted) -> void:
	draw_pile_count.text = str(state.draw_pile_ids.size())
	discard_pile_count.text = str(state.discard_pile_ids.size())
	energy_label.text = "%d / %d" % [state.energy, int(state.config["energy_max"])]
	hand_reset_label.text = tr("UI_RESET_HAND") if state.hand_reset_available else tr("UI_RESET_HAND_WAIT")
	_clear_cards()
	for hand_card in state.hand_cards:
		var card_view: Control = CardViewScene.instantiate()
		hand_container.add_child(card_view)
		card_view.call("display_card", database.get_card(hand_card.card_id), hand_card)
		card_view.card_pressed.connect(card_pressed.emit)
	hand_container.call_deferred("refresh_layout")


func refresh_interaction(controller: RefCounted, interaction_enabled: bool, reset_available: bool) -> void:
	hand_reset_button.disabled = not interaction_enabled or not reset_available
	if hand_reset_button.disabled:
		_animate_reset_button(Vector2.ONE, RESET_BUTTON_DISABLED_COLOR)
	elif not hand_reset_button.is_hovered():
		_animate_reset_button(Vector2.ONE, RESET_BUTTON_NORMAL_COLOR)
	for card_view in hand_container.get_children():
		var card_enabled: bool = (
			interaction_enabled
			and controller.can_select_card(card_view.card_id, card_view.card_instance_id)
		)
		var card_selected: bool = controller.is_card_selected(
			card_view.card_id, card_view.card_instance_id
		)
		card_view.call("set_interaction_state", card_selected, card_enabled)


func _on_reset_button_mouse_entered() -> void:
	if not hand_reset_button.disabled:
		_animate_reset_button(Vector2(1.06, 1.06), RESET_BUTTON_HOVER_COLOR)


func _on_reset_button_mouse_exited() -> void:
	if not hand_reset_button.disabled:
		_animate_reset_button(Vector2.ONE, RESET_BUTTON_NORMAL_COLOR)


func _on_reset_button_down() -> void:
	if not hand_reset_button.disabled:
		_animate_reset_button(Vector2(0.97, 0.97), RESET_BUTTON_PRESSED_COLOR)


func _on_reset_button_up() -> void:
	if not hand_reset_button.disabled:
		var target_scale := Vector2(1.06, 1.06) if hand_reset_button.is_hovered() else Vector2.ONE
		var target_color := RESET_BUTTON_HOVER_COLOR if hand_reset_button.is_hovered() else RESET_BUTTON_NORMAL_COLOR
		_animate_reset_button(target_scale, target_color)


func _animate_reset_button(target_scale: Vector2, target_color: Color) -> void:
	if reset_button_tween and reset_button_tween.is_valid():
		reset_button_tween.kill()
	reset_button_tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reset_button_tween.tween_property(hand_reset_button, "scale", target_scale, 0.1)
	reset_button_tween.tween_property(hand_reset_button, "modulate", target_color, 0.1)


func _update_reset_button_pivot() -> void:
	hand_reset_button.pivot_offset = hand_reset_button.size * 0.5


func _clear_cards() -> void:
	for child in hand_container.get_children():
		child.queue_free()
