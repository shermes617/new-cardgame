extends PanelContainer

signal card_pressed(card_id: String, card_instance_id: String)

@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var cost_label: Label = %CostLabel
@onready var charge_label: Label = %ChargeLabel
@onready var overload_label: Label = %OverloadLabel
@onready var select_button: Button = %SelectButton

var card_id: String = ""
var card_instance_id: String = ""


func _ready() -> void:
	select_button.pressed.connect(_on_select_button_pressed)


func display_card(card: RefCounted, hand_card: RefCounted) -> void:
	card_id = card.id
	card_instance_id = hand_card.instance_id
	name_label.text = tr(card.name_key)
	description_label.text = tr(card.description_key)
	cost_label.text = "%s: %d" % [tr("UI_COST"), card.cost]
	charge_label.text = "%s: %.1f" % [tr("UI_CHARGE"), card.charge]
	overload_label.text = "%s: %.1f" % [tr("UI_OVERLOAD"), card.overload]


func set_interaction_state(is_selected: bool, is_enabled: bool) -> void:
	select_button.disabled = not is_enabled
	select_button.text = tr("UI_SELECTED") if is_selected else tr("UI_SELECT")
	modulate = Color(1.08, 1.08, 1.08) if is_selected else Color.WHITE


func _on_select_button_pressed() -> void:
	card_pressed.emit(card_id, card_instance_id)
