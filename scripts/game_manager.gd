extends Control

# --- Signals ---
signal game_started
signal game_over(result: String)

# --- Constants ---
const BLACK := GameConstants.BLACK
const WHITE := GameConstants.WHITE

# --- Node References ---
@onready var board: Node = $Board
@onready var ai_controller: Node = $AIController
@onready var ui_manager: Control = $UIManager

# --- Configuration ---
@export var config: GameConfig

# --- State ---
var current_player: int = BLACK
var valid_moves: Array = []
var animating: bool = false
var message_ready: bool = true
var white_ai_enabled: bool = true

func _ready():
	if config:
		# Set up board with config
		board.config = config
	else:
		# Fallback defaults
		board.board_offset = Vector2(160, 60)
		board.cell_size = 60
		board.board_size = 8
		board.black_color = Color(0.1, 0.1, 0.1)
		board.white_color = Color(0.95, 0.95, 0.95)

	# Connect signals from components
	board.piece_placed.connect(_on_piece_placed)
	board.valid_moves_changed.connect(_on_valid_moves_changed)
	board.move_attempted.connect(_on_move_attempted)

	ui_manager.restart_requested.connect(_on_restart_requested)
	ui_manager.pass_requested.connect(_on_pass_requested)

	# Setup initial state
	init_game()

func init_game():
	board.reset_board()
	current_player = BLACK
	animating = false
	message_ready = true
	white_ai_enabled = true

	# Initial setup: four center pieces
	board.set_cell(3, 3, WHITE)
	board.set_cell(4, 4, WHITE)
	board.set_cell(3, 4, BLACK)
	board.set_cell(4, 3, BLACK)

	valid_moves = board.get_valid_moves_for_player(BLACK)
	board.update_valid_moves_for_drawing(valid_moves)

	ui_manager.update_scores(board.get_score().black, board.get_score().white)
	ui_manager.update_turn("Black")
	ui_manager.set_restart_button_visible(false)
	ui_manager.set_pass_button_visible(valid_moves.size() == 0)

	if valid_moves.size() == 0:
		await switch_turn()

	game_started.emit()

func _on_move_attempted(x: int, y: int):
	if animating or not message_ready:
		return

	# Check if the move is valid
	for move in valid_moves:
		if move.pos.x == x and move.pos.y == y:
			perform_move(x, y, move.flips)
			return
	# Optionally show an error message or sound
	pass

func perform_move(x: int, y: int, flips: Array):
	animating = true
	ui_manager.set_pass_button_visible(false)

	board.place_piece(x, y, current_player, flips)

	# We'll simulate the animation delay here
	await get_tree().create_timer(0.5).timeout

	animating = false
	await switch_turn()

func _on_piece_placed(_pos: Vector2i, _player: int, _flips: Array):
	print("Piece placed! Player: ", _player)
	var score = board.get_score()
	ui_manager.update_scores(score.black, score.white)

func _on_valid_moves_changed(moves: Array):
	valid_moves = moves
	board.update_valid_moves_for_drawing(moves)

func _on_restart_requested():
	init_game()

func _on_pass_requested():
	if not animating and message_ready:
		await switch_turn()

func switch_turn():
	var next_player = WHITE if current_player == BLACK else BLACK
	var next_moves = board.get_valid_moves_for_player(next_player)

	if next_moves.size() == 0:
		# Check if current player also has no moves
		var current_moves = board.get_valid_moves_for_player(current_player)
		if current_moves.size() == 0:
			var score = board.get_score()
			var result = get_game_over_message(score.black, score.white)
			ui_manager.show_message(result)
			ui_manager.set_restart_button_visible(true)
			game_over.emit(result)
			return

		# Pass
		ui_manager.show_message("Pass!")
		message_ready = false
		await get_tree().create_timer(1.5).timeout
		message_ready = true
		current_player = next_player
		valid_moves = next_moves
		board.valid_moves_changed.emit(next_moves)
		ui_manager.update_turn("White" if current_player == WHITE else "Black")
		ui_manager.set_pass_button_visible(valid_moves.size() == 0)

		if white_ai_enabled and current_player == WHITE:
			call_ai_turn()
		return

	current_player = next_player
	valid_moves = next_moves
	board.valid_moves_changed.emit(next_moves)
	ui_manager.update_turn("White" if current_player == WHITE else "Black")
	ui_manager.set_pass_button_visible(valid_moves.size() == 0)

	if white_ai_enabled and current_player == WHITE:
		call_ai_turn()

func call_ai_turn():
	await get_tree().create_timer(0.5).timeout
	var move = ai_controller.choose_ai_move(WHITE, board)
	if move.is_empty():
		await switch_turn()
	else:
		# For AI, we use perform_move logic but directly
		perform_move(move.pos.x, move.pos.y, move.flips)

func get_game_over_message(black: int, white: int) -> String:
	if black > white:
		return "Black Wins! %d-%d" % [black, white]
	elif white > black:
		return "White Wins! %d-%d" % [black, white]
	else:
		return "Draw! %d-%d" % [black, white]
