extends Control

# --- Signals ---
signal piece_placed(pos: Vector2i, player: int, flips: Array)
signal valid_moves_changed(moves: Array)
signal move_attempted(x: int, y: int)
signal animations_complete

# --- Configuration ---
@export var config: GameConfig
@onready var cell_scene = preload("res://scenes/board_cell.tscn")

# --- State ---
var _state: RefCounted
var cells: Array = []
var black_color = Color(0.1, 0.1, 0.1)
var white_color = Color(0.95, 0.95, 0.95)
var board_bg_color = Color(0.1, 0.35, 0.15)
var grid_color = Color(0.05, 0.2, 0.05)
var board_offset := Vector2(160, 60)
var cell_size := 60
var board_size := 8

# For last placed piece indicator
var _last_placed_pos: Vector2i = Vector2i(-1, -1)

# For tracking animation completion
var _pending_animations: Array = []
var _animations_done_count: int = 0
var _placement_deferred_data: Dictionary = {}

# Replay mode
var replay_mode: bool = false

func _ready():
	if config:
		board_offset = config.board_offset
		cell_size = config.cell_size
		board_size = config.board_size
		black_color = config.black_color
		white_color = config.white_color
		board_bg_color = config.board_bg_color
		grid_color = config.grid_color

	_setup_cells()
	reset_board()

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
			cell.layout_mode = 0
			cell.position = board_offset + Vector2(x * cell_size, y * cell_size)
			cell.custom_minimum_size = Vector2(cell_size, cell_size)
			cell.size = Vector2(cell_size, cell_size)
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
	_state = load("res://scripts/game_state.gd").new(empty_board, board_size)
	_last_placed_pos = Vector2i(-1, -1)

	# Reset cell visuals
	for cell in cells:
		cell.set_piece(0, Color.TRANSPARENT)
		cell.set_valid_move(false)

	valid_moves_changed.emit([])
	queue_redraw()

func get_state() -> RefCounted:
	return _state

func is_valid_pos(x: int, y: int) -> bool:
	return _state.is_valid_pos(x, y)

func get_cell(x: int, y: int) -> int:
	return _state.get_cell(x, y)

func set_cell(x: int, y: int, val: int):
	_state.set_cell(x, y, val)

func get_valid_moves_for_player(player: int) -> Array:
	return _state.get_valid_moves(player)

func place_piece(x: int, y: int, player: int, flips: Array):
	# Update game state synchronously (critical for AI simulation)
	var move = {"pos": Vector2i(x, y), "flips": flips}
	_state.apply_move(move, player)
	_last_placed_pos = Vector2i(x, y)

	var color = white_color if player == GameConstants.WHITE else black_color

	# Build list of cells to animate
	var cells_to_animate: Array = []
	cells_to_animate.append(cells[y * board_size + x])
	for f in flips:
		cells_to_animate.append(cells[f.y * board_size + f.x])

	if cells_to_animate.size() == 0:
		_finish_placement(x, y, player, flips, color)
		return

	_pending_animations = cells_to_animate
	_animations_done_count = 0
	_placement_deferred_data = {"x": x, "y": y, "player": player, "flips": flips, "color": color}

	# Connect signals before triggering animations so no emissions are lost
	for cell in cells_to_animate:
		if not cell.flip_finished.is_connected(_on_cell_flip_finished):
			cell.flip_finished.connect(_on_cell_flip_finished)

	# Now trigger animations
	cells[y * board_size + x].set_piece(player, color)
	for f in flips:
		cells[f.y * board_size + f.x].set_piece(player, color)

	await animations_complete

func _on_cell_flip_finished():
	_animations_done_count += 1
	if _animations_done_count >= _pending_animations.size():
		# All animations done, clean up connections
		for cell in _pending_animations:
			if cell.flip_finished.is_connected(_on_cell_flip_finished):
				cell.flip_finished.disconnect(_on_cell_flip_finished)

		var data = _placement_deferred_data
		_finish_placement(data.x, data.y, data.player, data.flips, data.color)

		_pending_animations.clear()
		_animations_done_count = 0
		animations_complete.emit()

func _finish_placement(x: int, y: int, player: int, flips: Array, color: Color):
	# Update valid moves for the NEXT player
	var next_player = GameConstants.WHITE if player == GameConstants.BLACK else GameConstants.BLACK
	var next_moves = get_valid_moves_for_player(next_player)

	# Update cell visuals for valid moves
	for cell in cells:
		cell.set_valid_move(false)
	for m in next_moves:
		cells[m.pos.y * board_size + m.pos.x].set_valid_move(true)

	valid_moves_changed.emit(next_moves)
	piece_placed.emit(Vector2i(x, y), player, flips)
	queue_redraw()

func update_valid_moves_for_drawing(moves: Array):
	for cell in cells:
		cell.set_valid_move(false)
	for m in moves:
		cells[m.pos.y * board_size + m.pos.x].set_valid_move(true)
	# Sync piece visuals from state
	for y in board_size:
		for x in board_size:
			var cell_value = get_cell(x, y)
			if cell_value != GameConstants.EMPTY:
				var color = white_color if cell_value == GameConstants.WHITE else black_color
				cells[y * board_size + x].set_piece(cell_value, color)
	queue_redraw()

func get_score() -> Dictionary:
	return _state.get_score()

func apply_theme(bg_color: Color, gr_color: Color):
	board_bg_color = bg_color
	grid_color = gr_color
	queue_redraw()

func set_replay_mode(enabled: bool):
	replay_mode = enabled
	for cell in cells:
		cell.set_replay_mode(enabled)

func render_state_instantly():
	for cell in cells:
		cell.set_valid_move(false)
	_last_placed_pos = Vector2i(-1, 1)
	for y in board_size:
		for x in board_size:
			var cell_value = get_cell(x, y)
			cells[y * board_size + x].set_piece_instantly(cell_value)
	queue_redraw()

func _draw():
	# Background
	draw_rect(Rect2(Vector2.ZERO, get_size()), board_bg_color)

	# Grid lines
	for i in board_size + 1:
		var start = board_offset + Vector2(i * cell_size, 0)
		var end = board_offset + Vector2(i * cell_size, board_size * cell_size)
		draw_line(start, end, grid_color, 1.0)
		start = board_offset + Vector2(0, i * cell_size)
		end = board_offset + Vector2(board_size * cell_size, i * cell_size)
		draw_line(start, end, grid_color, 1.0)

	# Last placed indicator
	if _last_placed_pos.x >= 0:
		var lp = _last_placed_pos
		var center = board_offset + Vector2(lp.x * cell_size + cell_size / 2.0, lp.y * cell_size + cell_size / 2.0)
		draw_circle(center, cell_size * 0.48, Color(1.0, 0.2, 0.2, 0.6))
