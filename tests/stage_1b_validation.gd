extends SceneTree

const BattleScene := preload("res://scenes/battle/battle_scene.tscn")


func _init() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var scene: Control = BattleScene.instantiate()
	root.add_child(scene)
	await process_frame

	assert(scene.get_node("%AllyContainer").get_child_count() == 4, "Stage 1B: expected 4 allies")
	assert(scene.get_node("%EnemyContainer").get_child_count() == 4, "Stage 1B: expected 4 enemies")
	assert(
		scene.get_node("%AllyContainer").get_child(0).unit_id == "lia",
		"Stage 1B: ally position 4 should be leftmost"
	)
	assert(
		scene.get_node("%AllyContainer").get_child(3).unit_id == "arthur",
		"Stage 1B: ally position 1 should be nearest the center"
	)
	assert(scene.get_node("%HandContainer").get_child_count() == 5, "Stage 1B: expected 5 cards")
	assert(scene.get_node("%DrawPileCount").text == "5", "Stage 1B: expected 5 cards in draw pile")
	assert(scene.get_node("%DiscardPileCount").text == "0", "Stage 1B: expected empty discard pile")
	assert(scene.get_node("%EnergyLabel").text == "3 / 10", "Stage 1B: expected initial energy")
	assert(not scene.get_node("%HandResetButton").disabled, "Stage 1B: reset button should initially be enabled")
	assert(scene.get_node("%TimelinePanel") != null, "Stage 1B: expected timeline panel")
	assert(
		scene.get_node("EndOverlay").mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"Stage 1B: hidden end overlay must not block battle input"
	)
	var marker_layer: Control = scene.get_node("%TimelinePanel").get_node("%MarkerLayer")
	assert(marker_layer.get_child_count() == 9, "Stage 1B: expected action and energy markers")

	print("Stage 1B validation passed")
	quit()
