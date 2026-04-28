extends Button

signal cell_pressed(x: int, y: int)
signal flip_finished

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
var _is_flipping: bool = false
var _flip_progress: float = 0.0
var _old_color: Color = Color(1, 1, 1, 1)
var _new_color: Color = Color(1, 1, 1, 1)
var _flip_tween: Tween

func set_piece(player: int, color: Color):
	_piece_player = player

	# Skip if color unchanged
	if color == _piece_color and not _is_flipping:
		return
	if color == _piece_color:
		return

	# Cancel any in-progress animation
	if _is_flipping and _flip_tween and is_instance_valid(_flip_tween):
		_flip_tween.kill()

	_old_color = _piece_color
	_new_color = color
	_is_flipping = true
	_flip_progress = 0.0

	_flip_tween = create_tween()
	_flip_tween.tween_method(_on_flip_tick, 0.0, 1.0, 0.2)
	_flip_tween.tween_callback(_on_flip_complete)

func _on_flip_tick(progress: float):
	_flip_progress = progress
	queue_redraw()

func _on_flip_complete():
	_is_flipping = false
	_piece_color = _new_color
	_flip_progress = 0.0
	queue_redraw()
	flip_finished.emit()

func set_valid_move(is_valid: bool):
	_is_valid_move = is_valid
	queue_redraw()

func _draw():
	var s = get_size()
	var center = s / 2.0
	var piece_radius = s.x * 0.4

	# Draw round piece
	if _piece_player != 0:
		var draw_color: Color
		var draw_radius: float

		if _is_flipping:
			# 3D rotation effect: circle shrinks to edge-on, then grows
			var scale = abs(sin(_flip_progress * 3.14159))
			draw_radius = piece_radius * scale
			# Color transitions from old to new
			draw_color = _old_color.lerp(_new_color, _flip_progress)
		else:
			draw_radius = piece_radius
			draw_color = _piece_color

		if draw_radius > 0.5:
			# Draw shadow
			draw_circle(center + Vector2(2, 2), draw_radius, Color(0, 0, 0, 0.3))
			# Draw main piece
			draw_circle(center, draw_radius, draw_color)

	# Draw valid move indicator (smaller translucent dot)
	if _is_valid_move:
		var indicator_radius = s.x * 0.15
		draw_circle(center, indicator_radius, Color(0.0, 1.0, 0.0, 0.3))
		draw_circle(center, indicator_radius, Color(0.0, 1.0, 0.0, 0.5))
