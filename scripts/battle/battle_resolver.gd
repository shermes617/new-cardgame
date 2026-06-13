class_name BattleResolver
extends RefCounted


static func resolve_skill(
	state: RefCounted, database: RefCounted, event: RefCounted, deck_manager: RefCounted,
	energy_manager: RefCounted
) -> void:
	var actor: RefCounted = state.get_unit(event.unit_id)
	if actor == null or not actor.is_alive():
		return
	if event.card_id == "basic_attack":
		_resolve_damage(state, actor, event.target_ids, 1.0)
		energy_manager.gain(1)
		return
	if event.card_id == "enemy_basic_attack":
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
			"heal":
				_resolve_heal(state, actor, event.target_ids, float(effect["rate"]))
			"draw_card":
				deck_manager.draw_cards(int(effect["amount"]))
			"delayed_energy":
				energy_manager.schedule_delayed_gain(
					state.current_time + float(effect["delay"]), int(effect["amount"]), card.id
				)
			"damage_to_shield":
				_resolve_damage_to_shield(state, actor, event.target_ids, float(effect["rate"]))
	deck_manager.discard_card(card.id)


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


static func _resolve_heal(
	state: RefCounted, actor: RefCounted, target_ids: Array[String], rate: float
) -> void:
	var amount := roundi(actor.will * rate)
	for target_id in target_ids:
		var target: RefCounted = state.get_unit(target_id)
		if target != null and target.is_alive():
			target.heal(amount)


static func _resolve_damage_to_shield(
	state: RefCounted, actor: RefCounted, target_ids: Array[String], rate: float
) -> void:
	var amount := roundi(actor.strength * rate)
	var health_damage := 0
	for target_id in target_ids:
		var target: RefCounted = state.get_unit(target_id)
		if target != null and target.is_alive():
			health_damage += target.take_damage(amount)
	actor.add_shield(health_damage)
