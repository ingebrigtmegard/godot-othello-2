extends Control

# --- UI references ---
@onready var score_label: Label = $ScoreLabel
@onready var turn_label: Label = $TurnLabel
@onready var message_label: Label = $MessageLabel
@onready var restart_button: Button = $RestartButton
@onready var pass_button: Button = $PassButton

# --- Signals ---
signal restart_requested
signal pass_requested

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	restart_button.pressed.connect(_on_restart_pressed)
	pass_button.pressed.connect(_on_pass_pressed)
	restart_button.visible = false
	pass_button.visible = false
	message_label.visible = false

	# Score Label: Centered horizontally above the board (X=400, Y=30)
	score_label.anchors_preset = 0 # TOP_LEFT
	score_label.position = Vector2(300, 30)

	# Turn Label: Centered horizontally below the board (X=400, Y=580)
	turn_label.anchors_preset = 0 # TOP_LEFT
	turn_label.position = Vector2(300, 580)

	# Message Label: Centered horizontally
	message_label.anchors_preset = 0 # TOP_LEFT
	message_label.position = Vector2(300, 300)

	# Restart Button: CENTER
	restart_button.anchors_preset = 14 # CENTER
	restart_button.offset_left = -75
	restart_button.offset_top = -25
	restart_button.offset_right = 75
	restart_button.offset_bottom = 25

	# Pass Button: BOTTOM_RIGHT
	pass_button.anchors_preset = 10 # BOTTOM_RIGHT
	pass_button.offset_left = -80
	pass_button.offset_top = -40
	pass_button.offset_right = -20
	pass_button.offset_bottom = -20
	pass_button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pass_button.grow_vertical = Control.GROW_DIRECTION_BOTH

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
