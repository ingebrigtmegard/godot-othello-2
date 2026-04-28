extends Control

# --- UI references ---
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var turn_label: Label = $MarginContainer/VBoxContainer/TurnLabel
@onready var message_label: Label = $MarginContainer/VBoxContainer/MessageLabel
@onready var restart_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/RestartButton
@onready var pass_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/PassButton

# --- Signals ---
signal restart_requested
signal pass_requested

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Force container layout for children (deferred to apply after scene load)
	call_deferred("_set_layout_modes")

func _set_layout_modes():
	for child in $MarginContainer/VBoxContainer.get_children():
		child.layout_mode = 3
		for grandchild in child.get_children():
			grandchild.layout_mode = 3
	restart_button.pressed.connect(_on_restart_pressed)
	pass_button.pressed.connect(_on_pass_pressed)
	restart_button.visible = false
	pass_button.visible = false
	message_label.visible = false

func update_scores(black: int, white: int):
	score_label.text = "Black: %d  |  White: %d" % [black, white]

func update_turn(player_name: String):
	turn_label.text = "Turn: %s" % player_name

func show_message(msg: String):
	message_label.text = msg
	message_label.visible = true

func hide_message():
	message_label.visible = false

func set_restart_button_visible(p_visible: bool):
	restart_button.visible = p_visible

func set_pass_button_visible(p_visible: bool):
	pass_button.visible = p_visible

func _on_restart_pressed():
	restart_requested.emit()

func _on_pass_pressed():
	pass_requested.emit()
