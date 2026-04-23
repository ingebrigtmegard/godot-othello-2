extends Node

func _ready():
	var b = get_node("/root/main/Board")
	if not b:
		print("ERROR: Board node not found")
		return
	
	print("=== Initial State ===")
	print("Player: " + str(b.current_player))
	_print_board(b)
	
	print("\n--- Move 1: Black plays (3,2) ---")
	b.simulate_click(3, 2)
	_print_board(b)
	print("Player after: " + str(b.current_player))
	print("Score: " + b.score_label.text)
	
	print("\n--- Move 2: White plays (3,1) ---")
	b.simulate_click(3, 1)
	_print_board(b)
	print("Player after: " + str(b.current_player))
	print("Score: " + b.score_label.text)
	
	print("\n--- Move 3: Black plays (4,2) ---")
	b.simulate_click(4, 2)
	_print_board(b)
	print("Player after: " + str(b.current_player))
	print("Score: " + b.score_label.text)
	
	print("\n--- Move 4: White plays (2,2) ---")
	b.simulate_click(2, 2)
	_print_board(b)
	print("Player after: " + str(b.current_player))
	print("Score: " + b.score_label.text)
	
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
