extends VBoxContainer

@onready var icon_label: Label = %IconLabel
@onready var name_label: Label = %NameLabel
@onready var time_label: Label = %TimeLabel


func display_event(event: RefCounted, display_time: float, name_key: String) -> void:
	if event.event_type == "gain_energy":
		icon_label.text = "E"
		icon_label.modulate = Color(0.42, 0.76, 1.0)
		name_label.modulate = Color(0.62, 0.82, 1.0)
	elif event.event_type == "hand_reset_refresh":
		icon_label.text = "R"
		icon_label.modulate = Color(0.45, 0.9, 0.65)
		name_label.modulate = Color(0.65, 0.9, 0.75)
	else:
		var is_ally: bool = event.side == "ally"
		icon_label.text = "A" if event.event_type == "unit_action" else "S"
		icon_label.modulate = Color(0.35, 0.72, 1.0) if is_ally else Color(1.0, 0.42, 0.34)
		name_label.modulate = Color(0.65, 0.82, 1.0) if is_ally else Color(1.0, 0.67, 0.6)
	name_label.text = tr(name_key)
	time_label.text = "%.1f" % display_time
