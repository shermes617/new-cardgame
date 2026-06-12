extends SceneTree

const GameDatabaseScript := preload("res://scripts/data/game_database.gd")
const BattleStateScript := preload("res://scripts/models/battle_state.gd")


func _init() -> void:
	var database: RefCounted = GameDatabaseScript.new()
	assert(database.load_all(), "Stage 1A: database validation failed")
	assert(database.units_by_id.size() == 8, "Stage 1A: expected 8 units")
	assert(database.cards_by_id.size() == 12, "Stage 1A: expected 12 cards")
	assert(database.starter_deck_ids.size() == 10, "Stage 1A: expected a 10-card starter deck")
	assert(
		is_equal_approx(database.get_card("quick_strike").get_actual_overload(5), 1.0),
		"Stage 1A: actual overload calculation is incorrect"
	)

	var first_battle: RefCounted = BattleStateScript.new()
	first_battle.initialize(database)
	first_battle.get_unit("arthur").take_damage(13)
	var inherited_hp: Dictionary = first_battle.export_ally_hp()

	var next_battle: RefCounted = BattleStateScript.new()
	next_battle.initialize(database, inherited_hp)
	assert(next_battle.get_unit("arthur").hp == 17, "Stage 1A: ally HP was not inherited")
	assert(next_battle.get_unit("rift_bug").hp == 18, "Stage 1A: enemy HP should reset")
	assert(next_battle.get_unit("arthur").shield == 0, "Stage 1A: ally shield should reset")

	print("Stage 1A validation passed")
	quit()
