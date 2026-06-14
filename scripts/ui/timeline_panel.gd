extends PanelContainer

const TimelineEventScene := preload("res://scenes/battle/timeline_event.tscn")
const DISPLAY_RANGE := 20.0
const LANE_Y: Array[float] = [19.0, 52.0]
const MARKER_WIDTH := 48.0
const MARKER_GAP := 3.0

@onready var current_time_value: Label = %CurrentTimeValue
@onready var ruler: Control = %Ruler
@onready var marker_layer: Control = %MarkerLayer
@onready var tick_labels: Array[Label] = [%Tick0, %Tick5, %Tick10, %Tick15, %Tick20]


func display_timeline(current_time: float, events: Array, database: RefCounted) -> void:
	current_time_value.text = "%.1f" % current_time
	for index in tick_labels.size():
		tick_labels[index].text = "%.0f" % (current_time + float(index) * 5.0)
	await get_tree().process_frame
	_clear_markers()

	var displayed_events: Array = []
	for event in events:
		if event.event_type in ["unit_action", "skill_execute", "gain_energy", "hand_reset_refresh"]:
			displayed_events.append(event)
	var lane_ends: Array[float] = [-1000.0, -1000.0]
	for event in displayed_events:
		_add_marker(event, current_time, lane_ends, database)


func _add_marker(
	event: RefCounted, current_time: float, lane_ends: Array[float], database: RefCounted
) -> void:
	var marker: Control = TimelineEventScene.instantiate()
	marker_layer.add_child(marker)
	var display_time: float = event.time
	var normalized := clampf((display_time - current_time) / DISPLAY_RANGE, 0.0, 1.0)
	var marker_x := normalized * maxf(0.0, ruler.size.x - MARKER_WIDTH)
	var lane_index := _choose_lane(marker_x, lane_ends)
	if marker_x < lane_ends[lane_index]:
		marker_x = lane_ends[lane_index]
	lane_ends[lane_index] = marker_x + MARKER_WIDTH + MARKER_GAP
	marker.position = Vector2(marker_x, LANE_Y[lane_index])
	var name_key := ""
	var portrait_path := ""
	if event.event_type == "gain_energy":
		name_key = "UI_GAIN_ENERGY_EVENT"
	elif event.event_type == "hand_reset_refresh":
		name_key = "UI_HAND_RESET_REFRESH_EVENT"
	else:
		var definition: Dictionary = database.get_unit_definition(event.unit_id)
		name_key = definition.get("name_key", event.unit_id)
		portrait_path = definition.get("portrait_path", "")
	marker.call("display_event", event, display_time, name_key, portrait_path)


func _choose_lane(marker_x: float, lane_ends: Array[float]) -> int:
	for index in lane_ends.size():
		if marker_x >= lane_ends[index]:
			return index
	return 0 if lane_ends[0] <= lane_ends[1] else 1


func _clear_markers() -> void:
	for child in marker_layer.get_children():
		child.queue_free()
