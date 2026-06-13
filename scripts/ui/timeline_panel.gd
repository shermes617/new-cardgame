extends PanelContainer

const TimelineEventScene := preload("res://scenes/battle/timeline_event.tscn")
const DISPLAY_RANGE := 20.0

@onready var current_time_value: Label = %CurrentTimeValue
@onready var ruler: Control = %Ruler
@onready var marker_layer: Control = %MarkerLayer


func display_timeline(current_time: float, events: Array, database: RefCounted) -> void:
	current_time_value.text = "%.1f" % current_time
	await get_tree().process_frame
	_clear_markers()

	var displayed_events: Array = []
	for event in events:
		if event.event_type in ["unit_action", "skill_execute", "gain_energy", "hand_reset_refresh"]:
			displayed_events.append(event)
	var total_events := displayed_events.size()
	var event_index := 0
	for event in displayed_events:
		_add_marker(event, current_time, event_index, total_events, database)
		event_index += 1


func _add_marker(
	event: RefCounted, current_time: float, index: int, total_events: int, database: RefCounted
) -> void:
	var marker: Control = TimelineEventScene.instantiate()
	marker_layer.add_child(marker)
	var display_time: float = event.time
	var visible_end := maxf(DISPLAY_RANGE, current_time + DISPLAY_RANGE)
	var normalized := clampf(display_time / visible_end, 0.0, 1.0)
	marker.position = Vector2(normalized * maxf(0.0, ruler.size.x - marker.size.x), 0.0)
	var name_key := ""
	if event.event_type == "gain_energy":
		name_key = "UI_GAIN_ENERGY_EVENT"
	elif event.event_type == "hand_reset_refresh":
		name_key = "UI_HAND_RESET_REFRESH_EVENT"
	else:
		var definition: Dictionary = database.get_unit_definition(event.unit_id)
		name_key = definition.get("name_key", event.unit_id)
	marker.call("display_event", event, display_time, name_key)


func _clear_markers() -> void:
	for child in marker_layer.get_children():
		child.queue_free()
