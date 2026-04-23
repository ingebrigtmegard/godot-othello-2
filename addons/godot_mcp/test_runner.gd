extends Node

func test_all():
	var board_node = get_node("/root/main/Board")
	if not board_node:
		print("ERROR: Board node not found")
		return
	
	print("=== Initial State ===")
	print("Player: " + str(board_node.current_player))
	_print_board(board_node)
	
	# Move 1: Black plays at (3,2) - a valid move
	print("\n--- Move 1: Black plays (3,2) ---")
	board_node.simulate_click(3, 2)
	_print_board(board_node)
	print("Player after: " + str(board_node.current_player))
	print("Score: " + board_node.score_label.text)
	print("Turn: " + board_node.turn_label.text)
	
	# Move 2: White plays at (3,1) - a valid move
	print("\n--- Move 2: White plays (3,1) ---")
	board_node.simulate_click(3, 1)
	_print_board(board_node)
	print("Player after: " + str(board_node.current_player))
	print("Score: " + board_node.score_label.text)
	
	# Move 3: Black plays at (4,2) - a valid move
	print("\n--- Move 3: Black plays (4,2) ---")
	board_node.simulate_click(4, 2)
	_print_board(board_node)
	print("Player after: " + str(board_node.current_player))
	print("Score: " + board_node.score_label.text)
	
	# Move 4: White plays at (2,2) - a valid move
	print("\n--- Move 4: White plays (2,2) ---")
	board_node.simulate_click(2, 2)
	_print_board(board_node)
	print("Player after: " + str(board_node.current_player))
	print("Score: " + board_node.score_label.text)
	
	print("\n=== All 4 moves completed ===")

func _print_board(node):
	for r in range(8):
		var line = ""
		for c in range(8):
			var v = node.board[r][c]
			if v == 0: line += ". "
			elif v == 1: line += "B "
			else: line += "W "
		print(line)
