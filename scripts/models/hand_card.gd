class_name HandCard
extends RefCounted

var instance_id: String
var card_id: String
var draw_time: float


func _init(p_instance_id: String, p_card_id: String, p_draw_time: float) -> void:
	instance_id = p_instance_id
	card_id = p_card_id
	draw_time = snappedf(p_draw_time, 0.1)
