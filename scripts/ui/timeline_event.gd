extends VBoxContainer

@onready var icon_label: Label = %IconLabel
@onready var name_label: Label = %NameLabel
@onready var time_label: Label = %TimeLabel


func display_event(event: RefCounted, display_time: float, name_key: String) -> void:
	var is_ally: bool = event.side == "ally"
	icon_label.text = ("◇" if event.event_type == "unit_action" else "□") if is_ally else ("◆" if event.event_type == "unit_action" else "■")
	icon_label.modulate = Color(0.35, 0.72, 1.0) if is_ally else Color(1.0, 0.42, 0.34)
	name_label.text = tr(name_key)
	name_label.modulate = Color(0.65, 0.82, 1.0) if is_ally else Color(1.0, 0.67, 0.6)
	time_label.text = "%.1f" % display_time
