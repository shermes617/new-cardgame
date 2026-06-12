class_name UnitState
extends RefCounted

var id: String
var name_key: String
var role_key: String
var side: String
var position: int
var strength: int
var will: int
var max_hp: int
var hp: int
var speed: int = 0
var action_interval: float = 0.0
var shield: int = 0
var next_action_time: float = 0.0
var portrait_path: String
var ai_profile: String


func _init(definition: Dictionary, inherited_hp: int = -1) -> void:
	id = definition["id"]
	name_key = definition["name_key"]
	role_key = definition.get("job_key", definition.get("type_key", ""))
	side = definition["side"]
	position = int(definition["position"])
	strength = int(definition["strength"])
	will = int(definition["will"])
	max_hp = int(definition["max_hp"])
	hp = max_hp if inherited_hp < 0 else clampi(inherited_hp, 0, max_hp)
	speed = int(definition.get("speed", 0))
	action_interval = float(definition.get("action_interval", 0.0))
	portrait_path = definition["portrait_path"]
	ai_profile = definition.get("ai_profile", "")


func is_alive() -> bool:
	return hp > 0


func clear_shield() -> void:
	shield = 0


func add_shield(amount: int) -> void:
	shield += maxi(0, amount)


func heal(amount: int) -> int:
	var previous_hp := hp
	hp = mini(max_hp, hp + maxi(0, amount))
	return hp - previous_hp


func take_damage(amount: int) -> int:
	var remaining_damage := maxi(0, amount)
	var absorbed := mini(shield, remaining_damage)
	shield -= absorbed
	remaining_damage -= absorbed
	var previous_hp := hp
	hp = maxi(0, hp - remaining_damage)
	return previous_hp - hp
