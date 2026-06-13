extends PanelContainer

signal reward_selected(card_id: String)
signal restart_requested

@onready var title_label: Label = %TitleLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var run_progress_label: Label = %RunProgressLabel
@onready var reward_buttons: Array[Button] = [%RewardButton1, %RewardButton2, %RewardButton3]
@onready var restart_button: Button = %RestartButton

var reward_ids: Array[String] = []


func _ready() -> void:
	for index in reward_buttons.size():
		reward_buttons[index].pressed.connect(_on_reward_pressed.bind(index))
	restart_button.pressed.connect(restart_requested.emit)


func show_victory(rewards: Array[String], database: RefCounted, completed_battles: int, deck_size: int) -> void:
	get_parent().mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true
	title_label.text = tr("UI_VICTORY")
	instruction_label.text = tr("UI_CHOOSE_REWARD")
	_display_run_progress(completed_battles, deck_size)
	reward_ids.assign(rewards)
	restart_button.visible = false
	for index in reward_buttons.size():
		var has_reward := index < reward_ids.size()
		reward_buttons[index].visible = has_reward
		if has_reward:
			var card: RefCounted = database.get_card(reward_ids[index])
			reward_buttons[index].text = "%s\n%s: %d\n%s" % [
				tr(card.name_key), tr("UI_COST"), card.cost, tr(card.description_key)
			]


func show_defeat(completed_battles: int, deck_size: int) -> void:
	get_parent().mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true
	title_label.text = tr("UI_DEFEAT")
	instruction_label.text = tr("UI_DEFEAT_HINT")
	_display_run_progress(completed_battles, deck_size)
	reward_ids.clear()
	for button in reward_buttons:
		button.visible = false
	restart_button.visible = true
	restart_button.text = tr("UI_RESTART_RUN")


func hide_panel() -> void:
	visible = false
	get_parent().mouse_filter = Control.MOUSE_FILTER_IGNORE


func _display_run_progress(completed_battles: int, deck_size: int) -> void:
	run_progress_label.text = "%s: %d    %s: %d" % [
		tr("UI_COMPLETED_BATTLES"), completed_battles, tr("UI_DECK_SIZE"), deck_size
	]


func _on_reward_pressed(index: int) -> void:
	if index < reward_ids.size():
		reward_selected.emit(reward_ids[index])
