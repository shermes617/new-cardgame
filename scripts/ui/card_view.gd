extends Control

signal card_pressed(card_id: String, card_instance_id: String)

@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var card_image: TextureRect = %CardImage
@onready var energy_value: Label = %EnergyValue
@onready var charge_display: Control = %ChargeDisplay
@onready var charge_value: Label = %ChargeValue
@onready var overload_value: Label = %OverloadValue
var card_id: String = ""
var card_instance_id: String = ""
var interaction_enabled: bool = false
var selected: bool = false
var hovered: bool = false
var fan_position: Vector2 = Vector2.ZERO
var fan_rotation: float = 0.0
var fan_index: int = 0


func _ready() -> void:
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func display_card(card: RefCounted, hand_card: RefCounted) -> void:
	card_id = card.id
	card_instance_id = hand_card.instance_id
	name_label.text = tr(card.name_key)
	description_label.text = tr(card.description_key)
	card_image.texture = load(card.image_path)
	energy_value.text = str(card.cost)
	charge_display.visible = card.charge > 0.0
	charge_value.text = _format_time(card.charge)
	overload_value.text = _format_time(card.overload)
	tooltip_text = "%s\n%s" % [tr(card.name_key), tr(card.description_key)]


func set_interaction_state(is_selected: bool, is_enabled: bool) -> void:
	interaction_enabled = is_enabled
	selected = is_selected
	_update_visual_state()


func set_fan_transform(target_position: Vector2, target_rotation: float, index: int) -> void:
	fan_position = target_position
	fan_rotation = target_rotation
	fan_index = index
	pivot_offset = size * 0.5
	_update_visual_state()


func _on_gui_input(event: InputEvent) -> void:
	if (
		interaction_enabled
		and event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):
		card_pressed.emit(card_id, card_instance_id)


func _on_mouse_entered() -> void:
	hovered = true
	_update_visual_state()


func _on_mouse_exited() -> void:
	hovered = false
	_update_visual_state()


func _update_visual_state() -> void:
	position = fan_position + (Vector2(0.0, -34.0) if hovered else Vector2.ZERO)
	rotation = 0.0 if hovered else fan_rotation
	scale = Vector2(1.12, 1.12) if hovered else Vector2.ONE
	z_index = 100 if hovered else fan_index
	if selected:
		modulate = Color(1.12, 1.08, 0.92)
	elif interaction_enabled and hovered:
		modulate = Color(1.06, 1.06, 1.06)
	elif interaction_enabled:
		modulate = Color.WHITE
	else:
		modulate = Color(0.62, 0.62, 0.66)


func _format_time(value: float) -> String:
	return "%.0f" % value if is_equal_approx(value, roundf(value)) else "%.1f" % value
