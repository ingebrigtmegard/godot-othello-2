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
	await init_game()

func init_game():
	print("init_game starting")
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

	print("init_game finished")
	game_started.emit()

func _on_move_attempted(x: int, y: int):
	print("move_attempted received: ", x, ",", y)
	if animating or not message_ready:
		print("move ignored: animating=", animating, " message_ready=", message_ready)
		return

	# Check if the move is valid
	for move in valid_moves:
		if move.pos.x == x and move.pos.y == y:
			print("valid move found! performing move...")
			await perform_move(x, y, move.flips)
			return
	print("invalid move attempted at: ", x, ",", y)

func perform_move(x: int, y: int, flips: Array):
	print("DEBUG: perform_move called at line 91")
	print("perform_move start: player=", current_player)
	animating = true
	ui_manager.set_pass_button_visible(false)

	board.place_piece(x, y, current_player, flips)

	# We'll simulate the animation delay here
	await get_tree().create_timer(0.5).timeout

	await switch_turn()
	animating = false
	print("perform_move finished after switch_turn")

func _on_piece_placed(_pos: Vector2i, _player: int, _flips: Array):
	print("Piece placed! Player: ", _player)
	var score = board.get_score()
	ui_manager.update_scores(score.black, score.white)

func _on_valid_moves_changed(moves: Array):
	valid_moves = moves
	board.update_valid_moves_for_drawing(moves)

func _on_restart_requested():
	print("restart requested")
	await init_game()

func _on_pass_requested():
	print("pass requested")
	if not animating and message_ready:
		await switch_turn()

func switch_turn():
	print("DEBUG: switch_turn called at line 124")
	animating = true
	print("switch_turn start. current_player: ", current_player)
	var next_player = WHITE if current_player == BLACK else BLACK
	print("next_player: ", next_player)
	var next_moves = board.get_valid_moves_for_player(next_player)
	print("next_moves size: ", next_moves.size())

	if next_moves.size() == 0:
		# Check if current player also has no moves
		var current_moves = board.get_valid_moves_for_player(current_player)
		print("current_moves size (for pass check): ", current_moves.size())
		if current_moves.size() == 0:
			var score = board.get_score()
			var result = get_game_over_message(score.black, score.white)
			print("Game Over: ", result)
			ui_manager.show_message(result)
			ui_manager.set_restart_button_visible(true)
			game_over.emit(result)
			print("switch_turn (game over) finished")
			animating = false
			return

		# Pass
		print("Pass detected!")
		ui_manager.show_message("Pass!")
		message_ready = false
		await get_tree().create_timer(1.5).timeout
		message_ready = true
		current_player = next_player
		valid_moves = next_moves
		board.valid_moves_changed.emit(next_moves)
		ui_manager.update_turn("White" if current_player == WHITE else "Black")
		ui_manager.set_pass_button_visible(valid_moves.size() == 0)
		print("Pass switch_turn finished. current_player: ", current_player)

		if white_ai_enabled and current_player == WHITE:
			print("Calling AI turn after pass")
			await call_ai_turn()
		else:
			print("No AI turn needed after pass")
		print("switch_turn (pass) finished")
		animating = false
		return

	current_player = next_player
	valid_moves = next_moves
	board.valid_moves_changed.emit(next_moves)
	ui_manager.update_turn("White" if current_player == WHITE else "Black")
	ui_manager.set_pass_button_visible(valid_moves.size() == 0)
	print("switch_turn (normal) finished. current_player: ", current_player)

	if white_ai_enabled and current_player == WHITE:
		print("Calling AI turn")
		await call_ai_turn()

	animating = false

func call_ai_turn():
	print("call_ai_turn start")
	await get_tree().create_timer(0.5).timeout
	var move = ai_controller.choose_ai_move(WHITE, board)
	print("AI move chosen: ", move)
	if move.is_empty():
		print("AI move is empty, calling switch_turn")
		await switch_turn()
	else:
		print("AI move found, performing move...")
		await perform_move(move.pos.x, move.pos.y, move.flips)
	print("call_ai_turn finished")

func get_game_over_message(black: int, white: int) -> String:
	if black > white:
		return "Black Wins! %d-%d" % [black, white]
	elif white > black:
		return "White Wins! %d-%d" % [black, white]
	else:
		return "Draw! %d-%d" % [black, white]
