extends Button

signal cell_pressed(x: int, y: int)
signal flip_finished

const BLACK_PIECE = preload("res://assets/piece_black.png")
const WHITE_PIECE = preload("res://assets/piece_white.png")

var x: int = 0
var y: int = 0
var _is_valid_move: bool = false
var _piece_player: int = 0
var replay_mode: bool = false

@onready var piece_visual: TextureRect = $PieceVisual

func _ready():
	pressed.connect(_on_pressed)
	piece_visual.visible = false
	_piece_player = 0

func _on_pressed():
	if replay_mode:
		return
	cell_pressed.emit(x, y)

func set_piece(player: int, color: Color):
	# Skip if player unchanged
	if player == _piece_player:
		return

	var old_player = _piece_player
	_piece_player = player

	if piece_visual == null:
		return

	# Determine target texture
	var target_tex = WHITE_PIECE if player == GameConstants.WHITE else BLACK_PIECE

	# If no piece was there before, just show it instantly
	if old_player == GameConstants.EMPTY:
		piece_visual.texture = target_tex
		piece_visual.visible = true
		piece_visual.scale = Vector2(1, 1)
		flip_finished.emit()
		return

	# Hide piece if removing
	if player == GameConstants.EMPTY:
		piece_visual.visible = false
		return

	# Flip animation: shrink → swap texture → grow
	if piece_visual.visible:
		piece_visual.visible = true
		var tween = create_tween()

		# Phase 1: shrink to edge-on (100ms)
		tween.tween_property(piece_visual, "scale", Vector2(0.05, 1), 0.1)
		# Swap texture at midpoint
		tween.tween_callback(func(): piece_visual.texture = target_tex)
		# Phase 2: grow back (100ms)
		tween.tween_property(piece_visual, "scale", Vector2(1, 1), 0.1)
		tween.tween_callback(func(): flip_finished.emit())
	else:
		piece_visual.texture = target_tex
		piece_visual.visible = true
		flip_finished.emit()

func set_piece_instantly(player: int):
	_piece_player = player

	if player == GameConstants.EMPTY:
		piece_visual.visible = false
		return

	piece_visual.texture = WHITE_PIECE if player == GameConstants.WHITE else BLACK_PIECE
	piece_visual.visible = true
	piece_visual.scale = Vector2(1, 1)

func set_replay_mode(enabled: bool):
	replay_mode = enabled
	mouse_filter = MOUSE_FILTER_IGNORE if enabled else MOUSE_FILTER_STOP

func set_valid_move(is_valid: bool):
	_is_valid_move = is_valid
	queue_redraw()

func _draw():
	# Valid move indicator only
	if _is_valid_move:
		var s = get_size()
		var center = s / 2.0
		var indicator_radius = s.x * 0.15
		draw_circle(center, indicator_radius, Color(0.0, 1.0, 0.0, 0.3))
		draw_circle(center, indicator_radius, Color(0.0, 1.0, 0.0, 0.5))