extends Container

const CARD_SIZE := Vector2(112.0, 149.0)
const MAX_SPREAD_WIDTH := 880.0
const MAX_ROTATION := 8.0
const ARC_HEIGHT := 24.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_layout_cards()


func refresh_layout() -> void:
	queue_sort()


func _layout_cards() -> void:
	var cards: Array[Control] = []
	for child in get_children():
		if child is Control and child.visible:
			cards.append(child)
	var card_count := cards.size()
	if card_count == 0:
		return

	var spread_width := minf(MAX_SPREAD_WIDTH, maxf(CARD_SIZE.x, size.x - CARD_SIZE.x))
	var spacing := 0.0 if card_count == 1 else minf(
		CARD_SIZE.x * 0.82,
		spread_width / float(card_count - 1)
	)
	var total_width := CARD_SIZE.x + spacing * float(card_count - 1)
	var start_x := (size.x - total_width) * 0.5
	var base_y := size.y - CARD_SIZE.y - 2.0

	for index in card_count:
		var card := cards[index]
		var normalized := 0.0 if card_count == 1 else (
			float(index) / float(card_count - 1) * 2.0 - 1.0
		)
		var arc_offset := ARC_HEIGHT * normalized * normalized
		var target_position := Vector2(start_x + spacing * index, base_y + arc_offset)
		var target_rotation := deg_to_rad(MAX_ROTATION * normalized)
		card.call("set_fan_transform", target_position, target_rotation, index)
