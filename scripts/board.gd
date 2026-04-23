extends Control

# --- Signals ---
signal piece_placed(pos: Vector2i, player: int, flips: Array)
signal valid_moves_changed(moves: Array)
signal move_attempted(x: int, y: int)

# --- Configuration ---
@export var config: GameConfig

# --- State ---
var board: Array = []
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

func reset_board():
	board = []
	for i in board_size * board_size:
		board.append(GameConstants.EMPTY) # EMPTY
	_last_placed_pos = Vector2i(-1, -1)
	_valid_moves_to_draw = []
	valid_moves_changed.emit([])

func is_valid_pos(x: int, y: int) -> bool:
	return x >= 0 and x < board_size and y >= 0 and y < board_size

func get_cell(x: int, y: int) -> int:
	if not is_valid_pos(x, y):
		return -1
	return board[y * board_size + x]

func set_cell(x: int, y: int, val: int):
	if is_valid_pos(x, y):
		board[y * board_size + x] = val

func get_valid_moves_for_player(player: int) -> Array:
	var moves: Array = []
	for y in board_size:
		for x in board_size:
			if get_cell(x, y) != GameConstants.EMPTY:
				continue
			var dirs: Array = [Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1),
								   Vector2i(-1,0),             Vector2i(1,0),
								   Vector2i(-1,1),  Vector2i(0,1), Vector2i(1,1)]
			var flips: Array = []
			for dir in dirs:
				var result = flip_direction(x, y, dir.x, dir.y, player)
				if result.size() > 0:
					flips.append_array(result)
			if flips.size() > 0:
				moves.append({"pos": Vector2i(x, y), "flips": flips})
	return moves

func flip_direction(x: int, y: int, dx: int, dy: int, player: int) -> Array:
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
	set_cell(x, y, player)
	for f in flips:
		set_cell(f.x, f.y, player)

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
	var black = 0
	var white = 0
	for i in board.size():
		if board[i] == GameConstants.BLACK:
			black += 1
		elif board[i] == GameConstants.WHITE:
			white += 1
	return {"black": black, "white": white}

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = event.position
		var board_pos = mouse_pos - board_offset
		var x = int(board_pos.x / cell_size)
		var y = int(board_pos.y / cell_size)

		if is_valid_pos(x, y):
			move_attempted.emit(x, y)

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
		draw_circle(center, cell_size * 0.35, Color(1.0, 1.0, 0.0, 0.25))

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
