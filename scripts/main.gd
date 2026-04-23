extends Control

# --- Constants ---
const BOARD_OFFSET := Vector2(160, 60)
const CELL_SIZE := 60
const BOARD_SIZE := 8
const EMPTY := 0
const BLACK := 1
const WHITE := 2

# --- Signals ---
signal turn_ended

# --- State ---
var board: Array = []
var current_player: int = BLACK
var valid_moves: Array = []
var message_timer: Timer = Timer.new()
var message_ready: bool = true

# AI for White
var white_ai_enabled: bool = true
var ai_timer: Timer = Timer.new()
var ai_turn_requested: bool = false

# Animation state
var animating: bool = false
var anim_positions: Array = []  # [(position, timer: Timer, duration: float)]
var anim_start_values: Array = []  # stored initial scale values

# UI references
var score_label: Label
var turn_label: Label
var message_label: Label
var restart_button: Button
var pass_button: Button

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
		# (fewer opponent moves is better)
		set_cell(pos.x, pos.y, player)
		for f in move.flips:
			set_cell(f.x, f.y, player)
		var opp_moves = get_valid_moves_for_player(opp)
		score -= opp_moves.size() * 3.0
		# Undo simulation
		set_cell(pos.x, pos.y, EMPTY)
		for f in move.flips:
			set_cell(f.x, f.y, opp)

		# 6. Parity: prefer moves that limit opponent's choices
		# (this is a simplified version of mobility above)

		if score > best_score:
			best_score = score
			best_move = move

	return best_move

# --- Game logic ---
func init_board():
	board = []
	for i in BOARD_SIZE * BOARD_SIZE:
		board.append(EMPTY)
	# Initial setup: four center pieces
	set_cell(3, 3, WHITE)
	set_cell(4, 4, WHITE)
	set_cell(3, 4, BLACK)
	set_cell(4, 3, BLACK)
	current_player = BLACK
	valid_moves = get_valid_moves_for_player(BLACK)
	if valid_moves.size() == 0:
		await switch_turn()

func place_piece(x: int, y: int, player: int, flips: Array):
	set_cell(x, y, player)
	for f in flips:
		set_cell(f.x, f.y, player)
	valid_moves = get_valid_moves_for_player(WHITE if player == BLACK else BLACK)

func switch_turn():
	# Check if next player has any valid moves
	var next_player: int = WHITE if current_player == BLACK else BLACK
	var next_moves = get_valid_moves_for_player(next_player)
	if next_moves.size() == 0:
		# Check if current player also has no moves (shouldn't happen, but safety)
		var current_moves = get_valid_moves_for_player(current_player)
		if current_moves.size() == 0:
			# Game over
			show_game_over()
			return
		# Pass
		show_message("Pass!")
		await get_tree().create_timer(1.5).timeout
		current_player = next_player
		valid_moves = next_moves
		# Check again after pass
		if has_signal("turn_ended"):
			emit_signal("turn_ended")
		update_turn_label()
		if white_ai_enabled:
			ai_turn_requested = true
		return

	current_player = next_player
	valid_moves = next_moves
	turn_ended.emit()
	update_turn_label()
	if white_ai_enabled:
		ai_turn_requested = true

func show_message(msg: String):
	message_ready = false
	message_label.text = msg
	message_label.visible = true
	await get_tree().create_timer(2.0).timeout
	if message_label.text == msg:
		message_label.visible = false
	message_ready = true

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
	# Stop all animations
	for a in anim_positions:
		var t: Timer = a[1]
		if t and t.timeout.is_connected(_on_anim_finished):
			t.timeout.disconnect(_on_anim_finished)
		t.stop()
		t.queue_free()
	anim_positions.clear()
	anim_start_values.clear()
	ai_timer.stop()
	ai_timer.timeout.disconnect(_on_ai_move)
	ai_timer.queue_free()
	ai_timer = Timer.new()
	animating = false
	message_label.visible = false
	restart_button.visible = false
	init_board()
	update_scores()

func _on_pass_pressed():
	if not animating and message_ready:
		await switch_turn()

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
	if animating:
		return
	var player_name = "Black" if current_player == BLACK else "White"
	turn_label.text = "Turn: %s" % player_name

# --- Drawing ---
func _draw():
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
	# We track this via a member variable set during place_piece
	if has_last_placed() and not animating:
		var lp = get_last_placed_pos()
		var center = BOARD_OFFSET + Vector2(lp.x * CELL_SIZE + CELL_SIZE / 2.0,
											  lp.y * CELL_SIZE + CELL_SIZE / 2.0)
		draw_circle(center, CELL_SIZE * 0.48, Color(1.0, 0.2, 0.2, 0.6))

func _draw_pieces_with_anim():
	# Redraw everything but with animated pieces
	_draw()
	# Redraw animated pieces with their current scale
	for a in anim_positions:
		var pos = a[0]
		var timer = a[1]
		var progress = timer.wait_time - timer.time_left
		var t = progress / a[2]  # 0..1
		# Scale X: 1 -> 0 -> 1 (sin wave)
		var scale_x = abs(sin(t * PI))
		scale_x = 1.0 - scale_x  # flip: 1 at t=0, 0 at t=0.5, 1 at t=1
		var center = BOARD_OFFSET + Vector2(pos.x * CELL_SIZE + CELL_SIZE / 2.0,
											  pos.y * CELL_SIZE + CELL_SIZE / 2.0)
		var cell = get_cell(pos.x, pos.y)
		var color = Color(0.1, 0.1, 0.1) if cell == BLACK else Color(0.95, 0.95, 0.95)
		var radius = CELL_SIZE * 0.42 * scale_x
		if radius > 0.5:
			draw_circle(center, radius, color)
			draw_arc(center, radius, 0, TAU, 32, Color(0.0, 0.0, 0.0), 2.0, true)

# --- Input ---
func _input(event):
	if animating:
		return
	if not message_ready:
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

	# Place the piece immediately in the board data
	place_piece(x, y, current_player, flips)
	update_scores()
	update_turn_label()

	# Set last placed piece indicator
	set_last_placed(Vector2i(x, y))

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
	# Check if all animations are done
	var any_remaining = false
	for a in anim_positions:
		var timer: Timer = a[1]
		if timer and timer.time_left > 0.001:
			any_remaining = true
			break
	if not any_remaining:
		# Clean up timers
		for a in anim_positions:
			var timer: Timer = a[1]
			if timer and timer.timeout.is_connected(_on_anim_finished):
				timer.timeout.disconnect(_on_anim_finished)
			timer.stop()
			timer.queue_free()
		anim_positions.clear()
		animating = false
		# Force redraw
		queue_redraw()
		await switch_turn()
		# Trigger AI move if it's White's turn
		if white_ai_enabled and current_player == WHITE:
			ai_timer.wait_time = 0.5
			ai_timer.one_shot = true
			ai_timer.timeout.connect(_on_ai_move)
			ai_timer.start()

func _on_ai_move():
	var move = choose_ai_move(WHITE)
	if move.is_empty():
		await switch_turn()
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
	score_label.margin_top = 10
	score_label.margin_bottom = 30
	add_child(score_label)

	turn_label = Label.new()
	turn_label.text = "Turn: Black"
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_label.add_theme_font_size_override("font_size", 20)
	turn_label.anchor_bottom = 1.0
	turn_label.anchor_left = 0.0
	turn_label.anchor_right = 1.0
	turn_label.margin_bottom = 60
	turn_label.margin_top = 40
	add_child(turn_label)

	message_label = Label.new()
	message_label.text = ""
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 36)
	message_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.0))
	message_label.anchor_top = 0.5
	message_label.anchor_left = 0.5
	message_label.anchor_right = 0.5
	message_label.anchor_bottom = 0.5
	message_label.visible = false
	add_child(message_label)

	restart_button = Button.new()
	restart_button.text = "Restart Game"
	restart_button.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restart_button.add_theme_font_size_override("font_size", 22)
	restart_button.anchor_top = 0.5
	restart_button.anchor_left = 0.5
	restart_button.anchor_right = 0.5
	restart_button.anchor_bottom = 0.5
	restart_button.visible = false
	restart_button.pressed.connect(restart_game)
	add_child(restart_button)

	# Message timer (for auto-hiding)
	add_child(message_timer)

	# AI timer
	add_child(ai_timer)

	# Pass button
	pass_button = Button.new()
	pass_button.text = "Pass"
	pass_button.add_theme_font_size_override("font_size", 22)
	pass_button.anchor_left = 1.0
	pass_button.anchor_right = 1.0
	pass_button.anchor_top = 1.0
	pass_button.anchor_bottom = 1.0
	pass_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	pass_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	pass_button.offset_right = -20
	pass_button.offset_bottom = -20
	pass_button.pressed.connect(_on_pass_pressed)
	add_child(pass_button)

	# Initialize game
	init_board()
	queue_redraw()

# --- Last placed piece tracking ---
var _last_placed_pos: Vector2i = Vector2i(-1, -1)

func set_last_placed(pos: Vector2i):
	_last_placed_pos = pos

func get_last_placed_pos() -> Vector2i:
	return _last_placed_pos

func has_last_placed() -> bool:
	return _last_placed_pos.x >= 0
