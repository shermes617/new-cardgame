class_name EventQueue
extends RefCounted

var events: Array[RefCounted] = []
var next_creation_order: int = 0


func add_event(event: RefCounted) -> void:
	if event.id.is_empty():
		event.id = "event_%04d" % next_creation_order
	event.creation_order = next_creation_order
	next_creation_order += 1
	events.append(event)
	events.sort_custom(_comes_before)


func peek_next_time() -> float:
	return -1.0 if events.is_empty() else events[0].time


func pop_next_event() -> RefCounted:
	return null if events.is_empty() else events.pop_front()


func get_events_at_time(time: float, event_type: String = "", side: String = "") -> Array[RefCounted]:
	var result: Array[RefCounted] = []
	for event in events:
		if not is_equal_approx(event.time, time):
			continue
		if not event_type.is_empty() and event.event_type != event_type:
			continue
		if not side.is_empty() and event.side != side:
			continue
		result.append(event)
	return result


func remove_event(event: RefCounted) -> void:
	events.erase(event)


func cancel_unit_events(unit_id: String) -> void:
	for index in range(events.size() - 1, -1, -1):
		if events[index].unit_id == unit_id:
			events.remove_at(index)


func _comes_before(a: RefCounted, b: RefCounted) -> bool:
	if not is_equal_approx(a.time, b.time):
		return a.time < b.time
	if a.get_priority() != b.get_priority():
		return a.get_priority() < b.get_priority()
	return a.creation_order < b.creation_order
