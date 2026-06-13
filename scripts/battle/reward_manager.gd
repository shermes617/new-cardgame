class_name RewardManager
extends RefCounted

var database: RefCounted
var rng := RandomNumberGenerator.new()


func _init(p_database: RefCounted, seed: int = -1) -> void:
	database = p_database
	if seed >= 0:
		rng.seed = seed
	else:
		rng.randomize()


func generate_rewards(amount: int = 3) -> Array[String]:
	var pool: Array[String] = database.get_card_ids_by_category("common")
	var rewards: Array[String] = []
	while not pool.is_empty() and rewards.size() < amount:
		var index := rng.randi_range(0, pool.size() - 1)
		rewards.append(pool.pop_at(index))
	return rewards
