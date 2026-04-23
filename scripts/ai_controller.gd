extends Node

# --- State ---
var white_ai_enabled: bool = true

func choose_ai_move(player: int, board: Node) -> Dictionary:
	"""Choose the best move for the given player using a heuristic evaluation."""
	# Using the Board node's methods
	var moves = board.get_valid_moves_for_player(player)
	if moves.size() == 0:
		return {}

	var opp: int = GameConstants.WHITE if player == GameConstants.BLACK else GameConstants.BLACK

	# Corner positions (most valuable)
	var corners = [Vector2i(0,0), Vector2i(7,0), Vector2i(0,7), Vector2i(7,7)]
	# Positions adjacent to corners (dangerous)
	var corner_adjacent = [
		Vector2i(1,0), Vector2i(0,1),
		Vector2i(6,0), Vector2i(7,1),
		Vector2i(0,6), Vector2i(1,7),
		Vector2i(6,7), Vector2i(7,6)
	]

	var best_move: Dictionary = moves[0]
	var best_score: float = -999999

	for move in moves:
		var pos: Vector2i = move.pos
		var score: float = 0.0

		# 1. Count pieces flipped (more is better)
		score += move.flips.size() * 2.0

		# 2. Corner bonus (very high)
		if pos in corners:
			score += 100.0

		# 3. Penalty for adjacent to corner (gives opponent corner opportunity)
		if pos in corner_adjacent:
			score -= 30.0

		# 4. Edge position bonus (edges are more stable)
		if pos.y == 0 or pos.y == 7 or pos.x == 0 or pos.x == 7:
			if not (pos in corners):
				score += 5.0

		# 5. Mobility: simulate the move and count opponent's available moves
		# (fewer opponent moves is better)
		board.set_cell(pos.x, pos.y, player)
		for f in move.flips:
			board.set_cell(f.x, f.y, player)

		var opp_moves = board.get_valid_moves_for_player(opp)
		score -= opp_moves.size() * 3.0

		# Undo simulation
		board.set_cell(pos.x, pos.y, GameConstants.EMPTY) # EMPTY=0
		for f in move.flips:
			board.set_cell(f.x, f.y, opp)

		if score > best_score:
			best_score = score
			best_move = move

	return best_move
