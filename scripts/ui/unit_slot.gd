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
var unit_id: String = ""
var is_alive: bool = true
var interaction_enabled: bool = false


func _ready() -> void:
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func display_unit(unit: RefCounted) -> void:
	unit_id = unit.id
	is_alive = unit.is_alive()
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
	if not is_alive:
		modulate = Color(0.35, 0.35, 0.38, 0.72)


func set_interaction_state(
	is_current_actor: bool, is_selectable: bool
) -> void:
	interaction_enabled = is_selectable and is_alive
	if not is_alive:
		modulate = Color(0.35, 0.35, 0.38, 0.72)
	elif is_current_actor:
		modulate = Color(0.72, 0.9, 1.2)
	elif is_selectable:
		modulate = Color(1.12, 1.12, 1.08)
	else:
		modulate = Color.WHITE


func _on_gui_input(event: InputEvent) -> void:
	if (
		interaction_enabled
		and event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):
		unit_pressed.emit(unit_id)


func _on_mouse_entered() -> void:
	if interaction_enabled:
		scale = Vector2(1.015, 1.015)


func _on_mouse_exited() -> void:
	scale = Vector2.ONE
