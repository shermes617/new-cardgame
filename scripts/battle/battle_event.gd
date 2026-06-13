class_name BattleEvent
extends RefCounted

var id: String
var time: float
var event_type: String
var side: String
var unit_id: String
var card_id: String
var card_instance_id: String
var amount: int
var target_ids: Array[String] = []
var creation_order: int


func _init(
	p_id: String,
	p_time: float,
	p_event_type: String,
	p_side: String = "",
	p_unit_id: String = "",
	p_card_id: String = "",
	p_target_ids: Array[String] = [],
	p_creation_order: int = 0,
	p_card_instance_id: String = "",
	p_amount: int = 0
) -> void:
	id = p_id
	time = snappedf(p_time, 0.1)
	event_type = p_event_type
	side = p_side
	unit_id = p_unit_id
	card_id = p_card_id
	card_instance_id = p_card_instance_id
	amount = p_amount
	target_ids.assign(p_target_ids)
	creation_order = p_creation_order


func get_priority() -> int:
	match event_type:
		"skill_execute":
			return 1 if side == "ally" else 2
		"gain_energy", "hand_reset_refresh":
			return 4
		"unit_action":
			return 5 if side == "ally" else 6
		_:
			return 7
