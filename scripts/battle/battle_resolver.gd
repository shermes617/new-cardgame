class_name BattleResolver
extends RefCounted


static func resolve_skill(state: RefCounted, database: RefCounted, event: RefCounted) -> void:
	var actor: RefCounted = state.get_unit(event.unit_id)
	if actor == null or not actor.is_alive():
		return
	if event.card_id == "basic_attack" or event.card_id == "enemy_basic_attack":
		_resolve_damage(state, actor, event.target_ids, 1.0)
		return

	var card: RefCounted = database.get_card(event.card_id)
	if card == null:
		return
	for effect in card.effects:
		match effect["effect_type"]:
			"damage":
				_resolve_damage(state, actor, event.target_ids, float(effect["rate"]))
			"shield":
				_resolve_shield(state, actor, event.target_ids, float(effect["rate"]))


static func _resolve_damage(
	state: RefCounted, actor: RefCounted, target_ids: Array[String], rate: float
) -> void:
	var amount := roundi(actor.strength * rate)
	for target_id in target_ids:
		var target: RefCounted = state.get_unit(target_id)
		if target != null and target.is_alive():
			target.take_damage(amount)


static func _resolve_shield(
	state: RefCounted, actor: RefCounted, target_ids: Array[String], rate: float
) -> void:
	var amount := roundi(actor.will * rate)
	for target_id in target_ids:
		var target: RefCounted = state.get_unit(target_id)
		if target != null and target.is_alive():
			target.add_shield(amount)
