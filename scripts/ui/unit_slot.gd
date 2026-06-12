extends PanelContainer

signal unit_pressed(unit_id: String)

@onready var portrait: TextureRect = %Portrait
@onready var position_label: Label = %PositionLabel
@onready var name_label: Label = %NameLabel
@onready var role_label: Label = %RoleLabel
@onready var hp_text: Label = %HpText
@onready var hp_bar: ProgressBar = %HpBar
@onready var shield_label: Label = %ShieldLabel
@onready var action_time_label: Label = %ActionTimeLabel
@onready var select_button: Button = %SelectButton

var unit_id: String = ""


func _ready() -> void:
	select_button.pressed.connect(_on_select_button_pressed)


func display_unit(unit: RefCounted) -> void:
	unit_id = unit.id
	portrait.texture = load(unit.portrait_path)
	position_label.text = str(unit.position)
	name_label.text = tr(unit.name_key)
	role_label.text = tr(unit.role_key)
	hp_text.text = "%d / %d" % [unit.hp, unit.max_hp]
	hp_bar.max_value = unit.max_hp
	hp_bar.value = unit.hp
	shield_label.text = "%s %d" % [tr("UI_SHIELD_SHORT"), unit.shield]
	action_time_label.text = "%s %.1f" % [tr("UI_TIME_SHORT"), unit.next_action_time]
	if unit.side == "enemy":
		position_label.modulate = Color(1.0, 0.48, 0.42)
		hp_bar.modulate = Color(1.0, 0.48, 0.42)


func set_interaction_state(
	is_current_actor: bool, is_selectable: bool, select_text_key: String = "UI_SELECT_TARGET"
) -> void:
	select_button.disabled = not is_selectable
	select_button.visible = is_selectable
	select_button.text = tr(select_text_key)
	modulate = Color(1.08, 1.08, 1.08) if is_current_actor or is_selectable else Color.WHITE


func _on_select_button_pressed() -> void:
	unit_pressed.emit(unit_id)
