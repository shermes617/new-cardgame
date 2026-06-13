class_name ActionRequest
extends RefCounted

var actor_id: String
var action_type: String
var card_id: String
var card_instance_id: String
var target_ids: Array[String] = []


func _init(
	p_actor_id: String,
	p_action_type: String,
	p_card_id: String = "",
	p_target_ids: Array[String] = [],
	p_card_instance_id: String = ""
) -> void:
	actor_id = p_actor_id
	action_type = p_action_type
	card_id = p_card_id
	card_instance_id = p_card_instance_id
	target_ids.assign(p_target_ids)


func describe() -> String:
	return "%s:%s:%s:%s" % [actor_id, action_type, card_id, ",".join(target_ids)]
