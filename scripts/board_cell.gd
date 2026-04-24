extends Button

signal cell_pressed(x: int, y: int)

var x: int = 0
var y: int = 0
var _is_valid_move: bool = false

@onready var piece_visual = $PieceVisual

func _ready():
	pressed.connect(_on_pressed)
	if piece_visual:
		piece_visual.visible = false

func _on_pressed():
	cell_pressed.emit(x, y)

func set_piece(player: int, color: Color):
	if piece_visual:
		if player == 0:
			piece_visual.visible = false
		else:
			piece_visual.color = color
			piece_visual.visible = true

func set_valid_move(is_valid: bool):
	_is_valid_move = is_valid
	queue_redraw()

func _draw():
	if _is_valid_move:
		var s = get_size()
		var radius = s.x * 0.35
		draw_circle(s / 2.0, radius, Color(0.0, 1.0, 0.0, 0.25))
