extends PanelContainer

signal basic_attack_pressed
signal cancel_pressed

@onready var actor_label: Label = %ActorLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var request_label: Label = %RequestLabel
@onready var basic_attack_button: Button = %BasicAttackButton
@onready var cancel_button: Button = %CancelButton


func _ready() -> void:
	basic_attack_button.pressed.connect(basic_attack_pressed.emit)
	cancel_button.pressed.connect(cancel_pressed.emit)


func display_state(
	actor_name: String,
	selected_action_name: String,
	has_selection: bool,
	request_text: String,
	has_actor: bool
) -> void:
	actor_label.text = (
		"%s: %s" % [tr("UI_CURRENT_ACTOR"), actor_name] if has_actor else tr("UI_CHOOSE_ACTOR")
	)
	if request_text.is_empty():
		instruction_label.text = (
			"%s: %s" % [tr("UI_SELECTED_ACTION"), selected_action_name]
			if has_selection
			else (tr("UI_CHOOSE_ACTION") if has_actor else tr("UI_CHOOSE_ACTOR_HINT"))
		)
		request_label.text = ""
	else:
		instruction_label.text = tr("UI_ACTION_REQUEST_READY")
		request_label.text = request_text
	cancel_button.disabled = not has_selection and request_text.is_empty()
	basic_attack_button.disabled = not has_actor
