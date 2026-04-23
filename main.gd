extends Control

# --- Constants ---
const BOARD_OFFSET := Vector2(160, 60)
const CELL_SIZE := 60
const BOARD_SIZE := 8
const EMPTY := 0
const BLACK := 1
const WHITE := 2

# --- State ---
var board: Array = []
var current_player: int = BLACK
var valid_moves: Array = []
var message_timer: Timer = Timer.new()

# AI for White
var white_ai_enabled: bool = true
var ai_timer: Timer = Timer.new()
var ai_turn_requested: bool = false

var animating: bool = false
var anim_positions: Array = []
var _last_placed_pos: Vector2i = Vector2i(-1, -1)

# UI references
var score_label: Label
var turn_label: Label
var message_label: Label
var restart_button: Button


# --- Board helpers ---
func is_valid_pos(x: int, y: int) -> bool:
	return x >= 0 and x < BOARD_SIZE and y >= 0 and y < BOARD_SIZE

func get_cell(x: int, y: int) -> int:
	if not is_valid_pos(x, y):
		return -1
	return board[y * BOARD_SIZE + x]

func set_cell(x: int, y: int, val: int):
	board[y * BOARD_SIZE + x] = val

func flip_direction(x: int, y: int, dx: int, dy: int, player: int) -> Array:
	var opp: int = WHITE if player == BLACK else BLACK
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

func get_valid_moves_for_player(player: int) -> Array:
	var moves: Array = []
	for y in BOARD_SIZE:
		for x in BOARD_SIZE:
			if get_cell(x, y) != EMPTY:
				continue
			var dirs: Array = [Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1),
							   Vector2i(-1,0),             Vector2i(1,0),
							   Vector2i(-1,1),  Vector2i(0,1), Vector2i(1,1)]
			var flips: Array = []
			for dir_idx in dirs.size():
				var dir: Vector2i = dirs[dir_idx]
				var result = flip_direction(x, y, dir.x, dir.y, player)
				if result.size() > 0:
					flips.append_array(result)
			if flips.size() > 0:
				moves.append({"pos": Vector2i(x, y), "flips": flips})
	return moves

# --- AI ---
func choose_ai_move(player: int) -> Dictionary:
	"""Choose the best move for the given player using a heuristic evaluation."""
	var moves = get_valid_moves_for_player(player)
	if moves.size() == 0:
		return {}

	var opp: int = WHITE if player == BLACK else BLACK

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
		set_cell(pos.x, pos.y, player)
		for f in move.flips:
			set_cell(f.x, f.y, player)
		var opp_moves = get_valid_moves_for_player(opp)
		score -= opp_moves.size() * 3.0
		# Undo simulation
		set_cell(pos.x, pos.y, EMPTY)
		for f in move.flips:
			set_cell(f.x, f.y, opp)

		if score > best_score:
			best_score = score
			best_move = move

	return best_move

# --- Game logic ---
func init_board():
	board = []
	for i in BOARD_SIZE * BOARD_SIZE:
		board.append(EMPTY)
	set_cell(3, 3, WHITE)
	set_cell(4, 4, WHITE)
	set_cell(3, 4, BLACK)
	set_cell(4, 3, BLACK)
	current_player = BLACK
	valid_moves = get_valid_moves_for_player(BLACK)

func place_piece(x: int, y: int, player: int, flips: Array):
	set_cell(x, y, player)
	for f in flips:
		set_cell(f.x, f.y, player)
	valid_moves = get_valid_moves_for_player(WHITE if player == BLACK else BLACK)

func switch_turn():
	var next_player: int = WHITE if current_player == BLACK else BLACK
	var next_moves = get_valid_moves_for_player(next_player)
	if next_moves.size() == 0:
		var current_moves = get_valid_moves_for_player(current_player)
		if current_moves.size() == 0:
			show_game_over()
			return
		show_message("Pass!")
		message_timer.start(1.5)
		await message_timer.timeout
		current_player = next_player
		valid_moves = next_moves
		update_turn_label()
		if white_ai_enabled:
			ai_turn_requested = true
		return

	current_player = next_player
	valid_moves = next_moves
	update_turn_label()
	if white_ai_enabled:
		ai_turn_requested = true

func show_message(msg: String):
	message_label.text = msg
	message_label.visible = true
	message_timer.start(2.0)
	await message_timer.timeout
	if message_label.text == msg:
		message_label.visible = false

func show_game_over():
	var black_count = 0
	var white_count = 0
	for i in board.size():
		if board[i] == BLACK:
			black_count += 1
		elif board[i] == WHITE:
			white_count += 1
	var result = ""
	if black_count > white_count:
		result = "Black Wins! %d-%d" % [black_count, white_count]
	elif white_count > black_count:
		result = "White Wins! %d-%d" % [white_count, black_count]
	else:
		result = "Draw! %d-%d" % [black_count, white_count]
	show_message(result)
	restart_button.visible = true

func restart_game():
	for a in anim_positions:
		var t: Timer = a[1]
		if t and t.timeout.is_connected(_on_anim_finished):
			t.timeout.disconnect(_on_anim_finished)
		t.stop()
		t.queue_free()
	anim_positions.clear()
	ai_timer.stop()
	if ai_timer.timeout.is_connected(_on_ai_move):
		ai_timer.timeout.disconnect(_on_ai_move)
	ai_turn_requested = false
	animating = false
	message_label.visible = false
	restart_button.visible = false
	init_board()
	update_scores()

func can_place(x: int, y: int) -> bool:
	for m in valid_moves:
		if m.pos.x == x and m.pos.y == y:
			return true
	return false

func get_flips_for_move(x: int, y: int) -> Array:
	for m in valid_moves:
		if m.pos.x == x and m.pos.y == y:
			return m.flips
	return []


# --- UI ---
func update_scores():
	var black = 0
	var white = 0
	for i in board.size():
		if board[i] == BLACK:
			black += 1
		elif board[i] == WHITE:
			white += 1
	score_label.text = "Black: %d  |  White: %d" % [black, white]

func update_turn_label():
	var player_name = "Black" if current_player == BLACK else "White"
	turn_label.text = "Turn: %s" % player_name


# --- Drawing ---
func _draw():
	# Guard against _draw() being called before _ready()
	if board.size() == 0:
		return

	# Page background (dark blue-gray)
	var bg_color = Color(0.15, 0.18, 0.25)
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), bg_color)

	# Board background (dark green)
	var board_rect = Rect2(BOARD_OFFSET, Vector2(CELL_SIZE * BOARD_SIZE, CELL_SIZE * BOARD_SIZE))
	draw_rect(board_rect, Color(0.1, 0.35, 0.15))

	# Grid lines (darker)
	var grid_color = Color(0.05, 0.2, 0.05)
	for i in BOARD_SIZE + 1:
		var start = BOARD_OFFSET + Vector2(i * CELL_SIZE, 0)
		var end = BOARD_OFFSET + Vector2(i * CELL_SIZE, CELL_SIZE * BOARD_SIZE)
		draw_line(start, end, grid_color, 1.0)
		start = BOARD_OFFSET + Vector2(0, i * CELL_SIZE)
		end = BOARD_OFFSET + Vector2(CELL_SIZE * BOARD_SIZE, i * CELL_SIZE)
		draw_line(start, end, grid_color, 1.0)

	# Highlight valid moves (yellow semi-transparent)
	for m in valid_moves:
		var center = BOARD_OFFSET + Vector2(m.pos.x * CELL_SIZE + CELL_SIZE / 2.0,
											  m.pos.y * CELL_SIZE + CELL_SIZE / 2.0)
		var highlight_color = Color(1.0, 1.0, 0.0, 0.25)
		draw_circle(center, CELL_SIZE * 0.35, highlight_color)

	# Draw pieces
	for y in BOARD_SIZE:
		for x in BOARD_SIZE:
			var cell = get_cell(x, y)
			if cell == EMPTY:
				continue
			var center = BOARD_OFFSET + Vector2(x * CELL_SIZE + CELL_SIZE / 2.0,
												  y * CELL_SIZE + CELL_SIZE / 2.0)
			var color = Color(0.1, 0.1, 0.1) if cell == BLACK else Color(0.95, 0.95, 0.95)
			var radius = CELL_SIZE * 0.42
			draw_circle(center, radius, color)
			# Outline
			draw_arc(center, radius, 0, TAU, 32, Color(0.0, 0.0, 0.0), 2.0, true)

	# Last placed piece indicator (red circle)
	if _last_placed_pos.x >= 0 and not animating:
		var center = BOARD_OFFSET + Vector2(_last_placed_pos.x * CELL_SIZE + CELL_SIZE / 2.0,
											  _last_placed_pos.y * CELL_SIZE + CELL_SIZE / 2.0)
		draw_circle(center, CELL_SIZE * 0.48, Color(1.0, 0.2, 0.2, 0.6))


# --- Input ---
func _input(event):
	if animating:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = event.global_position
			var board_pos = mouse_pos - BOARD_OFFSET
			var x = int(board_pos.x / CELL_SIZE)
			var y = int(board_pos.y / CELL_SIZE)
			if can_place(x, y):
				perform_move(x, y)


# --- Move execution ---
func perform_move(x: int, y: int):
	var flips = get_flips_for_move(x, y)
	if flips.size() == 0:
		return

	place_piece(x, y, current_player, flips)
	update_scores()

	# Set last placed piece indicator
	_last_placed_pos = Vector2i(x, y)

	# Animate the new piece (scale X 1->0->1)
	var anim_timer = Timer.new()
	anim_timer.wait_time = 0.4
	anim_timer.one_shot = true
	anim_timer.timeout.connect(_on_anim_finished)
	add_child(anim_timer)
	anim_timer.start()
	anim_positions.append([Vector2i(x, y), anim_timer, 0.4])
	animating = true

	# Animate flipped pieces
	for f in flips:
		var flip_timer = Timer.new()
		flip_timer.wait_time = 0.3
		flip_timer.one_shot = true
		flip_timer.timeout.connect(_on_anim_finished)
		add_child(flip_timer)
		flip_timer.start()
		anim_positions.append([f, flip_timer, 0.3])
		animating = true

func _on_anim_finished():
	var any_remaining = false
	for a in anim_positions:
		var timer: Timer = a[1]
		if timer and timer.time_left > 0.001:
			any_remaining = true
			break
	if not any_remaining:
		for a in anim_positions:
			var timer: Timer = a[1]
			if timer and timer.timeout.is_connected(_on_anim_finished):
				timer.timeout.disconnect(_on_anim_finished)
			timer.stop()
			timer.queue_free()
		# Trigger AI if it's White's turn
		anim_positions.clear()
		ai_timer.stop()
		if ai_timer.timeout.is_connected(_on_ai_move):
			ai_timer.timeout.disconnect(_on_ai_move)
		ai_turn_requested = false
		animating = false
		queue_redraw()
		# Switch turn (async - use await)
		await switch_turn()
		# Trigger AI after turn switch if White is playing
		if white_ai_enabled and current_player == WHITE:
			ai_timer.wait_time = 0.5
			ai_timer.one_shot = true
			ai_timer.timeout.connect(_on_ai_move)
			ai_timer.start()

func _on_ai_move():
	var move = choose_ai_move(WHITE)
	if move.is_empty():
		return
	perform_move(move.pos.x, move.pos.y)


# --- Setup ---
func _ready():
	# Create UI controls
	score_label = Label.new()
	score_label.text = "Black: 2  |  White: 2"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.anchor_top = 0.0
	score_label.anchor_left = 0.0
	score_label.anchor_right = 1.0
	score_label.offset_top = 10
	score_label.offset_bottom = 30
	add_child(score_label)

	turn_label = Label.new()
	turn_label.text = "Turn: Black"
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_label.add_theme_font_size_override("font_size", 20)
	turn_label.anchor_top = 1.0
	turn_label.anchor_bottom = 1.0
	turn_label.anchor_left = 0.0
	turn_label.anchor_right = 1.0
	turn_label.offset_top = -40
	turn_label.offset_bottom = -10
	add_child(turn_label)

	message_label = Label.new()
	message_label.text = ""
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 36)
	message_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.0))
	message_label.anchor_top = 0.1
	message_label.anchor_left = 0.5
	message_label.anchor_right = 0.5
	message_label.anchor_bottom = 0.1
	message_label.offset_top = 40
	message_label.offset_bottom = 80
	message_label.visible = false
	add_child(message_label)

	restart_button = Button.new()
	restart_button.text = "Restart Game"
	restart_button.add_theme_font_size_override("font_size", 22)
	restart_button.anchor_top = 1.0
	restart_button.anchor_left = 0.5
	restart_button.anchor_right = 0.5
	restart_button.anchor_bottom = 1.0
	restart_button.offset_top = -60
	restart_button.offset_bottom = -20
	restart_button.visible = false
	restart_button.pressed.connect(restart_game)
	add_child(restart_button)

	# Message timer (for auto-hiding)
	add_child(message_timer)

	# AI timer
	add_child(ai_timer)

	# Initialize game
	init_board()
	queue_redraw()
