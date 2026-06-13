class_name EnergyManager
extends RefCounted

const BattleEventScript := preload("res://scripts/battle/battle_event.gd")

const AUTO_ENERGY_SOURCE := "auto_energy"

var state: RefCounted
var event_queue: RefCounted


func _init(p_state: RefCounted, p_event_queue: RefCounted) -> void:
	state = p_state
	event_queue = p_event_queue


func initialize_events() -> void:
	schedule_auto_gain(state.current_time)


func gain(amount: int) -> int:
	var previous_energy: int = state.energy
	state.energy = clampi(state.energy + maxi(0, amount), 0, int(state.config["energy_max"]))
	return state.energy - previous_energy


func spend(amount: int) -> bool:
	var cost := maxi(0, amount)
	if state.energy < cost:
		return false
	state.energy -= cost
	return true


func schedule_delayed_gain(time: float, amount: int, source_id: String = "") -> void:
	event_queue.add_event(
		BattleEventScript.new("", time, "gain_energy", "", "", source_id, [], 0, "", amount)
	)


func resolve_gain_event(event: RefCounted) -> void:
	gain(event.amount)
	if event.card_id == AUTO_ENERGY_SOURCE:
		schedule_auto_gain(event.time)


func schedule_auto_gain(from_time: float) -> void:
	var gain_time := snappedf(from_time + float(state.config["energy_recovery_interval"]), 0.1)
	schedule_delayed_gain(gain_time, 1, AUTO_ENERGY_SOURCE)
