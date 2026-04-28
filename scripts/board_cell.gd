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
	_piece_player = 0

func _on_pressed():
	cell_pressed.emit(x, y)

var _piece_player: int = 0
var _piece_color: Color = Color(1, 1, 1, 1)

func set_piece(player: int, color: Color):
	_piece_player = player
	_piece_color = color
	queue_redraw()

func set_valid_move(is_valid: bool):
	_is_valid_move = is_valid
	queue_redraw()

func _draw():
	var s = get_size()
	var center = s / 2.0
	var piece_radius = s.x * 0.4

	# Draw round piece
	if _piece_player != 0:
		var margin = s.x * 0.08
		# Draw shadow for depth
		draw_circle(center + Vector2(2, 2), piece_radius, Color(0, 0, 0, 0.3))
		# Draw main piece
		draw_circle(center, piece_radius, _piece_color)

	# Draw valid move indicator (smaller translucent dot)
	if _is_valid_move:
		var indicator_radius = s.x * 0.15
		draw_circle(center, indicator_radius, Color(0.0, 1.0, 0.0, 0.3))
		draw_circle(center, indicator_radius, Color(0.0, 1.0, 0.0, 0.5))
