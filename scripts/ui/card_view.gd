extends PanelContainer

signal card_pressed(card_id: String, card_instance_id: String)

@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var cost_label: Label = %CostLabel
@onready var charge_label: Label = %ChargeLabel
@onready var overload_label: Label = %OverloadLabel
var card_id: String = ""
var card_instance_id: String = ""
var interaction_enabled: bool = false


func _ready() -> void:
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func display_card(card: RefCounted, hand_card: RefCounted) -> void:
	card_id = card.id
	card_instance_id = hand_card.instance_id
	name_label.text = tr(card.name_key)
	description_label.text = tr(card.description_key)
	cost_label.text = "%s: %d" % [tr("UI_COST"), card.cost]
	charge_label.text = "%s: %.1f" % [tr("UI_CHARGE"), card.charge]
	overload_label.text = "%s: %.1f" % [tr("UI_OVERLOAD"), card.overload]


func set_interaction_state(is_selected: bool, is_enabled: bool) -> void:
	interaction_enabled = is_enabled
	position.y = -5.0 if is_selected else 0.0
	modulate = Color(1.12, 1.08, 0.92) if is_selected else (Color.WHITE if is_enabled else Color(0.62, 0.62, 0.66))


func _on_gui_input(event: InputEvent) -> void:
	if (
		interaction_enabled
		and event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):
		card_pressed.emit(card_id, card_instance_id)


func _on_mouse_entered() -> void:
	if interaction_enabled and position.y == 0.0:
		position.y = -3.0


func _on_mouse_exited() -> void:
	if position.y == -3.0:
		position.y = 0.0
