# Implementation Plan: Game History / Replay System

## Context

The game has no way to review completed games. Players want to replay finished games step by step to see how the position evolved. This plan adds move recording during normal play and a replay mode accessible after game-over with Prev/Next navigation.

## Files Modified

| File | Change |
|------|--------|
| `scripts/game_state.gd` | Fix `undo_move()` bug (line 67) |
| `scripts/board_cell.gd` | Add `set_piece_instantly()` and `set_replay_mode()` |
| `scripts/board.gd` | Add `render_state_instantly()` and `set_replay_mode()` |
| `scripts/ui_manager.gd` | Add replay signals, UI refs, step label method |
| `scripts/game_manager.gd` | Record moves, replay state machine, wire UI |
| `scenes/game_manager.tscn` | Add ReplayButton + ReplayHBox (Prev, StepLabel, Next, Exit) |

## Move Data Model

Each entry in `move_history` is one of:
- **Move:** `{"pos": Vector2i, "flips": Array[Vector2i], "player": int}`
- **Pass:** `{"pass": true, "player": int}`

Replay rebuilds from the initial 4-piece state by applying moves 0..N forward via `apply_move()`.

## Implementation Steps

### 1. `scripts/game_state.gd` — Fix undo_move bug

Line 67: change `set_cell(pos.x, pos.y, opponent)` → `set_cell(pos.x, pos.y, GameConstants.EMPTY)`. The placed cell was EMPTY before the move, not opponent-colored.

### 2. `scripts/board_cell.gd` — Instant rendering + replay mode

- Add `var replay_mode: bool = false`
- Add `func set_piece_instantly(player: int)`: forces cell to correct visual state (texture, visibility, scale) with no animation, no signal emissions
- Add `func set_replay_mode(enabled: bool)`: sets `replay_mode` flag, disables cell clicks via `mouse_filter = MOUSE_FILTER_IGNORE`

### 3. `scripts/board.gd` — Replay rendering

- Add `var replay_mode: bool = false`
- Add `func set_replay_mode(enabled: bool)`: propagates to all cells
- Add `func render_state_instantly()`: reads all cell values from `_state`, calls `set_piece_instantly()` on each cell, clears valid move dots and last-placed indicator, `queue_redraw()`

### 4. `scenes/game_manager.tscn` — Replay UI nodes

Add to `HBoxContainer` (sibling of RestartButton/PassButton):
- `ReplayButton` (Button, text "Replay", `visible = false`, `layout_mode = 2`)

Add after `HBoxContainer`, before `SettingsHBox`:
- `ReplayHBox` (HBoxContainer, `visible = false`, `layout_mode = 2`, `alignment = 1`)
  - `PrevButton` (Button, text "Prev", `layout_mode = 2`)
  - `StepLabel` (Label, text "0/0", `layout_mode = 2`, `size_flags_horizontal = 3`, `horizontal_alignment = 1`)
  - `NextButton` (Button, text "Next", `layout_mode = 2`)
  - `ExitReplayButton` (Button, text "Exit", `layout_mode = 2`)

### 5. `scripts/ui_manager.gd` — Replay signals and methods

- Add `@onready` refs: `replay_button`, `replay_hbox`, `prev_button`, `step_label`, `next_button`, `exit_replay_button`
- Add signals: `replay_requested`, `replay_prev_requested`, `replay_next_requested`, `replay_exit_requested`
- In `_ready()`: wire button pressed signals, set `replay_button.visible = false`, `replay_hbox.visible = false`
- Add methods: `set_replay_button_visible(bool)`, `set_replay_controls_visible(bool)`, `update_step_label(current, total)`

### 6. `scripts/game_manager.gd` — Move recording and replay logic

- Add vars: `move_history: Array = []`, `replay_mode: bool = false`, `replay_index: int = -1`
- In `init_game()`: clear `move_history`, reset replay flags
- In `perform_move()`: append move dict to `move_history` before `await board.place_piece()`
- In `switch_turn()` pass branch: append `{"pass": true, "player": current_player}` to history
- In `switch_turn()` game-over branch: call `ui_manager.set_replay_button_visible(true)`
- Add `enter_replay_mode()`: reset board to initial 4 pieces instantly, hide game controls, show replay controls, render initial position
- Add `step_replay(direction)`: rebuild board from initial state through move `replay_index + direction`, render instantly, update step label and scores
- Add `exit_replay_mode()`: rebuild final position, restore game-over UI
- In `_on_move_attempted()`: guard with `if replay_mode: return`
- In `_ready()`: wire `ui_manager.replay_requested`, `replay_prev_requested`, `replay_next_requested`, `replay_exit_requested`

## Step Counter Semantics

- `replay_index = -1`: Initial position. Label: `0/N`
- `replay_index = 0`: After first move. Label: `1/N`
- `replay_index = N-1`: Final position. Label: `N/N`

Pass entries increment the step counter but don't change the board.

## UI Visibility Matrix

| Element | Playing | Game-Over | Replay |
|---------|---------|-----------|--------|
| ScoreLabel | visible | visible | visible |
| MessageLabel | hidden | visible | hidden |
| TurnLabel | visible | visible | hidden |
| RestartButton | hidden | visible | hidden |
| ReplayButton | hidden | visible | hidden |
| PassButton | conditional | hidden | hidden |
| SettingsHBox | visible | visible | hidden |
| ReplayHBox | hidden | hidden | visible |

## Verification

1. Play a full game to game-over → Replay button appears
2. Click Replay → board shows initial 4 pieces, Prev/Next/Exit visible, step label `0/N`
3. Click Next → board shows position after move 1, label `1/N`
4. Click Prev → returns to initial position, label `0/N`
5. Step through all moves → final position matches game-over board
6. Click Exit → returns to game-over screen with score and Restart/Replay buttons
7. Pass moves appear as distinct steps in replay (board unchanged, counter advances)
8. Cell clicks are disabled during replay
