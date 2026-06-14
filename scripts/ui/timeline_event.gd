extends Control

const ALLY_COLOR := Color(0.42, 0.75, 1.0)
const ENEMY_COLOR := Color(1.0, 0.42, 0.34)
const RESOURCE_COLOR := Color(0.45, 0.9, 0.65)

@onready var portrait_frame: PanelContainer = %PortraitFrame
@onready var portrait: TextureRect = %Portrait
@onready var icon_label: Label = %IconLabel
@onready var time_label: Label = %TimeLabel


func display_event(
	event: RefCounted, display_time: float, name_key: String, portrait_path: String
) -> void:
	var accent_color: Color = ALLY_COLOR if event.side == "ally" else ENEMY_COLOR
	if event.event_type == "gain_energy":
		accent_color = ALLY_COLOR
		icon_label.text = "E"
	elif event.event_type == "hand_reset_refresh":
		accent_color = RESOURCE_COLOR
		icon_label.text = "R"
	elif event.event_type == "skill_execute":
		icon_label.text = "S"
	else:
		icon_label.text = "A"

	portrait_frame.modulate = accent_color
	icon_label.modulate = accent_color
	if portrait_path.is_empty():
		portrait.texture = null
		portrait_frame.self_modulate = Color(0.25, 0.3, 0.38, 1)
	else:
		portrait.texture = load(portrait_path)
		portrait_frame.self_modulate = Color.WHITE
	time_label.text = "%.1f" % display_time
	tooltip_text = "%s  %.1f" % [tr(name_key), display_time]

