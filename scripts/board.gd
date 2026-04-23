extends Control

const GameState = preload("res://scripts/game_state.gd")

# --- Signals ---
signal piece_placed(pos: Vector2i, player: int, flips: Array)
signal valid_moves_changed(moves: Array)
signal move_attempted(x: int, y: int)

# --- Configuration ---
@export var config: GameConfig
@onready var cell_scene = preload("res://scenes/board_cell.tscn")

# --- State ---
var _state: GameState
var cells: Array[Node] = []
var black_color = Color(0.1, 0.1, 0.1)
var white_color = Color(0.95, 0.95, 0.95)
var board_offset := Vector2(160, 60)
var cell_size := 60
var board_size := 8
var _valid_moves_to_draw: Array = [] # For drawing purposes

# For last placed piece indicator
var _last_placed_pos: Vector2i = Vector2i(-1, -1)

func _ready():
	if config:
		board_offset = config.board_offset
		cell_size = config.cell_size
		board_size = config.board_size
		black_color = config.black_color
		white_color = config.white_color

	reset_board()
	_setup_cells()

func _setup_cells():
	# Clear existing cells if any
	for cell in cells:
		cell.queue_free()
	cells.clear()

	for y in board_size:
		for x in board_size:
			var cell = cell_scene.instantiate()
			cell.name = "Cell_%d_%d" % [x, y]
			cell.x = x
			cell.y = y
			cell.position = board_offset + Vector2(x * cell_size, y * cell_size)
			cell.size = Vector2(cell_size, cell_size)
			cell.flat = true # Make it transparent
			cell.mouse_filter = Control.MOUSE_FILTER_STOP
			cell.cell_pressed.connect(_on_cell_pressed)
			add_child(cell)
			cells.append(cell)

func _on_cell_pressed(x: int, y: int):
	move_attempted.emit(x, y)

func reset_board():
	var empty_board = []
	for i in board_size * board_size:
		empty_board.append(GameConstants.EMPTY)
	_state = GameState.new(empty_board, board_size)
	_last_placed_pos = Vector2i(-1, -1)
	_valid_moves_to_draw = []
	valid_moves_changed.emit([])

func get_state() -> GameState:
	return _state

func is_valid_pos(x: int, y: int) -> bool:
	return _state.is_valid_pos(x, y)

func get_cell(x: int, y: int) -> int:
	return _state.get_cell(x, y)

func set_cell(x: int, y: int, val: int):
	_state.set_cell(x, y, val)

func get_valid_moves_for_player(player: int) -> Array:
	return _state.get_valid_moves(player)

func flip_direction(x: int, y: int, dx: int, dy: int, player: int) -> Array:
	# This is still here for backward compatibility if needed,
	# though it's better to use the state's internal logic.
	# For now, we'll implement it using the state's private logic if possible,
	# but since it's private, we'll just re-implement or use a helper.
	# Actually, let's just re-implement it to avoid complex logic.
	var opp: int = GameConstants.WHITE if player == GameConstants.BLACK else GameConstants.BLACK
	var flips: Array = []
	var cx: int = x + dx
	var cy: int = y + dy
	while is_valid_pos(cx, cy) and get_cell(cx, cy) == opp:
		flips.append(Vector2i(cx, cy))
		cx += dx
		cy += dy
	if flips.size() > 0 and is_valid_pos(cx, cy) and get_cell(cx, cy) == player:
		return flips
	return []

func place_piece(x: int, y: int, player: int, flips: Array):
	var move = {"pos": Vector2i(x, y), "flips": flips}
	_state.apply_move(move, player)

	_last_placed_pos = Vector2i(x, y)

	# Update valid moves for the NEXT player
	var next_player = GameConstants.WHITE if player == GameConstants.BLACK else GameConstants.BLACK
	var next_moves = get_valid_moves_for_player(next_player)
	_valid_moves_to_draw = next_moves
	valid_moves_changed.emit(next_moves)

	piece_placed.emit(Vector2i(x, y), player, flips)
	queue_redraw()

func update_valid_moves_for_drawing(moves: Array):
	_valid_moves_to_draw = moves
	queue_redraw()

func get_score() -> Dictionary:
	return _state.get_score()

func _draw():
	# Background
	var bg_color = Color(0.1, 0.35, 0.15)
	draw_rect(Rect2(Vector2.ZERO, get_size()), bg_color)

	# Grid lines
	var grid_color = Color(0.05, 0.2, 0.05)
	for i in board_size + 1:
		var start = board_offset + Vector2(i * cell_size, 0)
		var end = board_offset + Vector2(i * cell_size, board_size * cell_size)
		draw_line(start, end, grid_color, 1.0)
		start = board_offset + Vector2(0, i * cell_size)
		end = board_offset + Vector2(board_size * cell_size, i * cell_size)
		draw_line(start, end, grid_color, 1.0)

	# Valid moves
	for m in _valid_moves_to_draw:
		var center = board_offset + Vector2(m.pos.x * cell_size + cell_size / 2.0, m.pos.y * cell_size + cell_size / 2.0)
		draw_circle(center, cell_size * 0.35, Color(0.0, 1.0, 0.0, 0.25))

	# Pieces
	for y in board_size:
		for x in board_size:
			var cell = get_cell(x, y)
			if cell == GameConstants.EMPTY: continue
			var center = board_offset + Vector2(x * cell_size + cell_size / 2.0, y * cell_size + cell_size / 2.0)
			var color = black_color if cell == GameConstants.BLACK else white_color
			draw_circle(center, cell_size * 0.42, color)
			draw_arc(center, cell_size * 0.42, 0, TAU, 32, Color.BLACK, 2.0, true)

	# Last placed indicator
	if _last_placed_pos.x >= 0:
		var lp = _last_placed_pos
		var center = board_offset + Vector2(lp.x * cell_size + cell_size / 2.0, lp.y * cell_size + cell_size / 2.0)
		draw_circle(center, cell_size * 0.48, Color(1.0, 0.2, 0.2, 0.6))
