class_name EnemyAI
extends RefCounted

const ActionRequestScript := preload("res://scripts/battle/action_request.gd")


static func create_request(state: RefCounted, enemy: RefCounted) -> RefCounted:
	var targets: Array[RefCounted] = []
	for ally in state.allies:
		if ally.is_alive():
			targets.append(ally)
	if targets.is_empty():
		return null

	var target: RefCounted
	match enemy.ai_profile:
		"lowest_hp":
			target = _get_lowest_hp_target(targets)
		"front":
			target = _get_front_target(targets)
		_:
			target = targets[randi() % targets.size()]
	return ActionRequestScript.new(enemy.id, "enemy_basic_attack", "", [target.id])


static func _get_lowest_hp_target(targets: Array[RefCounted]) -> RefCounted:
	var result: RefCounted = targets[0]
	for target in targets:
		if target.hp < result.hp:
			result = target
	return result


static func _get_front_target(targets: Array[RefCounted]) -> RefCounted:
	var result: RefCounted = targets[0]
	for target in targets:
		if target.position < result.position:
			result = target
	return result
