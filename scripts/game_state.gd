extends RefCounted
class_name GameState

var board: Array = []
var board_size: int

func _init(p_board: Array, p_size: int):
	board = p_board.duplicate()
	board_size = p_size

func is_valid_pos(x: int, y: int) -> bool:
	return x >= 0 and x < board_size and y >= 0 and y < board_size

func get_cell(x: int, y: int) -> int:
	if not is_valid_pos(x, y):
		return -1
	return board[y * board_size + x]

func set_cell(x: int, y: int, val: int):
	if is_valid_pos(x, y):
		board[y * board_size + x] = val

func get_valid_moves(player: int) -> Array:
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
				var result = _flip_direction(x, y, dir.x, dir.y, player)
				if result.size() > 0:
					flips.append_array(result)
			if flips.size() > 0:
				moves.append({"pos": Vector2i(x, y), "flips": flips})
	return moves

func _flip_direction(x: int, y: int, dx: int, dy: int, player: int) -> Array:
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

func apply_move(move: Dictionary, player: int) -> Dictionary:
	var pos: Vector2i = move.pos
	var flips: Array = move.flips
	set_cell(pos.x, pos.y, player)
	for f in flips:
		set_cell(f.x, f.y, player)
	return {"pos": pos, "flips": flips, "player": player}

func undo_move(undo_data: Dictionary) -> void:
	var pos: Vector2i = undo_data.pos
	var flips: Array = undo_data.flips
	var player: int = undo_data.player
	var opponent: int = GameConstants.WHITE if player == GameConstants.BLACK else GameConstants.BLACK
	set_cell(pos.x, pos.y, GameConstants.EMPTY)
	for f in flips:
		set_cell(f.x, f.y, opponent)

func get_score() -> Dictionary:
	var black = 0
	var white = 0
	for i in board.size():
		if board[i] == GameConstants.BLACK:
			black += 1
		elif board[i] == GameConstants.WHITE:
			white += 1
	return {"black": black, "white": white}
