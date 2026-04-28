extends Control

# --- UI references ---
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var turn_label: Label = $MarginContainer/VBoxContainer/TurnLabel
@onready var message_label: Label = $MarginContainer/VBoxContainer/MessageLabel
@onready var restart_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/RestartButton
@onready var pass_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/PassButton
@onready var settings_hbox: HBoxContainer = $MarginContainer/VBoxContainer/SettingsHBox
@onready var ai_toggle_checkbox: CheckBox = $MarginContainer/VBoxContainer/SettingsHBox/AiToggleCheckBox
@onready var difficulty_selector: OptionButton = $MarginContainer/VBoxContainer/SettingsHBox/DifficultySelector
@onready var theme_label: Label = $MarginContainer/VBoxContainer/SettingsHBox/ThemeLabel
@onready var theme_selector: OptionButton = $MarginContainer/VBoxContainer/SettingsHBox/ThemeSelector

# --- Replay UI references ---
@onready var replay_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/ReplayButton
@onready var replay_hbox: HBoxContainer = $MarginContainer/VBoxContainer/ReplayHBox
@onready var prev_button: Button = $MarginContainer/VBoxContainer/ReplayHBox/PrevButton
@onready var step_label: Label = $MarginContainer/VBoxContainer/ReplayHBox/StepLabel
@onready var next_button: Button = $MarginContainer/VBoxContainer/ReplayHBox/NextButton
@onready var exit_replay_button: Button = $MarginContainer/VBoxContainer/ReplayHBox/ExitReplayButton

# --- Signals ---
signal restart_requested
signal pass_requested
signal ai_toggle_changed(enabled: bool)
signal difficulty_changed(depth: int)
signal theme_applied(bg_color: Color, grid_color: Color)
signal replay_requested
signal replay_prev_requested
signal replay_next_requested
signal replay_exit_requested

# --- Theme Definitions ---
var _THEMES = [
	{"name": "Classic Green", "bg": Color(0.1, 0.35, 0.15), "grid": Color(0.05, 0.2, 0.05)},
	{"name": "Dark Mode", "bg": Color(0.15, 0.15, 0.2), "grid": Color(0.08, 0.08, 0.12)},
	{"name": "Ocean Blue", "bg": Color(0.05, 0.2, 0.35), "grid": Color(0.03, 0.12, 0.2)},
	{"name": "Wood", "bg": Color(0.35, 0.22, 0.08), "grid": Color(0.22, 0.14, 0.05)}
]

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Force container layout for children (deferred to apply after scene load)
	call_deferred("_set_layout_modes")
	populate_difficulty_selector()
	_populate_theme_selector()
	restart_button.pressed.connect(_on_restart_pressed)
	pass_button.pressed.connect(_on_pass_pressed)
	ai_toggle_checkbox.toggled.connect(_on_ai_toggle_changed)
	difficulty_selector.item_selected.connect(_on_difficulty_selected)
	theme_selector.item_selected.connect(_on_theme_selected)

	replay_button.pressed.connect(_on_replay_pressed)
	prev_button.pressed.connect(_on_replay_prev_pressed)
	next_button.pressed.connect(_on_replay_next_pressed)
	exit_replay_button.pressed.connect(_on_replay_exit_pressed)

	restart_button.visible = false
	pass_button.visible = false
	message_label.visible = false
	replay_button.visible = false
	replay_hbox.visible = false
	# Defer initial theme application so game_manager can connect to theme_applied first
	call_deferred("_apply_initial_theme")

func _set_layout_modes():
	for child in $MarginContainer/VBoxContainer.get_children():
		child.layout_mode = 3
		for grandchild in child.get_children():
			grandchild.layout_mode = 3

func populate_difficulty_selector():
	if difficulty_selector.item_count == 0:
		difficulty_selector.add_item("Easy")
		difficulty_selector.add_item("Medium")
		difficulty_selector.add_item("Hard")
		difficulty_selector.select(1)

func hide_settings():
	settings_hbox.visible = false

func show_settings(p_visible: bool = true):
	settings_hbox.visible = p_visible

func _on_ai_toggle_changed(p_pressed: bool):
	ai_toggle_changed.emit(p_pressed)

func _on_difficulty_selected(index: int):
	var depths = [2, 4, 6]
	difficulty_changed.emit(depths[index])

func update_scores(black: int, white: int):
	score_label.text = "Black: %d  |  White: %d" % [black, white]

func update_turn(player_name: String):
	turn_label.text = "Turn: %s" % player_name

func show_message(msg: String):
	message_label.text = msg
	message_label.visible = true

func hide_message():
	message_label.visible = false

func set_restart_button_visible(p_visible: bool):
	restart_button.visible = p_visible

func set_pass_button_visible(p_visible: bool):
	pass_button.visible = p_visible

func _on_restart_pressed():
	restart_requested.emit()

func _on_pass_pressed():
	pass_requested.emit()

func _populate_theme_selector():
	if theme_selector.item_count == 0:
		for t in _THEMES:
			theme_selector.add_item(t.name)
		theme_selector.select(0)

func _load_saved_theme() -> int:
	var cfg = ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		return cfg.get_value("settings", "theme_index", 0)
	return 0

func _save_theme(index: int):
	var cfg = ConfigFile.new()
	cfg.load("user://settings.cfg")
	cfg.set_value("settings", "theme_index", index)
	cfg.save("user://settings.cfg")

func _apply_theme(index: int):
	if index < 0 or index >= _THEMES.size():
		return
	var t = _THEMES[index]
	theme_applied.emit(t.bg, t.grid)
	theme_selector.select(index)
	_save_theme(index)

func _apply_initial_theme():
	var index = _load_saved_theme()
	_apply_theme(index)

func _on_theme_selected(index: int):
	_apply_theme(index)

func set_replay_button_visible(p_visible: bool):
	replay_button.visible = p_visible

func set_replay_controls_visible(p_visible: bool):
	replay_hbox.visible = p_visible

func update_step_label(current: int, total: int):
	step_label.text = "%d/%d" % [current, total]

func _on_replay_pressed():
	replay_requested.emit()

func _on_replay_prev_pressed():
	replay_prev_requested.emit()

func _on_replay_next_pressed():
	replay_next_requested.emit()

func _on_replay_exit_pressed():
	replay_exit_requested.emit()
