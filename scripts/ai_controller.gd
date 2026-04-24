extends Node

# --- State ---
var white_ai_enabled: bool = true

func choose_ai_move(player: int, board: Node) -> Dictionary:
	"""Choose the best move for the given player using Minimax with Alpha-Beta pruning."""
	var current_state = board.get_state()
	var moves = current_state.get_valid_moves(player)

	if moves.is_empty():
		return {}

	var depth = board.config.ai_depth if board.config else 4
	var best_move: Dictionary = moves[0]

	# Create a single simulation state to avoid massive allocations
	var sim_state = GameState.new(current_state.board, current_state.board_size)

	# Sort moves to improve Alpha-Beta pruning efficiency
	_sort_moves(moves)

	if player == GameConstants.WHITE:
		var best_val = -1000000.0
		for m in moves:
			var undo_data = sim_state.apply_move(m, player)
			var val = _minimax(sim_state, depth - 1, -1000000.0, 1000000.0, false)
			sim_state.undo_move(undo_data)
			if val > best_val:
				best_val = val
				best_move = m
	else:
		var best_val = 1000000.0
		for m in moves:
			var undo_data = sim_state.apply_move(m, player)
			var val = _minimax(sim_state, depth - 1, -1000000.0, 1000000.0, true)
			sim_state.undo_move(undo_data)
			if val < best_val:
				best_val = val
				best_move = m

	return best_move

func _sort_moves(moves: Array) -> void:
	# Simple move ordering: Corners > Edges > Others
	moves.sort_custom(func(a, b):
		var score_a = _get_move_priority(a.pos)
		var score_b = _get_move_priority(b.pos)
		return score_a > score_b
	)

func _get_move_priority(pos: Vector2i) -> int:
	if (pos.x == 0 or pos.x == 7) and (pos.y == 0 or pos.y == 7):
		return 3 # Corner
	if pos.x == 0 or pos.x == 7 or pos.y == 0 or pos.y == 7:
		return 2 # Edge
	return 1 # Middle

func _minimax(state, depth: int, alpha: float, beta: float, is_maximizing: bool) -> float:
	if depth == 0:
		return _evaluate(state)

	var player = GameConstants.WHITE if is_maximizing else GameConstants.BLACK
	var moves = state.get_valid_moves(player)

	if moves.is_empty():
		# Check if opponent has moves (pass turn)
		var opp = GameConstants.BLACK if is_maximizing else GameConstants.WHITE
		var opp_moves = state.get_valid_moves(opp)
		if opp_moves.is_empty():
			# Game Over
			return _evaluate(state)
		else:
			# Pass turn: continue minimax with the other player
			return _minimax(state, depth - 1, alpha, beta, !is_maximizing)

	# Sort moves for pruning efficiency
	_sort_moves(moves)

	if is_maximizing:
		var max_eval = -1000000.0
		for m in moves:
			var undo_data = state.apply_move(m, player)
			var eval = _minimax(state, depth - 1, alpha, beta, false)
			state.undo_move(undo_data)
			max_eval = max(max_eval, eval)
			alpha = max(alpha, eval)
			if beta <= alpha:
				break
		return max_eval
	else:
		var min_eval = 1000000.0
		for m in moves:
			var undo_data = state.apply_move(m, player)
			var eval = _minimax(state, depth - 1, alpha, beta, true)
			state.undo_move(undo_data)
			min_eval = min(min_eval, eval)
			beta = min(beta, eval)
			if beta <= alpha:
				break
		return min_eval

func _evaluate(state) -> float:
	# Score = White - Black
	var score_dict = state.get_score()
	var score = float(score_dict.white - score_dict.black) * 10.0

	# Positional advantage
	var positional_score = 0.0
	var corners = [Vector2i(0,0), Vector2i(7,0), Vector2i(0,7), Vector2i(7,7)]
	var corner_adjacent = [
		Vector2i(1,0), Vector2i(0,1),
		Vector2i(6,0), Vector2i(7,1),
		Vector2i(0,6), Vector2i(1,7),
		Vector2i(6,7), Vector2i(7,6)
	]

	for y in state.board_size:
		for x in state.board_size:
			var cell = state.get_cell(x, y)
			if cell == GameConstants.EMPTY: continue

			var pos = Vector2i(x, y)
			var val = 1.0 if cell == GameConstants.WHITE else -1.0

			if pos in corners:
				positional_score += val * 100.0
			elif pos in corner_adjacent:
				positional_score += val * -30.0
			elif x == 0 or x == 7 or y == 0 or y == 7:
				positional_score += val * 5.0

	score += positional_score

	# Mobility
	var white_moves = state.get_valid_moves(GameConstants.WHITE).size()
	var black_moves = state.get_valid_moves(GameConstants.BLACK).size()
	score += float(white_moves - black_moves) * 5.0

	return score
